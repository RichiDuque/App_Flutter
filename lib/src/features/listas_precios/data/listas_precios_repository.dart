import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/lista_precio.dart';
import '../domain/precio_producto.dart';
import '../../../core/database/database_service.dart';
import '../../../core/network/connectivity_service.dart';

class ListasPreciosRepository {
  final String baseUrl;
  final Dio _dio;
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  ListasPreciosRepository(this.baseUrl)
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

  /// Obtener todas las listas de precios (offline-first)
  /// Lee de SQLite primero, sincroniza en background
  Future<List<ListaPrecio>> getListasPrecios() async {
    try {
      // Leer de la base de datos local primero
      final db = await _db.database;

      final List<Map<String, dynamic>> localListas = await db.query(
        'listas_precios',
        orderBy: 'nombre ASC',
      );

      print('[ListasPreciosRepository] Listas locales encontradas: ${localListas.length}');

      final listas = localListas.map((map) => _listaPrecioFromLocalDb(map)).toList();

      // Sincronizar en background si hay conexión
      if (await _connectivity.checkConnection()) {
        _syncListasPreciosInBackground();
      }

      return listas;
    } catch (e, stack) {
      print('[ListasPreciosRepository] Error al obtener listas locales: $e');
      print('[ListasPreciosRepository] Stack: $stack');

      // Fallback: intentar desde el servidor
      return _getListasPreciosFromServer();
    }
  }

  /// Obtener listas de precios desde el servidor (método privado para fallback)
  Future<List<ListaPrecio>> _getListasPreciosFromServer() async {
    try {
      final response = await _dio.get('/listas-precios');
      final List<dynamic> data = response.data;
      return data.map((json) => ListaPrecio.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método público para forzar sincronización desde el servidor
  Future<void> syncFromServer() async {
    await _syncListasPreciosInBackground();
    await _syncPreciosInBackground();
  }

  /// Sincronizar listas de precios en background
  Future<void> _syncListasPreciosInBackground() async {
    try {
      final listas = await _getListasPreciosFromServer();
      final db = await _db.database;

      for (final lista in listas) {
        await db.insert(
          'listas_precios',
          {
            'id': lista.id,
            'uuid': lista.uuid,
            'nombre': lista.nombre,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('[ListasPreciosRepository] Sincronización en background completada: ${listas.length} listas');
    } catch (e) {
      print('[ListasPreciosRepository] Error en sincronización background: $e');
      // Ignorar errores de sincronización en background
    }
  }

  /// Convertir registro de SQLite a modelo ListaPrecio
  ListaPrecio _listaPrecioFromLocalDb(Map<String, dynamic> map) {
    return ListaPrecio(
      id: map['id'] as int,
      uuid: map['uuid'] as String,
      nombre: map['nombre'] as String,
    );
  }

  // Crear precio para un producto en una lista específica
  Future<PrecioProducto> crearPrecio({
    required int productoId,
    required int listaId,
    required double precio,
  }) async {
    try {
      final response = await _dio.post('/precios', data: {
        'producto_id': productoId,
        'lista_id': listaId,
        'precio': precio,
      });
      return PrecioProducto.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Actualizar precio existente
  Future<PrecioProducto> actualizarPrecio({
    required int precioId,
    required double nuevoPrecio,
  }) async {
    try {
      final response = await _dio.put('/precios/$precioId', data: {
        'precio': nuevoPrecio,
      });
      return PrecioProducto.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener precios de un producto específico (offline-first)
  /// Lee de SQLite primero, sincroniza en background
  Future<List<PrecioProducto>> getPreciosProducto(int productoId) async {
    try {
      // Leer de la base de datos local primero
      final db = await _db.database;

      final List<Map<String, dynamic>> localPrecios = await db.query(
        'precios',
        where: 'producto_id = ?',
        whereArgs: [productoId],
      );

      print('[ListasPreciosRepository] Precios locales encontrados para producto $productoId: ${localPrecios.length}');

      final precios = localPrecios.map((map) => _precioProductoFromLocalDb(map)).toList();

      // Sincronizar en background si hay conexión
      if (await _connectivity.checkConnection()) {
        _syncPreciosInBackground();
      }

      return precios;
    } catch (e, stack) {
      print('[ListasPreciosRepository] Error al obtener precios locales: $e');
      print('[ListasPreciosRepository] Stack: $stack');

      // Fallback: intentar desde el servidor
      return _getPreciosProductoFromServer(productoId);
    }
  }

  /// Obtener precios desde el servidor (método privado para fallback)
  Future<List<PrecioProducto>> _getPreciosProductoFromServer(int productoId) async {
    try {
      final response = await _dio.get('/precios');
      final List<dynamic> data = response.data;
      final precios = data.map((json) => PrecioProducto.fromJson(json)).toList();
      return precios.where((p) => p.productoId == productoId).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Sincronizar todos los precios en background
  Future<void> _syncPreciosInBackground() async {
    try {
      final response = await _dio.get('/precios');
      final List<dynamic> data = response.data;
      final precios = data.map((json) => PrecioProducto.fromJson(json)).toList();
      final db = await _db.database;

      for (final precio in precios) {
        await db.insert(
          'precios',
          {
            'id': precio.id,
            'uuid': precio.uuid ?? 'precio-${precio.id}',
            'producto_id': precio.productoId,
            'lista_id': precio.listaId,
            'precio': precio.precio,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('[ListasPreciosRepository] Sincronización de precios en background completada: ${precios.length} precios');
    } catch (e) {
      print('[ListasPreciosRepository] Error en sincronización de precios background: $e');
      // Ignorar errores de sincronización en background
    }
  }

  /// Convertir registro de SQLite a modelo PrecioProducto
  PrecioProducto _precioProductoFromLocalDb(Map<String, dynamic> map) {
    return PrecioProducto(
      id: map['id'] as int,
      uuid: map['uuid'] as String,
      productoId: map['producto_id'] as int,
      listaId: map['lista_id'] as int,
      precio: (map['precio'] as num).toDouble(),
    );
  }

  // Obtener precios de un producto como Map para fácil acceso
  Future<Map<int, double>> getPreciosProductoMap(int productoId) async {
    try {
      final precios = await getPreciosProducto(productoId);
      final Map<int, double> preciosMap = {};
      for (var precio in precios) {
        preciosMap[precio.listaId] = precio.precio;
      }
      return preciosMap;
    } catch (e) {
      rethrow;
    }
  }

  // Obtener precio de un producto según la lista de precios del usuario
  // Si no tiene lista asignada o no hay precio, usa la lista "General"
  Future<double> getPrecioProductoPorLista({
    required int productoId,
    int? listaId,
  }) async {
    try {
      print('🔍 [getPrecioProductoPorLista] Producto ID: $productoId, Lista ID: $listaId');

      // Obtener todos los precios del producto
      final response = await _dio.get('/precios', queryParameters: {
        'producto_id': productoId,
      });
      final List<dynamic> data = response.data;

      print('📦 [getPrecioProductoPorLista] Precios recibidos: $data');

      if (data.isEmpty) {
        throw Exception('No se encontró precio para este producto');
      }

      final precios = data.map((json) => PrecioProducto.fromJson(json)).toList();

      // Si el usuario tiene lista asignada, buscar ese precio
      if (listaId != null) {
        final precioUsuario = precios.firstWhere(
          (p) => p.listaId == listaId,
          orElse: () => PrecioProducto(id: 0, productoId: productoId, listaId: 0, precio: 0),
        );

        print('💰 [getPrecioProductoPorLista] Precio encontrado para lista $listaId: ${precioUsuario.precio}');

        if (precioUsuario.precio > 0) {
          return precioUsuario.precio;
        }
      }

      // Fallback: buscar la lista "General" primero obteniendo todas las listas
      final listasResponse = await _dio.get('/listas-precios');
      final List<dynamic> listasData = listasResponse.data;
      final listas = listasData.map((json) => ListaPrecio.fromJson(json)).toList();

      final listaGeneral = listas.firstWhere(
        (l) => l.nombre.toLowerCase() == 'general',
        orElse: () => ListaPrecio(id: 0, uuid: '', nombre: ''),
      );

      if (listaGeneral.id > 0) {
        final precioGeneral = precios.firstWhere(
          (p) => p.listaId == listaGeneral.id,
          orElse: () => PrecioProducto(id: 0, productoId: productoId, listaId: 0, precio: 0),
        );

        if (precioGeneral.precio > 0) {
          return precioGeneral.precio;
        }
      }

      // Si no hay lista "General", devolver el primer precio disponible
      return precios.first.precio;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Crear lista de precios
  Future<ListaPrecio> crearListaPrecios(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/listas-precios', data: data);
      return ListaPrecio.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Actualizar lista de precios
  Future<ListaPrecio> actualizarListaPrecios(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/listas-precios/$id', data: data);
      return ListaPrecio.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Eliminar lista de precios
  Future<void> eliminarListaPrecios(int id) async {
    try {
      await _dio.delete('/listas-precios/$id');
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