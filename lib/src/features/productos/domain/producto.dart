class Producto {
  final int id;
  final String uuid;
  final String nombre;
  final String? descripcion;
  final String? codigoBarras;
  final double precio;
  final int stock;
  final int? categoriaId;
  final String? imagenUrl;

  Producto({
    required this.id,
    required this.uuid,
    required this.nombre,
    this.descripcion,
    this.codigoBarras,
    required this.precio,
    required this.stock,
    this.categoriaId,
    this.imagenUrl,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: _parseInt(json['id']),
      uuid: json['uuid'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Sin nombre',
      descripcion: json['descripcion'] as String?,
      codigoBarras: json['codigo_barras'] as String?,
      precio: _parseDouble(json['precio']),
      stock: _parseInt(json['stock']),
      categoriaId: json['categoria_id'] as int?,
      imagenUrl: json['imagen_url'] as String?,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Devuelve la URL de imagen en formato directo para mostrar en la app.
  /// Si es una URL de Google Drive con formato /view, la convierte al formato uc?export=view.
  String? get imagenUrlDirecta {
    if (imagenUrl == null || imagenUrl!.isEmpty) return null;

    // Detectar URLs de Google Drive tipo: /file/d/{ID}/view
    final driveRegex = RegExp(r'drive\.google\.com/file/d/([^/]+)');
    final match = driveRegex.firstMatch(imagenUrl!);
    if (match != null) {
      final fileId = match.group(1)!;
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }

    return imagenUrl;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'nombre': nombre,
      'descripcion': descripcion,
      'codigo_barras': codigoBarras,
      'precio': precio,
      'stock': stock,
      'categoria_id': categoriaId,
      'imagen_url': imagenUrl,
    };
  }
}