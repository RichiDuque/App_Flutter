class Descuento {
  final int id;
  final String uuid;
  final String nombre;
  final double porcentaje;

  Descuento({
    required this.id,
    required this.uuid,
    required this.nombre,
    required this.porcentaje,
  });

  factory Descuento.fromJson(Map<String, dynamic> json) {
    return Descuento(
      id: _parseInt(json['id']),
      uuid: json['uuid'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      porcentaje: _parseDouble(json['porcentaje']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'nombre': nombre,
      'porcentaje': porcentaje,
    };
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
}