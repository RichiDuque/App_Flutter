import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:facturacion_app/src/features/productos/presentation/productos_provider.dart';
import 'package:facturacion_app/src/features/facturacion/presentation/facturacion_controller.dart';
import 'package:facturacion_app/src/features/facturacion/presentation/factura_detail_screen.dart';
import 'package:facturacion_app/src/features/facturacion/presentation/facturas_guardadas_screen.dart';
import 'package:facturacion_app/src/features/categorias/presentation/categorias_provider.dart';
import 'package:facturacion_app/src/features/clientes/presentation/screens/clientes_screen.dart';
import 'package:facturacion_app/src/features/clientes/presentation/screens/cliente_detail_screen.dart';
import 'package:facturacion_app/src/features/clientes/presentation/clientes_provider.dart';
import 'package:facturacion_app/src/features/facturas/presentation/facturas_provider.dart';
import 'package:facturacion_app/src/features/listas_precios/presentation/listas_precios_provider.dart';
import 'package:facturacion_app/src/features/usuarios/presentation/usuarios_provider.dart' as usuarios_mod;
import 'package:facturacion_app/src/features/cargues/presentation/cargues_provider.dart';
import 'package:facturacion_app/src/features/descuentos/presentation/descuentos_provider.dart';
import 'package:facturacion_app/src/features/equipos/presentation/equipos_provider.dart';
import '../../../core/theme/theme_provider.dart';
import 'widgets/app_drawer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsync = ref.watch(productosProvider);
    final facturaState = ref.watch(facturacionControllerProvider);
    final categoriasAsync = ref.watch(categoriasProvider);
    final categoriaSeleccionada = ref.watch(categoriaSeleccionadaProvider);
    final busqueda = ref.watch(busquedaProductosProvider);
    final modoBusquedaActivo = ref.watch(modoBusquedaActivoProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FacturaDetailScreen(),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Facturas',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${facturaState.cantidadProductos}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Botón de cliente: muestra diferente ícono si hay cliente asignado
          IconButton(
            icon: Icon(
              facturaState.clienteId != null
                ? Icons.person_outlined  // Cliente asignado
                : Icons.person_add_outlined,  // Sin cliente
              color: facturaState.clienteId != null
                ? Colors.greenAccent  // Color verde cuando hay cliente
                : Colors.white,
            ),
            tooltip: facturaState.clienteId != null
              ? 'Ver cliente asignado'
              : 'Agregar cliente',
            onPressed: () {
              if (facturaState.clienteId != null) {
                // Si hay cliente asignado, ir al detalle del cliente
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClienteDetailScreen(
                      clienteId: facturaState.clienteId!,
                    ),
                  ),
                );
              } else {
                // Si no hay cliente, ir a la lista de clientes
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientesScreen(),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            tooltip: 'Sincronizar',
            onPressed: () => _sincronizarDatos(context, ref),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'home'),
      body: Column(
        children: [
          // Banner de facturas abiertas / cobrar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[600]!, Colors.green[700]!],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FacturasGuardadasScreen(),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'FACTURAS ABIERTAS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FacturaDetailScreen(),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'COBRAR',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${facturaState.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Barra de búsqueda y filtro
          Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: modoBusquedaActivo
                      ? // TextField de búsqueda inline
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: TextField(
                            autofocus: true,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Buscar',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (value) {
                              ref.read(busquedaProductosProvider.notifier).state = value;
                            },
                          ),
                        )
                      : // Dropdown de categorías
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: categoriasAsync.when(
                            data: (categorias) {
                              return DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: categoriaSeleccionada,
                                  dropdownColor: Colors.grey[800],
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('Todos los artículos'),
                                    ),
                                    ...categorias.map((categoria) {
                                      return DropdownMenuItem<int?>(
                                        value: categoria.id,
                                        child: Text(categoria.nombre),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    ref.read(categoriaSeleccionadaProvider.notifier).state = value;
                                  },
                                ),
                              );
                            },
                            loading: () => const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            error: (err, stack) => const Text(
                              'Todos los artículos',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    modoBusquedaActivo ? Icons.close : Icons.search,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    if (modoBusquedaActivo) {
                      // Cerrar búsqueda
                      ref.read(modoBusquedaActivoProvider.notifier).state = false;
                      ref.read(busquedaProductosProvider.notifier).state = '';
                    } else {
                      // Activar búsqueda
                      ref.read(modoBusquedaActivoProvider.notifier).state = true;
                    }
                  },
                ),
              ],
            ),
          ),
          // Lista de productos
          Expanded(
            child: productosAsync.when(
              data: (productos) {
                // Filtrar productos por categoría seleccionada
                var productosFiltrados = categoriaSeleccionada == null
                    ? productos
                    : productos.where((p) => p.categoriaId == categoriaSeleccionada).toList();

                // Filtrar por búsqueda si hay texto
                if (busqueda.isNotEmpty) {
                  final busquedaLower = busqueda.toLowerCase();
                  productosFiltrados = productosFiltrados
                      .where((p) => p.nombre.toLowerCase().contains(busquedaLower))
                      .toList();
                }

                if (productosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          busqueda.isNotEmpty
                              ? Icons.search_off
                              : Icons.category_outlined,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          busqueda.isNotEmpty
                              ? 'No se encontraron productos con "$busqueda"'
                              : (categoriaSeleccionada == null
                                  ? 'No hay productos disponibles'
                                  : 'No hay productos en esta categoría'),
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final producto = productosFiltrados[index];
                    return _buildProductItem(
                      context,
                      producto.nombre,
                      '\$${producto.precio.toStringAsFixed(2)}',
                      imageUrl: producto.imagenUrlDirecta,
                      onTap: () async {
                        await ref
                            .read(facturacionControllerProvider.notifier)
                            .agregarProducto(producto);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${producto.nombre} agregado a la factura'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
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
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar productos',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(productosProvider);
                      },
                      child: const Text('Reintentar'),
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

  Widget _buildProductItem(BuildContext context, String name, String price, {String? imageUrl, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: imageUrl != null && imageUrl.isNotEmpty
              ? () => _mostrarImagenAmpliada(context, imageUrl, name)
              : null,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                        // Ícono de lupa para indicar que se puede ampliar
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: Text(
          price,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _mostrarImagenAmpliada(BuildContext context, String imageUrl, String productName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra superior con el nombre del producto y botón cerrar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Imagen ampliada
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(50),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image, color: Colors.grey, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'No se pudo cargar la imagen',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sincroniza todos los datos desde el servidor
  void _sincronizarDatos(BuildContext context, WidgetRef ref) async {
    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(width: 20),
            const Expanded(
              child: Text(
                'Sincronizando datos desde el servidor...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Obtener los repositorios y forzar sincronización desde el servidor
      final productosRepo = ref.read(productosRepositoryProvider);
      final categoriasRepo = ref.read(categoriasRepositoryProvider);
      final clientesRepo = ref.read(clientesRepositoryProvider);
      final facturasRepo = ref.read(facturasRepositoryProvider);
      final listasPreciosRepo = ref.read(listasPreciosRepositoryProvider);
      final usuariosRepo = ref.read(usuarios_mod.usuariosRepositoryProvider);
      final carguesRepo = ref.read(carguesRepositoryProvider);
      final descuentosRepo = ref.read(descuentosRepositoryProvider);
      final equiposRepo = ref.read(equiposRepositoryProvider);

      // Sincronizar todos los datos en paralelo
      await Future.wait([
        productosRepo.syncFromServer(),
        categoriasRepo.syncFromServer(),
        clientesRepo.syncFromServer(),
        facturasRepo.syncFromServer(),
        listasPreciosRepo.syncFromServer(),
        usuariosRepo.syncFromServer(),
        carguesRepo.syncFromServer(),
        descuentosRepo.syncFromServer(),
        equiposRepo.syncFromServer(),
      ]);

      // Invalidar todos los providers para forzar la recarga desde SQLite actualizado
      ref.invalidate(productosProvider);
      ref.invalidate(categoriasProvider);
      ref.invalidate(clientesProvider);
      ref.invalidate(facturasProvider);
      ref.invalidate(listasPreciosProvider);
      ref.invalidate(usuarios_mod.usuariosProvider);
      ref.invalidate(carguesProvider);
      ref.invalidate(descuentosProvider);
      ref.invalidate(equiposProvider);

      if (context.mounted) {
        Navigator.of(context).pop(); // Cerrar diálogo de carga

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización completada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Cerrar diálogo de carga

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}