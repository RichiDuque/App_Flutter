import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../clientes_provider.dart';
import '../../../facturas/domain/factura.dart';
import '../../../facturas/presentation/factura_detalle_screen.dart';

class HistorialComprasScreen extends ConsumerStatefulWidget {
  final int clienteId;

  const HistorialComprasScreen({super.key, required this.clienteId});

  @override
  ConsumerState<HistorialComprasScreen> createState() => _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends ConsumerState<HistorialComprasScreen> {
  String _busqueda = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  Future<void> _seleccionarFechaInicio() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Colors.grey[850]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaInicio) {
      setState(() {
        _fechaInicio = picked;
      });
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Colors.grey[850]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaFin) {
      setState(() {
        _fechaFin = picked;
      });
    }
  }

  void _limpiarFiltroFechas() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final historialAsync = ref.watch(historialComprasProvider(widget.clienteId));
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Historial de Compras', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[850],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(historialComprasProvider(widget.clienteId));
            },
          ),
        ],
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.greenAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historial de Facturas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Compras realizadas por el cliente',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
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
                  hintText: 'Buscar por número de factura...',
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

          // Filtro por rango de fechas
          Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _seleccionarFechaInicio,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _fechaInicio != null ? Colors.green : Colors.grey[700]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fechaInicio != null
                                  ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                                  : 'Fecha inicio',
                              style: TextStyle(
                                color: _fechaInicio != null ? Colors.white : Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _seleccionarFechaFin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _fechaFin != null ? Colors.green : Colors.grey[700]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fechaFin != null
                                  ? DateFormat('dd/MM/yyyy').format(_fechaFin!)
                                  : 'Fecha fin',
                              style: TextStyle(
                                color: _fechaFin != null ? Colors.white : Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_fechaInicio != null || _fechaFin != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                    onPressed: _limpiarFiltroFechas,
                    tooltip: 'Limpiar filtro',
                  ),
              ],
            ),
          ),

          // Lista de compras
          Expanded(
            child: historialAsync.when(
              data: (facturas) {
                if (facturas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay compras registradas',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Las facturas del cliente aparecerán aquí',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrar facturas por búsqueda y fecha
                var facturasFiltradas = facturas.where((factura) {
                  // Filtro por número de factura
                  if (_busqueda.isNotEmpty) {
                    final numeroFactura = factura['numero_factura']?.toString() ?? '';
                    if (!numeroFactura.contains(_busqueda)) {
                      return false;
                    }
                  }

                  // Filtro por rango de fechas - solo aplicar si hay al menos una fecha seleccionada
                  if (_fechaInicio != null || _fechaFin != null) {
                    // Si la factura no tiene fecha, excluirla del filtro
                    if (factura['created_at'] == null) return false;

                    try {
                      final fechaFactura = DateTime.parse(factura['created_at']).toLocal();
                      final fechaFacturaSoloFecha = DateTime(fechaFactura.year, fechaFactura.month, fechaFactura.day);

                      // Aplicar filtro de fecha inicio si está definida
                      if (_fechaInicio != null) {
                        final fechaInicioNormalizada = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day);
                        if (fechaFacturaSoloFecha.isBefore(fechaInicioNormalizada)) {
                          return false;
                        }
                      }

                      // Aplicar filtro de fecha fin si está definida
                      if (_fechaFin != null) {
                        final fechaFinNormalizada = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day);
                        if (fechaFacturaSoloFecha.isAfter(fechaFinNormalizada)) {
                          return false;
                        }
                      }
                    } catch (e) {
                      // Si hay error parseando la fecha, excluir la factura
                      return false;
                    }
                  }

                  return true;
                }).toList();

                if (facturasFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        const Text(
                          'No se encontraron facturas',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Intenta con otro término de búsqueda',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(historialComprasProvider(widget.clienteId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: facturasFiltradas.length,
                    itemBuilder: (context, index) {
                      final facturaData = facturasFiltradas[index];

                      // Convertir a objeto Factura
                      final factura = Factura.fromJson(facturaData);
                      final detalles = facturaData['DetalleFacturas'] as List<dynamic>? ?? [];

                      return Card(
                        color: Colors.grey[850],
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FacturaDetalleScreen(factura: factura),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Ícono
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.receipt, color: Colors.greenAccent, size: 24),
                                ),
                                const SizedBox(width: 16),

                                // Contenido
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Factura #${factura.numeroFormateado}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                                          const SizedBox(width: 4),
                                          Text(
                                            dateFormat.format(factura.fechaCreacion),
                                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        currencyFormat.format(factura.total),
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Badge de items
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${detalles.length}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        detalles.length == 1 ? 'item' : 'items',
                                        style: TextStyle(
                                          color: Colors.blue[300],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Flecha
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        ),
                      );
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
                      'Error al cargar el historial',
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
                      onPressed: () => ref.invalidate(historialComprasProvider(widget.clienteId)),
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
}