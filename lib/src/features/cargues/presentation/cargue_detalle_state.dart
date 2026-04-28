import 'package:flutter_riverpod/flutter_riverpod.dart';

// Estado para mantener los checks de despachado entre cambios de pantalla
final detallesDespachosProvider =
    StateProvider.family<Map<int, bool>, int>((ref, cargueId) => {});

// Estado para mantener los checks de faltantes entre cambios de pantalla
final detallesFaltantesProvider =
    StateProvider.family<Map<int, bool>, int>((ref, cargueId) => {});

// Estado para mantener las cantidades modificadas por el admin
final detallesCantidadesProvider =
    StateProvider.family<Map<int, int>, int>((ref, cargueId) => {});