import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:facturacion_app/src/features/productos/presentation/productos_provider.dart';
import 'package:facturacion_app/src/features/productos/domain/producto.dart';
import 'package:facturacion_app/src/features/home/presentation/widgets/app_drawer.dart';
import 'package:facturacion_app/src/features/categorias/presentation/categorias_provider.dart';
import 'producto_form_screen.dart';

class ProductosScreen extends ConsumerStatefulWidget {
  const ProductosScreen({super.key});

  @override
  ConsumerState<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends ConsumerState<ProductosScreen> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productosProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text(
          'Productos',
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
              ref.invalidate(productosProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'productos'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductoFormScreen(),
            ),
          );

          if (resultado == true && context.mounted) {
            ref.invalidate(productosProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto creado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
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
                        Icons.inventory_2,
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
                            'Gestión de Productos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Administra tu inventario',
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

          // Barra de búsqueda
          Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey[500]),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _busqueda = value;
                  });
                },
              ),
            ),
          ),

          // Lista de productos
          Expanded(
            child: productosAsync.when(
              data: (productos) {
                // Filtrar por búsqueda
                var productosFiltrados = productos;
                if (_busqueda.isNotEmpty) {
                  final busquedaLower = _busqueda.toLowerCase();
                  productosFiltrados = productos.where((p) {
                    return p.nombre.toLowerCase().contains(busquedaLower) ||
                        (p.descripcion?.toLowerCase().contains(busquedaLower) ?? false);
                  }).toList();
                }

                if (productosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _busqueda.isNotEmpty
                              ? Icons.search_off
                              : Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _busqueda.isNotEmpty
                              ? 'No se encontraron productos'
                              : 'No hay productos registrados',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _busqueda.isNotEmpty
                              ? 'Intenta con otro término de búsqueda'
                              : 'Agrega productos para comenzar',
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final producto = productosFiltrados[index];
                    return _buildProductoCard(context, producto);
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
                      'Error al cargar productos',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
                        ref.invalidate(productosProvider);
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

  Widget _buildProductoCard(BuildContext context, Producto producto) {
    // Indicador de stock bajo
    final stockBajo = producto.stock < 10;

    // Obtener las categorías para mostrar el nombre
    final categoriasAsync = ref.watch(categoriasProvider);

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => ProductoFormScreen(producto: producto),
            ),
          );

          if (resultado == true && context.mounted) {
            ref.invalidate(productosProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto actualizado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagen o icono del producto
              if (producto.imagenUrlDirecta != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: producto.imagenUrlDirecta!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Colors.greenAccent,
                        size: 32,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: Colors.greenAccent,
                    size: 32,
                  ),
                ),
              const SizedBox(width: 16),

              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            producto.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Etiqueta de categoría
                        if (producto.categoriaId != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: categoriasAsync.when(
                              data: (categorias) {
                                final categoria = categorias.firstWhere(
                                  (c) => c.id == producto.categoriaId,
                                  orElse: () => categorias.first,
                                );
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blueAccent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    categoria.nombre,
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                      ],
                    ),
                    if (producto.descripcion != null &&
                        producto.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        producto.descripcion!,
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
                        Icon(Icons.attach_money, color: Colors.grey[500], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '\$${producto.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.inventory,
                          color: stockBajo ? Colors.orange : Colors.grey[500],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stock: ${producto.stock}',
                          style: TextStyle(
                            color: stockBajo ? Colors.orange : Colors.grey[400],
                            fontSize: 14,
                            fontWeight: stockBajo ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón de eliminar
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmarEliminar(context, producto),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Eliminar Producto',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${producto.nombre}"?\n\nEsta acción no se puede deshacer.',
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

    if (confirmar == true && context.mounted) {
      try {
        await ref.read(productosRepositoryProvider).eliminarProducto(producto.id);
        ref.invalidate(productosProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
