import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/cliente.dart';
import '../clientes_provider.dart';

class ClienteFormDialog extends ConsumerStatefulWidget {
  final Cliente? cliente;

  const ClienteFormDialog({super.key, this.cliente});

  @override
  ConsumerState<ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends ConsumerState<ClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreEstablecimientoController;
  late TextEditingController _propietarioController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _direccionController;
  late TextEditingController _ciudadController;
  late TextEditingController _departamentoController;
  late TextEditingController _codigoPostalController;
  late TextEditingController _codigoClienteController;
  late TextEditingController _notaController;
  String _paisSeleccionado = 'Colombia';
  bool _isLoading = false;

  final List<String> _paises = [
    'Colombia',
    'Argentina',
    'Chile',
    'México',
    'Perú',
    'Venezuela',
    'Ecuador',
    'Bolivia',
    'Paraguay',
    'Uruguay',
  ];

  @override
  void initState() {
    super.initState();
    _nombreEstablecimientoController = TextEditingController(text: widget.cliente?.nombreEstablecimiento ?? '');
    _propietarioController = TextEditingController(text: widget.cliente?.propietario ?? '');
    _emailController = TextEditingController(text: widget.cliente?.email ?? '');
    _telefonoController = TextEditingController(text: widget.cliente?.telefono ?? '');
    _direccionController = TextEditingController(text: widget.cliente?.direccion ?? '');
    _ciudadController = TextEditingController(text: widget.cliente?.ciudad ?? '');
    _departamentoController = TextEditingController(text: widget.cliente?.departamento ?? '');
    _codigoPostalController = TextEditingController(text: widget.cliente?.codigoPostal ?? '');
    _codigoClienteController = TextEditingController(text: widget.cliente?.codigoCliente ?? '');
    _notaController = TextEditingController(text: widget.cliente?.nota ?? '');
    _paisSeleccionado = widget.cliente?.pais ?? 'Colombia';
  }

  @override
  void dispose() {
    _nombreEstablecimientoController.dispose();
    _propietarioController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _departamentoController.dispose();
    _codigoPostalController.dispose();
    _codigoClienteController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(clientesRepositoryProvider);

      if (widget.cliente == null) {
        // Crear nuevo cliente
        await repository.crearCliente(
          nombreEstablecimiento: _nombreEstablecimientoController.text,
          propietario: _propietarioController.text.isEmpty ? null : _propietarioController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          telefono: _telefonoController.text.isEmpty ? null : _telefonoController.text,
          direccion: _direccionController.text.isEmpty ? null : _direccionController.text,
          ciudad: _ciudadController.text.isEmpty ? null : _ciudadController.text,
          departamento: _departamentoController.text.isEmpty ? null : _departamentoController.text,
          codigoPostal: _codigoPostalController.text.isEmpty ? null : _codigoPostalController.text,
          pais: _paisSeleccionado,
          codigoCliente: _codigoClienteController.text.isEmpty ? null : _codigoClienteController.text,
          nota: _notaController.text.isEmpty ? null : _notaController.text,
        );
      } else {
        // Actualizar cliente existente
        await repository.actualizarCliente(widget.cliente!.id, {
          'nombre_establecimiento': _nombreEstablecimientoController.text,
          'propietario': _propietarioController.text.isEmpty ? null : _propietarioController.text,
          'email': _emailController.text.isEmpty ? null : _emailController.text,
          'telefono': _telefonoController.text.isEmpty ? null : _telefonoController.text,
          'direccion': _direccionController.text.isEmpty ? null : _direccionController.text,
          'ciudad': _ciudadController.text.isEmpty ? null : _ciudadController.text,
          'departamento': _departamentoController.text.isEmpty ? null : _departamentoController.text,
          'codigo_postal': _codigoPostalController.text.isEmpty ? null : _codigoPostalController.text,
          'pais': _paisSeleccionado,
          'codigo_cliente': _codigoClienteController.text.isEmpty ? null : _codigoClienteController.text,
          'nota': _notaController.text.isEmpty ? null : _notaController.text,
        });
      }

      // Refrescar la lista de clientes
      ref.invalidate(clientesProvider);

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
                      widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente',
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
                      // Nombre Establecimiento (requerido)
                      TextFormField(
                        controller: _nombreEstablecimientoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nombre Establecimiento *',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre del establecimiento es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Propietario
                      TextFormField(
                        controller: _propietarioController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Propietario',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Email inválido';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Teléfono
                      TextFormField(
                        controller: _telefonoController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dirección
                      TextFormField(
                        controller: _direccionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Dirección',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ciudad
                      TextFormField(
                        controller: _ciudadController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Ciudad',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Departamento
                      TextFormField(
                        controller: _departamentoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Departamento',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Código Postal
                      TextFormField(
                        controller: _codigoPostalController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Código Postal',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // País (dropdown)
                      DropdownButtonFormField<String>(
                        value: _paisSeleccionado,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey[850],
                        decoration: InputDecoration(
                          labelText: 'País',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _paises.map((pais) {
                          return DropdownMenuItem(
                            value: pais,
                            child: Text(pais),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _paisSeleccionado = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Código de Cliente
                      TextFormField(
                        controller: _codigoClienteController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Código de Cliente',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nota
                      TextFormField(
                        controller: _notaController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Nota',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón Guardar
                      ElevatedButton(
                        onPressed: _isLoading ? null : _guardarCliente,
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