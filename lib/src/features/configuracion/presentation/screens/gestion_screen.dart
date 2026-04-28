import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/categorias_tab.dart';
import 'widgets/descuentos_tab.dart';
import 'widgets/listas_precios_tab.dart';
import '../../../home/presentation/widgets/app_drawer.dart';

class GestionScreen extends ConsumerWidget {
  const GestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.grey[850],
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Gestión',
            style: TextStyle(color: Colors.white),
          ),
          bottom: TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[400],
            tabs: const [
              Tab(
                icon: Icon(Icons.category),
                text: 'Categorías',
              ),
              Tab(
                icon: Icon(Icons.discount),
                text: 'Descuentos',
              ),
              Tab(
                icon: Icon(Icons.price_change),
                text: 'Listas de Precios',
              ),
            ],
          ),
        ),
        drawer: const AppDrawer(currentRoute: 'gestion'),
        body: const TabBarView(
          children: [
            CategoriasTab(),
            DescuentosTab(),
            ListasPreciosTab(),
          ],
        ),
      ),
    );
  }
}