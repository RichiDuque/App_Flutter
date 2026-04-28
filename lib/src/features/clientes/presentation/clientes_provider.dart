import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/env.dart';
import '../data/clientes_repository.dart';
import '../domain/cliente.dart';

final clientesRepositoryProvider = Provider<ClientesRepository>((ref) {
  return ClientesRepository(Env.apiBaseUrl);
});

final clientesProvider = FutureProvider<List<Cliente>>((ref) async {
  final repository = ref.watch(clientesRepositoryProvider);
  return repository.getClientes();
});

final clienteByIdProvider =
    FutureProvider.family<Cliente, int>((ref, id) async {
  final repository = ref.watch(clientesRepositoryProvider);
  return repository.getClienteById(id);
});

// Provider para el texto de búsqueda
final busquedaClientesProvider = StateProvider<String>((ref) => '');

// Provider para controlar si está en modo búsqueda
final modoBusquedaClientesActivoProvider = StateProvider<bool>((ref) => false);

// Provider para los resultados de búsqueda
final clientesBusquedaProvider = FutureProvider<List<Cliente>>((ref) async {
  final busqueda = ref.watch(busquedaClientesProvider);
  final repository = ref.watch(clientesRepositoryProvider);
  
  if (busqueda.isEmpty) {
    return [];
  }
  
  return repository.buscarClientePorNombre(busqueda);
});

// Provider para el historial de compras de un cliente
final historialComprasProvider =
    FutureProvider.family<List<dynamic>, int>((ref, clienteId) async {
  final repository = ref.watch(clientesRepositoryProvider);
  return repository.getHistorialCompras(clienteId);
});

// Provider para refrescar la lista de clientes
final refrescarClientesProvider = StateProvider<int>((ref) => 0);
