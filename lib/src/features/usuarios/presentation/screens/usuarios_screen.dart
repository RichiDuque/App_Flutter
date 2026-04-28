import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/usuarios/presentation/usuarios_provider.dart';
import 'package:facturacion_app/src/features/usuarios/domain/usuario.dart';
import 'package:facturacion_app/src/features/usuarios/presentation/widgets/usuario_form_dialog.dart';
import 'package:facturacion_app/src/features/home/presentation/widgets/app_drawer.dart';

class UsuariosScreen extends ConsumerStatefulWidget {
  const UsuariosScreen({super.key});

  @override
  ConsumerState<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends ConsumerState<UsuariosScreen> {
  String _busqueda = '';
  String? _filtroRol;
  bool? _filtroActivo;

  @override
  Widget build(BuildContext context) {
    final usuariosAsync = ref.watch(usuariosProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      drawer: const AppDrawer(currentRoute: 'usuarios'),
      appBar: AppBar(
        title: const Text('Gestión de Usuarios', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[850],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(usuariosProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioCrear(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Usuario'),
        backgroundColor: Colors.green[600],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Campo de búsqueda
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o email...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _busqueda = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filtros
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _filtroRol,
                        dropdownColor: Colors.grey[800],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Filtrar por rol',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text('Todos', style: TextStyle(color: Colors.grey[400]))),
                          const DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                          const DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filtroRol = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        value: _filtroActivo,
                        dropdownColor: Colors.grey[800],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Filtrar por estado',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text('Todos', style: TextStyle(color: Colors.grey[400]))),
                          const DropdownMenuItem(value: true, child: Text('Activos')),
                          const DropdownMenuItem(value: false, child: Text('Inactivos')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filtroActivo = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de usuarios
          Expanded(
            child: usuariosAsync.when(
              data: (usuarios) {
                // Aplicar filtros
                var usuariosFiltrados = usuarios.where((usuario) {
                  // Filtro de búsqueda
                  if (_busqueda.isNotEmpty) {
                    final busquedaLower = _busqueda.toLowerCase();
                    if (!usuario.nombre.toLowerCase().contains(busquedaLower) &&
                        !usuario.email.toLowerCase().contains(busquedaLower)) {
                      return false;
                    }
                  }

                  // Filtro por rol
                  if (_filtroRol != null && usuario.rol != _filtroRol) {
                    return false;
                  }

                  // Filtro por estado
                  if (_filtroActivo != null && usuario.activo != _filtroActivo) {
                    return false;
                  }

                  return true;
                }).toList();

                if (usuariosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          _busqueda.isNotEmpty || _filtroRol != null || _filtroActivo != null
                              ? 'No se encontraron usuarios con los filtros aplicados'
                              : 'No hay usuarios registrados',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: usuariosFiltrados.length,
                  itemBuilder: (context, index) {
                    final usuario = usuariosFiltrados[index];
                    return _buildUsuarioCard(context, usuario);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar usuarios',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
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

  Widget _buildUsuarioCard(BuildContext context, Usuario usuario) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: usuario.activo ? Colors.green[700] : Colors.grey[700],
          child: Text(
            usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          usuario.nombre,
          style: TextStyle(
            color: usuario.activo ? Colors.white : Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              usuario.email,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChip(usuario.rolDisplay, usuario.rol == 'admin' ? Colors.purple : Colors.blue),
                const SizedBox(width: 8),
                _buildChip(usuario.estadoDisplay, usuario.activo ? Colors.green : Colors.red),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: Colors.grey[800],
          onSelected: (value) {
            switch (value) {
              case 'editar':
                _mostrarFormularioEditar(context, usuario);
                break;
              case 'toggle_estado':
                _cambiarEstado(usuario);
                break;
              case 'eliminar':
                _confirmarEliminar(context, usuario);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Editar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_estado',
              child: Row(
                children: [
                  Icon(
                    usuario.activo ? Icons.block : Icons.check_circle,
                    color: usuario.activo ? Colors.orange : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    usuario.activo ? 'Deshabilitar' : 'Habilitar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _mostrarFormularioCrear(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UsuarioFormDialog(
        onGuardar: () {
          ref.invalidate(usuariosProvider);
        },
      ),
    );
  }

  void _mostrarFormularioEditar(BuildContext context, Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => UsuarioFormDialog(
        usuario: usuario,
        onGuardar: () {
          ref.invalidate(usuariosProvider);
        },
      ),
    );
  }

  Future<void> _cambiarEstado(Usuario usuario) async {
    try {
      final repository = ref.read(usuariosRepositoryProvider);
      await repository.cambiarEstadoUsuario(usuario.id, !usuario.activo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario ${!usuario.activo ? "habilitado" : "deshabilitado"} correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      ref.invalidate(usuariosProvider);
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

  void _confirmarEliminar(BuildContext context, Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Confirmar eliminación', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de que deseas eliminar al usuario "${usuario.nombre}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _eliminarUsuario(usuario);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarUsuario(Usuario usuario) async {
    try {
      final repository = ref.read(usuariosRepositoryProvider);
      await repository.eliminarUsuario(usuario.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      ref.invalidate(usuariosProvider);
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