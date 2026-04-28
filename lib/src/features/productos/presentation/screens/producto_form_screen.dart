import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/productos/presentation/productos_provider.dart';
import 'package:facturacion_app/src/features/categorias/presentation/categorias_provider.dart';
import 'package:facturacion_app/src/features/listas_precios/presentation/listas_precios_provider.dart';
import 'package:facturacion_app/src/features/productos/domain/producto.dart';

class ProductoFormScreen extends ConsumerStatefulWidget {
  final Producto? producto;

  const ProductoFormScreen({
    super.key,
    this.producto,
  });

  @override
  ConsumerState<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends ConsumerState<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _stockController = TextEditingController();
  final _imagenUrlController = TextEditingController();

  bool _isLoading = false;
  int? _categoriaSeleccionada;
  final Map<int, TextEditingController> _preciosPorListaControllers = {};
  Map<int, double> _preciosExistentes = {};

  bool get _isEditing => widget.producto != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nombreController.text = widget.producto!.nombre;
      _descripcionController.text = widget.producto!.descripcion ?? '';
      _stockController.text = widget.producto!.stock.toString();
      _imagenUrlController.text = widget.producto!.imagenUrl ?? '';
      _categoriaSeleccionada = widget.producto!.categoriaId;
      _cargarPreciosExistentes();
    }
  }

  Future<void> _cargarPreciosExistentes() async {
    if (!_isEditing) return;

    try {
      final repository = ref.read(listasPreciosRepositoryProvider);
      final precios = await repository.getPreciosProductoMap(widget.producto!.id);

      if (mounted) {
        setState(() {
          _preciosExistentes = precios;
          // Inicializar controladores con precios existentes
          for (var entry in precios.entries) {
            if (!_preciosPorListaControllers.containsKey(entry.key)) {
              _preciosPorListaControllers[entry.key] = TextEditingController(
                text: entry.value.toStringAsFixed(2),
              );
            } else {
              _preciosPorListaControllers[entry.key]!.text = entry.value.toStringAsFixed(2);
            }
          }
        });
      }
    } catch (e) {
      // Si hay error, simplemente no se cargan los precios (quedan vacíos)
      // El usuario puede ingresarlos manualmente
    }
  }

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

    // Validar que al menos tenga un precio (solo para nuevo producto)
    if (!_isEditing && preciosPorLista.isEmpty) {
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
      if (_isEditing) {
        await ref.read(productosRepositoryProvider).actualizarProducto(
              id: widget.producto!.id,
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
      } else {
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
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${_isEditing ? "actualizar" : "crear"} producto: $e'),
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
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: Text(
          _isEditing ? 'Editar Producto' : 'Nuevo Producto',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con icono
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.withValues(alpha: 0.3), Colors.green.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit : Icons.add_shopping_cart,
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
                            _isEditing ? 'Editar Producto' : 'Crear Nuevo Producto',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEditing
                                ? 'Actualiza la información del producto'
                                : 'Completa los datos del nuevo producto',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[850],
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
                maxLines: 3,
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
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[850],
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
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[850],
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
                        initialValue: _categoriaSeleccionada,
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
                            borderSide: const BorderSide(color: Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[850],
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
                        color: Colors.grey[850],
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
                        color: Colors.grey[850],
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
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[850],
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.list_alt, color: Colors.orangeAccent, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isEditing ? 'Precios por Lista' : 'Precios por Lista *',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!_isEditing)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Requerido',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Campos de precios para cada lista
                          ...listas.map((lista) {
                            // Crear controller si no existe (sin inicializar con valor aquí)
                            if (!_preciosPorListaControllers.containsKey(lista.id)) {
                              // Los controladores se inicializan vacíos, se llenarán en _cargarPreciosExistentes
                              _preciosPorListaControllers[lista.id] = TextEditingController();
                            }

                            // Resaltar "General" como obligatoria (solo para nuevo producto)
                            final esGeneral = !_isEditing && (lista.nombre.toLowerCase() == 'general' || lista.id == 1);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
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
                                  filled: true,
                                  fillColor: Colors.grey[850],
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

              const SizedBox(height: 32),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[600]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                          : Text(
                              _isEditing ? 'Actualizar' : 'Crear',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
