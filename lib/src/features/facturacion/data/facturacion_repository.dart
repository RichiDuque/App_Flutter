import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../../../core/network/connectivity_service.dart';

class FacturacionRepository {
  final Dio _dio;
  final String? token;
  final DatabaseService _db = DatabaseService();
  final SyncQueueService _queue = SyncQueueService();
  final ConnectivityService _connectivity = ConnectivityService();

  FacturacionRepository(String baseUrl, this.token)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
        ));

  Future<Map<String, dynamic>> crearFactura(
      Map<String, dynamic> facturaData) async {
    try {
      final uuid = const Uuid().v4();
      // Usar hora local del dispositivo
      final now = DateTime.now();

      print('=== CREAR FACTURA (OFFLINE FIRST) ===');
      print('Fecha/hora local: $now');
      print('Datos enviados: $facturaData');

      // Guardar en base de datos local
      final db = await _db.database;

      // Obtener el último número de factura para generar el siguiente
      String numeroFactura = 'TEMP-$uuid';
      try {
        final List<Map<String, dynamic>> lastFactura = await db.rawQuery('''
          SELECT numero_factura
          FROM facturas
          WHERE numero_factura NOT LIKE 'TEMP-%'
          ORDER BY id DESC
          LIMIT 1
        ''');

        if (lastFactura.isNotEmpty && lastFactura.first['numero_factura'] != null) {
          final lastNumero = lastFactura.first['numero_factura'] as String;
          // Extraer el número de la factura (ej: "FAC-00123" -> 123)
          final match = RegExp(r'(\d+)$').firstMatch(lastNumero);
          if (match != null) {
            final lastNumber = int.parse(match.group(1)!);
            final nextNumber = lastNumber + 1;
            // Mantener el mismo formato (ej: "FAC-00124")
            final prefix = lastNumero.substring(0, lastNumero.length - match.group(1)!.length);
            numeroFactura = '$prefix${nextNumber.toString().padLeft(match.group(1)!.length, '0')}';
            print('[FacturacionRepository] Número de factura generado: $numeroFactura (siguiente de $lastNumero)');
          }
        }
      } catch (e) {
        print('[FacturacionRepository] Error al generar número de factura, usando temporal: $e');
        // Si hay error, usar el número temporal
      }

      // Preparar datos para guardar localmente
      // Formatear fecha/hora manteniendo la hora local (sin conversión a UTC)
      final fechaLocal = now.toIso8601String().split('.')[0]; // Remover microsegundos y zona horaria

      final facturaLocal = {
        'uuid': uuid,
        'numero_factura': numeroFactura,
        'usuario_id': facturaData['usuario_id'],
        'cliente_id': facturaData['cliente_id'],
        'descuento_id': facturaData['descuento_id'], // Puede ser null
        'subtotal': facturaData['subtotal'] ?? 0,
        'descuento': facturaData['descuento'] ?? 0,
        'total': facturaData['total'] ?? 0,
        'estado': 'completada',
        'fecha': fechaLocal,
        'created_at': fechaLocal,
        'updated_at': fechaLocal,
        'synced': 0,
        'pending_sync': 1,
      };
      final facturaId = await db.insert('facturas', facturaLocal);

      print('Factura guardada localmente con ID: $facturaId');

      // Guardar items de la factura si existen
      if (facturaData['items'] != null && facturaData['items'] is List) {
        final items = facturaData['items'] as List;
        for (final item in items) {
          await db.insert('facturas_items', {
            'uuid': const Uuid().v4(),
            'factura_id': facturaId,
            'producto_id': item['producto_id'],
            'cantidad': item['cantidad'],
            'precio_unitario': item['precio_unitario'],
            'subtotal': item['subtotal'],
            'comentario': item['comentario'], // Agregar comentario
            'created_at': fechaLocal,
            'updated_at': fechaLocal,
            'synced': 0,
          });
        }
      }

      // Agregar a cola de sincronización
      await _queue.addToQueue(SyncQueueItem(
        entityType: EntityType.factura,
        entityUuid: uuid,
        operation: SyncOperation.create,
        data: facturaData,
      ));

      print('Factura agregada a cola de sincronización');

      // Intentar sincronizar inmediatamente si hay conexión
      if (await _connectivity.checkConnection()) {
        try {
          print('Conexión detectada, intentando sincronizar inmediatamente...');
          final response = await _dio.post('/facturas', data: facturaData);

          print('Respuesta recibida del servidor: ${response.data}');

          // Actualizar con datos reales del servidor
          // El servidor devuelve factura_id, no id
          final responseData = response.data as Map<String, dynamic>;
          await db.update(
            'facturas',
            {
              'id': responseData['factura_id'], // Corregido: el servidor devuelve 'factura_id'
              'numero_factura': responseData['numero_factura'],
              'synced': 1,
              'pending_sync': 0,
            },
            where: 'uuid = ?',
            whereArgs: [uuid],
          );

          // Remover de cola
          await _queue.removeByUuid(EntityType.factura, uuid);

          print('Factura sincronizada exitosamente');

          return response.data as Map<String, dynamic>;
        } catch (e) {
          print('Error al sincronizar inmediatamente: $e');
          // Si falla la sincronización inmediata, quedará en cola para reintento
        }
      } else {
        print('Sin conexión, factura quedará en cola para sincronización posterior');
      }

      // Retornar factura local si no se pudo sincronizar
      return {
        'factura_id': facturaId,
        'numero_factura': numeroFactura,
        'total': facturaData['total'] ?? 0,
        'uuid': uuid,
        'mensaje': 'Factura guardada localmente. Se sincronizará cuando haya conexión.',
      };
    } catch (e) {
      print('Error al crear factura: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFacturas() async {
    try {
      final response = await _dio.get('/facturas');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getFacturaById(int id) async {
    try {
      final response = await _dio.get('/facturas/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      String errorMessage;

      if (data is Map) {
        errorMessage = data["mensaje"] ?? // API usa "mensaje" en español
                      data["message"] ??
                      data["error"] ??
                      "Error ${e.response?.statusCode}: ${data.toString()}";
      } else if (data is String) {
        errorMessage = data;
      } else {
        errorMessage = "Error ${e.response?.statusCode}: ${e.response?.statusMessage ?? 'Error desconocido'}";
      }

      return Exception(errorMessage);
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception("No hay conexión con el servidor");
    }

    if (e.type == DioExceptionType.connectionTimeout) {
      return Exception("Tiempo de espera agotado");
    }

    return Exception("Error inesperado: ${e.message}");
  }
}