import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';

class GeneralScreen extends ConsumerWidget {
  const GeneralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración General'),
      ),
      body: ListView(
        children: [
          // Sección: Apariencia
          _buildSectionHeader(context, 'Apariencia'),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Modo Oscuro'),
            subtitle: Text(
              isDarkMode
                  ? 'La aplicación está en modo oscuro'
                  : 'La aplicación está en modo claro',
            ),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const Divider(),

          // Preview de colores del tema actual
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vista previa del tema',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildColorChip(
                      context,
                      'Primario',
                      Theme.of(context).colorScheme.primary,
                    ),
                    _buildColorChip(
                      context,
                      'Secundario',
                      Theme.of(context).colorScheme.secondary,
                    ),
                    _buildColorChip(
                      context,
                      'Superficie',
                      Theme.of(context).colorScheme.surface,
                    ),
                    _buildColorChip(
                      context,
                      'Error',
                      Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Botones de ejemplo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Componentes de ejemplo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Botón Primario'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Botón Secundario'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Esto es una tarjeta de ejemplo con el tema actual',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildColorChip(BuildContext context, String label, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
      ),
      label: Text(label),
    );
  }
}