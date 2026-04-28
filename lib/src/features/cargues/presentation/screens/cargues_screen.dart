import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../home/presentation/widgets/app_drawer.dart';
import '../widgets/crear_cargue_tab.dart';
import '../widgets/mis_cargues_tab.dart';

class CarguesScreen extends ConsumerWidget {
  const CarguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.role == 'admin';

    // Admin solo ve la lista, vendedor ve ambos tabs
    return DefaultTabController(
      length: isAdmin ? 1 : 2,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.grey[850],
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Cargues',
            style: TextStyle(color: Colors.white),
          ),
          bottom: isAdmin
              ? null
              : TabBar(
                  indicatorColor: Colors.green,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.add_shopping_cart),
                      text: 'Crear Cargue',
                    ),
                    Tab(
                      icon: Icon(Icons.list_alt),
                      text: 'Mis Cargues',
                    ),
                  ],
                ),
        ),
        drawer: const AppDrawer(currentRoute: 'cargues'),
        body: isAdmin
            ? const MisCarguesTab(isAdminView: true)
            : const TabBarView(
                children: [
                  CrearCargueTab(),
                  MisCarguesTab(isAdminView: false),
                ],
              ),
      ),
    );
  }
}