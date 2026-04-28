import 'dart:async';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';
import '../network/connectivity_service.dart';
import 'sync_queue_service.dart';

/// Estado de la sincronización
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Resultado de una sincronización
class SyncResult {
  final SyncStatus status;
  final int itemsSynced;
  final int itemsFailed;
  final String? error;
  final DateTime timestamp;

  SyncResult({
    required this.status,
    this.itemsSynced = 0,
    this.itemsFailed = 0,
    this.error,
  }) : timestamp = DateTime.now();
}

/// Servicio principal de sincronización
/// Coordina la sincronización de datos entre el almacenamiento local y el servidor
class SyncService {
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();
  final SyncQueueService _queue = SyncQueueService();

  final Dio _dio;
  final String _baseUrl;
  final String? _token;

  StreamController<SyncStatus>? _statusController;
  StreamController<int>? _pendingCountController;
  Timer? _periodicSyncTimer;

  bool _isSyncing = false;
  SyncStatus _currentStatus = SyncStatus.idle;

  SyncService({
    required String baseUrl,
    String? token,
  })  : _baseUrl = baseUrl,
        _token = token,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
        ));

  /// Stream del estado de sincronización
  Stream<SyncStatus> get statusStream {
    _statusController ??= StreamController<SyncStatus>.broadcast();
    return _statusController!.stream;
  }

  /// Stream del contador de items pendientes
  Stream<int> get pendingCountStream {
    _pendingCountController ??= StreamController<int>.broadcast();
    return _pendingCountController!.stream;
  }

  /// Inicializa el servicio de sincronización
  Future<void> initialize() async {
    await _connectivity.initialize();

    // Escuchar cambios en la conectividad
    _connectivity.connectionStream.listen((isConnected) {
      if (isConnected && !_isSyncing) {
        // Sincronizar automáticamente cuando se recupera la conexión
        syncPendingData();
      }
    });

    // Programar sincronización periódica cada 5 minutos
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncPendingData(),
    );

    // Actualizar contador inicial
    await _updatePendingCount();
  }

  /// Sincroniza todos los datos pendientes
  Future<SyncResult> syncPendingData() async {
    if (_isSyncing) {
      return SyncResult(
        status: SyncStatus.idle,
        error: 'Sincronización ya en progreso',
      );
    }

    if (!await _connectivity.checkConnection()) {
      return SyncResult(
        status: SyncStatus.error,
        error: 'Sin conexión a Internet',
      );
    }

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    int itemsSynced = 0;
    int itemsFailed = 0;
    String? lastError;

    try {
      final pendingItems = await _queue.getPendingItems();

      for (final item in pendingItems) {
        try {
          await _syncItem(item);
          await _queue.removeFromQueue(item.id!);
          itemsSynced++;
        } catch (e) {
          await _queue.markAsFailed(item.id!, e.toString());
          itemsFailed++;
          lastError = e.toString();
        }
      }

      await _updatePendingCount();

      if (itemsFailed == 0) {
        _updateStatus(SyncStatus.success);
        return SyncResult(
          status: SyncStatus.success,
          itemsSynced: itemsSynced,
        );
      } else {
        _updateStatus(SyncStatus.error);
        return SyncResult(
          status: SyncStatus.error,
          itemsSynced: itemsSynced,
          itemsFailed: itemsFailed,
          error: lastError,
        );
      }
    } catch (e) {
      _updateStatus(SyncStatus.error);
      return SyncResult(
        status: SyncStatus.error,
        itemsFailed: itemsFailed,
        error: e.toString(),
      );
    } finally {
      _isSyncing = false;
      // Volver a idle después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentStatus != SyncStatus.syncing) {
          _updateStatus(SyncStatus.idle);
        }
      });
    }
  }

  /// Sincroniza un item específico
  Future<void> _syncItem(SyncQueueItem item) async {
    final endpoint = _getEndpointForEntity(item.entityType);

    switch (item.operation) {
      case SyncOperation.create:
        await _dio.post(endpoint, data: item.data);
        break;
      case SyncOperation.update:
        final id = item.data['id'];
        await _dio.put('$endpoint/$id', data: item.data);
        break;
      case SyncOperation.delete:
        final id = item.data['id'];
        await _dio.delete('$endpoint/$id');
        break;
    }
  }

  String _getEndpointForEntity(EntityType type) {
    switch (type) {
      case EntityType.factura:
        return '/facturas';
      case EntityType.devolucion:
        return '/devoluciones';
      case EntityType.cliente:
        return '/clientes';
      case EntityType.producto:
        return '/productos';
      case EntityType.cargue:
        return '/cargues';
    }
  }

  /// Descarga datos desde el servidor y actualiza la base de datos local
  Future<void> downloadData() async {
    if (!await _connectivity.checkConnection()) {
      throw Exception('Sin conexión a Internet');
    }

    try {
      // Descargar productos
      final productosResponse = await _dio.get('/productos');
      await _saveProductosToLocal(productosResponse.data);

      // Descargar clientes
      final clientesResponse = await _dio.get('/clientes');
      await _saveClientesToLocal(clientesResponse.data);

      // Descargar categorías
      final categoriasResponse = await _dio.get('/categorias');
      await _saveCategoriasToLocal(categoriasResponse.data);

      // Descargar listas de precios
      final listasResponse = await _dio.get('/listas-precios');
      await _saveListasPreciosToLocal(listasResponse.data);

      // Descargar precios
      final preciosResponse = await _dio.get('/precios');
      await _savePreciosToLocal(preciosResponse.data);

      // Descargar cargues
      final carguesResponse = await _dio.get('/cargues');
      await _saveCarguesToLocal(carguesResponse.data);

      // Actualizar metadatos de sincronización
      await _updateSyncMetadata('last_download', DateTime.now().toIso8601String());
    } catch (e) {
      throw Exception('Error al descargar datos: $e');
    }
  }

  Future<void> _saveProductosToLocal(List<dynamic> productos) async {
    final db = await _db.database;
    final batch = db.batch();

    for (final producto in productos) {
      batch.insert(
        'productos',
        {
          'id': producto['id'],
          'uuid': producto['uuid'],
          'nombre': producto['nombre'],
          'descripcion': producto['descripcion'],
          'stock': producto['stock'],
          'categoria_id': producto['categoria_id'],
          'imagen_url': producto['imagen_url'],
          'created_at': producto['created_at'],
          'updated_at': producto['updated_at'],
          'synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> _saveClientesToLocal(List<dynamic> clientes) async {
    final db = await _db.database;
    final batch = db.batch();

    for (final cliente in clientes) {
      batch.insert(
        'clientes',
        {
          'id': cliente['id'],
          'uuid': cliente['uuid'],
          'nombre_establecimiento': cliente['nombre_establecimiento'],
          'propietario': cliente['propietario'],
          'email': cliente['email'],
          'telefono': cliente['telefono'],
          'direccion': cliente['direccion'],
          'ciudad': cliente['ciudad'],
          'departamento': cliente['departamento'],
          'codigo_postal': cliente['codigo_postal'],
          'pais': cliente['pais'],
          'codigo_cliente': cliente['codigo_cliente'],
          'nota': cliente['nota'],
          'puntos': cliente['puntos'],
          'visitas': cliente['visitas'],
          'created_at': cliente['created_at'],
          'updated_at': cliente['updated_at'],
          'synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> _saveCategoriasToLocal(List<dynamic> categorias) async {
    final db = await _db.database;
    final batch = db.batch();

    for (final categoria in categorias) {
      batch.insert(
        'categorias',
        {
          'id': categoria['id'],
          'uuid': categoria['uuid'],
          'nombre': categoria['nombre'],
          'descripcion': categoria['descripcion'],
          'created_at': categoria['created_at'],
          'updated_at': categoria['updated_at'],
          'synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> _saveListasPreciosToLocal(List<dynamic> listas) async {
    final db = await _db.database;
    final batch = db.batch();

    for (final lista in listas) {
      batch.insert(
        'listas_precios',
        {
          'id': lista['id'],
          'uuid': lista['uuid'],
          'nombre': lista['nombre'],
          'descripcion': lista['descripcion'],
          'created_at': lista['created_at'],
          'updated_at': lista['updated_at'],
          'synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> _savePreciosToLocal(List<dynamic> precios) async {
    final db = await _db.database;
    final batch = db.batch();

    for (final precio in precios) {
      batch.insert(
        'precios',
        {
          'id': precio['id'],
          'uuid': precio['uuid'],
          'producto_id': precio['producto_id'],
          'lista_id': precio['lista_id'],
          'precio': precio['precio'],
          'created_at': precio['created_at'],
          'updated_at': precio['updated_at'],
          'synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> _saveCarguesToLocal(List<dynamic> cargues) async {
    final db = await _db.database;
    final batch = db.batch();

    for (final cargue in cargues) {
      batch.insert(
        'cargues',
        {
          'id': cargue['id'],
          'uuid': cargue['uuid'],
          'numero_cargue': cargue['numero_cargue'],
          'usuario_id': cargue['usuario_id'],
          'fecha': cargue['fecha'],
          'total': cargue['total'],
          'estado': cargue['estado'],
          'comentario': cargue['comentario'],
          'created_at': cargue['created_at'],
          'updated_at': cargue['updated_at'],
          'synced': 1,
          'pending_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Guardar detalles si existen
      if (cargue['detalles'] != null && cargue['detalles'] is List) {
        for (final detalle in cargue['detalles']) {
          batch.insert(
            'cargues_detalles',
            {
              'id': detalle['id'],
              'uuid': detalle['uuid'],
              'cargue_id': detalle['cargue_id'],
              'producto_id': detalle['producto_id'],
              'cantidad': detalle['cantidad'],
              'cantidad_original': detalle['cantidad_original'],
              'precio_unitario': detalle['precio_unitario'],
              'subtotal': detalle['subtotal'],
              'comentario': detalle['comentario'],
              'despachado': detalle['despachado'] == true ? 1 : 0,
              'faltante': detalle['faltante'] == true ? 1 : 0,
              'created_at': detalle['created_at'],
              'updated_at': detalle['updated_at'],
              'synced': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }

    await batch.commit(noResult: true);
  }

  Future<void> _updateSyncMetadata(String key, String value) async {
    final db = await _db.database;
    await db.insert(
      'sync_metadata',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _updatePendingCount() async {
    final count = await _queue.getPendingCount();
    _pendingCountController?.add(count);
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController?.add(status);
  }

  /// Obtiene el número de items pendientes de sincronización
  Future<int> getPendingCount() => _queue.getPendingCount();

  /// Libera recursos
  void dispose() {
    _periodicSyncTimer?.cancel();
    _statusController?.close();
    _pendingCountController?.close();
    _connectivity.dispose();
  }
}
