import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/usuarios/presentation/usuarios_provider.dart';
import 'package:facturacion_app/src/features/usuarios/domain/vendedor.dart';
import 'package:facturacion_app/src/features/listas_precios/presentation/listas_precios_provider.dart';
import 'package:facturacion_app/src/features/listas_precios/domain/lista_precio.dart';
import 'package:facturacion_app/src/features/home/presentation/widgets/app_drawer.dart';

class VendedoresScreen extends ConsumerWidget {
  const VendedoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendedoresAsync = ref.watch(vendedoresCompletoProvider);
    final listasPreciosAsync = ref.watch(listasPreciosProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text(
          'Gestión de Vendedores',
          style: TextStyle(color: Colors.white),
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
              ref.invalidate(vendedoresCompletoProvider);
              ref.invalidate(listasPreciosProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'vendedores'),
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
                        Icons.badge,
                        color: Colors.greenAccent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Listas de Precios',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Asigna listas de precios a vendedores',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de vendedores
          Expanded(
            child: vendedoresAsync.when(
              data: (vendedores) {
                if (vendedores.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay vendedores registrados',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return listasPreciosAsync.when(
                  data: (listasPrecios) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vendedores.length,
                      itemBuilder: (context, index) {
                        final vendedor = vendedores[index];
                        return _buildVendedorCard(
                          context,
                          ref,
                          vendedor,
                          listasPrecios,
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
                          'Error al cargar listas de precios',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style:
                              const TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
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
                      'Error al cargar vendedores',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
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

  Widget _buildVendedorCard(
    BuildContext context,
    WidgetRef ref,
    Vendedor vendedor,
    List<ListaPrecio> listasPrecios,
  ) {
    // Encontrar la lista de precios asignada
    final listaAsignada = vendedor.listaPreciosId != null
        ? listasPrecios.firstWhere(
            (l) => l.id == vendedor.listaPreciosId,
            orElse: () => ListaPrecio(id: 0, uuid: '', nombre: 'Sin asignar'),
          )
        : null;

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre y email del vendedor
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.greenAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendedor.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vendedor.email,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey),
            const SizedBox(height: 12),

            // Selector de lista de precios
            Row(
              children: [
                Icon(Icons.price_change, color: Colors.grey[400], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Lista de Precios:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: vendedor.listaPreciosId,
                        dropdownColor: Colors.grey[850],
                        isExpanded: true,
                        hint: const Text(
                          'Seleccionar lista',
                          style: TextStyle(color: Colors.white54),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Sin asignar',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          ...listasPrecios.map((lista) {
                            return DropdownMenuItem<int?>(
                              value: lista.id,
                              child: Text(
                                lista.nombre,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }),
                        ],
                        onChanged: (newListaId) async {
                          // Mostrar diálogo de confirmación
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.grey[850],
                              title: const Text(
                                'Confirmar cambio',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                'Se cambiará la lista de precios de ${vendedor.nombre} a "${newListaId != null ? listasPrecios.firstWhere((l) => l.id == newListaId).nombre : "Sin asignar"}".\n\n¿Deseas continuar?',
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
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Confirmar'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            try {
                              // Actualizar en el servidor
                              await ref
                                  .read(usuariosRepositoryProvider)
                                  .actualizarListaPreciosVendedor(
                                    vendedorId: vendedor.id,
                                    listaPreciosId: newListaId,
                                  );

                              // Refrescar la lista
                              ref.invalidate(vendedoresCompletoProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lista de precios actualizada'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
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
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Mostrar lista asignada actual
            if (listaAsignada != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Lista actual: ${listaAsignada.nombre}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
