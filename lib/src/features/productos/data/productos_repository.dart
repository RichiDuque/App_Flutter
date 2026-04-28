import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/producto.dart';
import '../../../core/database/database_service.dart';
import '../../../core/network/connectivity_service.dart';

class ProductosRepository {
  final Dio _dio;
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  ProductosRepository(String baseUrl, String? token)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
        ));

  Future<List<Producto>> getProductos({int? listaId}) async {
    try {
      // Primero obtener de la base de datos local
      final db = await _db.database;

      // Si se proporciona lista_id, hacer JOIN con precios
      // Si no, intentar obtener el precio de la lista por defecto (id=1)
      final int listaPreciosId = listaId ?? 1;

      print('[ProductosRepository] Obteniendo productos con lista de precios ID: $listaPreciosId');

      final List<Map<String, dynamic>> localProductos = await db.rawQuery('''
        SELECT
          p.id,
          p.uuid,
          p.nombre,
          p.descripcion,
          p.stock,
          p.categoria_id,
          p.imagen_url,
          COALESCE(pr.precio, 0.0) as precio
        FROM productos p
        LEFT JOIN precios pr ON p.id = pr.producto_id AND pr.lista_id = ?
        ORDER BY p.nombre ASC
      ''', [listaPreciosId]);

      print('[ProductosRepository] Productos locales encontrados: ${localProductos.length}');

      // Convertir de formato SQLite a modelo Producto
      final productos = localProductos.map((map) => _productoFromLocalDb(map)).toList();

      // Si hay conexión, sincronizar en background
      if (await _connectivity.checkConnection()) {
        _syncProductosInBackground();
      }

      return productos;
    } catch (e, stack) {
      print('[ProductosRepository] Error al obtener productos: $e');
      print('[ProductosRepository] Stack: $stack');

      // Si falla la lectura local, intentar desde el servidor
      return _getProductosFromServer();
    }
  }

  // Obtener productos desde el servidor (método legacy para fallback)
  Future<List<Producto>> _getProductosFromServer() async {
    try {
      final response = await _dio.get('/productos');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Producto.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método público para forzar sincronización desde el servidor
  Future<void> syncFromServer() async {
    await _syncProductosInBackground();
  }

  // Sincronizar productos en background
  Future<void> _syncProductosInBackground() async {
    try {
      final productos = await _getProductosFromServer();
      final db = await _db.database;

      for (final producto in productos) {
        await db.insert(
          'productos',
          {
            'id': producto.id,
            'uuid': producto.uuid,
            'nombre': producto.nombre,
            'descripcion': producto.descripcion,
            'stock': producto.stock,
            'categoria_id': producto.categoriaId,
            'imagen_url': producto.imagenUrl,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('[ProductosRepository] Productos sincronizados: ${productos.length}');

      // Sincronizar precios de todos los productos
      await _syncPreciosInBackground();

      print('[ProductosRepository] Sincronización en background completada');
    } catch (e) {
      print('[ProductosRepository] Error en sincronización background: $e');
      // Ignorar errores de sincronización en background
    }
  }

  // Sincronizar todos los precios en background
  Future<void> _syncPreciosInBackground() async {
    try {
      final response = await _dio.get('/precios');
      final List<dynamic> data = response.data;
      final db = await _db.database;

      int preciosSincronizados = 0;

      for (final precioJson in data) {
        await db.insert(
          'precios',
          {
            'id': precioJson['id'],
            'uuid': precioJson['uuid'] ?? '',
            'producto_id': precioJson['producto_id'],
            'lista_id': precioJson['lista_id'],
            'precio': precioJson['precio'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        preciosSincronizados++;
      }

      print('[ProductosRepository] Precios sincronizados: $preciosSincronizados');
    } catch (e) {
      print('[ProductosRepository] Error en sincronización de precios: $e');
      // Ignorar errores de sincronización de precios en background
    }
  }

  // Convertir registro de SQLite a modelo Producto
  Producto _productoFromLocalDb(Map<String, dynamic> map) {
    // Parsear el precio desde el JOIN con la tabla precios
    double precio = 0.0;
    if (map['precio'] != null) {
      if (map['precio'] is double) {
        precio = map['precio'] as double;
      } else if (map['precio'] is int) {
        precio = (map['precio'] as int).toDouble();
      } else if (map['precio'] is String) {
        precio = double.tryParse(map['precio'] as String) ?? 0.0;
      }
    }

    return Producto(
      id: map['id'] as int,
      uuid: map['uuid'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      precio: precio,
      stock: map['stock'] as int,
      categoriaId: map['categoria_id'] as int?,
      imagenUrl: map['imagen_url'] as String?,
    );
  }

  Future<Producto> getProductoById(int id) async {
    try {
      final response = await _dio.get('/productos/$id');
      return Producto.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Producto> getProductoByNombre(String nombre) async {
    try {
      final response = await _dio.get('/productos/nombre/$nombre');
      return Producto.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Producto> crearProducto({
    required String nombre,
    String? descripcion,
    required int stock,
    int? categoriaId,
    String? imagenUrl,
    required Map<int, double> preciosPorLista,
  }) async {
    // Verificar conexión antes de permitir creación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden crear productos sin conexión a internet');
    }

    try {
      final response = await _dio.post(
        '/productos',
        data: {
          'nombre': nombre,
          'descripcion': descripcion,
          'stock': stock,
          'categoria_id': categoriaId,
          'imagen_url': imagenUrl,
        },
      );
      final producto = Producto.fromJson(response.data);

      // Crear precios por lista (ahora es obligatorio)
      if (preciosPorLista.isNotEmpty) {
        await _crearPreciosProducto(producto.id, preciosPorLista);
      }

      return producto;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Producto> actualizarProducto({
    required int id,
    required String nombre,
    String? descripcion,
    required int stock,
    int? categoriaId,
    String? imagenUrl,
    required Map<int, double> preciosPorLista,
  }) async {
    // Verificar conexión antes de permitir actualización
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden actualizar productos sin conexión a internet');
    }

    try {
      final response = await _dio.put(
        '/productos/$id',
        data: {
          'nombre': nombre,
          'descripcion': descripcion,
          'stock': stock,
          'categoria_id': categoriaId,
          'imagen_url': imagenUrl,
        },
      );
      final producto = Producto.fromJson(response.data);

      // Actualizar precios por lista (ahora es obligatorio)
      if (preciosPorLista.isNotEmpty) {
        await _actualizarPreciosProducto(id, preciosPorLista);
      }

      return producto;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> eliminarProducto(int id) async {
    // Verificar conexión antes de permitir eliminación
    if (!await _connectivity.checkConnection()) {
      throw Exception('No se pueden eliminar productos sin conexión a internet');
    }

    try {
      await _dio.delete('/productos/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Métodos privados para manejar precios
  Future<void> _crearPreciosProducto(
      int productoId, Map<int, double> preciosPorLista) async {
    for (var entry in preciosPorLista.entries) {
      if (entry.value > 0) {
        // Solo crear si el precio es mayor a 0
        await _dio.post('/precios', data: {
          'producto_id': productoId,
          'lista_id': entry.key,
          'precio': entry.value,
        });
      }
    }
  }

  Future<void> _actualizarPreciosProducto(
      int productoId, Map<int, double> preciosPorLista) async {
    // Obtener precios existentes del producto
    final response = await _dio.get('/precios');
    final List<dynamic> data = response.data as List<dynamic>;
    final preciosExistentes = data
        .where((p) => p['producto_id'] == productoId)
        .toList();

    for (var entry in preciosPorLista.entries) {
      final listaId = entry.key;
      final nuevoPrecio = entry.value;

      // Buscar si ya existe un precio para esta lista
      final precioExistente = preciosExistentes.firstWhere(
        (p) => p['lista_id'] == listaId,
        orElse: () => null,
      );

      if (precioExistente != null) {
        // Actualizar precio existente
        if (nuevoPrecio > 0) {
          await _dio.put('/precios/${precioExistente['id']}', data: {
            'precio': nuevoPrecio,
          });
        }
      } else {
        // Crear nuevo precio si no existe
        if (nuevoPrecio > 0) {
          await _dio.post('/precios', data: {
            'producto_id': productoId,
            'lista_id': listaId,
            'precio': nuevoPrecio,
          });
        }
      }
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;
      String message = "Error desconocido en el servidor";

      if (data is Map<String, dynamic> && data.containsKey("message")) {
        // Convertir el mensaje a String sin importar su tipo
        message = data["message"].toString();
      } else if (data is String) {
        // Si la respuesta es HTML (error del servidor)
        if (data.contains('<html') || data.contains('<!DOCTYPE')) {
          message = "Error en el servidor (Código $statusCode). Verifica que el backend esté correctamente configurado.";
        } else {
          message = data;
        }
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