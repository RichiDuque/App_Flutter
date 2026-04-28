import 'factura_item.dart';
import '../../productos/domain/producto.dart';

class FacturaGuardada {
  final String id;
  final List<FacturaItem> items;
  final int? clienteId;
  final String? clienteNombre;
  final int? descuentoId;
  final double total;
  final DateTime fechaCreacion;

  FacturaGuardada({
    required this.id,
    required this.items,
    this.clienteId,
    this.clienteNombre,
    this.descuentoId,
    required this.total,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => {
        'producto_id': item.producto.id,
        'producto_uuid': item.producto.uuid,
        'producto_nombre': item.producto.nombre,
        'producto_descripcion': item.producto.descripcion,
        'producto_precio': item.producto.precio,
        'producto_stock': item.producto.stock,
        'producto_categoria_id': item.producto.categoriaId,
        'cantidad': item.cantidad,
        'precio_unitario': item.precioUnitario,
        'comentario': item.comentario,
      }).toList(),
      'cliente_id': clienteId,
      'cliente_nombre': clienteNombre,
      'descuento_id': descuentoId,
      'total': total,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory FacturaGuardada.fromJson(Map<String, dynamic> json) {
    return FacturaGuardada(
      id: json['id'] as String,
      items: (json['items'] as List).map((item) {
        // Reconstruir el producto desde los datos guardados
        final producto = Producto(
          id: item['producto_id'] as int,
          uuid: item['producto_uuid'] as String? ?? '',
          nombre: item['producto_nombre'] as String,
          descripcion: item['producto_descripcion'] as String?,
          precio: (item['producto_precio'] as num).toDouble(),
          stock: item['producto_stock'] as int? ?? 0,
          categoriaId: item['producto_categoria_id'] as int?,
        );

        return FacturaItem(
          producto: producto,
          cantidad: item['cantidad'] as int,
          precioUnitario: (item['precio_unitario'] as num).toDouble(),
          comentario: item['comentario'] as String?,
        );
      }).toList(),
      clienteId: json['cliente_id'] as int?,
      clienteNombre: json['cliente_nombre'] as String?,
      descuentoId: json['descuento_id'] as int?,
      total: (json['total'] as num).toDouble(),
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
    );
  }
}