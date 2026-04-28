import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../descuentos/domain/descuento.dart';
import '../../../../descuentos/presentation/descuentos_provider.dart';

class DescuentosTab extends ConsumerWidget {
  const DescuentosTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descuentosAsync = ref.watch(descuentosProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: descuentosAsync.when(
        data: (descuentos) {
          if (descuentos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.discount_outlined,
                      size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay descuentos',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega un nuevo descuento',
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
            itemCount: descuentos.length,
            itemBuilder: (context, index) {
              final descuento = descuentos[index];
              return _buildDescuentoItem(context, ref, descuento);
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
                'Error al cargar descuentos',
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
                onPressed: () => ref.invalidate(descuentosProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _mostrarDialogoDescuento(context, ref),
      ),
    );
  }

  Widget _buildDescuentoItem(
      BuildContext context, WidgetRef ref, Descuento descuento) {
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
            color: Colors.orange[700],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.discount, color: Colors.white, size: 30),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                descuento.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${descuento.porcentaje.toStringAsFixed(0)}% OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () =>
                  _mostrarDialogoDescuento(context, ref, descuento: descuento),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarEliminar(context, ref, descuento),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoDescuento(BuildContext context, WidgetRef ref,
      {Descuento? descuento}) {
    final nombreController =
        TextEditingController(text: descuento?.nombre ?? '');
    final porcentajeController = TextEditingController(
        text: descuento != null ? descuento.porcentaje.toString() : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          descuento == null ? 'Nuevo Descuento' : 'Editar Descuento',
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
                hintText: 'Ej: Descuento 10%',
                hintStyle: TextStyle(color: Colors.grey[600]),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: porcentajeController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Porcentaje (%)',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'Ej: 10',
                hintStyle: TextStyle(color: Colors.grey[600]),
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

              final porcentaje = double.tryParse(porcentajeController.text);
              if (porcentaje == null || porcentaje <= 0 || porcentaje > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa un porcentaje válido entre 0 y 100'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final repository = ref.read(descuentosRepositoryProvider);
                final data = {
                  'nombre': nombreController.text.trim(),
                  'porcentaje': porcentaje,
                };

                if (descuento == null) {
                  await repository.crearDescuento(data);
                } else {
                  await repository.actualizarDescuento(descuento.id, data);
                }

                ref.invalidate(descuentosProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(descuento == null
                          ? 'Descuento creado'
                          : 'Descuento actualizado'),
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
      BuildContext context, WidgetRef ref, Descuento descuento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Eliminar Descuento',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de eliminar el descuento "${descuento.nombre}"?',
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
                final repository = ref.read(descuentosRepositoryProvider);
                await repository.eliminarDescuento(descuento.id);
                ref.invalidate(descuentosProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Descuento eliminado'),
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