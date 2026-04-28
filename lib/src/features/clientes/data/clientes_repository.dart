import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/cliente.dart';
import '../../../core/database/database_service.dart';
import '../../../core/network/connectivity_service.dart';

class ClientesRepository {
  final String baseUrl;
  final Dio _dio;
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  ClientesRepository(this.baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // Obtener todos los clientes (con soporte offline)
  Future<List<Cliente>> getClientes() async {
    try {
      // Primero obtener de la base de datos local
      final db = await _db.database;
      final List<Map<String, dynamic>> localClientes = await db.query(
        'clientes',
        orderBy: 'nombre_establecimiento ASC',
      );

      print('[ClientesRepository] Clientes locales encontrados: ${localClientes.length}');

      // Convertir de formato SQLite a modelo Cliente
      final clientes = localClientes.map((map) => _clienteFromLocalDb(map)).toList();

      // Si hay conexión, sincronizar en background
      if (await _connectivity.checkConnection()) {
        _syncClientesInBackground();
      }

      return clientes;
    } catch (e, stack) {
      print('[ClientesRepository] Error al obtener clientes: $e');
      print('[ClientesRepository] Stack: $stack');

      // Si falla la lectura local, intentar desde el servidor
      return _getClientesFromServer();
    }
  }

  // Obtener clientes desde el servidor (método legacy para fallback)
  Future<List<Cliente>> _getClientesFromServer() async {
    try {
      final response = await _dio.get('/clientes');
      final List<dynamic> data = response.data;
      return data.map((json) => Cliente.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método público para forzar sincronización desde el servidor
  Future<void> syncFromServer() async {
    await _syncClientesInBackground();
  }

  // Sincronizar clientes en background
  Future<void> _syncClientesInBackground() async {
    try {
      final clientes = await _getClientesFromServer();
      final db = await _db.database;

      for (final cliente in clientes) {
        await db.insert(
          'clientes',
          {
            'id': cliente.id,
            'uuid': cliente.uuid,
            'nombre_establecimiento': cliente.nombreEstablecimiento,
            'propietario': cliente.propietario,
            'email': cliente.email,
            'telefono': cliente.telefono,
            'direccion': cliente.direccion,
            'ciudad': cliente.ciudad,
            'departamento': cliente.departamento,
            'codigo_postal': cliente.codigoPostal,
            'pais': cliente.pais,
            'codigo_cliente': cliente.codigoCliente,
            'nota': cliente.nota,
            'puntos': cliente.puntos,
            'visitas': cliente.visitas,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('[ClientesRepository] Sincronización en background completada');
    } catch (e) {
      print('[ClientesRepository] Error en sincronización background: $e');
      // Ignorar errores de sincronización en background
    }
  }

  // Convertir registro de SQLite a modelo Cliente
  Cliente _clienteFromLocalDb(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int,
      uuid: map['uuid'] as String,
      nombreEstablecimiento: map['nombre_establecimiento'] as String,
      propietario: map['propietario'] as String?,
      email: map['email'] as String?,
      telefono: map['telefono'] as String?,
      direccion: map['direccion'] as String?,
      ciudad: map['ciudad'] as String?,
      departamento: map['departamento'] as String?,
      codigoPostal: map['codigo_postal'] as String?,
      pais: map['pais'] as String? ?? 'Colombia',
      codigoCliente: map['codigo_cliente'] as String?,
      nota: map['nota'] as String?,
      puntos: map['puntos'] as int? ?? 0,
      visitas: map['visitas'] as int? ?? 0,
    );
  }

  /// Obtener un cliente por ID (offline-first)
  /// Lee de SQLite primero, sincroniza en background
  Future<Cliente> getClienteById(int id) async {
    try {
      // Leer de la base de datos local primero
      final db = await _db.database;

      final List<Map<String, dynamic>> result = await db.query(
        'clientes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        print('[ClientesRepository] Cliente local encontrado para ID: $id');
        final cliente = _clienteFromLocalDb(result.first);

        // Sincronizar en background si hay conexión
        if (await _connectivity.checkConnection()) {
          _syncClientesInBackground();
        }

        return cliente;
      }

      // Si no está en local, buscar en servidor
      print('[ClientesRepository] Cliente no encontrado en local, buscando en servidor');
      return _getClienteByIdFromServer(id);
    } catch (e, stack) {
      print('[ClientesRepository] Error al obtener cliente local por ID: $e');
      print('[ClientesRepository] Stack: $stack');

      // Fallback: intentar desde el servidor
      return _getClienteByIdFromServer(id);
    }
  }

  /// Obtener cliente por ID desde el servidor (método privado para fallback)
  Future<Cliente> _getClienteByIdFromServer(int id) async {
    try {
      final response = await _dio.get('/clientes/$id');
      return Cliente.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Crear un nuevo cliente
  Future<Cliente> crearCliente({
    required String nombreEstablecimiento,
    String? propietario,
    String? email,
    String? telefono,
    String? direccion,
    String? ciudad,
    String? departamento,
    String? codigoPostal,
    String? pais,
    String? codigoCliente,
    String? nota,
    int? listaId,
  }) async {
    // Verificar conexión antes de permitir creación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden crear clientes sin conexión a internet');
    }

    try {
      final response = await _dio.post('/clientes', data: {
        'nombre_establecimiento': nombreEstablecimiento,
        'propietario': propietario,
        'email': email,
        'telefono': telefono,
        'direccion': direccion,
        'ciudad': ciudad,
        'departamento': departamento,
        'codigo_postal': codigoPostal,
        'pais': pais,
        'codigo_cliente': codigoCliente,
        'nota': nota,
        'lista_id': listaId,
      });
      return Cliente.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Actualizar un cliente existente
  Future<Cliente> actualizarCliente(int id, Map<String, dynamic> datos) async {
    // Verificar conexión antes de permitir actualización
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden actualizar clientes sin conexión a internet');
    }

    try {
      final response = await _dio.put('/clientes/$id', data: datos);
      return Cliente.fromJson(response.data['cliente']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Eliminar un cliente
  Future<void> eliminarCliente(int id) async {
    // Verificar conexión antes de permitir eliminación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden eliminar clientes sin conexión a internet');
    }

    try {
      await _dio.delete('/clientes/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Buscar cliente por nombre (offline-first)
  /// Lee de SQLite primero, sincroniza en background
  Future<List<Cliente>> buscarClientePorNombre(String nombre) async {
    try {
      // Leer de la base de datos local primero
      final db = await _db.database;

      // Buscar por coincidencia parcial en nombre_establecimiento, propietario o codigo_cliente
      final List<Map<String, dynamic>> result = await db.query(
        'clientes',
        where: 'nombre_establecimiento LIKE ? OR propietario LIKE ? OR codigo_cliente LIKE ?',
        whereArgs: ['%$nombre%', '%$nombre%', '%$nombre%'],
        orderBy: 'nombre_establecimiento ASC',
      );

      print('[ClientesRepository] Clientes locales encontrados para búsqueda "$nombre": ${result.length}');

      final clientes = result.map((map) => _clienteFromLocalDb(map)).toList();

      // Sincronizar en background si hay conexión
      if (await _connectivity.checkConnection()) {
        _syncClientesInBackground();
      }

      return clientes;
    } catch (e, stack) {
      print('[ClientesRepository] Error al buscar clientes locales: $e');
      print('[ClientesRepository] Stack: $stack');

      // Fallback: intentar desde el servidor
      return _buscarClientePorNombreFromServer(nombre);
    }
  }

  /// Buscar cliente por nombre desde el servidor (método privado para fallback)
  Future<List<Cliente>> _buscarClientePorNombreFromServer(String nombre) async {
    try {
      final response = await _dio.get('/clientes/buscar/$nombre');
      final List<dynamic> data = response.data;
      return data.map((json) => Cliente.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Obtener historial de compras de un cliente
  Future<List<dynamic>> getHistorialCompras(int clienteId) async {
    try {
      final response = await _dio.get('/clientes/$clienteId/historial');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Incrementar visitas de un cliente
  Future<Cliente> incrementarVisitas(int clienteId) async {
    // Verificar conexión antes de permitir actualización de visitas
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden actualizar visitas sin conexión a internet');
    }

    try {
      final response = await _dio.post('/clientes/$clienteId/visitas');
      return Cliente.fromJson(response.data['cliente']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Actualizar puntos de un cliente
  Future<Cliente> actualizarPuntos(int clienteId, int puntos) async {
    // Verificar conexión antes de permitir actualización de puntos
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden actualizar puntos sin conexión a internet');
    }

    try {
      final response = await _dio.put('/clientes/$clienteId/puntos', data: {
        'puntos': puntos,
      });
      return Cliente.fromJson(response.data['cliente']);
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
