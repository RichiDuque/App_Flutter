import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'facturacion_controller.dart';
import 'facturas_guardadas_controller.dart';
import '../domain/factura_state.dart';

enum OrdenFacturas {
  reciente,
  antigua,
  montoMayor,
  montoMenor,
  cliente,
}

class FacturasGuardadasScreen extends ConsumerStatefulWidget {
  const FacturasGuardadasScreen({super.key});

  @override
  ConsumerState<FacturasGuardadasScreen> createState() => _FacturasGuardadasScreenState();
}

class _FacturasGuardadasScreenState extends ConsumerState<FacturasGuardadasScreen> {
  OrdenFacturas _ordenActual = OrdenFacturas.reciente;
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();
  bool _mostrarBusqueda = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facturasGuardadas = ref.watch(facturasGuardadasControllerProvider);
    final facturaActual = ref.watch(facturacionControllerProvider);

    // Filtrar y ordenar facturas
    var facturasFiltradas = facturasGuardadas.where((factura) {
      if (_busqueda.isEmpty) return true;
      final cliente = (factura.clienteNombre ?? '').toLowerCase();
      final total = factura.total.toString();
      final busquedaLower = _busqueda.toLowerCase();
      return cliente.contains(busquedaLower) || total.contains(busquedaLower);
    }).toList();

    // Ordenar según criterio seleccionado
    switch (_ordenActual) {
      case OrdenFacturas.reciente:
        facturasFiltradas.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        break;
      case OrdenFacturas.antigua:
        facturasFiltradas.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
        break;
      case OrdenFacturas.montoMayor:
        facturasFiltradas.sort((a, b) => b.total.compareTo(a.total));
        break;
      case OrdenFacturas.montoMenor:
        facturasFiltradas.sort((a, b) => a.total.compareTo(b.total));
        break;
      case OrdenFacturas.cliente:
        facturasFiltradas.sort((a, b) {
          final clienteA = (a.clienteNombre ?? '').toLowerCase();
          final clienteB = (b.clienteNombre ?? '').toLowerCase();
          return clienteA.compareTo(clienteB);
        });
        break;
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tickets abiertos',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () {
              _mostrarMenuOrdenamiento(context);
            },
          ),
          IconButton(
            icon: Icon(_mostrarBusqueda ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _mostrarBusqueda = !_mostrarBusqueda;
                if (!_mostrarBusqueda) {
                  _busqueda = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: facturasGuardadas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay tickets guardados',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Barra de búsqueda
                if (_mostrarBusqueda)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[850],
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar por cliente o monto...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _busqueda = value;
                        });
                      },
                    ),
                  ),
                // Header "Mis tickets"
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mis tickets',
                    style: TextStyle(
                      color: Colors.green[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Lista de facturas guardadas
                Expanded(
                  child: facturasFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.grey[700]),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron resultados',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                    itemCount: facturasFiltradas.length,
                    itemBuilder: (context, index) {
                      final factura = facturasFiltradas[index];
                      final tiempoTranscurrido =
                          DateTime.now().difference(factura.fechaCreacion);

                      String tiempoTexto;
                      if (tiempoTranscurrido.inMinutes < 60) {
                        tiempoTexto =
                            '${tiempoTranscurrido.inMinutes} minutos atrás';
                      } else if (tiempoTranscurrido.inHours < 24) {
                        tiempoTexto = '${tiempoTranscurrido.inHours} horas atrás';
                      } else {
                        tiempoTexto = '${tiempoTranscurrido.inDays} días atrás';
                      }

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Colors.grey[800]!, width: 1),
                          ),
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: false,
                            onChanged: (value) {
                              // TODO: Selección múltiple
                            },
                            fillColor: WidgetStateProperty.all(Colors.grey[700]),
                          ),
                          title: Text(
                            factura.clienteNombre ?? 'Sin cliente',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '$tiempoTexto, Propietario',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          trailing: Text(
                            '\$${factura.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            // Verificar si hay factura activa
                            if (!facturaActual.isEmpty) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[850],
                                  title: const Text(
                                    'Factura en proceso',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'Ya tienes una factura en proceso. Debes finalizarla o guardarla antes de abrir otra.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Entendido'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            // Restaurar factura
                            final facturaState = FacturaState(
                              items: factura.items,
                              clienteId: factura.clienteId,
                              descuentoId: factura.descuentoId,
                            );

                            ref
                                .read(facturacionControllerProvider.notifier)
                                .restaurarFacturaDesdeGuardada(facturaState);

                            // Eliminar de guardadas
                            ref
                                .read(facturasGuardadasControllerProvider.notifier)
                                .eliminarFactura(factura.id);

                            // Cerrar pantalla
                            Navigator.of(context).pop();

                            // Mostrar mensaje
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Factura restaurada'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _mostrarMenuOrdenamiento(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850],
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.access_time,
                color: _ordenActual == OrdenFacturas.reciente ? Colors.green : Colors.white,
              ),
              title: Text(
                'Más reciente',
                style: TextStyle(
                  color: _ordenActual == OrdenFacturas.reciente ? Colors.green : Colors.white,
                ),
              ),
              onTap: () {
                setState(() {
                  _ordenActual = OrdenFacturas.reciente;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.history,
                color: _ordenActual == OrdenFacturas.antigua ? Colors.green : Colors.white,
              ),
              title: Text(
                'Más antigua',
                style: TextStyle(
                  color: _ordenActual == OrdenFacturas.antigua ? Colors.green : Colors.white,
                ),
              ),
              onTap: () {
                setState(() {
                  _ordenActual = OrdenFacturas.antigua;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.arrow_upward,
                color: _ordenActual == OrdenFacturas.montoMayor ? Colors.green : Colors.white,
              ),
              title: Text(
                'Monto mayor',
                style: TextStyle(
                  color: _ordenActual == OrdenFacturas.montoMayor ? Colors.green : Colors.white,
                ),
              ),
              onTap: () {
                setState(() {
                  _ordenActual = OrdenFacturas.montoMayor;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.arrow_downward,
                color: _ordenActual == OrdenFacturas.montoMenor ? Colors.green : Colors.white,
              ),
              title: Text(
                'Monto menor',
                style: TextStyle(
                  color: _ordenActual == OrdenFacturas.montoMenor ? Colors.green : Colors.white,
                ),
              ),
              onTap: () {
                setState(() {
                  _ordenActual = OrdenFacturas.montoMenor;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.person,
                color: _ordenActual == OrdenFacturas.cliente ? Colors.green : Colors.white,
              ),
              title: Text(
                'Cliente (A-Z)',
                style: TextStyle(
                  color: _ordenActual == OrdenFacturas.cliente ? Colors.green : Colors.white,
                ),
              ),
              onTap: () {
                setState(() {
                  _ordenActual = OrdenFacturas.cliente;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}