import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/productos/presentation/productos_provider.dart';
import 'package:facturacion_app/src/features/categorias/presentation/categorias_provider.dart';
import 'package:facturacion_app/src/features/listas_precios/presentation/listas_precios_provider.dart';

class CrearProductoDialog extends ConsumerStatefulWidget {
  const CrearProductoDialog({super.key});

  @override
  ConsumerState<CrearProductoDialog> createState() => _CrearProductoDialogState();
}

class _CrearProductoDialogState extends ConsumerState<CrearProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _stockController = TextEditingController();
  final _imagenUrlController = TextEditingController();

  bool _isLoading = false;
  int? _categoriaSeleccionada;
  final Map<int, TextEditingController> _preciosPorListaControllers = {};

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _stockController.dispose();
    _imagenUrlController.dispose();
    for (var controller in _preciosPorListaControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Recopilar precios por lista
    final Map<int, double> preciosPorLista = {};
    for (var entry in _preciosPorListaControllers.entries) {
      final precio = double.tryParse(entry.value.text.trim());
      if (precio != null && precio > 0) {
        preciosPorLista[entry.key] = precio;
      }
    }

    // Validar que al menos tenga un precio (preferentemente General con id 1)
    if (preciosPorLista.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes ingresar al menos el precio en la lista General'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(productosRepositoryProvider).crearProducto(
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            stock: int.parse(_stockController.text),
            categoriaId: _categoriaSeleccionada,
            imagenUrl: _imagenUrlController.text.trim().isEmpty
                ? null
                : _imagenUrlController.text.trim(),
            preciosPorLista: preciosPorLista,
          );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_shopping_cart,
              color: Colors.greenAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Nuevo Producto',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre
                TextFormField(
                  controller: _nombreController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Ej: Coca Cola 1.5L',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.label, color: Colors.greenAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descripcionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Descripción opcional del producto',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.description, color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),


                // Stock
                TextFormField(
                  controller: _stockController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Stock Inicial *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.inventory, color: Colors.greenAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El stock es requerido';
                    }
                    final stock = int.tryParse(value);
                    if (stock == null || stock < 0) {
                      return 'Ingresa un stock válido mayor o igual a 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Categoría
                Consumer(
                  builder: (context, ref, child) {
                    final categoriasAsync = ref.watch(categoriasProvider);

                    return categoriasAsync.when(
                      data: (categorias) {
                        return DropdownButtonFormField<int>(
                          value: _categoriaSeleccionada,
                          dropdownColor: Colors.grey[800],
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Categoría',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.category, color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[700]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.green),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          hint: Text(
                            'Selecciona una categoría (opcional)',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Sin categoría'),
                            ),
                            ...categorias.map((categoria) {
                              return DropdownMenuItem<int>(
                                value: categoria.id,
                                child: Text(categoria.nombre),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _categoriaSeleccionada = value;
                            });
                          },
                        );
                      },
                      loading: () => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Cargando categorías...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Error al cargar categorías',
                          style: TextStyle(color: Colors.red[300]),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // URL de Imagen
                TextFormField(
                  controller: _imagenUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'URL de Imagen',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'https://ejemplo.com/imagen.jpg',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.image, color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 24),

                // Sección de Listas de Precios
                Consumer(
                  builder: (context, ref, child) {
                    final listasPreciosAsync = ref.watch(listasPreciosProvider);

                    return listasPreciosAsync.when(
                      data: (listas) {
                        if (listas.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título de la sección
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.list_alt, color: Colors.orangeAccent, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Precios por Lista *',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Requerido',
                                    style: TextStyle(
                                      color: Colors.orange[300],
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Campos de precios para cada lista
                            ...listas.map((lista) {
                              // Crear controller si no existe
                              if (!_preciosPorListaControllers.containsKey(lista.id)) {
                                _preciosPorListaControllers[lista.id] = TextEditingController();
                              }

                              // Resaltar "General" como obligatoria
                              final esGeneral = lista.nombre.toLowerCase() == 'general' || lista.id == 1;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextFormField(
                                  controller: _preciosPorListaControllers[lista.id],
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: esGeneral ? '${lista.nombre} *' : lista.nombre,
                                    labelStyle: TextStyle(
                                      color: esGeneral ? Colors.orangeAccent : Colors.white70,
                                      fontWeight: esGeneral ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    hintText: '0.00',
                                    hintStyle: TextStyle(color: Colors.grey[600]),
                                    prefixIcon: Icon(
                                      Icons.attach_money,
                                      color: esGeneral ? Colors.orangeAccent : Colors.blueAccent,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: esGeneral ? Colors.orange.withValues(alpha: 0.5) : Colors.grey[700]!,
                                        width: esGeneral ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: esGeneral ? Colors.orange : Colors.blue,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (error, stack) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}
