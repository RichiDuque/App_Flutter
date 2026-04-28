import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/env.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/cargues_repository.dart';
import '../domain/cargue.dart';
import 'cargues_filters.dart';

final carguesRepositoryProvider = Provider<CarguesRepository>((ref) {
  final authState = ref.watch(authControllerProvider);
  final vendedorNombre = authState.user ?? 'Usuario';

  return CarguesRepository(
    baseUrl: Env.apiBaseUrl,
    token: authState.token,
    vendedorNombre: vendedorNombre,
  );
});

final carguesProvider = FutureProvider.family<List<Cargue>, CarguesFilters?>((ref, filters) async {
  final repository = ref.watch(carguesRepositoryProvider);
  return repository.getCargues(
    usuarioId: null,
    usuariosIds: filters?.usuariosIds,
    fechaInicio: filters?.fechaInicio,
    fechaFin: filters?.fechaFin,
  );
});

final cargueByIdProvider = FutureProvider.family<Cargue, int>((ref, id) async {
  final repository = ref.watch(carguesRepositoryProvider);
  return repository.getCargueById(id);
});