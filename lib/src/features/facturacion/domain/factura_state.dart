import 'factura_item.dart';

class FacturaState {
  final List<FacturaItem> items;
  final int? clienteId;
  final int? descuentoId;
  final bool isLoading;
  final String? error;

  FacturaState({
    this.items = const [],
    this.clienteId,
    this.descuentoId,
    this.isLoading = false,
    this.error,
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Método para calcular el total con descuento
  double totalConDescuento(double porcentajeDescuento) {
    final descuentoMonto = subtotal * (porcentajeDescuento / 100);
    return subtotal - descuentoMonto;
  }

  // Método para calcular el monto del descuento
  double montoDescuento(double porcentajeDescuento) {
    return subtotal * (porcentajeDescuento / 100);
  }

  // Total sin descuento (para compatibilidad)
  double get total => subtotal;

  int get cantidadProductos {
    return items.fold(0, (sum, item) => sum + item.cantidad);
  }

  bool get isEmpty => items.isEmpty;

  FacturaState copyWith({
    List<FacturaItem>? items,
    Object? clienteId = _undefined,
    Object? descuentoId = _undefined,
    bool? isLoading,
    String? error,
  }) {
    return FacturaState(
      items: items ?? this.items,
      clienteId: clienteId == _undefined ? this.clienteId : clienteId as int?,
      descuentoId: descuentoId == _undefined ? this.descuentoId : descuentoId as int?,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  FacturaState clearError() {
    return copyWith(error: null);
  }

  Map<String, dynamic> toJson(int usuarioId, {double porcentajeDescuento = 0.0}) {
    final descuentoMonto = montoDescuento(porcentajeDescuento);
    final totalFinal = totalConDescuento(porcentajeDescuento);

    return {
      'cliente_id': clienteId,
      'usuario_id': usuarioId,
      'descuento_id': descuentoId,
      'subtotal': subtotal,
      'descuento': descuentoMonto,
      'total': totalFinal,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

// Constante privada para distinguir entre "no cambiar" y "cambiar a null"
const _undefined = Object();