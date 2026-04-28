import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/cliente.dart';
import '../clientes_provider.dart';

class ClienteFormScreen extends ConsumerStatefulWidget {
  final Cliente? cliente;

  const ClienteFormScreen({super.key, this.cliente});

  @override
  ConsumerState<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends ConsumerState<ClienteFormScreen> {
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

  bool get _isEditing => widget.cliente != null;

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
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: Text(
          _isEditing ? 'Editar Cliente' : 'Nuevo Cliente',
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
                        _isEditing ? Icons.edit : Icons.person_add,
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
                            _isEditing ? 'Editar Cliente' : 'Crear Nuevo Cliente',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEditing
                                ? 'Actualiza la información del cliente'
                                : 'Completa los datos del nuevo cliente',
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

              // Información Básica
              Text(
                'Información Básica',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Nombre Establecimiento (requerido)
              TextFormField(
                controller: _nombreEstablecimientoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre Establecimiento *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Ej: Tienda Mi Negocio',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.store, color: Colors.greenAccent),
                  filled: true,
                  fillColor: Colors.grey[850],
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
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre del establecimiento es requerido';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Propietario
              TextFormField(
                controller: _propietarioController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Propietario',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Nombre del propietario',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850],
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Código de Cliente
              TextFormField(
                controller: _codigoClienteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Código de Cliente',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Código único del cliente',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.qr_code, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850],
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Información de Contacto
              Text(
                'Información de Contacto',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'correo@ejemplo.com',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.email, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850],
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
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: '+57 300 123 4567',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850],
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Ubicación
              Text(
                'Ubicación',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Dirección
              TextFormField(
                controller: _direccionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Calle, número, detalles...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850],
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ciudad y Departamento en fila
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ciudadController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ciudad',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Bogotá',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.location_city, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[850],
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _departamentoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Departamento',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Cundinamarca',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.map, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[850],
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Código Postal y País en fila
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codigoPostalController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Código Postal',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: '110111',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.local_post_office, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[850],
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _paisSeleccionado,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey[800],
                      decoration: InputDecoration(
                        labelText: 'País',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.public, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[850],
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.green, width: 2),
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
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notas
              Text(
                'Notas Adicionales',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Nota
              TextFormField(
                controller: _notaController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Nota',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Información adicional sobre el cliente...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.note, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850],
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
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
                      onPressed: _isLoading ? null : _guardarCliente,
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
                              _isEditing ? 'Actualizar' : 'Guardar',
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
