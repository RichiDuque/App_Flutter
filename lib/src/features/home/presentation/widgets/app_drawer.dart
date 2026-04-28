import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/auth/presentation/auth_controller.dart';
import 'package:facturacion_app/src/features/facturas/presentation/facturas_screen.dart';
import 'package:facturacion_app/src/features/equipos/presentation/equipos_screen.dart';
import 'package:facturacion_app/src/features/usuarios/presentation/screens/vendedores_screen.dart';
import 'package:facturacion_app/src/features/usuarios/presentation/screens/usuarios_screen.dart';
import 'package:facturacion_app/src/features/productos/presentation/screens/productos_screen.dart';
import '../../../clientes/presentation/screens/clientes_screen.dart';
import '../../../configuracion/presentation/screens/configuracion_screen.dart';
import '../../../configuracion/presentation/screens/gestion_screen.dart';
import '../../../cargues/presentation/screens/cargues_screen.dart';

class AppDrawer extends ConsumerWidget {
  final String? currentRoute;

  const AppDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final userName = authState.user ?? 'Usuario';

    return Drawer(
      backgroundColor: Colors.grey[900],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey[850],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Propietario',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sistema de Facturación',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.shopping_basket,
            title: 'Ventas',
            color: Colors.green,
            isSelected: currentRoute == 'home' || currentRoute == null,
            onTap: () {
              Navigator.pop(context);
              // Navegar a home (ventas) - usar popUntil para volver al home
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          _buildDrawerItem(
            icon: Icons.receipt_long,
            title: 'Facturas',
            isSelected: currentRoute == 'facturas',
            onTap: () {
              Navigator.pop(context);
              // Solo navegar si no estamos ya en facturas
              if (currentRoute != 'facturas') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FacturasScreen(),
                  ),
                );
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.local_shipping,
            title: 'Cargues',
            color: Colors.teal,
            isSelected: currentRoute == 'cargues',
            onTap: () {
              Navigator.pop(context);
              // Solo navegar si no estamos ya en cargues
              if (currentRoute != 'cargues') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CarguesScreen(),
                  ),
                );
              }
            },
          ),
          // Productos - Solo visible para administradores
          if (authState.role == 'admin')
            _buildDrawerItem(
              icon: Icons.inventory_2,
              title: 'Productos',
              isSelected: currentRoute == 'productos',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductosScreen(),
                  ),
                );
              },
            ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Clientes',
            isSelected: currentRoute == 'clientes',
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != 'clientes') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientesScreen(),
                  ),
                );
              }
            },
          ),
          // Equipos - Solo visible para administradores
          if (authState.role == 'admin')
            _buildDrawerItem(
              icon: Icons.groups,
              title: 'Equipos',
              color: Colors.blue,
              isSelected: currentRoute == 'equipos',
              onTap: () {
                Navigator.pop(context);
                // Solo navegar si no estamos ya en equipos
                if (currentRoute != 'equipos') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EquiposScreen(),
                    ),
                  );
                }
              },
            ),
          // Vendedores - Solo visible para administradores
          if (authState.role == 'admin')
            _buildDrawerItem(
              icon: Icons.badge,
              title: 'Vendedores',
              color: Colors.purple,
              isSelected: currentRoute == 'vendedores',
              onTap: () {
                Navigator.pop(context);
                // Solo navegar si no estamos ya en vendedores
                if (currentRoute != 'vendedores') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendedoresScreen(),
                    ),
                  );
                }
              },
            ),
          // Usuarios - Solo visible para administradores
          if (authState.role == 'admin')
            _buildDrawerItem(
              icon: Icons.manage_accounts,
              title: 'Usuarios',
              color: Colors.indigo,
              isSelected: currentRoute == 'usuarios',
              onTap: () {
                Navigator.pop(context);
                // Solo navegar si no estamos ya en usuarios
                if (currentRoute != 'usuarios') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UsuariosScreen(),
                    ),
                  );
                }
              },
            ),
          // Gestión (Categorías y Descuentos) - Solo visible para administradores
          if (authState.role == 'admin')
            _buildDrawerItem(
              icon: Icons.tune,
              title: 'Gestión',
              color: Colors.orange,
              isSelected: currentRoute == 'gestion',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'gestion') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GestionScreen(),
                    ),
                  );
                }
              },
            ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Configuración',
            isSelected: currentRoute == 'configuracion',
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != 'configuracion') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConfiguracionScreen(),
                  ),
                );
              }
            },
          ),
          const Divider(color: Colors.grey),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            color: Colors.red,
            onTap: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    Color? color,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.green.withValues(alpha: 0.2),
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}