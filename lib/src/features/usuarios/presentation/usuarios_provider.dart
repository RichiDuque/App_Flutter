import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/config/env.dart';
import 'package:facturacion_app/src/config/dio_interceptor.dart';
import 'package:facturacion_app/src/features/usuarios/data/usuarios_repository.dart';
import 'package:facturacion_app/src/features/usuarios/domain/vendedor.dart';
import 'package:facturacion_app/src/features/usuarios/domain/usuario.dart';
import 'package:facturacion_app/src/features/equipos/domain/miembro_equipo.dart';
import 'package:facturacion_app/src/features/auth/presentation/auth_controller.dart';

// Provider del repository
final usuariosRepositoryProvider = Provider<UsuariosRepository>((ref) {
  final authState = ref.watch(authControllerProvider);
  final interceptor = InactiveUserInterceptor(ref);
  return UsuariosRepository(Env.apiBaseUrl, authState.token, interceptor: interceptor);
});

// Provider para obtener todos los vendedores (solo admin)
final vendedoresProvider = FutureProvider<List<MiembroEquipo>>((ref) async {
  final repository = ref.watch(usuariosRepositoryProvider);
  return repository.obtenerVendedores();
});

// Provider para obtener todos los vendedores con información completa
final vendedoresCompletoProvider = FutureProvider<List<Vendedor>>((ref) async {
  final repository = ref.watch(usuariosRepositoryProvider);
  return repository.obtenerVendedoresCompleto();
});

// Provider para obtener todos los usuarios (admin y vendedores)
final usuariosProvider = FutureProvider<List<Usuario>>((ref) async {
  final repository = ref.watch(usuariosRepositoryProvider);
  return repository.obtenerTodosLosUsuarios();
});

// Provider para obtener un usuario por ID
final usuarioPorIdProvider = FutureProvider.family<Usuario, int>((ref, id) async {
  final repository = ref.watch(usuariosRepositoryProvider);
  return repository.obtenerUsuarioPorId(id);
});