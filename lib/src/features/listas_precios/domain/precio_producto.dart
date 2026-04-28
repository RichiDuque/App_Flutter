class PrecioProducto {
  final int? id;
  final String? uuid;
  final int productoId;
  final int listaId;
  final double precio;

  PrecioProducto({
    this.id,
    this.uuid,
    required this.productoId,
    required this.listaId,
    required this.precio,
  });

  factory PrecioProducto.fromJson(Map<String, dynamic> json) {
    return PrecioProducto(
      id: json['id'] as int?,
      uuid: json['uuid'] as String?,
      productoId: json['producto_id'] as int,
      listaId: json['lista_id'] as int,
      precio: _parseDouble(json['precio']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      'producto_id': productoId,
      'lista_id': listaId,
      'precio': precio,
    };
  }
}