import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/env.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/descuentos_repository.dart';
import '../domain/descuento.dart';

final descuentosRepositoryProvider = Provider<DescuentosRepository>((ref) {
  final authState = ref.watch(authControllerProvider);
  return DescuentosRepository(Env.apiBaseUrl, authState.token);
});

final descuentosProvider = FutureProvider<List<Descuento>>((ref) async {
  final repository = ref.watch(descuentosRepositoryProvider);
  return repository.getDescuentos();
});