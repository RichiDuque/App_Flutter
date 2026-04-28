import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/auth/presentation/auth_controller.dart';
import 'facturas_provider.dart';
import '../domain/factura.dart';
import 'widgets/filtro_usuarios_dialog.dart';
import 'widgets/selector_fechas_dialog.dart';

class FacturasScreen extends ConsumerWidget {
  const FacturasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final facturasAsync = ref.watch(facturasProvider);
    final busqueda = ref.watch(busquedaFacturasProvider);
    final usuariosSeleccionados = ref.watch(usuariosSeleccionadosProvider);
    final fechaSeleccionada = ref.watch(fechaSeleccionadaProvider);
    final isAdmin = authState.role == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text(
          'Facturas',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Botón de selector de fecha
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: fechaSeleccionada != null ? Colors.greenAccent : Colors.white,
            ),
            onPressed: () async {
              final nuevaFecha = await showDialog<DateTime?>(
                context: context,
                builder: (context) => SelectorFechasDialog(
                  fechaSeleccionada: fechaSeleccionada,
                ),
              );
              if (nuevaFecha != null || nuevaFecha != fechaSeleccionada) {
                ref.read(fechaSeleccionadaProvider.notifier).state = nuevaFecha;
              }
            },
          ),
          // Botón de filtro de usuarios (solo para admin)
          if (isAdmin)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list, color: Colors.white),
                  if (usuariosSeleccionados.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${usuariosSeleccionados.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const FiltroUsuariosDialog(),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(facturasProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner con información del usuario y rol
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
                Text(
                  isAdmin ? 'Vista de Administrador' : 'Vista de Vendedor',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authState.user ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (fechaSeleccionada != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _formatFechaHeader(fechaSeleccionada),
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          ref.read(fechaSeleccionadaProvider.notifier).state =
                              null;
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isAdmin && usuariosSeleccionados.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Filtrando ${usuariosSeleccionados.length} usuario(s)',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
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
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente o número...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey[500]),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  ref.read(busquedaFacturasProvider.notifier).state = value;
                },
              ),
            ),
          ),
          // Lista de facturas
          Expanded(
            child: facturasAsync.when(
              data: (facturas) {
                // Filtrar por búsqueda
                var facturasFiltradas = facturas;
                if (busqueda.isNotEmpty) {
                  final busquedaLower = busqueda.toLowerCase();
                  facturasFiltradas = facturas.where((f) {
                    return f.clienteNombre
                            ?.toLowerCase()
                            .contains(busquedaLower) ==
                        true ||
                        f.numeroFormateado.toLowerCase().contains(busquedaLower);
                  }).toList();
                }

                // Filtrar por fecha seleccionada
                if (fechaSeleccionada != null) {
                  facturasFiltradas = facturasFiltradas.where((f) {
                    return _isSameDay(f.fechaCreacion, fechaSeleccionada);
                  }).toList();
                }

                if (facturasFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          busqueda.isNotEmpty || fechaSeleccionada != null
                              ? Icons.search_off
                              : Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getMensajeVacio(
                              busqueda, fechaSeleccionada, isAdmin, usuariosSeleccionados),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        if (fechaSeleccionada != null ||
                            usuariosSeleccionados.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              ref.read(fechaSeleccionadaProvider.notifier).state =
                                  null;
                              ref
                                  .read(usuariosSeleccionadosProvider.notifier)
                                  .state = [];
                            },
                            icon: const Icon(Icons.clear_all,
                                color: Colors.greenAccent),
                            label: const Text(
                              'Limpiar filtros',
                              style: TextStyle(color: Colors.greenAccent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // Agrupar facturas por día
                final facturasAgrupadas = _agruparPorDia(facturasFiltradas);
                final fechasOrdenadas = facturasAgrupadas.keys.toList()
                  ..sort((a, b) => b.compareTo(a)); // Más recientes primero

                return ListView.builder(
                  itemCount: fechasOrdenadas.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final fecha = fechasOrdenadas[index];
                    final facturasDelDia = facturasAgrupadas[fecha]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header del día
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.greenAccent, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        color: Colors.greenAccent, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatFechaDia(fecha),
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${facturasDelDia.length} factura${facturasDelDia.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Facturas del día
                        ...facturasDelDia.map((factura) => _buildFacturaCard(
                              context,
                              ref,
                              factura,
                              isAdmin,
                            )),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al cargar facturas',
                      style: TextStyle(color: Colors.white, fontSize: 18),
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
                        ref.invalidate(facturasProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
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

  // Agrupar facturas por día
  Map<DateTime, List<Factura>> _agruparPorDia(List<Factura> facturas) {
    final Map<DateTime, List<Factura>> agrupadas = {};

    for (final factura in facturas) {
      final fecha = DateTime(
        factura.fechaCreacion.year,
        factura.fechaCreacion.month,
        factura.fechaCreacion.day,
      );

      if (!agrupadas.containsKey(fecha)) {
        agrupadas[fecha] = [];
      }
      agrupadas[fecha]!.add(factura);
    }

    return agrupadas;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMensajeVacio(String busqueda, DateTime? fechaSeleccionada,
      bool isAdmin, List<int> usuariosSeleccionados) {
    if (busqueda.isNotEmpty) {
      return 'No se encontraron facturas con "$busqueda"';
    }
    if (fechaSeleccionada != null) {
      return 'No hay facturas para ${_formatFechaHeader(fechaSeleccionada)}';
    }
    if (isAdmin && usuariosSeleccionados.isEmpty) {
      return 'No hay facturas registradas';
    }
    return 'No hay facturas para mostrar';
  }

  String _formatFechaHeader(DateTime fecha) {
    final now = DateTime.now();
    if (_isSameDay(fecha, now)) {
      return 'Hoy';
    } else if (_isSameDay(fecha, now.subtract(const Duration(days: 1)))) {
      return 'Ayer';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  String _formatFechaDia(DateTime fecha) {
    final now = DateTime.now();
    if (_isSameDay(fecha, now)) {
      return 'Hoy';
    } else if (_isSameDay(fecha, now.subtract(const Duration(days: 1)))) {
      return 'Ayer';
    } else {
      final dias = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final meses = [
        '',
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic'
      ];
      return '${dias[fecha.weekday]} ${fecha.day} ${meses[fecha.month]}';
    }
  }

  Widget _buildFacturaCard(
    BuildContext context,
    WidgetRef ref,
    Factura factura,
    bool isAdmin,
  ) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ver detalle de factura ${factura.numeroFormateado}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Número de factura y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      factura.numeroFormateado,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildEstadoBadge(factura.estado),
                ],
              ),
              const SizedBox(height: 12),
              // Cliente
              Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.grey[500], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      factura.clienteNombre ?? 'Cliente #${factura.clienteId}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              // Usuario (solo visible para admin)
              if (isAdmin && factura.usuarioNombre != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.badge_outlined,
                        color: Colors.grey[500], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vendedor: ${factura.usuarioNombre}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Hora y total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          color: Colors.grey[500], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _formatHora(factura.fechaCreacion),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${factura.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Mostrar descuento si existe
              if (factura.descuento > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal: \$${factura.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Desc: -\$${factura.descuento.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    String label;

    switch (estado.toLowerCase()) {
      case 'completada':
      case 'finalizada':
        color = Colors.green;
        label = 'COMPLETADA';
        break;
      case 'pendiente':
        color = Colors.orange;
        label = 'PENDIENTE';
        break;
      case 'cancelada':
        color = Colors.red;
        label = 'CANCELADA';
        break;
      default:
        color = Colors.grey;
        label = estado.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatHora(DateTime fecha) {
    final hour = fecha.hour > 12 ? fecha.hour - 12 : (fecha.hour == 0 ? 12 : fecha.hour);
    final minute = fecha.minute.toString().padLeft(2, '0');
    final period = fecha.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $period';
  }
}