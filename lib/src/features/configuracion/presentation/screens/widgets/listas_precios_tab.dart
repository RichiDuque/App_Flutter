import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../listas_precios/domain/lista_precio.dart';
import '../../../../listas_precios/presentation/listas_precios_provider.dart';

class ListasPreciosTab extends ConsumerWidget {
  const ListasPreciosTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listasPreciosAsync = ref.watch(listasPreciosProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: listasPreciosAsync.when(
        data: (listas) {
          if (listas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.price_change_outlined,
                      size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay listas de precios',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega una nueva lista de precios',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: listas.length,
            itemBuilder: (context, index) {
              final lista = listas[index];
              return _buildListaPrecioItem(context, ref, lista);
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
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar listas de precios',
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
                onPressed: () => ref.invalidate(listasPreciosProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _mostrarDialogoListaPrecio(context, ref),
      ),
    );
  }

  Widget _buildListaPrecioItem(
      BuildContext context, WidgetRef ref, ListaPrecio lista) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.price_change, color: Colors.white, size: 30),
        ),
        title: Text(
          lista.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () =>
                  _mostrarDialogoListaPrecio(context, ref, lista: lista),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarEliminar(context, ref, lista),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoListaPrecio(BuildContext context, WidgetRef ref,
      {ListaPrecio? lista}) {
    final nombreController =
        TextEditingController(text: lista?.nombre ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          lista == null ? 'Nueva Lista de Precios' : 'Editar Lista de Precios',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (nombreController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El nombre es requerido'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final repository = ref.read(listasPreciosRepositoryProvider);
                final data = {
                  'nombre': nombreController.text.trim(),
                };

                if (lista == null) {
                  await repository.crearListaPrecios(data);
                } else {
                  await repository.actualizarListaPrecios(lista.id, data);
                }

                ref.invalidate(listasPreciosProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lista == null
                          ? 'Lista de precios creada'
                          : 'Lista de precios actualizada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(
      BuildContext context, WidgetRef ref, ListaPrecio lista) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Eliminar Lista de Precios',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de eliminar la lista "${lista.nombre}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final repository = ref.read(listasPreciosRepositoryProvider);
                await repository.eliminarListaPrecios(lista.id);
                ref.invalidate(listasPreciosProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lista de precios eliminada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}