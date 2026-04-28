import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/cliente.dart';
import '../clientes_provider.dart';
import 'cliente_form_screen.dart';
import 'historial_compras_screen.dart';
import '../../../facturacion/presentation/facturacion_controller.dart';

class ClienteDetailScreen extends ConsumerWidget {
  final int clienteId;

  const ClienteDetailScreen({super.key, required this.clienteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clienteAsync = ref.watch(clienteByIdProvider(clienteId));
    final facturaState = ref.watch(facturacionControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Detalle del Cliente', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[850],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          clienteAsync.when(
            data: (cliente) {
              final clienteYaSeleccionado = facturaState.clienteId == cliente.id;
              return IconButton(
                icon: Icon(
                  clienteYaSeleccionado ? Icons.person_remove : Icons.add_shopping_cart,
                  color: clienteYaSeleccionado ? Colors.redAccent : Colors.white,
                ),
                tooltip: clienteYaSeleccionado ? 'Desasignar cliente' : 'Agregar a factura',
                onPressed: () {
                  if (clienteYaSeleccionado) {
                    // Desasignar cliente
                    ref.read(facturacionControllerProvider.notifier).setCliente(null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${cliente.nombreCompleto} desasignado de la factura'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    // Asignar cliente
                    ref.read(facturacionControllerProvider.notifier).setCliente(cliente.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${cliente.nombreCompleto} agregado a la factura'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 1),
                      ),
                    );

                    // Redirigir a la ventana de ventas (home)
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(clienteByIdProvider(clienteId));
            },
          ),
        ],
      ),
      body: clienteAsync.when(
        data: (cliente) => _buildClienteDetail(context, ref, cliente),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar el cliente',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClienteDetail(BuildContext context, WidgetRef ref, Cliente cliente) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con avatar y nombre
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green[700]!, Colors.green[900]!],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    cliente.iniciales,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  cliente.nombreEstablecimiento,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (cliente.propietario != null && cliente.propietario!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Propietario: ${cliente.propietario}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Estadísticas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    label: 'Puntos',
                    value: '${cliente.puntos}',
                    backgroundColor: Colors.amber.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.shopping_bag,
                    iconColor: Colors.blue,
                    label: 'Visitas',
                    value: '${cliente.visitas}',
                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Última visita
          if (cliente.updatedAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.grey[850],
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.greenAccent),
                  ),
                  title: const Text(
                    'Última Visita',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  subtitle: Text(
                    dateFormat.format(cliente.updatedAt!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Información de contacto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Colors.grey[850],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de Contacto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
                      _buildInfoRow(Icons.phone, 'Teléfono', cliente.telefono!),
                    if (cliente.email != null && cliente.email!.isNotEmpty)
                      _buildInfoRow(Icons.email, 'Email', cliente.email!),
                    if (cliente.direccionCompleta.isNotEmpty)
                      _buildInfoRow(Icons.location_on, 'Dirección', cliente.direccionCompleta),
                    if (cliente.codigoCliente != null && cliente.codigoCliente!.isNotEmpty)
                      _buildInfoRow(Icons.badge, 'Código de Cliente', cliente.codigoCliente!),
                    if (cliente.nota != null && cliente.nota!.isNotEmpty)
                      _buildInfoRow(Icons.note, 'Nota', cliente.nota!),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final resultado = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClienteFormScreen(cliente: cliente),
                      ),
                    );

                    if (resultado == true && context.mounted) {
                      ref.invalidate(clienteByIdProvider(clienteId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cliente actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('EDITAR PERFIL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoCanjearPuntos(context, ref, cliente),
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('CANJEAR PUNTOS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistorialComprasScreen(clienteId: cliente.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('VER HISTORIAL DE COMPRAS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color backgroundColor,
  }) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.greenAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCanjearPuntos(BuildContext context, WidgetRef ref, Cliente cliente) {
    final TextEditingController puntosController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Canjear Puntos', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Puntos disponibles: ${cliente.puntos}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: puntosController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Puntos a canjear',
                labelStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () async {
              final puntosACanjear = int.tryParse(puntosController.text) ?? 0;

              if (puntosACanjear <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingrese una cantidad válida de puntos'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (puntosACanjear > cliente.puntos) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No hay suficientes puntos'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final repository = ref.read(clientesRepositoryProvider);
                await repository.actualizarPuntos(
                  cliente.id,
                  cliente.puntos - puntosACanjear,
                );

                ref.invalidate(clienteByIdProvider(cliente.id));

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Puntos canjeados exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
  }
}