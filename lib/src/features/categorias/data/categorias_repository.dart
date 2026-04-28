import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/categoria.dart';
import '../../../core/database/database_service.dart';
import '../../../core/network/connectivity_service.dart';

class CategoriasRepository {
  final Dio _dio;
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  CategoriasRepository(String baseUrl, String? token)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
        ));

  /// Obtener todas las categorías (offline-first)
  /// Lee de SQLite primero, sincroniza en background
  Future<List<Categoria>> getCategorias() async {
    try {
      // Leer de la base de datos local primero
      final db = await _db.database;

      final List<Map<String, dynamic>> localCategorias = await db.query(
        'categorias',
        orderBy: 'nombre ASC',
      );

      print('[CategoriasRepository] Categorías locales encontradas: ${localCategorias.length}');

      final categorias = localCategorias.map((map) => _categoriaFromLocalDb(map)).toList();

      // Sincronizar en background si hay conexión
      if (await _connectivity.checkConnection()) {
        _syncCategoriasInBackground();
      }

      return categorias;
    } catch (e, stack) {
      print('[CategoriasRepository] Error al obtener categorías locales: $e');
      print('[CategoriasRepository] Stack: $stack');

      // Fallback: intentar desde el servidor
      return _getCategoriasFromServer();
    }
  }

  /// Obtener categorías desde el servidor (método privado para fallback)
  Future<List<Categoria>> _getCategoriasFromServer() async {
    try {
      final response = await _dio.get('/categorias');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Categoria.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método público para forzar sincronización desde el servidor
  Future<void> syncFromServer() async {
    await _syncCategoriasInBackground();
  }

  /// Sincronizar categorías en background
  Future<void> _syncCategoriasInBackground() async {
    try {
      final categorias = await _getCategoriasFromServer();
      final db = await _db.database;

      for (final categoria in categorias) {
        await db.insert(
          'categorias',
          {
            'id': categoria.id,
            'uuid': categoria.uuid,
            'nombre': categoria.nombre,
            'descripcion': categoria.descripcion,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('[CategoriasRepository] Sincronización en background completada: ${categorias.length} categorías');
    } catch (e) {
      print('[CategoriasRepository] Error en sincronización background: $e');
      // Ignorar errores de sincronización en background
    }
  }

  /// Convertir registro de SQLite a modelo Categoria
  Categoria _categoriaFromLocalDb(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int,
      uuid: map['uuid'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
    );
  }

  Future<Categoria> crearCategoria(Map<String, dynamic> data) async {
    // Verificar conexión antes de permitir creación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden crear categorías sin conexión a internet');
    }

    try {
      final response = await _dio.post('/categorias', data: data);
      return Categoria.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Categoria> actualizarCategoria(int id, Map<String, dynamic> data) async {
    // Verificar conexión antes de permitir actualización
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden actualizar categorías sin conexión a internet');
    }

    try {
      final response = await _dio.put('/categorias/$id', data: data);
      return Categoria.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> eliminarCategoria(int id) async {
    // Verificar conexión antes de permitir eliminación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden eliminar categorías sin conexión a internet');
    }

    try {
      await _dio.delete('/categorias/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      String message = "Error desconocido en el servidor";

      if (data is Map<String, dynamic> && data.containsKey("message")) {
        message = data["message"].toString();
      } else if (data is String) {
        message = data;
      }

      return Exception(message);
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
