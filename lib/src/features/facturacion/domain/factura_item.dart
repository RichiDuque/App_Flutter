import '../../productos/domain/producto.dart';

class FacturaItem {
  final Producto producto;
  int cantidad;
  final double precioUnitario;
  String? comentario;

  FacturaItem({
    required this.producto,
    this.cantidad = 1,
    required this.precioUnitario,
    this.comentario,
  });

  double get subtotal => precioUnitario * cantidad;

  Map<String, dynamic> toJson() {
    return {
      'producto_id': producto.id,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'comentario': comentario ?? '',
    };
  }

  FacturaItem copyWith({
    Producto? producto,
    int? cantidad,
    double? precioUnitario,
    String? comentario,
  }) {
    return FacturaItem(
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      comentario: comentario ?? this.comentario,
    );
  }
}