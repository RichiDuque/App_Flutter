import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/descuento.dart';
import '../../../core/database/database_service.dart';
import '../../../core/network/connectivity_service.dart';

class DescuentosRepository {
  final Dio _dio;
  final String? token;
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  DescuentosRepository(String baseUrl, this.token)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
        ));

  // Obtener todos los descuentos (offline-first)
  Future<List<Descuento>> getDescuentos() async {
    try {
      // Primero obtener de la base de datos local
      final db = await _db.database;
      final List<Map<String, dynamic>> localDescuentos = await db.query(
        'descuentos',
        orderBy: 'nombre ASC',
      );

      print('[DescuentosRepository] Descuentos locales encontrados: ${localDescuentos.length}');

      // Convertir de formato SQLite a modelo Descuento
      final descuentos = localDescuentos.map((map) => _descuentoFromLocalDb(map)).toList();

      // Si hay conexión, sincronizar en background
      if (await _connectivity.checkConnection()) {
        _syncDescuentosInBackground();
      }

      return descuentos;
    } catch (e, stack) {
      print('[DescuentosRepository] Error al obtener descuentos: $e');
      print('[DescuentosRepository] Stack: $stack');

      // Si falla la lectura local, intentar desde el servidor
      return _getDescuentosFromServer();
    }
  }

  // Obtener descuento por ID (offline-first)
  Future<Descuento> getDescuentoById(int id) async {
    try {
      // Primero buscar en la base de datos local
      final db = await _db.database;
      final List<Map<String, dynamic>> result = await db.query(
        'descuentos',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        print('[DescuentosRepository] Descuento encontrado en local: $id');
        return _descuentoFromLocalDb(result.first);
      }

      print('[DescuentosRepository] Descuento no encontrado en local, consultando servidor...');

      // Si no está en local y hay conexión, obtener del servidor
      if (await _connectivity.checkConnection()) {
        return await _getDescuentoByIdFromServer(id);
      }

      throw Exception('Descuento no encontrado y sin conexión');
    } catch (e, stack) {
      print('[DescuentosRepository] Error al obtener descuento: $e');
      print('[DescuentosRepository] Stack: $stack');

      // Fallback al servidor
      return _getDescuentoByIdFromServer(id);
    }
  }

  // Método privado para obtener descuentos desde el servidor
  Future<List<Descuento>> _getDescuentosFromServer() async {
    try {
      final response = await _dio.get('/descuentos');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Descuento.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método privado para obtener un descuento por ID desde el servidor
  Future<Descuento> _getDescuentoByIdFromServer(int id) async {
    try {
      final response = await _dio.get('/descuentos/$id');
      return Descuento.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método público para forzar sincronización desde el servidor
  Future<void> syncFromServer() async {
    await _syncDescuentosInBackground();
  }

  // Sincronizar descuentos en background
  Future<void> _syncDescuentosInBackground() async {
    try {
      final descuentos = await _getDescuentosFromServer();
      final db = await _db.database;

      for (final descuento in descuentos) {
        await db.insert(
          'descuentos',
          {
            'id': descuento.id,
            'uuid': descuento.uuid,
            'nombre': descuento.nombre,
            'porcentaje': descuento.porcentaje,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('[DescuentosRepository] Sincronización en background completada: ${descuentos.length} descuentos');
    } catch (e) {
      print('[DescuentosRepository] Error en sincronización background: $e');
      // Ignorar errores de sincronización en background
    }
  }

  // Convertir registro de SQLite a modelo Descuento
  Descuento _descuentoFromLocalDb(Map<String, dynamic> map) {
    return Descuento(
      id: map['id'] as int,
      uuid: map['uuid'] as String,
      nombre: map['nombre'] as String,
      porcentaje: (map['porcentaje'] as num).toDouble(),
    );
  }

  // Crear descuento (siempre va al servidor)
  Future<Descuento> crearDescuento(Map<String, dynamic> data) async {
    // Verificar conexión antes de permitir creación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden crear descuentos sin conexión a internet');
    }

    try {
      final response = await _dio.post('/descuentos', data: data);
      return Descuento.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Actualizar descuento (siempre va al servidor)
  Future<Descuento> actualizarDescuento(int id, Map<String, dynamic> data) async {
    // Verificar conexión antes de permitir actualización
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden actualizar descuentos sin conexión a internet');
    }

    try {
      final response = await _dio.put('/descuentos/$id', data: data);
      return Descuento.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Eliminar descuento (siempre va al servidor)
  Future<void> eliminarDescuento(int id) async {
    // Verificar conexión antes de permitir eliminación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden eliminar descuentos sin conexión a internet');
    }

    try {
      await _dio.delete('/descuentos/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      return Exception(
          e.response?.data["message"] ?? "Error desconocido en el servidor");
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
