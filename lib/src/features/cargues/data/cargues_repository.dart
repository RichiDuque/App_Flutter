import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/cargue.dart';
import '../domain/detalle_cargue.dart';
import '../../productos/domain/producto.dart';
import '../../usuarios/domain/vendedor.dart';
import '../../../core/database/database_service.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../../../core/network/connectivity_service.dart';

class CarguesRepository {
  final Dio _dio;
  final DatabaseService _db = DatabaseService();
  final SyncQueueService _queue = SyncQueueService();
  final ConnectivityService _connectivity = ConnectivityService();

  CarguesRepository({
    required String baseUrl,
    String? token,
    String? vendedorNombre, // Ya no se usa, pero lo dejamos para compatibilidad
  })  : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
        ));

  // Obtener todos los cargues (con soporte offline)
  Future<List<Cargue>> getCargues({
    int? usuarioId,
    String? usuariosIds,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      // Primero obtener de la base de datos local
      final db = await _db.database;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (usuarioId != null) {
        whereClause += ' AND usuario_id = ?';
        whereArgs.add(usuarioId);
      }

      final List<Map<String, dynamic>> localCargues = await db.query(
        'cargues',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
      );

      print('[CarguesRepository] Cargues locales encontrados: ${localCargues.length}');

      // Si hay conexión, sincronizar
      if (await _connectivity.checkConnection()) {
        // Si la base de datos local está vacía, esperar la sincronización
        if (localCargues.isEmpty) {
          print('[CarguesRepository] Base de datos vacía, sincronizando desde servidor...');
          await _syncCarguesInBackground(
            usuarioId: usuarioId,
            usuariosIds: usuariosIds,
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
          );

          // Volver a consultar después de la sincronización
          final List<Map<String, dynamic>> updatedCargues = await db.query(
            'cargues',
            where: whereClause,
            whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
            orderBy: 'created_at DESC',
          );

          print('[CarguesRepository] Cargues después de sincronización: ${updatedCargues.length}');

          final cargues = await Future.wait(
            updatedCargues.map((map) => _cargueFromLocalDb(map))
          );
          return cargues;
        } else {
          // Si ya hay datos locales, sincronizar en background
          _syncCarguesInBackground(
            usuarioId: usuarioId,
            usuariosIds: usuariosIds,
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
          );
        }
      }

      // Convertir de formato SQLite a modelo Cargue
      final cargues = await Future.wait(
        localCargues.map((map) => _cargueFromLocalDb(map))
      );

      return cargues;
    } catch (e, stack) {
      print('[CarguesRepository] Error al obtener cargues: $e');
      print('[CarguesRepository] Stack: $stack');

      // Si falla la lectura local, intentar desde el servidor
      return _getCarguesFromServer(
        usuarioId: usuarioId,
        usuariosIds: usuariosIds,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
    }
  }

  // Obtener cargues desde el servidor (método legacy para fallback)
  Future<List<Cargue>> _getCarguesFromServer({
    int? usuarioId,
    String? usuariosIds,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (usuarioId != null) queryParams['usuario_id'] = usuarioId;
      if (usuariosIds != null) queryParams['usuarios_ids'] = usuariosIds;
      if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

      final response = await _dio.get('/cargues', queryParameters: queryParams);
      final List<dynamic> data = response.data;
      return data.map((json) => Cargue.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método público para forzar sincronización desde el servidor
  Future<void> syncFromServer() async {
    await _syncCarguesInBackground(
      usuarioId: null,
      usuariosIds: null,
      fechaInicio: null,
      fechaFin: null,
    );
  }

  // Sincronizar cargues en background
  Future<void> _syncCarguesInBackground({
    int? usuarioId,
    String? usuariosIds,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final cargues = await _getCarguesFromServer(
        usuarioId: usuarioId,
        usuariosIds: usuariosIds,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      final db = await _db.database;

      for (final cargue in cargues) {
        // Insertar el cargue
        await db.insert(
          'cargues',
          {
            'id': cargue.id,
            'uuid': cargue.uuid,
            'numero_cargue': cargue.numeroCargue,
            'usuario_id': cargue.usuarioId,
            'fecha': cargue.fecha.toIso8601String(),
            'total': cargue.total,
            'estado': cargue.estado,
            'comentario': cargue.comentario,
            'created_at': cargue.fecha.toIso8601String(),
            'updated_at': cargue.fecha.toIso8601String(),
            'synced': 1,
            'pending_sync': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insertar el usuario si existe
        if (cargue.usuario != null) {
          // Generar UUID único para el usuario
          final usuarioUuid = 'user-${cargue.usuario!.id}-${cargue.usuario!.email}';

          await db.insert(
            'usuarios',
            {
              'id': cargue.usuario!.id,
              'uuid': usuarioUuid,
              'nombre': cargue.usuario!.nombre,
              'email': cargue.usuario!.email ?? '',
              'rol': cargue.usuario!.rol ?? 'vendedor',
              'lista_id': cargue.usuario!.listaPreciosId,
              'activo': 1,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'synced': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Insertar los detalles del cargue
        for (final detalle in cargue.detalles) {
          await db.insert(
            'cargues_detalles',
            {
              'id': detalle.id,
              'uuid': detalle.uuid ?? '',
              'cargue_id': cargue.id,
              'producto_id': detalle.productoId,
              'cantidad': detalle.cantidad,
              'cantidad_original': detalle.cantidadOriginal ?? detalle.cantidad,
              'precio_unitario': detalle.precioUnitario,
              'subtotal': detalle.subtotal,
              'comentario': detalle.comentario,
              'despachado': detalle.despachado ? 1 : 0,
              'faltante': detalle.faltante ? 1 : 0,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'synced': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      print('[CarguesRepository] Sincronización en background completada: ${cargues.length} cargues');
    } catch (e) {
      print('[CarguesRepository] Error en sincronización background: $e');
      // Ignorar errores de sincronización en background
    }
  }

  // Convertir registro de SQLite a modelo Cargue
  Future<Cargue> _cargueFromLocalDb(Map<String, dynamic> map) async {
    final db = await _db.database;
    final cargueId = map['id'] as int;
    final usuarioId = map['usuario_id'] as int;

    // Cargar el usuario desde la tabla usuarios
    Vendedor? usuario;
    try {
      final List<Map<String, dynamic>> usuarioResult = await db.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [usuarioId],
        limit: 1,
      );

      if (usuarioResult.isNotEmpty) {
        final usuarioMap = usuarioResult.first;
        usuario = Vendedor(
          id: usuarioMap['id'] as int,
          nombre: usuarioMap['nombre'] as String,
          email: usuarioMap['email'] as String? ?? '',
          rol: usuarioMap['rol'] as String? ?? 'vendedor',
          listaPreciosId: usuarioMap['lista_id'] as int?,
        );
      }
    } catch (e) {
      print('[CarguesRepository] Error al cargar usuario: $e');
    }

    // Cargar los detalles desde cargues_detalles con JOIN a productos
    List<DetalleCargue> detalles = [];
    try {
      final List<Map<String, dynamic>> detallesResult = await db.rawQuery('''
        SELECT
          cd.id, cd.uuid, cd.cargue_id, cd.producto_id, cd.cantidad,
          cd.cantidad_original, cd.precio_unitario, cd.subtotal,
          cd.comentario, cd.despachado, cd.faltante,
          p.id as p_id, p.uuid as p_uuid, p.nombre as p_nombre,
          p.descripcion as p_descripcion, p.stock as p_stock,
          p.categoria_id as p_categoria_id, p.imagen_url as p_imagen_url
        FROM cargues_detalles cd
        LEFT JOIN productos p ON cd.producto_id = p.id
        WHERE cd.cargue_id = ?
      ''', [cargueId]);

      detalles = detallesResult.map((detalleMap) {
        Producto? producto;
        if (detalleMap['p_id'] != null) {
          producto = Producto(
            id: detalleMap['p_id'] as int,
            uuid: detalleMap['p_uuid'] as String? ?? '',
            nombre: detalleMap['p_nombre'] as String? ?? 'Sin nombre',
            descripcion: detalleMap['p_descripcion'] as String?,
            precio: (detalleMap['precio_unitario'] as num).toDouble(),
            stock: detalleMap['p_stock'] as int? ?? 0,
            categoriaId: detalleMap['p_categoria_id'] as int?,
            imagenUrl: detalleMap['p_imagen_url'] as String?,
          );
        }

        return DetalleCargue(
          id: detalleMap['id'] as int,
          uuid: detalleMap['uuid'] as String,
          cargueId: detalleMap['cargue_id'] as int,
          productoId: detalleMap['producto_id'] as int,
          cantidad: detalleMap['cantidad'] as int,
          cantidadOriginal: detalleMap['cantidad_original'] as int?,
          precioUnitario: (detalleMap['precio_unitario'] as num).toDouble(),
          subtotal: (detalleMap['subtotal'] as num).toDouble(),
          comentario: detalleMap['comentario'] as String?,
          despachado: (detalleMap['despachado'] as int) == 1,
          faltante: (detalleMap['faltante'] as int) == 1,
          producto: producto,
        );
      }).toList();
    } catch (e) {
      print('[CarguesRepository] Error al cargar detalles: $e');
    }

    return Cargue(
      id: cargueId,
      uuid: map['uuid'] as String,
      numeroCargue: map['numero_cargue'] as String?,
      usuarioId: usuarioId,
      fecha: DateTime.parse(map['fecha'] as String),
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      estado: map['estado'] as String? ?? 'pendiente',
      comentario: map['comentario'] as String?,
      usuario: usuario,
      detalles: detalles,
    );
  }

  // Obtener cargue por ID (offline-first)
  Future<Cargue> getCargueById(int id) async {
    try {
      // Primero intentar obtener desde la base de datos local
      final db = await _db.database;

      final List<Map<String, dynamic>> localCargue = await db.query(
        'cargues',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      print('[CarguesRepository.getCargueById] Cargue local encontrado: ${localCargue.isNotEmpty}');

      if (localCargue.isNotEmpty) {
        // Convertir de SQLite a modelo Cargue (con usuario y detalles)
        return await _cargueFromLocalDb(localCargue.first);
      }

      // Si no hay cargue local y hay conexión, obtener del servidor
      if (await _connectivity.checkConnection()) {
        print('[CarguesRepository.getCargueById] No hay cargue local, consultando servidor...');
        final response = await _dio.get('/cargues/$id');
        return Cargue.fromJson(response.data);
      }

      // Si no hay conexión, lanzar error
      throw Exception('No se encontró el cargue en la base de datos local y no hay conexión a internet');
    } on DioException catch (e) {
      // Si falla el servidor, intentar leer de SQLite como fallback
      try {
        final db = await _db.database;
        final List<Map<String, dynamic>> localCargue = await db.query(
          'cargues',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (localCargue.isNotEmpty) {
          return await _cargueFromLocalDb(localCargue.first);
        }

        throw _handleError(e);
      } catch (sqliteError) {
        throw _handleError(e);
      }
    } catch (e) {
      print('[CarguesRepository.getCargueById] Error: $e');
      rethrow;
    }
  }

  // Crear cargue (con soporte offline)
  Future<Cargue> crearCargue(Map<String, dynamic> data) async {
    try {
      final uuid = const Uuid().v4();
      final now = DateTime.now();

      print('=== CREAR CARGUE (OFFLINE FIRST) ===');
      print('Datos enviados: $data');

      // Preparar datos para guardar localmente
      final cargueLocal = {
        'uuid': uuid,
        'numero_cargue': 'TEMP-$uuid',
        'usuario_id': data['usuario_id'],
        'fecha': now.toIso8601String(),
        'total': data['total'] ?? 0,
        'estado': data['estado'] ?? 'pendiente',
        'comentario': data['comentario'],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'synced': 0,
        'pending_sync': 1,
      };

      // Guardar en base de datos local
      final db = await _db.database;
      final cargueId = await db.insert('cargues', cargueLocal);

      print('Cargue guardado localmente con ID: $cargueId');

      // Guardar detalles del cargue si existen
      if (data['detalles'] != null && data['detalles'] is List) {
        final detalles = data['detalles'] as List;
        for (final detalle in detalles) {
          await db.insert('cargues_detalles', {
            'uuid': const Uuid().v4(),
            'cargue_id': cargueId,
            'producto_id': detalle['producto_id'],
            'cantidad': detalle['cantidad'],
            'cantidad_original': detalle['cantidad'],
            'precio_unitario': detalle['precio_unitario'] ?? 0,
            'subtotal': detalle['subtotal'] ?? 0,
            'comentario': detalle['comentario'],
            'despachado': 0,
            'faltante': 0,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'synced': 0,
          });
        }
      }

      // Agregar a cola de sincronización
      await _queue.addToQueue(SyncQueueItem(
        entityType: EntityType.cargue,
        entityUuid: uuid,
        operation: SyncOperation.create,
        data: data,
      ));

      print('Cargue agregado a cola de sincronización');

      // Intentar sincronizar inmediatamente si hay conexión
      if (await _connectivity.checkConnection()) {
        try {
          print('Conexión detectada, intentando sincronizar inmediatamente...');
          final response = await _dio.post('/cargues', data: data);

          print('Respuesta recibida del servidor: ${response.data}');

          // Actualizar con datos reales del servidor
          await db.update(
            'cargues',
            {
              'id': response.data['id'],
              'numero_cargue': response.data['numero_cargue'],
              'synced': 1,
              'pending_sync': 0,
            },
            where: 'uuid = ?',
            whereArgs: [uuid],
          );

          // Remover de cola
          await _queue.removeByUuid(EntityType.cargue, uuid);

          print('Cargue sincronizado exitosamente');

          return Cargue.fromJson(response.data);
        } catch (e) {
          if (e is DioException && e.response != null) {
            print('[CarguesRepository] Error servidor ${e.response?.statusCode}: ${e.response?.data}');
          } else {
            print('[CarguesRepository] Error al sincronizar inmediatamente: $e');
          }
          // Si falla la sincronización inmediata, quedará en cola para reintento
        }
      } else {
        print('Sin conexión, cargue quedará en cola para sincronización posterior');
      }

      // Retornar cargue local si no se pudo sincronizar
      return Cargue(
        id: cargueId,
        uuid: uuid,
        numeroCargue: 'TEMP-$uuid',
        usuarioId: data['usuario_id'],
        fecha: now,
        total: (data['total'] ?? 0).toDouble(),
        estado: data['estado'] ?? 'pendiente',
        comentario: data['comentario'],
        detalles: [],
      );
    } catch (e) {
      print('Error al crear cargue: $e');
      rethrow;
    }
  }

  // Actualizar cargue
  Future<Cargue> actualizarCargue(int id, Map<String, dynamic> data) async {
    // Verificar conexión antes de permitir actualización
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden actualizar cargues sin conexión a internet');
    }

    try {
      final response = await _dio.put('/cargues/$id', data: data);
      return Cargue.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Actualizar despacho (solo admin)
  Future<Cargue> actualizarDespacho(
      int id, List<Map<String, dynamic>> detallesEstado) async {
    // Verificar conexión antes de permitir actualización de despacho
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden actualizar despachos sin conexión a internet');
    }

    try {
      final response = await _dio.put('/cargues/$id/despacho',
          data: {'detalles_estado': detallesEstado});
      return Cargue.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Actualizar cantidad de un detalle de cargue (solo admin)
  Future<Cargue> actualizarCantidadDetalle(
      int cargueId, int detalleId, int nuevaCantidad) async {
    // Verificar conexión antes de permitir actualización de cantidad
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden actualizar cantidades sin conexión a internet');
    }

    try {
      final response = await _dio.put(
        '/cargues/$cargueId/detalles/$detalleId/cantidad',
        data: {'cantidad': nuevaCantidad},
      );
      return Cargue.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Finalizar cargue (solo admin)
  Future<Cargue> finalizarCargue(int id) async {
    // Verificar conexión antes de permitir finalización
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden finalizar cargues sin conexión a internet');
    }

    try {
      final response = await _dio.put('/cargues/$id/finalizar');
      final cargue = Cargue.fromJson(response.data);

      // Actualizar estado en la base de datos local
      final db = await _db.database;
      await db.update(
        'cargues',
        {
          'estado': 'realizado',
          'synced': 1,
          'pending_sync': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      return cargue;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Eliminar cargue (solo admin)
  Future<void> eliminarCargue(int id) async {
    // Verificar conexión antes de permitir eliminación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden eliminar cargues sin conexión a internet');
    }

    try {
      await _dio.delete('/cargues/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Obtener resumen de cargues (solo admin)
  Future<Map<String, dynamic>> getResumenCargues({
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

      final response =
          await _dio.get('/cargues/resumen', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;
      String message = "Error desconocido en el servidor";

      if (data is Map<String, dynamic> && data.containsKey("error")) {
        message = data["error"].toString();
      } else if (data is Map<String, dynamic> && data.containsKey("message")) {
        message = data["message"].toString();
      } else if (data is String) {
        if (data.contains('<html') || data.contains('<!DOCTYPE')) {
          message =
              "Error en el servidor (Código $statusCode). Verifica que el backend esté correctamente configurado.";
        } else {
          message = data;
        }
      }

      return Exception(message);
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception("Tiempo de espera agotado. Verifica tu conexión.");
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception(
          "No se pudo conectar al servidor. Verifica que el backend esté en ejecución.");
    }

    return Exception("Error de red: ${e.message}");
  }
}