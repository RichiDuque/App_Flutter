import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/usuarios/domain/usuario.dart';
import 'package:facturacion_app/src/features/usuarios/presentation/usuarios_provider.dart';
import 'package:facturacion_app/src/features/listas_precios/presentation/listas_precios_provider.dart';

class UsuarioFormDialog extends ConsumerStatefulWidget {
  final Usuario? usuario;
  final VoidCallback onGuardar;

  const UsuarioFormDialog({
    super.key,
    this.usuario,
    required this.onGuardar,
  });

  @override
  ConsumerState<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends ConsumerState<UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String _rol = 'vendedor';
  int? _listaPreciosId;
  bool _activo = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.usuario?.nombre ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _passwordController = TextEditingController();
    _rol = widget.usuario?.rol ?? 'vendedor';
    _listaPreciosId = widget.usuario?.listaPreciosId;
    _activo = widget.usuario?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listasAsync = ref.watch(listasPreciosProvider);
    final esEdicion = widget.usuario != null;

    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              esEdicion ? 'Editar Usuario' : 'Nuevo Usuario',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Formulario
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nombre completo *',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.person, color: Colors.white70),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Email
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.email, color: Colors.white70),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el email';
                        }
                        if (!value.contains('@')) {
                          return 'Ingresa un email válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Contraseña
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: esEdicion ? 'Contraseña (dejar vacío para no cambiar)' : 'Contraseña *',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      ),
                      validator: (value) {
                        if (!esEdicion && (value == null || value.isEmpty)) {
                          return 'Por favor ingresa una contraseña';
                        }
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Rol
                    DropdownButtonFormField<String>(
                      value: _rol,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Rol *',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.admin_panel_settings, color: Colors.white70),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                        DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _rol = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Lista de precios (solo para vendedores)
                    if (_rol == 'vendedor')
                      listasAsync.when(
                        data: (listas) {
                          return DropdownButtonFormField<int?>(
                            value: _listaPreciosId,
                            dropdownColor: Colors.grey[800],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Lista de precios',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[800],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.attach_money, color: Colors.white70),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Sin lista asignada', style: TextStyle(color: Colors.grey[500])),
                              ),
                              ...listas.map((lista) => DropdownMenuItem(
                                    value: lista.id,
                                    child: Text(lista.nombre),
                                  )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _listaPreciosId = value;
                              });
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => Text(
                          'Error al cargar listas de precios',
                          style: TextStyle(color: Colors.red[300]),
                        ),
                      ),
                    if (_rol == 'vendedor') const SizedBox(height: 16),
                    // Estado (solo en edición)
                    if (esEdicion)
                      SwitchListTile(
                        title: const Text('Usuario activo', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          _activo ? 'El usuario puede iniciar sesión' : 'El usuario está deshabilitado',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        value: _activo,
                        activeColor: Colors.green,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            _activo = value;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(esEdicion ? 'Actualizar' : 'Crear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(usuariosRepositoryProvider);

      if (widget.usuario == null) {
        // Crear nuevo usuario
        await repository.crearUsuario(
          nombre: _nombreController.text,
          email: _emailController.text,
          password: _passwordController.text,
          rol: _rol,
          listaPreciosId: _rol == 'vendedor' ? _listaPreciosId : null,
        );
      } else {
        // Actualizar usuario existente
        await repository.actualizarUsuario(
          id: widget.usuario!.id,
          nombre: _nombreController.text,
          email: _emailController.text,
          password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
          rol: _rol,
          listaPreciosId: _listaPreciosId,
          activo: _activo,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.usuario == null ? 'Usuario creado correctamente' : 'Usuario actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onGuardar();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

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