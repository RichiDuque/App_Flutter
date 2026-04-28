import '../../productos/domain/producto.dart';

class DetalleCargue {
  final int id;
  final String uuid;
  final int cargueId;
  final int productoId;
  final int cantidad;
  final int? cantidadOriginal;
  final double precioUnitario;
  final double subtotal;
  final String? comentario;
  final bool despachado;
  final bool faltante;
  final Producto? producto;

  DetalleCargue({
    required this.id,
    required this.uuid,
    required this.cargueId,
    required this.productoId,
    required this.cantidad,
    this.cantidadOriginal,
    required this.precioUnitario,
    required this.subtotal,
    this.comentario,
    this.despachado = false,
    this.faltante = false,
    this.producto,
  });

  factory DetalleCargue.fromJson(Map<String, dynamic> json) {
    return DetalleCargue(
      id: json['id'] as int,
      uuid: json['uuid'] as String? ?? '',
      cargueId: json['cargue_id'] as int,
      productoId: json['producto_id'] as int,
      cantidad: json['cantidad'] as int,
      cantidadOriginal: json['cantidad_original'] as int?,
      precioUnitario: double.tryParse(json['precio_unitario'].toString()) ?? 0.0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      comentario: json['comentario'] as String?,
      despachado: json['despachado'] as bool? ?? false,
      faltante: json['faltante'] as bool? ?? false,
      producto: json['Producto'] != null
          ? Producto.fromJson(json['Producto'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'cargue_id': cargueId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'comentario': comentario,
      'despachado': despachado,
      'faltante': faltante,
    };
  }

  DetalleCargue copyWith({
    int? id,
    String? uuid,
    int? cargueId,
    int? productoId,
    int? cantidad,
    int? cantidadOriginal,
    double? precioUnitario,
    double? subtotal,
    String? comentario,
    bool? despachado,
    bool? faltante,
    Producto? producto,
  }) {
    return DetalleCargue(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      cargueId: cargueId ?? this.cargueId,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      cantidadOriginal: cantidadOriginal ?? this.cantidadOriginal,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? this.subtotal,
      comentario: comentario ?? this.comentario,
      despachado: despachado ?? this.despachado,
      faltante: faltante ?? this.faltante,
      producto: producto ?? this.producto,
    );
  }
}