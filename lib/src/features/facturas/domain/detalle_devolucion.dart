class DetalleDevolucion {
  final int id;
  final int devolucionId;
  final int productoId;
  final String? productoNombre;
  final String? productoDescripcion;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleDevolucion({
    required this.id,
    required this.devolucionId,
    required this.productoId,
    this.productoNombre,
    this.productoDescripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleDevolucion.fromJson(Map<String, dynamic> json) {
    // Extraer nombre del producto desde el objeto anidado Producto
    String? productoNombre;
    String? productoDescripcion;
    if (json['Producto'] != null) {
      productoNombre = json['Producto']['nombre'] as String?;
      productoDescripcion = json['Producto']['descripcion'] as String?;
    }

    // Helper para convertir valores que pueden ser string o número
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return DetalleDevolucion(
      id: json['id'] as int,
      devolucionId: json['devolucion_id'] as int,
      productoId: json['producto_id'] as int,
      productoNombre: productoNombre,
      productoDescripcion: productoDescripcion,
      cantidad: parseInt(json['cantidad']),
      precioUnitario: parseDouble(json['precio_unitario']),
      subtotal: parseDouble(json['subtotal']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'devolucion_id': devolucionId,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'producto_descripcion': productoDescripcion,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }
}