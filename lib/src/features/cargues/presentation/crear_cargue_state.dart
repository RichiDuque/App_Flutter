import 'package:flutter_riverpod/flutter_riverpod.dart';

// Estado para mantener los productos seleccionados entre cambios de tab
final productosSeleccionadosProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// Estado para el comentario del cargue
final comentarioCargueProvider = StateProvider<String>((ref) => '');