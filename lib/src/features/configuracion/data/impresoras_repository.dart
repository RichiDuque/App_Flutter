import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/impresora.dart';

class ImpresorasRepository {
  static const String _keyImpresoras = 'impresoras';

  final SharedPreferences _prefs;

  ImpresorasRepository(this._prefs);

  // Obtener todas las impresoras
  Future<List<Impresora>> obtenerImpresoras() async {
    try {
      final String? impresorasJson = _prefs.getString(_keyImpresoras);

      if (impresorasJson == null || impresorasJson.isEmpty) {
        return [];
      }

      final List<dynamic> impresorasList = json.decode(impresorasJson) as List<dynamic>;
      return impresorasList
          .map((json) => Impresora.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Guardar impresora
  Future<void> guardarImpresora(Impresora impresora) async {
    try {
      final impresoras = await obtenerImpresoras();

      // Buscar si ya existe
      final index = impresoras.indexWhere((i) => i.id == impresora.id);

      if (index != -1) {
        // Actualizar existente
        impresoras[index] = impresora;
      } else {
        // Agregar nueva
        impresoras.add(impresora);
      }

      // Guardar en preferences
      final impresorasJson = json.encode(
        impresoras.map((i) => i.toJson()).toList(),
      );
      await _prefs.setString(_keyImpresoras, impresorasJson);
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar impresora
  Future<void> eliminarImpresora(String id) async {
    try {
      final impresoras = await obtenerImpresoras();
      impresoras.removeWhere((i) => i.id == id);

      final impresorasJson = json.encode(
        impresoras.map((i) => i.toJson()).toList(),
      );
      await _prefs.setString(_keyImpresoras, impresorasJson);
    } catch (e) {
      rethrow;
    }
  }

  // Obtener impresora por defecto para recibos
  Future<Impresora?> obtenerImpresoraRecibos() async {
    try {
      final impresoras = await obtenerImpresoras();

      // Buscar la primera impresora marcada para imprimir recibos
      final impresoraRecibos = impresoras.where((i) => i.imprimirRecibos).toList();

      if (impresoraRecibos.isNotEmpty) {
        return impresoraRecibos.first;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Establecer impresora por defecto para recibos
  Future<void> establecerImpresoraRecibos(String id) async {
    try {
      final impresoras = await obtenerImpresoras();

      // Desmarcar todas las impresoras
      for (var i = 0; i < impresoras.length; i++) {
        if (impresoras[i].id == id) {
          impresoras[i] = impresoras[i].copyWith(imprimirRecibos: true);
        } else {
          impresoras[i] = impresoras[i].copyWith(imprimirRecibos: false);
        }
      }

      // Guardar cambios
      final impresorasJson = json.encode(
        impresoras.map((i) => i.toJson()).toList(),
      );
      await _prefs.setString(_keyImpresoras, impresorasJson);
    } catch (e) {
      rethrow;
    }
  }

  // Limpiar todas las impresoras
  Future<void> limpiarImpresoras() async {
    await _prefs.remove(_keyImpresoras);
  }
}