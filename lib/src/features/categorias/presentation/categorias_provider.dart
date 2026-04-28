import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/config/env.dart';
import 'package:facturacion_app/src/features/categorias/data/categorias_repository.dart';
import 'package:facturacion_app/src/features/categorias/domain/categoria.dart';
import '../../auth/presentation/auth_controller.dart';

// Provider del repository
final categoriasRepositoryProvider = Provider<CategoriasRepository>((ref) {
  final authState = ref.watch(authControllerProvider);
  return CategoriasRepository(Env.apiBaseUrl, authState.token);
});

// Provider para obtener todas las categorías
final categoriasProvider = FutureProvider<List<Categoria>>((ref) async {
  final repository = ref.watch(categoriasRepositoryProvider);
  return repository.getCategorias();
});
