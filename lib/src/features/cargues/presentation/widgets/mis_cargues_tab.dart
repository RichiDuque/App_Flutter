import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../usuarios/presentation/usuarios_provider.dart';
import '../cargues_provider.dart';
import '../cargues_filters.dart';
import '../screens/cargue_detalle_screen.dart';

class MisCarguesTab extends ConsumerStatefulWidget {
  final bool isAdminView;

  const MisCarguesTab({super.key, required this.isAdminView});

  @override
  ConsumerState<MisCarguesTab> createState() => _MisCarguesTabState();
}

class _MisCarguesTabState extends ConsumerState<MisCarguesTab> {
  List<int> _vendedoresSeleccionados = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  CarguesFilters? _buildFiltros() {
    // Para vendedores solo permitir filtro por fecha
    if (!widget.isAdminView) {
      if (_fechaInicio == null && _fechaFin == null) {
        return null;
      }
      return CarguesFilters(
        usuariosIds: null,
        fechaInicio: _fechaInicio != null
            ? DateFormat('yyyy-MM-dd').format(_fechaInicio!)
            : null,
        fechaFin: _fechaFin != null
            ? DateFormat('yyyy-MM-dd').format(_fechaFin!)
            : null,
      );
    }

    // Para admins permitir todos los filtros
    if (_vendedoresSeleccionados.isEmpty && _fechaInicio == null && _fechaFin == null) {
      return null;
    }

    return CarguesFilters(
      usuariosIds: _vendedoresSeleccionados.isNotEmpty
          ? _vendedoresSeleccionados.join(',')
          : null,
      fechaInicio: _fechaInicio != null
          ? DateFormat('yyyy-MM-dd').format(_fechaInicio!)
          : null,
      fechaFin: _fechaFin != null
          ? DateFormat('yyyy-MM-dd').format(_fechaFin!)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtros = _buildFiltros();
    final carguesAsync = ref.watch(carguesProvider(filtros));

    return Column(
      children: [
        _buildFiltrosWidget(),
        Expanded(
          child: carguesAsync.when(
            data: (cargues) {
              if (cargues.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 80, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        widget.isAdminView ? 'No hay cargues' : 'No hay cargues',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!widget.isAdminView)
                        Text(
                          'Crea tu primer cargue',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                );
              }

              final totalGeneral = cargues.fold<double>(
                0.0,
                (sum, cargue) => sum + cargue.total,
              );

              return Column(
                children: [
                  // Total general
                  Container(
                    color: Colors.grey[850],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total General',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cargues.length} cargue(s)',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\$${totalGeneral.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(carguesProvider(_buildFiltros()));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cargues.length,
                        itemBuilder: (context, index) {
                          final cargue = cargues[index];
                          return _buildCargueCard(context, cargue);
                        },
                      ),
                    ),
                  ),
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
                  const Text(
                    'Error al cargar cargues',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(carguesProvider(_buildFiltros())),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltrosWidget() {
    return Container(
      color: Colors.grey[850],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Filtro por vendedores (solo para admin)
          if (widget.isAdminView) ...[
            ref.watch(vendedoresCompletoProvider).when(
              data: (vendedores) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _mostrarDialogoVendedores(vendedores),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          border: Border.all(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _vendedoresSeleccionados.isEmpty
                                    ? 'Seleccionar vendedores'
                                    : '${_vendedoresSeleccionados.length} vendedor(es) seleccionado(s)',
                                style: TextStyle(
                                  color: _vendedoresSeleccionados.isEmpty
                                      ? Colors.grey[500]
                                      : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_vendedoresSeleccionados.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _vendedoresSeleccionados.map((vendedorId) {
                          final vendedor = vendedores.firstWhere(
                            (v) => v.id == vendedorId,
                            orElse: () => vendedores.first,
                          );
                          return Chip(
                            label: Text(
                              vendedor.nombre,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            backgroundColor: Colors.green.withOpacity(0.3),
                            deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                            onDeleted: () {
                              setState(() {
                                _vendedoresSeleccionados.remove(vendedorId);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 12),
          ],
          // Filtros de fecha
          Row(
            children: [
              Expanded(
                child: _buildFechaField(
                  'Desde',
                  _fechaInicio,
                  (fecha) => setState(() => _fechaInicio = fecha),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFechaField(
                  'Hasta',
                  _fechaFin,
                  (fecha) => setState(() => _fechaFin = fecha),
                ),
              ),
            ],
          ),
          if (_fechaInicio != null || _fechaFin != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _fechaInicio = null;
                    _fechaFin = null;
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpiar fechas'),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFechaField(
    String label,
    DateTime? fecha,
    Function(DateTime?) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: fecha ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                  primary: Colors.green,
                  surface: Colors.grey[850]!,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          filled: true,
          fillColor: Colors.grey[800],
          suffixIcon: fecha != null
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today, color: Colors.white, size: 18),
        ),
        child: Text(
          fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : 'Seleccionar',
          style: TextStyle(
            color: fecha != null ? Colors.white : Colors.grey[500],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCargueCard(BuildContext context, dynamic cargue) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final estadoColor = _getEstadoColor(cargue.estado);

    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CargueDetalleScreen(cargueId: cargue.id),
            ),
          ).then((_) => ref.invalidate(carguesProvider(_buildFiltros())));
        },
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
                      cargue.numeroCargue ?? 'Sin número',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(cargue.fecha),
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    cargue.usuario?.nombre ?? 'Desconocido',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.shopping_bag, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${cargue.detalles.length} producto(s)',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.grey),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '\$${cargue.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoVendedores(List<dynamic> vendedores) async {
    final seleccionados = List<int>.from(_vendedoresSeleccionados);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[850],
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seleccionar Vendedores',
                  style: TextStyle(color: Colors.white),
                ),
                if (seleccionados.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        seleccionados.clear();
                      });
                    },
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: vendedores.length,
                itemBuilder: (context, index) {
                  final vendedor = vendedores[index];
                  final isSelected = seleccionados.contains(vendedor.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          seleccionados.add(vendedor.id);
                        } else {
                          seleccionados.remove(vendedor.id);
                        }
                      });
                    },
                    title: Text(
                      vendedor.nombre,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      vendedor.email,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    activeColor: Colors.green,
                    checkColor: Colors.white,
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _vendedoresSeleccionados = seleccionados;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
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