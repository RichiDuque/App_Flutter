import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/facturacion/presentation/facturacion_controller.dart';
import '../../clientes/presentation/clientes_provider.dart';
import '../../descuentos/presentation/descuentos_provider.dart';
import '../../facturas/presentation/facturas_provider.dart';
import 'facturas_guardadas_controller.dart';
import '../domain/factura_guardada.dart';
import 'widgets/cliente_selector_dialog.dart';
import 'widgets/descuento_selector_dialog.dart';
import 'factura_confirmacion_screen.dart';
import 'comentario_screen.dart';

class FacturaDetailScreen extends ConsumerWidget {
  const FacturaDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facturaState = ref.watch(facturacionControllerProvider);
    final clientesAsync = ref.watch(clientesProvider);
    final descuentosAsync = ref.watch(descuentosProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text(
          'Detalle de Factura',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (facturaState.items.isNotEmpty)
            IconButton(
              icon: Icon(
                facturaState.descuentoId != null
                    ? Icons.discount
                    : Icons.discount_outlined,
                color: facturaState.descuentoId != null
                    ? Colors.green[300]
                    : Colors.white,
              ),
              onPressed: () {
                descuentosAsync.when(
                  data: (descuentos) {
                    showDialog(
                      context: context,
                      builder: (context) => DescuentoSelectorDialog(
                        descuentos: descuentos,
                        descuentoIdSeleccionado: facturaState.descuentoId,
                        onDescuentoSelected: (descuentoId) {
                          ref
                              .read(facturacionControllerProvider.notifier)
                              .setDescuento(descuentoId);
                        },
                      ),
                    );
                  },
                  loading: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cargando descuentos...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  error: (err, stack) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cargar descuentos: $err'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                );
              },
            ),
          if (facturaState.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Limpiar factura'),
                    content: const Text(
                        '¿Estás seguro de que deseas eliminar todos los productos de la factura?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(facturacionControllerProvider.notifier)
                              .limpiarFactura();
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: facturaState.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay productos en la factura',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega productos desde la lista',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Cliente Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[700]!, width: 2),
                      ),
                    ),
                    child: clientesAsync.when(
                      data: (clientes) {
                        final clienteSeleccionado = clientes.firstWhere(
                          (c) => c.id == facturaState.clienteId,
                          orElse: () => clientes.first,
                        );

                        return Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ClienteSelectorDialog(
                                      clientes: clientes,
                                      clienteIdSeleccionado: facturaState.clienteId,
                                      onClienteSelected: (clienteId) {
                                        ref
                                            .read(facturacionControllerProvider.notifier)
                                            .setCliente(clienteId);
                                      },
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.person_outline,
                                        color: Colors.grey[400], size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cliente',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            facturaState.clienteId == null
                                                ? 'Seleccionar cliente'
                                                : clienteSeleccionado.nombreEstablecimiento,
                                            style: TextStyle(
                                              color: facturaState.clienteId == null
                                                  ? Colors.orange
                                                  : Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios,
                                        color: Colors.grey[600], size: 16),
                                  ],
                                ),
                              ),
                            ),
                            if (facturaState.clienteId != null)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                tooltip: 'Remover cliente',
                                onPressed: () {
                                  ref.read(facturacionControllerProvider.notifier).setCliente(null);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cliente removido de la factura'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      error: (err, stack) => Text(
                        'Error al cargar clientes',
                        style: TextStyle(color: Colors.red[300]),
                      ),
                    ),
                  ),
                  // Lista de productos
                  ...facturaState.items.map((item) {
                    return Dismissible(
                      key: Key(item.producto.id.toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Colors.grey[850],
                              title: const Text(
                                'Eliminar producto',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                '¿Deseas eliminar "${item.producto.nombre}" de la factura?',
                                style: const TextStyle(color: Colors.white),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        ref
                            .read(facturacionControllerProvider.notifier)
                            .removerProducto(item.producto.id);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Colors.grey[800]!, width: 1),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.producto.nombre,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${item.precioUnitario.toStringAsFixed(2)} c/u',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.white),
                                      onPressed: () {
                                        ref
                                            .read(
                                                facturacionControllerProvider
                                                    .notifier)
                                            .decrementarCantidad(
                                                item.producto.id);
                                      },
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        final controller = TextEditingController(
                                            text: '${item.cantidad}');
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: Colors.grey[850],
                                            title: const Text('Editar Cantidad',
                                                style: TextStyle(color: Colors.white)),
                                            content: TextField(
                                              controller: controller,
                                              keyboardType: TextInputType.number,
                                              autofocus: true,
                                              style: const TextStyle(
                                                  color: Colors.white, fontSize: 20),
                                              decoration: InputDecoration(
                                                hintText: 'Cantidad',
                                                hintStyle: TextStyle(
                                                    color: Colors.grey[600]),
                                                enabledBorder: UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.grey[600]!),
                                                ),
                                                focusedBorder:
                                                    const UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.green),
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  final nuevaCantidad =
                                                      int.tryParse(controller.text);
                                                  if (nuevaCantidad != null &&
                                                      nuevaCantidad > 0) {
                                                    ref
                                                        .read(
                                                            facturacionControllerProvider
                                                                .notifier)
                                                        .actualizarCantidad(
                                                          item.producto.id,
                                                          nuevaCantidad,
                                                        );
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                child: const Text('Guardar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.grey[600]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              '${item.cantidad}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.edit,
                                                size: 14, color: Colors.grey[500]),
                                          ],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          color: Colors.white),
                                      onPressed: () {
                                        ref
                                            .read(
                                                facturacionControllerProvider
                                                    .notifier)
                                            .incrementarCantidad(
                                                item.producto.id);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    '\$${item.subtotal.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (item.comentario != null &&
                                item.comentario!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.comment,
                                        size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.comentario!,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            TextButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ComentarioScreen(
                                      productoId: item.producto.id,
                                      comentarioInicial: item.comentario,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.note_add,
                                  size: 16, color: Colors.grey[400]),
                              label: Text(
                                item.comentario == null ||
                                        item.comentario!.isEmpty
                                    ? 'Agregar comentario'
                                    : 'Editar comentario',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Summary section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    border: Border(
                      top: BorderSide(color: Colors.grey[700]!, width: 2),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: descuentosAsync.when(
                    data: (descuentos) {
                      // Buscar el descuento seleccionado
                      final descuentoSeleccionado = facturaState.descuentoId != null
                          ? descuentos.firstWhere(
                              (d) => d.id == facturaState.descuentoId,
                              orElse: () => descuentos.first,
                            )
                          : null;

                      final porcentajeDescuento = descuentoSeleccionado?.porcentaje ?? 0.0;
                      final montoDescuento = facturaState.montoDescuento(porcentajeDescuento);
                      final totalFinal = facturaState.totalConDescuento(porcentajeDescuento);

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '\$${facturaState.subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          // Mostrar descuento si está aplicado
                          if (descuentoSeleccionado != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.discount,
                                        size: 16, color: Colors.green[300]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Descuento (${porcentajeDescuento.toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        color: Colors.green[300],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '-\$${montoDescuento.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.green[300],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'IVA (0%)',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '\$0.00',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.grey),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${totalFinal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      const SizedBox(height: 20),
                      // Botón Guardar (como borrador)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: facturaState.items.isEmpty
                              ? null
                              : () async {
                                  // Obtener nombre del cliente si está seleccionado
                                  String? clienteNombre;
                                  if (facturaState.clienteId != null) {
                                    final clientes = clientesAsync.value ?? [];
                                    final cliente = clientes.firstWhere(
                                      (c) => c.id == facturaState.clienteId,
                                      orElse: () => clientes.first,
                                    );
                                    clienteNombre = cliente.nombreEstablecimiento;
                                  }

                                  // Crear factura guardada
                                  final facturaGuardada = FacturaGuardada(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    items: facturaState.items,
                                    clienteId: facturaState.clienteId,
                                    clienteNombre: clienteNombre,
                                    descuentoId: facturaState.descuentoId,
                                    total: facturaState.total,
                                    fechaCreacion: DateTime.now(),
                                  );

                                  // Guardar en storage
                                  await ref
                                      .read(facturasGuardadasControllerProvider.notifier)
                                      .agregarFactura(facturaGuardada);

                                  // Limpiar factura actual
                                  ref.read(facturacionControllerProvider.notifier).limpiarFactura();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ticket guardado'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[600]!, width: 2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.save_outlined, size: 20),
                          label: const Text(
                            'GUARDAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Botón Finalizar Factura
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: facturaState.isLoading
                              ? null
                              : () async {
                                  final response = await ref
                                      .read(
                                          facturacionControllerProvider.notifier)
                                      .guardarFactura();

                                  if (context.mounted) {
                                    if (response != null) {
                                      // Invalidar el provider de facturas para que se recargue la lista
                                      ref.invalidate(facturasProvider);

                                      // Navegar a la pantalla de confirmación
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FacturaConfirmacionScreen(
                                            facturaId: response['factura_id'],
                                            numeroFactura:
                                                response['numero_factura'],
                                            total: (response['total'] as num)
                                                .toDouble(),
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(facturaState.error ??
                                              'Error al guardar la factura'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: facturaState.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'FINALIZAR FACTURA',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                        ],
                      );
                    },
                    loading: () => Column(
                      children: [
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ],
                    ),
                    error: (err, stack) => Column(
                      children: [
                        Text(
                          'Error al cargar descuentos',
                          style: TextStyle(color: Colors.red[300]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}