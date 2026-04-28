import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/factura.dart';
import 'facturas_provider.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/printer_service.dart';
import '../../configuracion/presentation/impresoras_provider.dart';

class FacturaDetalleScreen extends ConsumerStatefulWidget {
  final Factura factura;

  const FacturaDetalleScreen({super.key, required this.factura});

  @override
  ConsumerState<FacturaDetalleScreen> createState() => _FacturaDetalleScreenState();
}

class _FacturaDetalleScreenState extends ConsumerState<FacturaDetalleScreen> {
  List<Map<String, dynamic>> _detalles = [];
  bool _isLoading = true;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

  // Mapa para trackear qué productos están despachados (ID del detalle -> bool)
  final Map<int, bool> _productosDespachados = {};

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(facturasRepositoryProvider);
      final detalles = await repository.obtenerDetallesFactura(widget.factura.id);
      setState(() {
        _detalles = detalles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _mostrarDialogoReembolso() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => _ReembolsoScreen(
          factura: widget.factura,
          detalles: _detalles,
        ),
      ),
    );

    if (resultado == true && mounted) {
      Navigator.pop(context, true); // Volver a la lista de facturas
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: Text(
          '#${widget.factura.numeroFormateado}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.factura.estado != 'reembolsada')
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.grey[850],
                  builder: (context) => _buildMenuOpciones(),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total
                  Container(
                    padding: const EdgeInsets.all(32),
                    color: Colors.grey[850],
                    child: Column(
                      children: [
                        Text(
                          _currencyFormat.format(widget.factura.total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Información de la factura
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Empleado: ${widget.factura.usuarioNombre ?? 'N/A'}'),
                        _buildInfoRow('Cliente: ${widget.factura.clienteNombre ?? 'N/A'}'),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.grey, height: 1),

                  // Lista de productos
                  ..._detalles.map((detalle) => _buildProductoItem(detalle)),

                  const Divider(color: Colors.grey, height: 1),

                  // Totales
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTotalRow('Subtotal', widget.factura.subtotal),
                        if (widget.factura.descuento > 0) ...[
                          const SizedBox(height: 8),
                          _buildTotalRow('Descuento', widget.factura.descuento, isNegative: true),
                        ],
                        const SizedBox(height: 8),
                        const Divider(color: Colors.grey, height: 1),
                        const SizedBox(height: 8),
                        _buildTotalRow('Total', widget.factura.total, isBold: true),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.grey, height: 1),

                  // Fecha y número de factura
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _dateFormat.format(widget.factura.fechaCreacion),
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${widget.factura.numeroFormateado}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildProductoItem(Map<String, dynamic> detalle) {
    final id = detalle['id'] as int;
    final cantidad = detalle['cantidad'];
    final precioUnitarioRaw = detalle['precio_unitario'];
    final subtotalRaw = detalle['subtotal'];
    final comentario = detalle['comentario'] as String?;

    final precioUnitario = precioUnitarioRaw is String
        ? double.tryParse(precioUnitarioRaw) ?? 0.0
        : (precioUnitarioRaw is num ? precioUnitarioRaw.toDouble() : 0.0);

    final subtotal = subtotalRaw is String
        ? double.tryParse(subtotalRaw) ?? 0.0
        : (subtotalRaw is num ? subtotalRaw.toDouble() : 0.0);

    final producto = detalle['Producto'];
    final nombreProducto = producto != null ? producto['nombre'] ?? 'Producto' : 'Producto';

    final isDespachado = _productosDespachados[id] ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Checkbox para marcar como despachado
          Checkbox(
            value: isDespachado,
            onChanged: (bool? value) {
              setState(() {
                _productosDespachados[id] = value ?? false;
              });
            },
            activeColor: Colors.green,
            checkColor: Colors.white,
            side: BorderSide(color: Colors.grey[600]!),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreProducto,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: isDespachado ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cantidad x ${_currencyFormat.format(precioUnitario)}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    decoration: isDespachado ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.grey[600],
                  ),
                ),
                if (comentario != null && comentario.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    comentario,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      decoration: isDespachado ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _currencyFormat.format(subtotal),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: isDespachado ? TextDecoration.lineThrough : null,
              decorationColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double monto, {bool isNegative = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.white : Colors.grey[400],
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}${_currencyFormat.format(monto)}',
          style: TextStyle(
            color: isNegative ? Colors.red[300] : Colors.white,
            fontSize: isBold ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _imprimirFactura() async {
    try {
      // Obtener impresora de recibos configurada
      final impresoraAsync = ref.read(impresoraRecibosProvider);

      await impresoraAsync.when(
        data: (impresora) async {
          if (impresora == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No hay impresora de recibos configurada'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          // Mostrar indicador de carga
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text('Imprimiendo factura...'),
                  ],
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }

          // Imprimir factura
          final printerService = PrinterService();
          final success = await printerService.imprimirFactura(
            printerAddress: impresora.direccionBluetooth!,
            factura: widget.factura,
            detalles: _detalles,
          );

          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Factura impresa exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al imprimir factura. Verifique la conexión con la impresora.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        loading: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cargando configuración de impresora...'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        error: (error, stack) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al obtener impresora: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarFactura() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Eliminar Factura',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la factura #${widget.factura.numeroFormateado}?\n\nEsta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        final repository = ref.read(facturasRepositoryProvider);
        await repository.eliminarFactura(widget.factura.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Factura eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar factura: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildMenuOpciones() {
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.role == 'admin';

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.print, color: Colors.white),
            title: const Text(
              'IMPRIMIR',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _imprimirFactura();
            },
          ),
          ListTile(
            leading: const Icon(Icons.replay, color: Colors.white),
            title: const Text(
              'REEMBOLSAR',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _mostrarDialogoReembolso();
            },
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'ELIMINAR FACTURA',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _eliminarFactura();
              },
            ),
        ],
      ),
    );
  }
}

// Pantalla de Reembolso
class _ReembolsoScreen extends ConsumerStatefulWidget {
  final Factura factura;
  final List<Map<String, dynamic>> detalles;

  const _ReembolsoScreen({
    required this.factura,
    required this.detalles,
  });

  @override
  ConsumerState<_ReembolsoScreen> createState() => _ReembolsoScreenState();
}

class _ReembolsoScreenState extends ConsumerState<_ReembolsoScreen> {
  final Map<int, int> _cantidadesReembolso = {}; // ID detalle -> cantidad a reembolsar
  bool _isLoading = false;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // Inicializar cantidades en 0
    for (var detalle in widget.detalles) {
      final id = detalle['id'] as int;
      _cantidadesReembolso[id] = 0;
    }
  }

  double get _totalReembolso {
    double total = 0.0;
    for (var detalle in widget.detalles) {
      final id = detalle['id'] as int;
      final cantidadReembolso = _cantidadesReembolso[id] ?? 0;

      if (cantidadReembolso > 0) {
        final precioUnitarioRaw = detalle['precio_unitario'];
        final precioUnitario = precioUnitarioRaw is String
            ? double.tryParse(precioUnitarioRaw) ?? 0.0
            : (precioUnitarioRaw is num ? precioUnitarioRaw.toDouble() : 0.0);
        total += precioUnitario * cantidadReembolso;
      }
    }
    return total;
  }

  bool get _haySeleccionados {
    return _cantidadesReembolso.values.any((cantidad) => cantidad > 0);
  }

  Future<void> _procesarReembolso() async {
    if (!_haySeleccionados) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un producto para reembolsar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirmar reembolso
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Confirmar Reembolso', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Deseas reembolsar ${_currencyFormat.format(_totalReembolso)}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(facturasRepositoryProvider);

      // Crear lista de detalles con cantidades para reembolsar
      final detallesReembolso = <Map<String, dynamic>>[];

      for (var detalle in widget.detalles) {
        final id = detalle['id'] as int;
        final cantidadReembolso = _cantidadesReembolso[id] ?? 0;

        if (cantidadReembolso > 0) {
          detallesReembolso.add({
            'detalle_id': id,
            'cantidad': cantidadReembolso,
          });
        }
      }

      await repository.reembolsarFacturaConCantidades(widget.factura.id, detallesReembolso);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reembolso procesado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar reembolso: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text(
          'Reembolsar',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Lista de productos
          Expanded(
            child: ListView.builder(
              itemCount: widget.detalles.length,
              itemBuilder: (context, index) {
                final detalle = widget.detalles[index];
                return _buildProductoCheckbox(detalle);
              },
            ),
          ),

          // Total y botón
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                top: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(_totalReembolso),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _procesarReembolso,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'REEMBOLSAR ${_currencyFormat.format(_totalReembolso)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCheckbox(Map<String, dynamic> detalle) {
    final id = detalle['id'] as int;
    final cantidadTotal = detalle['cantidad'] as int;
    final cantidadReembolso = _cantidadesReembolso[id] ?? 0;
    final precioUnitarioRaw = detalle['precio_unitario'];

    final precioUnitario = precioUnitarioRaw is String
        ? double.tryParse(precioUnitarioRaw) ?? 0.0
        : (precioUnitarioRaw is num ? precioUnitarioRaw.toDouble() : 0.0);

    final producto = detalle['Producto'];
    final nombreProducto = producto != null ? producto['nombre'] ?? 'Producto' : 'Producto';

    final subtotalReembolso = precioUnitario * cantidadReembolso;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del producto
          Text(
            nombreProducto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Precio unitario
          Text(
            _currencyFormat.format(precioUnitario),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          // Controles de cantidad
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botones de cantidad
              Row(
                children: [
                  IconButton(
                    onPressed: cantidadReembolso > 0
                        ? () {
                            setState(() {
                              _cantidadesReembolso[id] = cantidadReembolso - 1;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.white,
                    disabledColor: Colors.grey[700],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$cantidadReembolso / $cantidadTotal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: cantidadReembolso < cantidadTotal
                        ? () {
                            setState(() {
                              _cantidadesReembolso[id] = cantidadReembolso + 1;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.white,
                    disabledColor: Colors.grey[700],
                  ),
                ],
              ),
              // Subtotal a reembolsar
              Text(
                _currencyFormat.format(subtotalReembolso),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}