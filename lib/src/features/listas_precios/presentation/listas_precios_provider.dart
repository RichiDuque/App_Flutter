import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/env.dart';
import '../data/listas_precios_repository.dart';
import '../domain/lista_precio.dart';

final listasPreciosRepositoryProvider = Provider<ListasPreciosRepository>((ref) {
  return ListasPreciosRepository(Env.apiBaseUrl);
});

final listasPreciosProvider = FutureProvider<List<ListaPrecio>>((ref) async {
  final repository = ref.watch(listasPreciosRepositoryProvider);
  return repository.getListasPrecios();
});