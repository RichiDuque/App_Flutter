import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/config/env.dart';
import '../data/facturas_repository.dart';
import '../domain/factura.dart';
import '../domain/usuario_factura.dart';
import '../../auth/presentation/auth_controller.dart';

// Provider para el repositorio
final facturasRepositoryProvider = Provider<FacturasRepository>((ref) {
  final authState = ref.watch(authControllerProvider);
  return FacturasRepository(Env.apiBaseUrl, authState.token);
});

// Provider para obtener usuarios (solo para admin)
final usuariosProvider = FutureProvider<List<UsuarioFactura>>((ref) async {
  final authState = ref.watch(authControllerProvider);

  // Solo admin puede ver la lista de usuarios
  if (authState.role != 'admin') {
    return [];
  }

  final repository = ref.watch(facturasRepositoryProvider);
  return repository.obtenerUsuarios();
});

// Provider para usuarios seleccionados (filtro)
final usuariosSeleccionadosProvider = StateProvider<List<int>>((ref) => []);

// Provider para obtener facturas según rol
final facturasProvider = FutureProvider<List<Factura>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final repository = ref.watch(facturasRepositoryProvider);
  final usuariosSeleccionados = ref.watch(usuariosSeleccionadosProvider);

  if (authState.role == 'admin') {
    // Admin puede ver todas las facturas o filtradas por usuario
    if (usuariosSeleccionados.isEmpty) {
      // Ver todas las facturas
      return repository.obtenerFacturas();
    } else {
      // Ver facturas de usuarios específicos
      return repository.obtenerFacturas(usuariosIds: usuariosSeleccionados);
    }
  } else {
    // Vendedor solo ve sus propias facturas
    return repository.obtenerFacturas(usuarioId: authState.userId);
  }
});

// Provider para el estado de búsqueda
final busquedaFacturasProvider = StateProvider<String>((ref) => '');

// Provider para la fecha seleccionada (null = todas las fechas)
final fechaSeleccionadaProvider = StateProvider<DateTime?>((ref) => null);