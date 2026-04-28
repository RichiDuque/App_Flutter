import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/widgets/app_drawer.dart';
import 'impresoras_screen.dart';
import 'general_screen.dart';

class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text(
          'Configuración',
          style: TextStyle(color: Colors.white),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: 'configuracion'),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildMenuItem(
            context: context,
            icon: Icons.print,
            title: 'Impresoras',
            subtitle: 'Configurar impresoras térmicas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImpresorasScreen(),
                ),
              );
            },
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildMenuItem(
            context: context,
            icon: Icons.percent,
            title: 'Impuestos',
            subtitle: 'Configurar tasas de impuestos',
            onTap: () {
              // TODO: Navegar a pantalla de impuestos
            },
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildMenuItem(
            context: context,
            icon: Icons.settings,
            title: 'General',
            subtitle: 'Configuración general de la aplicación',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GeneralScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.greenAccent, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}