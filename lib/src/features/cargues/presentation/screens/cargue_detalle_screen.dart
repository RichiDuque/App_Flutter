import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../domain/cargue.dart';
import '../../domain/detalle_cargue.dart';
import '../cargues_provider.dart';
import '../cargue_detalle_state.dart';

class CargueDetalleScreen extends ConsumerStatefulWidget {
  final int cargueId;

  const CargueDetalleScreen({super.key, required this.cargueId});

  @override
  ConsumerState<CargueDetalleScreen> createState() =>
      _CargueDetalleScreenState();
}

class _CargueDetalleScreenState extends ConsumerState<CargueDetalleScreen> {
  bool _procesando = false;

  @override
  Widget build(BuildContext context) {
    final cargueAsync = ref.watch(cargueByIdProvider(widget.cargueId));
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.role == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Detalle del Cargue',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'eliminar') {
                  _confirmarEliminar(cargueAsync.value);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar cargue'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: cargueAsync.when(
        data: (cargue) {
          // Inicializar estados de despacho en providers si están vacíos
          final despachos = ref.watch(detallesDespachosProvider(widget.cargueId));
          final faltantes = ref.watch(detallesFaltantesProvider(widget.cargueId));
          final cantidades = ref.watch(detallesCantidadesProvider(widget.cargueId));

          if (despachos.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final Map<int, bool> initialDespachos = {};
              final Map<int, bool> initialFaltantes = {};
              final Map<int, int> initialCantidades = {};

              for (var detalle in cargue.detalles) {
                initialDespachos[detalle.id] = detalle.despachado;
                initialFaltantes[detalle.id] = detalle.faltante;
                initialCantidades[detalle.id] = detalle.cantidad;
              }

              ref.read(detallesDespachosProvider(widget.cargueId).notifier).state = initialDespachos;
              ref.read(detallesFaltantesProvider(widget.cargueId).notifier).state = initialFaltantes;
              ref.read(detallesCantidadesProvider(widget.cargueId).notifier).state = initialCantidades;
            });
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(cargue, isAdmin),
                      _buildDetallesCard(cargue, isAdmin),
                    ],
                  ),
                ),
              ),
              if (isAdmin && !cargue.isRealizado)
                _buildAdminActions(cargue),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: ${error.toString()}',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(cargueByIdProvider(widget.cargueId)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(Cargue cargue, bool isAdmin) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final estadoColor = _getEstadoColor(cargue.estado);

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cargue.numeroCargue ?? 'Sin número',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(cargue.fecha),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cargue.estadoTexto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.person,
              'Vendedor',
              cargue.usuario?.nombre ?? 'Desconocido',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.shopping_bag,
              'Productos',
              '${cargue.detalles.length} producto(s)',
            ),
            if (cargue.comentario != null && cargue.comentario!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.comment,
                'Comentario',
                cargue.comentario!,
              ),
            ],
            const SizedBox(height: 16),
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),
            _buildTotalSection(cargue, isAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(Cargue cargue, bool isAdmin) {
    // Calcular total considerando cantidades modificadas y productos faltantes
    final faltantes = ref.watch(detallesFaltantesProvider(widget.cargueId));
    final cantidades = ref.watch(detallesCantidadesProvider(widget.cargueId));
    double totalSinFaltantes = 0;
    double totalFaltantes = 0;
    bool hayFaltantes = false;

    for (var detalle in cargue.detalles) {
      final isFaltante = faltantes[detalle.id] ?? detalle.faltante;
      final cantidadActual = cantidades[detalle.id] ?? detalle.cantidad;
      final subtotalActual = cantidadActual * detalle.precioUnitario;

      if (isFaltante) {
        totalFaltantes += subtotalActual;
        hayFaltantes = true;
      } else {
        totalSinFaltantes += subtotalActual;
      }
    }

    return Column(
      children: [
        // Mostrar advertencia si hay faltantes y el cargue no está realizado
        if (isAdmin && hayFaltantes && !cargue.isRealizado)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Productos faltantes detectados',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total de faltantes: \$${totalFaltantes.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Total actual o total recalculado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hayFaltantes && !cargue.isRealizado ? 'Total (sin faltantes):' : 'Total:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hayFaltantes && !cargue.isRealizado)
                  Text(
                    'Total original: \$${cargue.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
            Text(
              '\$${(hayFaltantes && !cargue.isRealizado ? totalSinFaltantes : cargue.total).toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetallesCard(Cargue cargue, bool isAdmin) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...cargue.detalles.map((detalle) {
              return _buildDetalleItem(detalle, isAdmin, cargue.isRealizado);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleItem(DetalleCargue detalle, bool isAdmin, bool cargueRealizado) {
    final despachos = ref.watch(detallesDespachosProvider(widget.cargueId));
    final faltantes = ref.watch(detallesFaltantesProvider(widget.cargueId));
    final cantidades = ref.watch(detallesCantidadesProvider(widget.cargueId));
    final isDespachado = despachos[detalle.id] ?? detalle.despachado;
    final isFaltante = faltantes[detalle.id] ?? detalle.faltante;
    final cantidadActual = cantidades[detalle.id] ?? detalle.cantidad;
    final cantidadModificada = (detalle.cantidadOriginal ?? detalle.cantidad) != cantidadActual;
    final subtotalActual = cantidadActual * detalle.precioUnitario;
    final subtotalOriginal = (detalle.cantidadOriginal ?? detalle.cantidad) * detalle.precioUnitario;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFaltante
            ? Colors.red.withOpacity(0.2)
            : isDespachado
                ? Colors.green.withOpacity(0.2)
                : Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFaltante
              ? Colors.red
              : isDespachado
                  ? Colors.green
                  : Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isAdmin && !cargueRealizado) ...[
                Checkbox(
                  value: isDespachado,
                  onChanged: (value) {
                    final newDespachos = Map<int, bool>.from(despachos);
                    final newFaltantes = Map<int, bool>.from(faltantes);
                    newDespachos[detalle.id] = value ?? false;
                    if (value == true) {
                      newFaltantes[detalle.id] = false;
                    }
                    ref.read(detallesDespachosProvider(widget.cargueId).notifier).state = newDespachos;
                    ref.read(detallesFaltantesProvider(widget.cargueId).notifier).state = newFaltantes;
                  },
                  activeColor: Colors.green,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detalle.producto?.nombre ?? 'Producto desconocido',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isAdmin && !cargueRealizado)
                      Row(
                        children: [
                          Text(
                            'Cantidad: ',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                          InkWell(
                            onTap: () => _mostrarDialogCantidad(detalle, cantidadActual),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cantidadModificada ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: cantidadModificada ? Colors.blue : Colors.grey[600]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$cantidadActual',
                                    style: TextStyle(
                                      color: cantidadModificada ? Colors.blue : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: cantidadModificada ? Colors.blue : Colors.grey[500],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (cantidadModificada) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(Original: ${detalle.cantidadOriginal ?? detalle.cantidad})',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      Row(
                        children: [
                          Text(
                            'Cantidad: ${detalle.cantidad}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                          if (cantidadModificada) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(Original: ${detalle.cantidadOriginal ?? detalle.cantidad})',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    Text(
                      'Precio unitario: \$${detalle.precioUnitario.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    if (detalle.comentario != null &&
                        detalle.comentario!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Comentario: ${detalle.comentario}',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${subtotalActual.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isFaltante ? Colors.red[300] : (cantidadModificada ? Colors.blue : Colors.green),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isFaltante ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (cantidadModificada && !isFaltante)
                    Text(
                      'Orig: \$${subtotalOriginal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (isFaltante)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'FALTANTE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isDespachado && !isFaltante)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'DESPACHADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (isAdmin && !cargueRealizado)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final newFaltantes = Map<int, bool>.from(faltantes);
                        final newDespachos = Map<int, bool>.from(despachos);
                        newFaltantes[detalle.id] = !isFaltante;
                        if (!isFaltante) {
                          newDespachos[detalle.id] = false;
                        }
                        ref.read(detallesFaltantesProvider(widget.cargueId).notifier).state = newFaltantes;
                        ref.read(detallesDespachosProvider(widget.cargueId).notifier).state = newDespachos;
                      },
                      icon: Icon(
                        isFaltante ? Icons.check_circle : Icons.cancel,
                        size: 18,
                      ),
                      label: Text(
                        isFaltante ? 'Disponible' : 'Marcar Faltante',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isFaltante ? Colors.green : Colors.red,
                        side: BorderSide(
                          color: isFaltante ? Colors.green : Colors.red,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildAdminActions(Cargue cargue) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[850],
      child: Column(
        children: [
          if (_procesando)
            const LinearProgressIndicator(color: Colors.green)
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmarFinalizarCargue(cargue),
                icon: const Icon(Icons.check_circle),
                label: const Text('Finalizar Cargue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmarFinalizarCargue(Cargue cargue) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Finalizar Cargue',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de finalizar este cargue? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _finalizarCargue(cargue);
    }
  }

  Future<void> _finalizarCargue(Cargue cargue) async {
    setState(() {
      _procesando = true;
    });

    try {
      final repository = ref.read(carguesRepositoryProvider);
      await repository.finalizarCargue(cargue.id);

      if (mounted) {
        ref.invalidate(cargueByIdProvider(widget.cargueId));
        ref.invalidate(carguesProvider(null));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cargue finalizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _confirmarEliminar(Cargue? cargue) async {
    if (cargue == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Eliminar Cargue',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de eliminar el cargue "${cargue.numeroCargue}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _eliminarCargue(cargue);
    }
  }

  Future<void> _eliminarCargue(Cargue cargue) async {
    try {
      final repository = ref.read(carguesRepositoryProvider);
      await repository.eliminarCargue(cargue.id);

      if (mounted) {
        ref.invalidate(carguesProvider(null));
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cargue eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _mostrarDialogCantidad(DetalleCargue detalle, int cantidadActual) async {
    final controller = TextEditingController(text: cantidadActual.toString());

    final nuevaCantidad = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Modificar Cantidad',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detalle.producto?.nombre ?? 'Producto',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cantidad solicitada originalmente: ${detalle.cantidadOriginal ?? detalle.cantidad}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nueva cantidad',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final valor = int.tryParse(controller.text);
              if (valor != null && valor > 0) {
                Navigator.pop(context, valor);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevaCantidad != null && nuevaCantidad != cantidadActual) {
      // Actualizar estado local inmediatamente para feedback instantáneo
      final cantidades = ref.read(detallesCantidadesProvider(widget.cargueId));
      final newCantidades = Map<int, int>.from(cantidades);
      newCantidades[detalle.id] = nuevaCantidad;
      ref.read(detallesCantidadesProvider(widget.cargueId).notifier).state = newCantidades;

      // Llamar a la API para guardar en la base de datos
      try {
        final repository = ref.read(carguesRepositoryProvider);
        final cargueActualizado = await repository.actualizarCantidadDetalle(
          widget.cargueId,
          detalle.id,
          nuevaCantidad,
        );

        // Sincronizar todos los providers con los datos actualizados del servidor
        final Map<int, bool> syncDespachos = {};
        final Map<int, bool> syncFaltantes = {};
        final Map<int, int> syncCantidades = {};

        for (var det in cargueActualizado.detalles) {
          syncDespachos[det.id] = det.despachado;
          syncFaltantes[det.id] = det.faltante;
          syncCantidades[det.id] = det.cantidad;
        }

        ref.read(detallesDespachosProvider(widget.cargueId).notifier).state = syncDespachos;
        ref.read(detallesFaltantesProvider(widget.cargueId).notifier).state = syncFaltantes;
        ref.read(detallesCantidadesProvider(widget.cargueId).notifier).state = syncCantidades;

        // Invalidar el provider para refrescar con datos actualizados del servidor
        ref.invalidate(cargueByIdProvider(widget.cargueId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cantidad actualizada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Revertir el cambio local si falla la API
        ref.read(detallesCantidadesProvider(widget.cargueId).notifier).state = cantidades;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar cantidad: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_progreso':
        return Colors.blue;
      case 'realizado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}