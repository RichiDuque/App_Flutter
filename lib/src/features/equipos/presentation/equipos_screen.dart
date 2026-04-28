import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/auth/presentation/auth_controller.dart';
import 'package:facturacion_app/src/features/home/presentation/widgets/app_drawer.dart';
import 'package:facturacion_app/src/features/equipos/presentation/equipos_provider.dart';
import 'package:facturacion_app/src/features/equipos/domain/equipo.dart';
import 'widgets/crear_equipo_dialog.dart';
import 'widgets/editar_equipo_dialog.dart';
import 'equipo_detalle_screen.dart';

class EquiposScreen extends ConsumerWidget {
  const EquiposScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final equiposAsync = ref.watch(equiposProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text(
          'Gestión de Equipos',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(equiposProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'equipos'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const CrearEquipoDialog(),
          );
          ref.invalidate(equiposProvider);
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Equipo'),
      ),
      body: Column(
        children: [
          // Banner de información
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
                const Text(
                  'Administrador',
                  style: TextStyle(
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
                const SizedBox(height: 8),
                const Text(
                  'Gestiona equipos de vendedores y asigna miembros',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Lista de equipos
          Expanded(
            child: equiposAsync.when(
              data: (equipos) {
                if (equipos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay equipos creados',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crea un equipo para comenzar',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: equipos.length,
                  itemBuilder: (context, index) {
                    final equipo = equipos[index];
                    return _buildEquipoCard(context, ref, equipo);
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
                      'Error al cargar equipos',
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
                        ref.invalidate(equiposProvider);
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

  Widget _buildEquipoCard(BuildContext context, WidgetRef ref, Equipo equipo) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipoDetalleScreen(equipo: equipo),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono de equipo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: Colors.greenAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Información del equipo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                equipo.nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildEstadoBadge(equipo.activo),
                          ],
                        ),
                        if (equipo.descripcion != null &&
                            equipo.descripcion!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            equipo.descripcion!,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people,
                                color: Colors.grey[500], size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${equipo.cantidadMiembros ?? 0} miembro${(equipo.cantidadMiembros ?? 0) != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Botón de opciones
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: Colors.grey[800],
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.visibility,
                                color: Colors.grey[300], size: 20),
                            const SizedBox(width: 12),
                            const Text('Ver detalles',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EquipoDetalleScreen(equipo: equipo),
                              ),
                            );
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.edit,
                                color: Colors.grey[300], size: 20),
                            const SizedBox(width: 12),
                            const Text('Editar',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        onTap: () async {
                          await Future.delayed(Duration.zero);
                          await showDialog(
                            context: context,
                            builder: (context) =>
                                EditarEquipoDialog(equipo: equipo),
                          );
                          ref.invalidate(equiposProvider);
                        },
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            const Text('Eliminar',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () async {
                            await _confirmarEliminar(context, ref, equipo);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    Equipo equipo,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Confirmar eliminación',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de que deseas eliminar el equipo "${equipo.nombre}"?\n\nEsta acción no se puede deshacer.',
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
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      try {
        final repository = ref.read(equiposRepositoryProvider);
        await repository.eliminarEquipo(equipo.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Equipo "${equipo.nombre}" eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }

        ref.invalidate(equiposProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar equipo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}