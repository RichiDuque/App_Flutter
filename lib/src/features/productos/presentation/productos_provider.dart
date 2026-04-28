import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/env.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/productos_repository.dart';
import '../domain/producto.dart';

final productosRepositoryProvider = Provider<ProductosRepository>((ref) {
  final authState = ref.watch(authControllerProvider);
  return ProductosRepository(Env.apiBaseUrl, authState.token);
});

final productosProvider = FutureProvider<List<Producto>>((ref) async {
  final repository = ref.watch(productosRepositoryProvider);
  final authState = ref.watch(authControllerProvider);

  // Obtener productos con la lista de precios del usuario
  // Si el usuario no tiene lista asignada, usar lista por defecto (1)
  return repository.getProductos(listaId: authState.listaPreciosId);
});

final productosByNameProvider =
    FutureProvider.family<Producto, String>((ref, nombre) async {
  final repository = ref.watch(productosRepositoryProvider);
  return repository.getProductoByNombre(nombre);
});

// Provider para el texto de búsqueda
final busquedaProductosProvider = StateProvider<String>((ref) => '');

// Provider para controlar si está en modo búsqueda
final modoBusquedaActivoProvider = StateProvider<bool>((ref) => false);

// Provider para la categoría seleccionada en el filtro
final categoriaSeleccionadaProvider = StateProvider<int?>((ref) => null);