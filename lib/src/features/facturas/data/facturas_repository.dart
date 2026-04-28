import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/factura.dart';
import '../domain/usuario_factura.dart';
import '../domain/devolucion.dart';
import '../../../core/database/database_service.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../../../core/network/connectivity_service.dart';

class FacturasRepository {
  final Dio _dio;
  final DatabaseService _db = DatabaseService();
  final SyncQueueService _queue = SyncQueueService();
  final ConnectivityService _connectivity = ConnectivityService();

  FacturasRepository(String baseUrl, String? token)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
        ));

  // ------------------------------------------------------------
  // OBTENER FACTURAS SEGÚN ROL (con soporte offline)
  // ------------------------------------------------------------
  Future<List<Factura>> obtenerFacturas({
    int? usuarioId,
    List<int>? usuariosIds,
  }) async {
    try {
      // Primero obtener de la base de datos local
      final db = await _db.database;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (usuarioId != null) {
        whereClause += ' AND f.usuario_id = ?';
        whereArgs.add(usuarioId);
      }

      if (usuariosIds != null && usuariosIds.isNotEmpty) {
        final placeholders = List.filled(usuariosIds.length, '?').join(',');
        whereClause += ' AND f.usuario_id IN ($placeholders)';
        whereArgs.addAll(usuariosIds);
      }

      // Usar rawQuery con JOIN para obtener nombres de cliente y usuario
      final List<Map<String, dynamic>> localFacturas = await db.rawQuery('''
        SELECT
          f.id,
          f.uuid,
          f.numero_factura,
          f.usuario_id,
          f.cliente_id,
          f.descuento_id,
          f.subtotal,
          f.descuento,
          f.total,
          f.estado,
          f.fecha,
          f.created_at,
          f.updated_at,
          c.nombre_establecimiento as cliente_nombre,
          u.nombre as usuario_nombre
        FROM facturas f
        LEFT JOIN clientes c ON f.cliente_id = c.id
        LEFT JOIN usuarios u ON f.usuario_id = u.id
        WHERE $whereClause
        ORDER BY f.created_at DESC
      ''', whereArgs.isNotEmpty ? whereArgs : []);

      print('[FacturasRepository] Facturas locales encontradas: ${localFacturas.length}');

      // Si la lista local está vacía Y hay conexión, sincronizar primero
      if (localFacturas.isEmpty && await _connectivity.checkConnection()) {
        print('[FacturasRepository] Lista local vacía, sincronizando desde servidor...');
        await _syncFacturasInBackground(usuarioId: usuarioId, usuariosIds: usuariosIds);

        // Volver a leer de la BD local después de sincronizar
        final List<Map<String, dynamic>> facturasSincronizadas = await db.rawQuery('''
          SELECT
            f.id,
            f.uuid,
            f.numero_factura,
            f.usuario_id,
            f.cliente_id,
            f.descuento_id,
            f.subtotal,
            f.descuento,
            f.total,
            f.estado,
            f.fecha,
            f.created_at,
            f.updated_at,
            c.nombre_establecimiento as cliente_nombre,
            u.nombre as usuario_nombre
          FROM facturas f
          LEFT JOIN clientes c ON f.cliente_id = c.id
          LEFT JOIN usuarios u ON f.usuario_id = u.id
          WHERE $whereClause
          ORDER BY f.created_at DESC
        ''', whereArgs.isNotEmpty ? whereArgs : []);

        print('[FacturasRepository] Facturas después de sincronizar: ${facturasSincronizadas.length}');
        return facturasSincronizadas.map((map) => _facturaFromLocalDb(map)).toList();
      }

      // Convertir de formato SQLite a modelo Factura
      final facturas = await Future.wait(
        localFacturas.map((map) => _facturaFromLocalDbWithDevoluciones(map, db))
      );

      // Si hay facturas locales y hay conexión, sincronizar en background
      if (facturas.isNotEmpty && await _connectivity.checkConnection()) {
        _syncFacturasInBackground(usuarioId: usuarioId, usuariosIds: usuariosIds);
      }

      return facturas;
    } catch (e, stack) {
      print('[FacturasRepository] Error al obtener facturas: $e');
      print('[FacturasRepository] Stack: $stack');

      // Si falla la lectura local, intentar desde el servidor
      return _obtenerFacturasDesdeServidor(
        usuarioId: usuarioId,
        usuariosIds: usuariosIds,
      );
    }
  }

  // Obtener facturas desde el servidor (método legacy para fallback)
  Future<List<Factura>> _obtenerFacturasDesdeServidor({
    int? usuarioId,
    List<int>? usuariosIds,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (usuarioId != null) {
        queryParams['usuario_id'] = usuarioId;
      }

      if (usuariosIds != null && usuariosIds.isNotEmpty) {
        queryParams['usuarios_ids'] = usuariosIds.join(',');
      }

      print('[FacturasRepository] Obteniendo facturas del servidor con params: $queryParams');

      final response = await _dio.get(
        "/facturas",
        queryParameters: queryParams,
      );

      print('[FacturasRepository] Response status: ${response.statusCode}');
      print('[FacturasRepository] Response data type: ${response.data.runtimeType}');

      // El API retorna un array directo
      final List<dynamic> data = response.data is List ? response.data : [];
      print('[FacturasRepository] Facturas en response: ${data.length}');

      if (data.isEmpty) {
        print('[FacturasRepository] WARNING: Response data está vacío!');
        return [];
      }

      print('[FacturasRepository] Primera factura JSON keys: ${(data[0] as Map).keys.toList()}');

      try {
        final facturas = data.map((json) {
          try {
            return Factura.fromJson(json);
          } catch (e) {
            print('[FacturasRepository] Error parseando factura individual: $e');
            print('[FacturasRepository] JSON problemático keys: ${(json as Map).keys.toList()}');
            rethrow;
          }
        }).toList();

        print('[FacturasRepository] Facturas parseadas correctamente: ${facturas.length}');
        return facturas;
      } catch (e) {
        print('[FacturasRepository] Error en el mapeo de facturas: $e');
        rethrow;
      }
    } on DioException catch (e) {
      print('[FacturasRepository] DioException: ${e.type}');
      print('[FacturasRepository] Error message: ${e.message}');
      throw _handleError(e);
    }
  }

  // Método público para forzar sincronización desde el servidor
  Future<void> syncFromServer({int? usuarioId, List<int>? usuariosIds}) async {
    await _syncFacturasInBackground(usuarioId: usuarioId, usuariosIds: usuariosIds);
  }

  // Sincronizar facturas en background
  Future<void> _syncFacturasInBackground({
    int? usuarioId,
    List<int>? usuariosIds,
  }) async {
    try {
      print('[FacturasRepository._syncFacturasInBackground] ===== INICIANDO SINCRONIZACIÓN =====');
      print('[FacturasRepository._syncFacturasInBackground] usuarioId: $usuarioId, usuariosIds: $usuariosIds');

      final facturas = await _obtenerFacturasDesdeServidor(
        usuarioId: usuarioId,
        usuariosIds: usuariosIds,
      );

      print('[FacturasRepository._syncFacturasInBackground] Facturas obtenidas del servidor: ${facturas.length}');

      final db = await _db.database;
      print('[FacturasRepository._syncFacturasInBackground] Base de datos obtenida, insertando facturas...');

      int insertadas = 0;
      for (final factura in facturas) {
        try {
          await db.insert(
            'facturas',
            {
              'id': factura.id,
              'uuid': factura.uuid,
              'cliente_id': factura.clienteId,
              'usuario_id': factura.usuarioId,
              'numero_factura': factura.numeroFactura,
              'subtotal': factura.subtotal,
              'descuento': factura.descuento,
              'total': factura.total,
              'estado': factura.estado,
              'fecha': factura.fechaCreacion.toIso8601String(),
              'created_at': factura.fechaCreacion.toIso8601String(),
              // Si no hay fecha de actualización, usar fecha de creación
              'updated_at': factura.fechaActualizacion?.toIso8601String() ?? factura.fechaCreacion.toIso8601String(),
              'synced': 1,
              'pending_sync': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          insertadas++;

          // Sincronizar los items (detalles) de esta factura
          await _syncFacturaItems(factura.id);

          // Sincronizar las devoluciones de esta factura
          await _syncFacturaDevoluciones(factura);
        } catch (e) {
          print('[FacturasRepository._syncFacturasInBackground] Error insertando factura ${factura.id}: $e');
        }
      }

      print('[FacturasRepository._syncFacturasInBackground] Facturas insertadas: $insertadas de ${facturas.length}');
      print('[FacturasRepository._syncFacturasInBackground] ===== SINCRONIZACIÓN COMPLETADA =====');
    } catch (e, stackTrace) {
      print('[FacturasRepository._syncFacturasInBackground] ===== ERROR EN SINCRONIZACIÓN =====');
      print('[FacturasRepository._syncFacturasInBackground] Error: $e');
      print('[FacturasRepository._syncFacturasInBackground] Stack trace: $stackTrace');
      // Ignorar errores de sincronización en background
    }
  }

  /// Sincronizar items de una factura específica desde el servidor
  Future<void> _syncFacturaItems(int facturaId) async {
    try {
      // Obtener los items de la factura desde el servidor
      final response = await _dio.get("/facturas/$facturaId/detalles");
      final List<dynamic> items = response.data is List ? response.data : [];

      if (items.isEmpty) {
        return;
      }

      final db = await _db.database;

      // Insertar cada item en la tabla facturas_items
      for (final itemJson in items) {
        // Validar que los campos requeridos no sean null
        final precioUnitario = itemJson['precio_unitario'] ?? 0.0;
        final cantidad = itemJson['cantidad'] ?? 0;
        final subtotal = itemJson['subtotal'] ?? (precioUnitario * cantidad);

        await db.insert(
          'facturas_items',
          {
            'id': itemJson['id'],
            'uuid': itemJson['uuid'] ?? 'item-${itemJson['id']}-${itemJson['factura_id']}',
            'factura_id': itemJson['factura_id'],
            'producto_id': itemJson['producto_id'],
            'cantidad': cantidad,
            'precio_unitario': precioUnitario,
            'subtotal': subtotal,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('[FacturasRepository._syncFacturaItems] Items sincronizados para factura $facturaId: ${items.length}');
    } catch (e) {
      print('[FacturasRepository._syncFacturaItems] Error sincronizando items de factura $facturaId: $e');
      // Ignorar errores al sincronizar items individuales
    }
  }

  /// Sincronizar devoluciones de una factura desde el modelo ya cargado
  Future<void> _syncFacturaDevoluciones(Factura factura) async {
    try {
      if (factura.devoluciones.isEmpty) {
        return;
      }

      final db = await _db.database;

      // Insertar cada devolución en la tabla devoluciones
      for (final devolucion in factura.devoluciones) {
        await db.insert(
          'devoluciones',
          {
            'id': devolucion.id,
            'uuid': devolucion.uuid,
            'factura_id': devolucion.facturaId,
            'usuario_id': devolucion.usuarioId,
            'motivo': devolucion.motivo,
            'total': devolucion.total,
            'fecha': devolucion.fecha.toIso8601String(),
            'created_at': devolucion.fecha.toIso8601String(),
            'updated_at': devolucion.fecha.toIso8601String(),
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('[FacturasRepository._syncFacturaDevoluciones] Devoluciones sincronizadas para factura ${factura.id}: ${factura.devoluciones.length}');
    } catch (e) {
      print('[FacturasRepository._syncFacturaDevoluciones] Error sincronizando devoluciones de factura ${factura.id}: $e');
      // Ignorar errores al sincronizar devoluciones individuales
    }
  }

  // Convertir registro de SQLite a modelo Factura
  Factura _facturaFromLocalDb(Map<String, dynamic> map) {
    return Factura(
      id: map['id'] as int,
      uuid: map['uuid'] as String,
      clienteId: map['cliente_id'] as int,
      clienteNombre: map['cliente_nombre'] as String?, // Viene del JOIN con clientes
      usuarioId: map['usuario_id'] as int,
      usuarioNombre: map['usuario_nombre'] as String?, // Viene del JOIN con usuarios
      numeroFactura: map['numero_factura'] as String?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      descuento: (map['descuento'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      estado: map['estado'] as String? ?? 'completada',
      fechaCreacion: DateTime.parse(map['fecha'] as String),
      fechaActualizacion: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      devoluciones: const [],
    );
  }

  // Convertir registro de SQLite a modelo Factura con devoluciones
  Future<Factura> _facturaFromLocalDbWithDevoluciones(Map<String, dynamic> map, Database db) async {
    final facturaId = map['id'] as int;

    // Obtener devoluciones de esta factura
    final List<Map<String, dynamic>> devolucionesData = await db.query(
      'devoluciones',
      where: 'factura_id = ?',
      whereArgs: [facturaId],
      orderBy: 'fecha DESC',
    );

    final devoluciones = devolucionesData.map((devMap) {
      return Devolucion(
        id: devMap['id'] as int,
        uuid: devMap['uuid'] as String,
        clienteId: map['cliente_id'] as int, // Usar el cliente de la factura
        clienteNombre: map['cliente_nombre'] as String?,
        usuarioId: devMap['usuario_id'] as int,
        facturaId: facturaId,
        motivo: devMap['motivo'] as String? ?? '',
        total: (devMap['total'] as num?)?.toDouble() ?? 0.0,
        fecha: DateTime.parse(devMap['fecha'] as String),
      );
    }).toList();

    return Factura(
      id: facturaId,
      uuid: map['uuid'] as String,
      clienteId: map['cliente_id'] as int,
      clienteNombre: map['cliente_nombre'] as String?,
      usuarioId: map['usuario_id'] as int,
      usuarioNombre: map['usuario_nombre'] as String?,
      numeroFactura: map['numero_factura'] as String?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      descuento: (map['descuento'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      estado: map['estado'] as String? ?? 'completada',
      fechaCreacion: DateTime.parse(map['fecha'] as String),
      fechaActualizacion: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      devoluciones: devoluciones,
    );
  }

  // ------------------------------------------------------------
  // OBTENER USUARIOS (para filtro de admin)
  // ------------------------------------------------------------
  Future<List<UsuarioFactura>> obtenerUsuarios() async {
    try {
      final response = await _dio.get("/usuarios");

      // El API retorna un array directo
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((json) => UsuarioFactura.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ------------------------------------------------------------
  // OBTENER DETALLE DE FACTURA
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> obtenerDetalleFactura(int facturaId) async {
    try {
      final response = await _dio.get("/facturas/$facturaId");
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ------------------------------------------------------------
  // OBTENER DETALLES (PRODUCTOS) DE UNA FACTURA
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerDetallesFactura(int facturaId) async {
    try {
      // Primero intentar obtener desde la base de datos local
      final db = await _db.database;

      // Buscar los items de la factura en SQLite con JOIN a productos
      final List<Map<String, dynamic>> localItems = await db.rawQuery('''
        SELECT
          fi.id,
          fi.factura_id,
          fi.producto_id,
          fi.cantidad,
          fi.precio_unitario,
          fi.subtotal,
          fi.comentario,
          p.nombre as producto_nombre,
          p.descripcion as producto_descripcion
        FROM facturas_items fi
        INNER JOIN productos p ON fi.producto_id = p.id
        WHERE fi.factura_id = ?
        ORDER BY fi.id ASC
      ''', [facturaId]);

      print('[FacturasRepository.obtenerDetallesFactura] Items locales encontrados: ${localItems.length}');

      if (localItems.isNotEmpty) {
        // Convertir formato SQLite a formato esperado por la UI
        final detalles = localItems.map((item) {
          return {
            'id': item['id'],
            'factura_id': item['factura_id'],
            'producto_id': item['producto_id'],
            'cantidad': item['cantidad'],
            'precio_unitario': item['precio_unitario'],
            'subtotal': item['subtotal'],
            'comentario': item['comentario'],
            'Producto': {
              'id': item['producto_id'],
              'nombre': item['producto_nombre'],
              'descripcion': item['producto_descripcion'],
            },
          };
        }).toList();

        return detalles;
      }

      // Si no hay items locales y hay conexión, obtener del servidor
      if (await _connectivity.checkConnection()) {
        print('[FacturasRepository.obtenerDetallesFactura] No hay items locales, consultando servidor...');
        final response = await _dio.get("/facturas/$facturaId/detalles");
        final List<dynamic> data = response.data is List ? response.data : [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }

      // Si no hay conexión, retornar lista vacía
      print('[FacturasRepository.obtenerDetallesFactura] Sin conexión y sin items locales');
      return [];
    } on DioException catch (e) {
      // Si falla el servidor, intentar leer de SQLite como fallback
      try {
        final db = await _db.database;
        final List<Map<String, dynamic>> localItems = await db.rawQuery('''
          SELECT
            fi.id,
            fi.factura_id,
            fi.producto_id,
            fi.cantidad,
            fi.precio_unitario,
            fi.subtotal,
            fi.comentario,
            p.nombre as producto_nombre,
            p.descripcion as producto_descripcion
          FROM facturas_items fi
          INNER JOIN productos p ON fi.producto_id = p.id
          WHERE fi.factura_id = ?
          ORDER BY fi.id ASC
        ''', [facturaId]);

        return localItems.map((item) {
          return {
            'id': item['id'],
            'factura_id': item['factura_id'],
            'producto_id': item['producto_id'],
            'cantidad': item['cantidad'],
            'precio_unitario': item['precio_unitario'],
            'subtotal': item['subtotal'],
            'comentario': item['comentario'],
            'Producto': {
              'id': item['producto_id'],
              'nombre': item['producto_nombre'],
              'descripcion': item['producto_descripcion'],
            },
          };
        }).toList();
      } catch (sqliteError) {
        throw _handleError(e);
      }
    } catch (e) {
      print('[FacturasRepository.obtenerDetallesFactura] Error: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // REEMBOLSAR FACTURA
  // ------------------------------------------------------------
  Future<void> reembolsarFactura(int facturaId, List<int> detallesIds) async {
    // Verificar conexión antes de permitir reembolso
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden procesar reembolsos sin conexión a internet');
    }

    try {
      await _dio.post(
        "/facturas/$facturaId/devolucion",
        data: {
          'detalles_ids': detallesIds,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ------------------------------------------------------------
  // REEMBOLSAR FACTURA CON CANTIDADES ESPECÍFICAS
  // ------------------------------------------------------------
  Future<void> reembolsarFacturaConCantidades(
    int facturaId,
    List<Map<String, dynamic>> detallesReembolso,
  ) async {
    // Verificar conexión antes de permitir reembolso
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden procesar reembolsos sin conexión a internet');
    }

    try {
      await _dio.post(
        "/facturas/$facturaId/devolucion",
        data: {
          'detalles': detallesReembolso,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ------------------------------------------------------------
  // OBTENER DETALLE DE DEVOLUCIÓN
  // ------------------------------------------------------------
  Future<Devolucion> obtenerDevolucion(int devolucionId) async {
    try {
      print('🔍 [obtenerDevolucion] Solicitando devolución ID: $devolucionId');
      final url = "/facturas/devoluciones/$devolucionId";
      print('🔍 [obtenerDevolucion] URL: $url');
      print('🔍 [obtenerDevolucion] Base URL completa: ${_dio.options.baseUrl}$url');

      final response = await _dio.get(url);

      print('✅ [obtenerDevolucion] Respuesta recibida con código: ${response.statusCode}');
      print('✅ [obtenerDevolucion] Datos recibidos: ${response.data}');

      return Devolucion.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ [obtenerDevolucion] Error de Dio: ${e.type}');
      print('❌ [obtenerDevolucion] Mensaje: ${e.message}');
      print('❌ [obtenerDevolucion] Respuesta: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('❌ [obtenerDevolucion] Error general: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // ELIMINAR FACTURA
  // ------------------------------------------------------------
  Future<void> eliminarFactura(int facturaId) async {
    // Verificar conexión antes de permitir eliminación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden eliminar facturas sin conexión a internet');
    }

    try {
      await _dio.delete("/facturas/$facturaId");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ------------------------------------------------------------
  // Error handler
  // ------------------------------------------------------------
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      String errorMessage = "Error desconocido en el servidor";

      if (data is Map) {
        errorMessage = data["mensaje"] ??
                      data["message"] ??
                      data["error"] ??
                      errorMessage;
      }

      return Exception(errorMessage);
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception("No hay conexión con el servidor");
    }

    if (e.type == DioExceptionType.connectionTimeout) {
      return Exception("Tiempo de espera agotado");
    }

    return Exception("Error inesperado");
  }
}