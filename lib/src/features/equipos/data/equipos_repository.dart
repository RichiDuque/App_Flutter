import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:facturacion_app/src/features/equipos/domain/equipo.dart';
import 'package:facturacion_app/src/features/equipos/domain/miembro_equipo.dart';
import '../../../core/database/database_service.dart';
import '../../../core/network/connectivity_service.dart';

class EquiposRepository {
  final Dio _dio;
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  EquiposRepository(String baseUrl, String? token)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
        ));

  // ==================== ENDPOINTS PARA ADMINISTRADORES ====================

  /// Obtener todos los equipos (solo admin) - Offline-first
  Future<List<Equipo>> obtenerEquipos() async {
    try {
      // Primero obtener de la base de datos local
      final db = await _db.database;
      final List<Map<String, dynamic>> localEquipos = await db.query(
        'equipos',
        orderBy: 'nombre ASC',
      );

      print('[EquiposRepository] Equipos locales encontrados: ${localEquipos.length}');

      // Convertir de formato SQLite a modelo Equipo
      final equipos = localEquipos.map((map) => _equipoFromLocalDb(map)).toList();

      // Si hay conexión, sincronizar en background
      if (await _connectivity.checkConnection()) {
        _syncEquiposInBackground();
      }

      return equipos;
    } catch (e, stack) {
      print('[EquiposRepository] Error al obtener equipos: $e');
      print('[EquiposRepository] Stack: $stack');

      // Si falla la lectura local, intentar desde el servidor
      return _obtenerEquiposFromServer();
    }
  }

  /// Método privado para obtener equipos desde el servidor
  Future<List<Equipo>> _obtenerEquiposFromServer() async {
    try {
      final response = await _dio.get('/equipos');
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((json) => Equipo.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Método público para forzar sincronización desde el servidor
  Future<void> syncFromServer() async {
    await _syncEquiposInBackground();
  }

  /// Sincronizar equipos en background
  Future<void> _syncEquiposInBackground() async {
    try {
      final equipos = await _obtenerEquiposFromServer();
      final db = await _db.database;

      for (final equipo in equipos) {
        await db.insert(
          'equipos',
          {
            'id': equipo.id,
            'nombre': equipo.nombre,
            'descripcion': equipo.descripcion,
            'activo': equipo.activo ? 1 : 0,
            'created_at': equipo.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'updated_at': equipo.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('[EquiposRepository] Sincronización en background completada: ${equipos.length} equipos');
    } catch (e) {
      print('[EquiposRepository] Error en sincronización background: $e');
      // Ignorar errores de sincronización en background
    }
  }

  /// Convertir registro de SQLite a modelo Equipo
  Equipo _equipoFromLocalDb(Map<String, dynamic> map) {
    return Equipo(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      activo: (map['activo'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  /// Obtener un equipo por ID (solo admin)
  Future<Equipo> obtenerEquipoPorId(int id) async {
    try {
      final response = await _dio.get('/equipos/$id');
      return Equipo.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear un nuevo equipo (solo admin)
  Future<Equipo> crearEquipo({
    required String nombre,
    String? descripcion,
    bool activo = true,
  }) async {
    // Verificar conexión antes de permitir creación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden crear equipos sin conexión a internet');
    }

    try {
      final response = await _dio.post(
        '/equipos',
        data: {
          'nombre': nombre,
          'descripcion': descripcion,
          'activo': activo,
        },
      );
      return Equipo.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar un equipo (solo admin)
  Future<Equipo> actualizarEquipo({
    required int id,
    required String nombre,
    String? descripcion,
    required bool activo,
  }) async {
    // Verificar conexión antes de permitir actualización
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden actualizar equipos sin conexión a internet');
    }

    try {
      final response = await _dio.put(
        '/equipos/$id',
        data: {
          'nombre': nombre,
          'descripcion': descripcion,
          'activo': activo,
        },
      );
      return Equipo.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar un equipo (solo admin)
  Future<void> eliminarEquipo(int id) async {
    // Verificar conexión antes de permitir eliminación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden eliminar equipos sin conexión a internet');
    }

    try {
      await _dio.delete('/equipos/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener miembros de un equipo (solo admin)
  Future<List<MiembroEquipo>> obtenerMiembrosEquipo(int equipoId) async {
    try {
      final response = await _dio.get('/equipos/$equipoId/miembros');
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((json) => MiembroEquipo.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Agregar un vendedor a un equipo (solo admin)
  Future<void> agregarMiembroEquipo({
    required int equipoId,
    required int usuarioId,
  }) async {
    try {
      await _dio.post(
        '/equipos/$equipoId/miembros',
        data: {'usuario_id': usuarioId},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Quitar un vendedor de un equipo (solo admin)
  Future<void> quitarMiembroEquipo({
    required int equipoId,
    required int usuarioId,
  }) async {
    try {
      await _dio.delete('/equipos/$equipoId/miembros/$usuarioId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ENDPOINTS PARA VENDEDORES ====================

  /// Obtener mis equipos (todos los roles)
  Future<List<Equipo>> obtenerMisEquipos() async {
    try {
      final response = await _dio.get('/equipos/mis-equipos');
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((json) => Equipo.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener mis compañeros de equipo (todos los roles)
  Future<List<MiembroEquipo>> obtenerMisCompaneros() async {
    try {
      final response = await _dio.get('/equipos/mis-companeros');
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((json) => MiembroEquipo.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== MANEJO DE ERRORES ====================

  Exception _handleError(DioException e) {
    print('Error en EquiposRepository: ${e.message}');
    print('Response data: ${e.response?.data}');
    print('Status code: ${e.response?.statusCode}');

    if (e.response != null) {
      final data = e.response!.data;
      String errorMessage = 'Error en el servidor';

      if (data is Map<String, dynamic>) {
        errorMessage = data['error'] ??
            data['message'] ??
            data['mensaje'] ??
            errorMessage;
      }

      switch (e.response!.statusCode) {
        case 400:
          return Exception('Solicitud inválida: $errorMessage');
        case 401:
          return Exception('No autorizado. Por favor inicia sesión nuevamente');
        case 403:
          return Exception(
              'Acceso denegado. Se requieren permisos de administrador');
        case 404:
          return Exception('Recurso no encontrado');
        case 409:
          return Exception('Conflicto: $errorMessage');
        case 500:
          return Exception('Error del servidor: $errorMessage');
        default:
          return Exception(errorMessage);
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de espera agotado. Verifica tu conexión');
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception(
          'Error de conexión. Verifica que el servidor esté disponible');
    }

    return Exception('Error inesperado: ${e.message}');
  }
}