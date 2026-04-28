import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/equipos/domain/equipo.dart';
import 'package:facturacion_app/src/features/equipos/domain/miembro_equipo.dart';
import 'package:facturacion_app/src/features/equipos/presentation/equipos_provider.dart';
import 'package:facturacion_app/src/features/usuarios/presentation/usuarios_provider.dart';

class EquipoDetalleScreen extends ConsumerWidget {
  final Equipo equipo;

  const EquipoDetalleScreen({super.key, required this.equipo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miembrosAsync = ref.watch(miembrosEquipoProvider(equipo.id));

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: Text(
          equipo.nombre,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(miembrosEquipoProvider(equipo.id));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoAgregarMiembro(context, ref),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Miembro'),
      ),
      body: Column(
        children: [
          // Banner de información del equipo
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
                        Icons.groups,
                        color: Colors.greenAccent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            equipo.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildEstadoBadge(equipo.activo),
                        ],
                      ),
                    ),
                  ],
                ),
                if (equipo.descripcion != null &&
                    equipo.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    equipo.descripcion!,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista de miembros
          Expanded(
            child: miembrosAsync.when(
              data: (miembros) {
                if (miembros.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay miembros en este equipo',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Agrega vendedores para comenzar',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: miembros.length,
                  itemBuilder: (context, index) {
                    final miembro = miembros[index];
                    return _buildMiembroCard(context, ref, miembro);
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
                      'Error al cargar miembros',
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
                        ref.invalidate(miembrosEquipoProvider(equipo.id));
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

  Widget _buildEstadoBadge(bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (activo ? Colors.green : Colors.grey).withValues(alpha: 0.2),
        border: Border.all(
          color: activo ? Colors.greenAccent : Colors.grey,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        activo ? 'ACTIVO' : 'INACTIVO',
        style: TextStyle(
          color: activo ? Colors.greenAccent : Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMiembroCard(
      BuildContext context, WidgetRef ref, MiembroEquipo miembro) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.2),
              radius: 28,
              child: Text(
                miembro.nombre.isNotEmpty
                    ? miembro.nombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Información del miembro
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    miembro.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.grey[500], size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          miembro.email,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (miembro.fechaAsignacion != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Colors.grey[500], size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Desde: ${_formatFecha(miembro.fechaAsignacion!)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Botón eliminar
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () =>
                  _confirmarQuitarMiembro(context, ref, miembro),
              tooltip: 'Quitar del equipo',
            ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Future<void> _mostrarDialogoAgregarMiembro(
      BuildContext context, WidgetRef ref) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Cargar vendedores y miembros actuales en paralelo
      final results = await Future.wait([
        ref.read(vendedoresProvider.future),
        ref.read(miembrosEquipoProvider(equipo.id).future),
      ]);

      final vendedores = results[0] as List<MiembroEquipo>;
      final miembrosActuales = results[1] as List<MiembroEquipo>;
      final miembrosIds = miembrosActuales.map((m) => m.id).toSet();

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Filtrar vendedores que ya están en el equipo
      final vendedoresDisponibles =
          vendedores.where((v) => !miembrosIds.contains(v.id)).toList();

      if (!context.mounted) return;

      if (vendedoresDisponibles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay vendedores disponibles para agregar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar diálogo de selección
      showDialog(
        context: context,
        builder: (context) => _AgregarMiembroDialog(
          equipo: equipo,
          vendedoresDisponibles: vendedoresDisponibles,
          onMiembroAgregado: () {
            ref.invalidate(miembrosEquipoProvider(equipo.id));
            ref.invalidate(equiposProvider);
          },
        ),
      );
    } catch (e) {
      // Cerrar indicador de carga si hay error
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar vendedores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmarQuitarMiembro(
      BuildContext context, WidgetRef ref, MiembroEquipo miembro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Confirmar',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Deseas quitar a ${miembro.nombre} de este equipo?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('QUITAR'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      try {
        final repository = ref.read(equiposRepositoryProvider);
        await repository.quitarMiembroEquipo(
          equipoId: equipo.id,
          usuarioId: miembro.id,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${miembro.nombre} fue quitado del equipo'),
              backgroundColor: Colors.green,
            ),
          );
        }

        ref.invalidate(miembrosEquipoProvider(equipo.id));
        ref.invalidate(equiposProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _AgregarMiembroDialog extends ConsumerStatefulWidget {
  final Equipo equipo;
  final List<MiembroEquipo> vendedoresDisponibles;
  final VoidCallback onMiembroAgregado;

  const _AgregarMiembroDialog({
    required this.equipo,
    required this.vendedoresDisponibles,
    required this.onMiembroAgregado,
  });

  @override
  ConsumerState<_AgregarMiembroDialog> createState() =>
      _AgregarMiembroDialogState();
}

class _AgregarMiembroDialogState extends ConsumerState<_AgregarMiembroDialog> {
  MiembroEquipo? _vendedorSeleccionado;
  bool _isLoading = false;

  Future<void> _agregarMiembro() async {
    if (_vendedorSeleccionado == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(equiposRepositoryProvider);
      await repository.agregarMiembroEquipo(
        equipoId: widget.equipo.id,
        usuarioId: _vendedorSeleccionado!.id,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${_vendedorSeleccionado!.nombre} agregado al equipo'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onMiembroAgregado();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar miembro: $e'),
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
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      title: const Text(
        'Agregar Miembro al Equipo',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona un vendedor para agregar a "${widget.equipo.nombre}":',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MiembroEquipo>(
            value: _vendedorSeleccionado,
            dropdownColor: Colors.grey[800],
            decoration: InputDecoration(
              labelText: 'Vendedor',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.person, color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green),
              ),
            ),
            items: widget.vendedoresDisponibles.map((vendedor) {
              return DropdownMenuItem<MiembroEquipo>(
                value: vendedor,
                child: Text(
                  '${vendedor.nombre} - ${vendedor.email}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() => _vendedorSeleccionado = value);
                  },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        FilledButton.icon(
          onPressed: _isLoading || _vendedorSeleccionado == null
              ? null
              : _agregarMiembro,
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add),
          label: Text(_isLoading ? 'AGREGANDO...' : 'AGREGAR'),
        ),
      ],
    );
  }
}