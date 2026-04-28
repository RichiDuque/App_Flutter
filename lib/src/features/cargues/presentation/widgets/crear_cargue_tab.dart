import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../productos/domain/producto.dart';
import '../../../productos/presentation/productos_provider.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../cargues_provider.dart';
import '../crear_cargue_state.dart';

class CrearCargueTab extends ConsumerStatefulWidget {
  const CrearCargueTab({super.key});

  @override
  ConsumerState<CrearCargueTab> createState() => _CrearCargueTabState();
}

class _CrearCargueTabState extends ConsumerState<CrearCargueTab> {
  final TextEditingController _searchController = TextEditingController();
  late final TextEditingController _comentarioController;
  bool _guardandoCargue = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _comentarioController = TextEditingController(
      text: ref.read(comentarioCargueProvider),
    );
    _comentarioController.addListener(() {
      ref.read(comentarioCargueProvider.notifier).state = _comentarioController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productosProvider);
    final productosSeleccionados = ref.watch(productosSeleccionadosProvider);

    return Column(
      children: [
        // Barra de búsqueda
        Container(
          color: Colors.grey[850],
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // Resumen de productos seleccionados
        if (productosSeleccionados.isNotEmpty)
          Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${productosSeleccionados.length} producto(s) agregado(s)',
                  style: const TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: () => _mostrarResumenProductos(),
                  child: const Text('Ver resumen'),
                ),
              ],
            ),
          ),

        // Lista de productos
        Expanded(
          child: productosAsync.when(
            data: (productos) {
              final productosFiltrados = _searchQuery.isEmpty
                  ? productos
                  : productos
                      .where((p) =>
                          p.nombre.toLowerCase().contains(_searchQuery) ||
                          (p.descripcion?.toLowerCase().contains(_searchQuery) ??
                              false))
                      .toList();

              if (productosFiltrados.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron productos',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: productosFiltrados.length,
                itemBuilder: (context, index) {
                  final producto = productosFiltrados[index];
                  return _buildProductoItem(producto, productosSeleccionados);
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
                  Text(
                    'Error: ${error.toString()}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Botones de acción
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[850],
          child: Column(
            children: [
              // Campo de comentario
              TextField(
                controller: _comentarioController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Comentario (opcional)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: productosSeleccionados.isEmpty || _guardandoCargue
                      ? null
                      : () => _guardarCargue('pendiente'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Finalizar Cargue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_guardandoCargue)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(color: Colors.green),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductoItem(Producto producto, List<Map<String, dynamic>> productosSeleccionados) {
    final yaAgregado = productosSeleccionados
        .any((p) => p['producto'].id == producto.id);

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
            color: yaAgregado ? Colors.green[700] : Colors.blue[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            yaAgregado ? Icons.check_circle : Icons.inventory_2,
            color: Colors.white,
          ),
        ),
        title: Text(
          producto.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (producto.descripcion != null && producto.descripcion!.isNotEmpty)
              Text(
                producto.descripcion!,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              'Stock: ${producto.stock}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            yaAgregado ? Icons.edit : Icons.add_circle,
            color: yaAgregado ? Colors.orange : Colors.green,
          ),
          onPressed: () => _agregarOEditarProducto(producto),
        ),
      ),
    );
  }

  void _agregarOEditarProducto(Producto producto) {
    final productosSeleccionados = ref.read(productosSeleccionadosProvider);
    final index = productosSeleccionados
        .indexWhere((p) => p['producto'].id == producto.id);

    if (index != -1) {
      _mostrarDialogoCantidad(producto, cantidadActual: productosSeleccionados[index]['cantidad']);
    } else {
      _mostrarDialogoCantidad(producto);
    }
  }

  void _mostrarDialogoCantidad(Producto producto, {int? cantidadActual}) {
    final cantidadController = TextEditingController(
      text: cantidadActual?.toString() ?? '1',
    );
    final comentarioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          cantidadActual != null ? 'Editar Cantidad' : 'Agregar Producto',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              producto.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Cantidad',
                labelStyle: TextStyle(color: Colors.grey[400]),
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
              controller: comentarioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
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
            onPressed: () {
              final cantidad = int.tryParse(cantidadController.text);
              if (cantidad == null || cantidad <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cantidad inválida'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final productosSeleccionados = List<Map<String, dynamic>>.from(
                ref.read(productosSeleccionadosProvider),
              );
              final index = productosSeleccionados
                  .indexWhere((p) => p['producto'].id == producto.id);

              if (index != -1) {
                productosSeleccionados[index] = {
                  'producto': producto,
                  'cantidad': cantidad,
                  'comentario': comentarioController.text.trim(),
                };
              } else {
                productosSeleccionados.add({
                  'producto': producto,
                  'cantidad': cantidad,
                  'comentario': comentarioController.text.trim(),
                });
              }

              ref.read(productosSeleccionadosProvider.notifier).state = productosSeleccionados;
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarResumenProductos() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850],
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final productosSeleccionados = ref.watch(productosSeleccionadosProvider);

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[700]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Productos Agregados',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: productosSeleccionados.length,
                      itemBuilder: (context, index) {
                        final item = productosSeleccionados[index];
                        final producto = item['producto'] as Producto;
                        final cantidad = item['cantidad'] as int;
                        final comentario = item['comentario'] as String?;

                        return Dismissible(
                          key: Key('${producto.id}'),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.grey[850],
                                title: const Text(
                                  '¿Eliminar producto?',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: Text(
                                  '¿Deseas eliminar "${producto.nombre}" del cargue?',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) {
                            final productos = List<Map<String, dynamic>>.from(productosSeleccionados);
                            productos.removeAt(index);
                            ref.read(productosSeleccionadosProvider.notifier).state = productos;
                          },
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.inventory_2,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              producto.nombre,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cantidad: $cantidad',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                if (comentario != null && comentario.isNotEmpty)
                                  Text(
                                    'Comentario: $comentario',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () {
                                Navigator.pop(context);
                                _agregarOEditarProducto(producto);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _guardarCargue(String estado) async {
    final productosSeleccionados = ref.read(productosSeleccionadosProvider);

    if (productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _guardandoCargue = true;
    });

    try {
      final repository = ref.read(carguesRepositoryProvider);

      final detalles = productosSeleccionados.map((item) {
        return {
          'producto_id': (item['producto'] as Producto).id,
          'cantidad': item['cantidad'],
          'comentario': item['comentario'],
        };
      }).toList();

      final authState = ref.read(authControllerProvider);

      final data = {
        'usuario_id': authState.userId,
        'detalles': detalles,
        'comentario': _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
        'estado': estado,
      };

      await repository.crearCargue(data);

      if (mounted) {
        // Limpiar los providers
        ref.read(productosSeleccionadosProvider.notifier).state = [];
        ref.read(comentarioCargueProvider.notifier).state = '';

        setState(() {
          _comentarioController.clear();
          _searchController.clear();
          _searchQuery = '';
          _guardandoCargue = false;
        });

        ref.invalidate(carguesProvider(null));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              estado == 'pendiente'
                  ? 'Cargue guardado como pendiente'
                  : 'Cargue creado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardandoCargue = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}