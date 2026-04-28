import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:facturacion_app/src/features/equipos/domain/miembro_equipo.dart';
import 'package:facturacion_app/src/features/usuarios/domain/vendedor.dart';
import 'package:facturacion_app/src/features/usuarios/domain/usuario.dart';
import '../../../core/database/database_service.dart';
import '../../../core/network/connectivity_service.dart';

class UsuariosRepository {
  final Dio _dio;
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  UsuariosRepository(String baseUrl, String? token, {Interceptor? interceptor})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
        )) {
    if (interceptor != null) {
      _dio.interceptors.add(interceptor);
    }
  }

  /// Obtener todos los vendedores (usuarios con rol 'vendedor')
  /// Solo disponible para administradores
  Future<List<MiembroEquipo>> obtenerVendedores() async {
    try {
      final response = await _dio.get('/usuarios/vendedores');
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((json) => MiembroEquipo.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener todos los vendedores con información completa (incluye lista_precios_id)
  /// Solo disponible para administradores (offline-first)
  Future<List<Vendedor>> obtenerVendedoresCompleto() async {
    try {
      // Leer de la base de datos local primero
      final db = await _db.database;

      final List<Map<String, dynamic>> localUsuarios = await db.query(
        'usuarios',
        where: 'rol = ?',
        whereArgs: ['vendedor'],
        orderBy: 'nombre ASC',
      );

      print('[UsuariosRepository] Vendedores locales encontrados: ${localUsuarios.length}');

      final vendedores = localUsuarios.map((map) => _vendedorFromLocalDb(map)).toList();

      // Sincronizar en background si hay conexión
      if (await _connectivity.checkConnection()) {
        _syncUsuariosInBackground();
      }

      return vendedores;
    } catch (e, stack) {
      print('[UsuariosRepository] Error al obtener vendedores locales: $e');
      print('[UsuariosRepository] Stack: $stack');

      // Fallback: intentar desde el servidor
      return _obtenerVendedoresCompletoFromServer();
    }
  }

  /// Obtener vendedores desde el servidor (método privado para fallback)
  Future<List<Vendedor>> _obtenerVendedoresCompletoFromServer() async {
    try {
      final response = await _dio.get('/usuarios/vendedores');
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((json) => Vendedor.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar la lista de precios asignada a un vendedor
  /// Solo disponible para administradores
  Future<void> actualizarListaPreciosVendedor({
    required int vendedorId,
    int? listaPreciosId,
  }) async {
    // Verificar conexión antes de permitir actualización
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se puede actualizar lista de precios sin conexión a internet');
    }

    try {
      await _dio.put(
        '/usuarios/$vendedorId',
        data: {
          'lista_precios_id': listaPreciosId,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener todos los usuarios (admin y vendedores)
  /// Solo disponible para administradores (offline-first)
  Future<List<Usuario>> obtenerTodosLosUsuarios() async {
    try {
      // Leer de la base de datos local primero
      final db = await _db.database;

      final List<Map<String, dynamic>> localUsuarios = await db.query(
        'usuarios',
        orderBy: 'nombre ASC',
      );

      print('[UsuariosRepository] Usuarios locales encontrados: ${localUsuarios.length}');

      final usuarios = localUsuarios.map((map) => _usuarioFromLocalDb(map)).toList();

      // Sincronizar en background si hay conexión
      if (await _connectivity.checkConnection()) {
        _syncUsuariosInBackground();
      }

      return usuarios;
    } catch (e, stack) {
      print('[UsuariosRepository] Error al obtener usuarios locales: $e');
      print('[UsuariosRepository] Stack: $stack');

      // Fallback: intentar desde el servidor
      return _obtenerTodosLosUsuariosFromServer();
    }
  }

  /// Obtener todos los usuarios desde el servidor (método privado para fallback)
  Future<List<Usuario>> _obtenerTodosLosUsuariosFromServer() async {
    try {
      final response = await _dio.get('/usuarios');
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((json) => Usuario.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener un usuario por ID
  /// Solo disponible para administradores (offline-first)
  Future<Usuario> obtenerUsuarioPorId(int id) async {
    try {
      // Leer de la base de datos local primero
      final db = await _db.database;

      final List<Map<String, dynamic>> result = await db.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        print('[UsuariosRepository] Usuario local encontrado para ID: $id');
        final usuario = _usuarioFromLocalDb(result.first);

        // Sincronizar en background si hay conexión
        if (await _connectivity.checkConnection()) {
          _syncUsuariosInBackground();
        }

        return usuario;
      }

      // Si no está en local, buscar en servidor
      print('[UsuariosRepository] Usuario no encontrado en local, buscando en servidor');
      return _obtenerUsuarioPorIdFromServer(id);
    } catch (e, stack) {
      print('[UsuariosRepository] Error al obtener usuario local por ID: $e');
      print('[UsuariosRepository] Stack: $stack');

      // Fallback: intentar desde el servidor
      return _obtenerUsuarioPorIdFromServer(id);
    }
  }

  /// Obtener usuario por ID desde el servidor (método privado para fallback)
  Future<Usuario> _obtenerUsuarioPorIdFromServer(int id) async {
    try {
      final response = await _dio.get('/usuarios/$id');
      return Usuario.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear un nuevo usuario
  /// Solo disponible para administradores
  Future<Usuario> crearUsuario({
    required String nombre,
    required String email,
    required String password,
    required String rol,
    int? listaPreciosId,
  }) async {
    // Verificar conexión antes de permitir creación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden crear usuarios sin conexión a internet');
    }

    try {
      final response = await _dio.post(
        '/usuarios',
        data: {
          'nombre': nombre,
          'email': email,
          'password': password,
          'rol': rol,
          if (listaPreciosId != null) 'lista_precios_id': listaPreciosId,
        },
      );
      // El backend devuelve { message, usuario }
      final data = response.data;
      if (data['usuario'] != null) {
        return Usuario.fromJson(data['usuario']);
      }
      return Usuario.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar un usuario existente
  /// Solo disponible para administradores
  Future<Usuario> actualizarUsuario({
    required int id,
    String? nombre,
    String? email,
    String? password,
    String? rol,
    int? listaPreciosId,
    bool? activo,
  }) async {
    // Verificar conexión antes de permitir actualización
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden actualizar usuarios sin conexión a internet');
    }

    try {
      final data = <String, dynamic>{};
      if (nombre != null && nombre.isNotEmpty) data['nombre'] = nombre;
      if (email != null && email.isNotEmpty) data['email'] = email;
      if (password != null && password.isNotEmpty) data['password'] = password;
      if (rol != null && rol.isNotEmpty) data['rol'] = rol;
      // Solo incluir lista_precios_id si no es null
      if (listaPreciosId != null) {
        data['lista_precios_id'] = listaPreciosId;
      }
      if (activo != null) data['activo'] = activo;

      print('🔍 Datos que se enviarán al backend: $data');

      final response = await _dio.put('/usuarios/$id', data: data);
      return Usuario.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Deshabilitar/habilitar un usuario
  /// Solo disponible para administradores
  Future<void> cambiarEstadoUsuario(int id, bool activo) async {
    // Verificar conexión antes de permitir cambio de estado
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se puede cambiar el estado de usuarios sin conexión a internet');
    }

    try {
      await _dio.put(
        '/usuarios/$id',
        data: {'activo': activo},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar un usuario
  /// Solo disponible para administradores
  Future<void> eliminarUsuario(int id) async {
    // Verificar conexión antes de permitir eliminación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden eliminar usuarios sin conexión a internet');
    }

    try {
      await _dio.delete('/usuarios/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método público para forzar sincronización desde el servidor
  Future<void> syncFromServer() async {
    await _syncUsuariosInBackground();
  }

  /// Sincronizar usuarios en background
  Future<void> _syncUsuariosInBackground() async {
    try {
      final response = await _dio.get('/usuarios');
      final List<dynamic> data = response.data is List ? response.data : [];
      final usuarios = data.map((json) => Usuario.fromJson(json)).toList();
      final db = await _db.database;

      print('[UsuariosRepository._syncUsuariosInBackground] Usuarios recibidos del servidor: ${usuarios.length}');

      int insertados = 0;
      for (final usuario in usuarios) {
        try {
          print('[UsuariosRepository._syncUsuariosInBackground] Insertando usuario ID: ${usuario.id}, Nombre: ${usuario.nombre}, Email: ${usuario.email}, Rol: ${usuario.rol}');

          // Generar un UUID único basado en el ID del usuario
          final uuid = 'user-${usuario.id}-${usuario.email}';

          final result = await db.insert(
            'usuarios',
            {
              'id': usuario.id,
              'uuid': uuid, // Generar UUID único para evitar conflictos
              'nombre': usuario.nombre,
              'email': usuario.email,
              'rol': usuario.rol,
              'lista_id': usuario.listaPreciosId,
              'activo': usuario.activo ? 1 : 0,
              'created_at': usuario.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'synced': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          print('[UsuariosRepository._syncUsuariosInBackground] Usuario ${usuario.id} insertado con resultado: $result, UUID: $uuid');
          insertados++;
        } catch (e) {
          print('[UsuariosRepository._syncUsuariosInBackground] Error insertando usuario ${usuario.id}: $e');
        }
      }

      print('[UsuariosRepository] Sincronización en background completada: $insertados de ${usuarios.length} usuarios');

      // Verificar cuántos usuarios hay en la base de datos después de la sincronización
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM usuarios');
      print('[UsuariosRepository._syncUsuariosInBackground] Total usuarios en BD después de sync: ${count.first['count']}');
    } catch (e) {
      print('[UsuariosRepository] Error en sincronización background: $e');
      // Ignorar errores de sincronización en background
    }
  }

  /// Convertir registro de SQLite a modelo Usuario
  Usuario _usuarioFromLocalDb(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      email: map['email'] as String,
      rol: map['rol'] as String,
      listaPreciosId: map['lista_id'] as int?,
      activo: (map['activo'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convertir registro de SQLite a modelo Vendedor
  Vendedor _vendedorFromLocalDb(Map<String, dynamic> map) {
    return Vendedor(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      email: map['email'] as String,
      rol: map['rol'] as String,
      listaPreciosId: map['lista_id'] as int?,
    );
  }

  Exception _handleError(DioException e) {
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