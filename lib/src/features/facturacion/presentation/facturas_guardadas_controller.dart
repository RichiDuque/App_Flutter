import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/factura_guardada.dart';

const String _kFacturasGuardadasKey = 'facturas_guardadas';

final facturasGuardadasControllerProvider =
    StateNotifierProvider<FacturasGuardadasController, List<FacturaGuardada>>(
        (ref) {
  return FacturasGuardadasController();
});

class FacturasGuardadasController extends StateNotifier<List<FacturaGuardada>> {
  FacturasGuardadasController() : super([]) {
    _cargarFacturas();
  }

  Future<void> _cargarFacturas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kFacturasGuardadasKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        state = jsonList
            .map((json) => FacturaGuardada.fromJson(json))
            .toList();
      }
    } catch (e) {
      // Error al cargar, mantener lista vacía
      state = [];
    }
  }

  Future<void> _guardarEnStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((factura) => factura.toJson()).toList();
      await prefs.setString(_kFacturasGuardadasKey, json.encode(jsonList));
    } catch (e) {
      // Error al guardar
    }
  }

  Future<void> agregarFactura(FacturaGuardada factura) async {
    state = [...state, factura];
    await _guardarEnStorage();
  }

  Future<void> eliminarFactura(String id) async {
    state = state.where((factura) => factura.id != id).toList();
    await _guardarEnStorage();
  }

  Future<void> actualizarFactura(FacturaGuardada factura) async {
    final index = state.indexWhere((f) => f.id == factura.id);
    if (index >= 0) {
      final newList = List<FacturaGuardada>.from(state);
      newList[index] = factura;
      state = newList;
      await _guardarEnStorage();
    }
  }
}