import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../facturas_provider.dart';

class FiltroUsuariosDialog extends ConsumerStatefulWidget {
  const FiltroUsuariosDialog({super.key});

  @override
  ConsumerState<FiltroUsuariosDialog> createState() =>
      _FiltroUsuariosDialogState();
}

class _FiltroUsuariosDialogState extends ConsumerState<FiltroUsuariosDialog> {
  late Set<int> _usuariosSeleccionadosTemp;

  @override
  void initState() {
    super.initState();
    _usuariosSeleccionadosTemp =
        Set.from(ref.read(usuariosSeleccionadosProvider));
  }

  @override
  Widget build(BuildContext context) {
    final usuariosAsync = ref.watch(usuariosProvider);

    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtrar por usuario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona los vendedores cuyas facturas deseas visualizar',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            // Botones de acción rápida
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        final usuarios = usuariosAsync.value ?? [];
                        _usuariosSeleccionadosTemp =
                            Set.from(usuarios.map((u) => u.id));
                      });
                    },
                    icon: const Icon(Icons.select_all, size: 18),
                    label: const Text('Seleccionar todos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      side: BorderSide(color: Colors.grey[700]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _usuariosSeleccionadosTemp.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Limpiar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.grey[700]!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Lista de usuarios
            Expanded(
              child: usuariosAsync.when(
                data: (usuarios) {
                  if (usuarios.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 48, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay usuarios disponibles',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      final usuario = usuarios[index];
                      final isSelected =
                          _usuariosSeleccionadosTemp.contains(usuario.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey[850],
                          border: Border.all(
                            color: isSelected
                                ? Colors.green
                                : Colors.grey[800]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _usuariosSeleccionadosTemp.add(usuario.id);
                              } else {
                                _usuariosSeleccionadosTemp.remove(usuario.id);
                              }
                            });
                          },
                          title: Text(
                            usuario.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                usuario.email,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: usuario.rol == 'admin'
                                      ? Colors.purple.withValues(alpha: 0.3)
                                      : Colors.blue.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  usuario.rol.toUpperCase(),
                                  style: TextStyle(
                                    color: usuario.rol == 'admin'
                                        ? Colors.purpleAccent
                                        : Colors.blueAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
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
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar usuarios',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(usuariosSeleccionadosProvider.notifier).state =
                          _usuariosSeleccionadosTemp.toList();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _usuariosSeleccionadosTemp.isEmpty
                          ? 'Ver todas'
                          : 'Aplicar (${_usuariosSeleccionadosTemp.length})',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}