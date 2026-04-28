import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/devolucion.dart';
import '../data/facturas_repository.dart';
import 'package:facturacion_app/src/features/auth/presentation/auth_controller.dart';
import 'package:facturacion_app/src/config/env.dart';

// Provider para obtener los detalles de una devolución
final devolucionDetalleProvider =
    FutureProvider.family<Devolucion, int>((ref, devolucionId) async {
  final authState = ref.watch(authControllerProvider);
  final repository = FacturasRepository(
    Env.apiBaseUrl,
    authState.token,
  );
  return repository.obtenerDevolucion(devolucionId);
});

class DevolucionDetalleScreen extends ConsumerWidget {
  final int devolucionId;

  const DevolucionDetalleScreen({
    super.key,
    required this.devolucionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devolucionAsync = ref.watch(devolucionDetalleProvider(devolucionId));
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalle de Devolución',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: devolucionAsync.when(
        data: (devolucion) => SingleChildScrollView(
          child: Column(
            children: [
              // Header con información general
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[900]!, Colors.orange[800]!],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.keyboard_return,
                          color: Colors.orange[200],
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DEVOLUCIÓN',
                                style: TextStyle(
                                  color: Colors.orange[200],
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(devolucion.total),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 16),
                    // Información de la factura relacionada
                    if (devolucion.facturaNumero != null)
                      _buildInfoRow(
                        'Factura Original',
                        devolucion.facturaNumero!,
                        Icons.receipt_long,
                      ),
                    if (devolucion.facturaTotal != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Total Factura',
                        currencyFormat.format(devolucion.facturaTotal!),
                        Icons.attach_money,
                      ),
                    ],
                  ],
                ),
              ),

              // Detalles de productos devueltos
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Productos Devueltos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...devolucion.detalles.map((detalle) =>
                      Card(
                        color: Colors.grey[850],
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      detalle.productoNombre ?? 'Producto #${detalle.productoId}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[900]?.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange[700]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'x${detalle.cantidad}',
                                      style: TextStyle(
                                        color: Colors.orange[300],
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (detalle.productoDescripcion != null &&
                                  detalle.productoDescripcion!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  detalle.productoDescripcion!,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Precio Unit.: ${currencyFormat.format(detalle.precioUnitario)}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(detalle.subtotal),
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.grey, height: 1),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Cliente',
                      devolucion.clienteNombre ?? 'Cliente #${devolucion.clienteId}',
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Procesado por',
                      devolucion.usuarioNombre ?? 'Usuario #${devolucion.usuarioId}',
                      Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Fecha',
                      _formatFecha(devolucion.fecha),
                      Icons.calendar_today,
                    ),
                    if (devolucion.motivo.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Motivo',
                        devolucion.motivo,
                        Icons.comment_outlined,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error al cargar la devolución',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(devolucionDetalleProvider(devolucionId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[500], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);

    if (diff.inDays == 0) {
      return 'Hoy a las ${_formatHora(fecha)}';
    } else if (diff.inDays == 1) {
      return 'Ayer a las ${_formatHora(fecha)}';
    } else {
      final formatter = DateFormat('dd/MM/yyyy HH:mm');
      return formatter.format(fecha);
    }
  }

  String _formatHora(DateTime fecha) {
    final hour = fecha.hour > 12 ? fecha.hour - 12 : (fecha.hour == 0 ? 12 : fecha.hour);
    final minute = fecha.minute.toString().padLeft(2, '0');
    final period = fecha.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $period';
  }
}