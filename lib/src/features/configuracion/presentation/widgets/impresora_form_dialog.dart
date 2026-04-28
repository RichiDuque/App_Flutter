import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/impresora.dart';
import '../../data/bluetooth_service.dart';
import '../impresoras_provider.dart';
import 'bluetooth_search_dialog.dart';

class ImpresoraFormDialog extends ConsumerStatefulWidget {
  final Impresora? impresora;

  const ImpresoraFormDialog({super.key, this.impresora});

  @override
  ConsumerState<ImpresoraFormDialog> createState() => _ImpresoraFormDialogState();
}

class _ImpresoraFormDialogState extends ConsumerState<ImpresoraFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _direccionBluetoothController;
  String _modeloSeleccionado = 'Otro modelo';
  String _interfazSeleccionada = 'Bluetooth';
  int _anchoPapelSeleccionado = 58;
  bool _imprimirRecibos = false;
  bool _isLoading = false;

  final List<String> _modelos = [
    'Otro modelo',
    'Xprinter',
    'Zebra',
    'Epson TM',
    'Star Micronics',
    'Citizen',
  ];

  final List<String> _interfaces = [
    'Bluetooth',
    'USB',
    'WiFi',
  ];

  final List<int> _anchosPapel = [58, 80];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.impresora?.nombre ?? '');
    _direccionBluetoothController = TextEditingController(text: widget.impresora?.direccionBluetooth ?? '');
    _modeloSeleccionado = widget.impresora?.modelo ?? 'Otro modelo';
    _interfazSeleccionada = widget.impresora?.interfaz ?? 'Bluetooth';
    _anchoPapelSeleccionado = widget.impresora?.anchoPapel ?? 58;
    _imprimirRecibos = widget.impresora?.imprimirRecibos ?? false;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionBluetoothController.dispose();
    super.dispose();
  }

  Future<void> _guardarImpresora() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(impresorasRepositoryProvider);

      final impresora = Impresora(
        id: widget.impresora?.id ?? const Uuid().v4(),
        nombre: _nombreController.text,
        modelo: _modeloSeleccionado,
        interfaz: _interfazSeleccionada,
        direccionBluetooth: _direccionBluetoothController.text.isEmpty
            ? null
            : _direccionBluetoothController.text,
        anchoPapel: _anchoPapelSeleccionado,
        imprimirRecibos: _imprimirRecibos,
      );

      await repository.guardarImpresora(impresora);

      // Si se marcó como impresora de recibos, establecerla como tal
      if (_imprimirRecibos) {
        await repository.establecerImpresoraRecibos(impresora.id);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  Future<void> _eliminarImpresora() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Confirmar eliminación', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta impresora?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && widget.impresora != null) {
      try {
        final repository = ref.read(impresorasRepositoryProvider);
        await repository.eliminarImpresora(widget.impresora!.id);

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
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

  void _buscarDispositivos() async {
    final dispositivo = await showDialog<BluetoothDeviceInfo>(
      context: context,
      builder: (context) => const BluetoothSearchDialog(),
    );

    if (dispositivo != null) {
      setState(() {
        _direccionBluetoothController.text = dispositivo.direccion;
        // Auto-completar el nombre si está vacío
        if (_nombreController.text.isEmpty) {
          _nombreController.text = dispositivo.displayName;
        }
      });
    }
  }

  void _pruebaImpresion() async {
    // TODO: Implementar prueba de impresión
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de prueba de impresión próximamente'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.impresora == null ? 'Nueva Impresora' : 'Editar Impresora',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Formulario
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nombre (requerido)
                      TextFormField(
                        controller: _nombreController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nombre *',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Modelo de la impresora (dropdown)
                      DropdownButtonFormField<String>(
                        value: _modeloSeleccionado,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey[850],
                        decoration: InputDecoration(
                          labelText: 'Modelo de la impresora',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _modelos.map((modelo) {
                          return DropdownMenuItem(
                            value: modelo,
                            child: Text(modelo),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _modeloSeleccionado = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Interfaz (dropdown)
                      DropdownButtonFormField<String>(
                        value: _interfazSeleccionada,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey[850],
                        decoration: InputDecoration(
                          labelText: 'Interfaz',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _interfaces.map((interfaz) {
                          return DropdownMenuItem(
                            value: interfaz,
                            child: Text(interfaz),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _interfazSeleccionada = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dirección Bluetooth (solo si es Bluetooth)
                      if (_interfazSeleccionada == 'Bluetooth') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _direccionBluetoothController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Impresora Bluetooth',
                                  labelStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[850],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _buscarDispositivos,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 22,
                                ),
                              ),
                              child: const Text('BUSCAR'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Ancho de papel (dropdown)
                      DropdownButtonFormField<int>(
                        value: _anchoPapelSeleccionado,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey[850],
                        decoration: InputDecoration(
                          labelText: 'Ancho de papel',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _anchosPapel.map((ancho) {
                          return DropdownMenuItem(
                            value: ancho,
                            child: Text('$ancho mm'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _anchoPapelSeleccionado = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Configuración Avanzada
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Text(
                          'Configuración Avanzada',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Switch para imprimir recibos
                      SwitchListTile(
                        title: const Text(
                          'Imprimir recibos y cuentas',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: _imprimirRecibos,
                        onChanged: (value) {
                          setState(() => _imprimirRecibos = value);
                        },
                        activeTrackColor: Colors.green,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Botón de prueba de impresión
                      OutlinedButton.icon(
                        onPressed: _pruebaImpresion,
                        icon: const Icon(Icons.print),
                        label: const Text('IMPRESIÓN DE PRUEBA'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón Guardar
                      ElevatedButton(
                        onPressed: _isLoading ? null : _guardarImpresora,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
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
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'GUARDAR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      // Botón Eliminar (solo si es edición)
                      if (widget.impresora != null) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _eliminarImpresora,
                          icon: const Icon(Icons.delete),
                          label: const Text('ELIMINAR IMPRESORA'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}