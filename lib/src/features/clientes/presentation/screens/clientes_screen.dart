import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/cliente.dart';
import '../clientes_provider.dart';
import 'cliente_form_screen.dart';
import 'cliente_detail_screen.dart';
import '../../../home/presentation/widgets/app_drawer.dart';

class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  String _busqueda = '';

  void _navegarADetalle(Cliente cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteDetailScreen(clienteId: cliente.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text(
          'Clientes',
          style: TextStyle(color: Colors.white),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(clientesProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'clientes'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const ClienteFormScreen(),
            ),
          );

          if (resultado == true && context.mounted) {
            ref.invalidate(clientesProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cliente creado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Cliente'),
      ),
      body: Column(
        children: [
          // Banner informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[800]!, Colors.grey[850]!],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Colors.greenAccent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión de Clientes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Administra tu cartera de clientes',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Barra de búsqueda
          Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Buscar cliente...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey[500]),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _busqueda = value;
                  });
                },
              ),
            ),
          ),

          // Lista de clientes
          Expanded(
            child: clientesAsync.when(
              data: (clientes) {
                // Filtrar por búsqueda
                var clientesFiltrados = clientes;
                if (_busqueda.isNotEmpty) {
                  final busquedaLower = _busqueda.toLowerCase();
                  clientesFiltrados = clientes.where((c) {
                    return c.nombreEstablecimiento.toLowerCase().contains(busquedaLower) ||
                        (c.propietario?.toLowerCase().contains(busquedaLower) ?? false) ||
                        (c.telefono?.toLowerCase().contains(busquedaLower) ?? false) ||
                        (c.email?.toLowerCase().contains(busquedaLower) ?? false);
                  }).toList();
                }

                if (clientesFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _busqueda.isNotEmpty
                              ? Icons.search_off
                              : Icons.people_outline,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _busqueda.isNotEmpty
                              ? 'No se encontraron clientes'
                              : 'No hay clientes registrados',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _busqueda.isNotEmpty
                              ? 'Intenta con otro término de búsqueda'
                              : 'Agrega clientes para comenzar',
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(clientesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final cliente = clientesFiltrados[index];
                      return _buildClienteCard(cliente);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al cargar clientes',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(clientesProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard(Cliente cliente) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[850],
      child: InkWell(
        onTap: () => _navegarADetalle(cliente),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.green,
                child: Text(
                  cliente.iniciales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Información del cliente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombreEstablecimiento,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (cliente.propietario != null && cliente.propietario!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Propietario: ${cliente.propietario}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            cliente.telefono!,
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    if (cliente.email != null && cliente.email!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cliente.email!,
                              style: TextStyle(color: Colors.grey[400], fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    // Estadísticas
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${cliente.puntos}',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_bag, size: 12, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                '${cliente.visitas}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Icono de flecha
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}