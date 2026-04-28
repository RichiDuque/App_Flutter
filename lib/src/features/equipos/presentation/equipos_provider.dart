import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/config/env.dart';
import 'package:facturacion_app/src/features/equipos/data/equipos_repository.dart';
import 'package:facturacion_app/src/features/equipos/domain/equipo.dart';
import 'package:facturacion_app/src/features/equipos/domain/miembro_equipo.dart';
import 'package:facturacion_app/src/features/auth/presentation/auth_controller.dart';

// Provider del repository
final equiposRepositoryProvider = Provider<EquiposRepository>((ref) {
  final authState = ref.watch(authControllerProvider);
  return EquiposRepository(Env.apiBaseUrl, authState.token);
});

// Provider para obtener todos los equipos (admin)
final equiposProvider = FutureProvider<List<Equipo>>((ref) async {
  final repository = ref.watch(equiposRepositoryProvider);
  return repository.obtenerEquipos();
});

// Provider para obtener un equipo por ID
final equipoPorIdProvider =
    FutureProvider.family<Equipo, int>((ref, equipoId) async {
  final repository = ref.watch(equiposRepositoryProvider);
  return repository.obtenerEquipoPorId(equipoId);
});

// Provider para obtener miembros de un equipo
final miembrosEquipoProvider =
    FutureProvider.family<List<MiembroEquipo>, int>((ref, equipoId) async {
  final repository = ref.watch(equiposRepositoryProvider);
  return repository.obtenerMiembrosEquipo(equipoId);
});

// Provider para obtener mis equipos (vendedor)
final misEquiposProvider = FutureProvider<List<Equipo>>((ref) async {
  final repository = ref.watch(equiposRepositoryProvider);
  return repository.obtenerMisEquipos();
});

// Provider para obtener mis compañeros
final misCompanerosProvider =
    FutureProvider<List<MiembroEquipo>>((ref) async {
  final repository = ref.watch(equiposRepositoryProvider);
  return repository.obtenerMisCompaneros();
});

// Provider de estado para el equipo seleccionado (para edición)
final equipoSeleccionadoProvider = StateProvider<Equipo?>((ref) => null);