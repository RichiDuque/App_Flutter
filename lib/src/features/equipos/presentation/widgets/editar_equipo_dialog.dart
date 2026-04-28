import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/equipos/domain/equipo.dart';
import 'package:facturacion_app/src/features/equipos/presentation/equipos_provider.dart';

class EditarEquipoDialog extends ConsumerStatefulWidget {
  final Equipo equipo;

  const EditarEquipoDialog({super.key, required this.equipo});

  @override
  ConsumerState<EditarEquipoDialog> createState() => _EditarEquipoDialogState();
}

class _EditarEquipoDialogState extends ConsumerState<EditarEquipoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late bool _activo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.equipo.nombre);
    _descripcionController =
        TextEditingController(text: widget.equipo.descripcion ?? '');
    _activo = widget.equipo.activo;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _actualizarEquipo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(equiposRepositoryProvider);
      await repository.actualizarEquipo(
        id: widget.equipo.id,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        activo: _activo,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipo actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar equipo: $e'),
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
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      title: const Text(
        'Editar Equipo',
        style: TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID del equipo
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tag, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'ID: ${widget.equipo.id}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Campo Nombre
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre del Equipo *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.groups, color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Campo Descripción
              TextFormField(
                controller: _descripcionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.description, color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Switch Activo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.toggle_on, color: Colors.white70),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Equipo activo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Switch(
                      value: _activo,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() => _activo = value);
                            },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),

              // Información adicional
              if (widget.equipo.cantidadMiembros != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${widget.equipo.cantidadMiembros} miembro${widget.equipo.cantidadMiembros != 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _actualizarEquipo,
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_isLoading ? 'GUARDANDO...' : 'GUARDAR'),
        ),
      ],
    );
  }
}