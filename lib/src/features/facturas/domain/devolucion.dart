import 'detalle_devolucion.dart';

class Devolucion {
  final int id;
  final String uuid;
  final int clienteId;
  final String? clienteNombre;
  final int usuarioId;
  final String? usuarioNombre;
  final int facturaId;
  final String? facturaNumero;
  final double? facturaTotal;
  final String motivo;
  final double total;
  final DateTime fecha;
  final List<DetalleDevolucion> detalles;

  Devolucion({
    required this.id,
    required this.uuid,
    required this.clienteId,
    this.clienteNombre,
    required this.usuarioId,
    this.usuarioNombre,
    required this.facturaId,
    this.facturaNumero,
    this.facturaTotal,
    required this.motivo,
    required this.total,
    required this.fecha,
    this.detalles = const [],
  });

  factory Devolucion.fromJson(Map<String, dynamic> json) {
    // Helper para convertir valores que pueden ser string o número
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Extraer nombre del cliente desde el objeto anidado Cliente
    String? clienteNombre;
    if (json['Cliente'] != null) {
      clienteNombre = json['Cliente']['nombre'] as String?;
    }

    // Extraer nombre del usuario desde el objeto anidado Usuario
    String? usuarioNombre;
    if (json['Usuario'] != null) {
      usuarioNombre = json['Usuario']['nombre'] as String?;
    }

    // Extraer información de la factura desde el objeto anidado Factura
    String? facturaNumero;
    double? facturaTotal;
    if (json['Factura'] != null) {
      facturaNumero = json['Factura']['numero_factura'] as String?;
      facturaTotal = parseDouble(json['Factura']['total']);
    }

    // Parsear detalles de devolución
    List<DetalleDevolucion> detalles = [];
    if (json['detalles'] != null && json['detalles'] is List) {
      detalles = (json['detalles'] as List)
          .map((detJson) => DetalleDevolucion.fromJson(detJson as Map<String, dynamic>))
          .toList();
    }

    return Devolucion(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      clienteId: json['cliente_id'] as int,
      clienteNombre: clienteNombre,
      usuarioId: json['usuario_id'] as int,
      usuarioNombre: usuarioNombre,
      facturaId: json['factura_id'] as int,
      facturaNumero: facturaNumero,
      facturaTotal: facturaTotal,
      motivo: json['motivo'] ?? '',
      total: parseDouble(json['total']),
      fecha: DateTime.parse(json['fecha'] as String),
      detalles: detalles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'cliente_id': clienteId,
      'cliente_nombre': clienteNombre,
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
      'factura_id': facturaId,
      'motivo': motivo,
      'total': total,
      'fecha': fecha.toIso8601String(),
    };
  }
}