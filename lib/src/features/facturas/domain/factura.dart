import 'devolucion.dart';

class Factura {
  final int id;
  final String uuid;
  final int clienteId;
  final String? clienteNombre;
  final int usuarioId;
  final String? usuarioNombre;
  final String? numeroFactura; // Formato: "1-00001"
  final double subtotal;
  final double descuento;
  final double total;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  final List<Devolucion> devoluciones;

  Factura({
    required this.id,
    required this.uuid,
    required this.clienteId,
    this.clienteNombre,
    required this.usuarioId,
    this.usuarioNombre,
    this.numeroFactura,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.estado,
    required this.fechaCreacion,
    this.fechaActualizacion,
    this.devoluciones = const [],
  });

  /// Obtiene el número de factura formateado o genera uno temporal
  /// Formato: "USUARIO_ID-NUMERO" (ej: "1-00001")
  String get numeroFormateado {
    if (numeroFactura != null && numeroFactura!.isNotEmpty) {
      return numeroFactura!;
    }
    // Si no hay número de factura del backend, generar temporal
    return '$usuarioId-${id.toString().padLeft(5, '0')}';
  }

  factory Factura.fromJson(Map<String, dynamic> json) {
    // Extraer nombre del cliente desde el objeto anidado Cliente
    String? clienteNombre;
    if (json['Cliente'] != null) {
      clienteNombre = json['Cliente']['nombre_establecimiento'] as String? ??
                      json['Cliente']['nombre'] as String?;
    }

    // Extraer nombre del usuario desde el objeto anidado Usuario
    String? usuarioNombre;
    if (json['Usuario'] != null) {
      usuarioNombre = json['Usuario']['nombre'] as String?;
    }

    // Helper para convertir valores que pueden ser string o número
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Calcular subtotal y descuento
    final total = parseDouble(json['total']);
    double subtotal = total;
    double descuentoMonto = 0.0;

    // Si hay descuento, calcular el subtotal antes del descuento
    if (json['Descuento'] != null && json['Descuento']['porcentaje'] != null) {
      final porcentaje = parseDouble(json['Descuento']['porcentaje']);
      // total = subtotal * (1 - porcentaje/100)
      // subtotal = total / (1 - porcentaje/100)
      if (porcentaje > 0) {
        subtotal = total / (1 - porcentaje / 100);
        descuentoMonto = subtotal - total;
      }
    }

    // Parsear devoluciones
    List<Devolucion> devoluciones = [];
    if (json['devoluciones'] != null && json['devoluciones'] is List) {
      devoluciones = (json['devoluciones'] as List)
          .map((devJson) => Devolucion.fromJson(devJson as Map<String, dynamic>))
          .toList();
    }

    return Factura(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      clienteId: json['cliente_id'] as int,
      clienteNombre: clienteNombre,
      usuarioId: json['usuario_id'] as int,
      usuarioNombre: usuarioNombre,
      numeroFactura: json['numero_factura'] as String?,
      subtotal: subtotal,
      descuento: descuentoMonto,
      total: total,
      estado: json['estado'] ?? 'completada',
      fechaCreacion: DateTime.parse(json['fecha'] as String),
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'] as String)
          : null,
      devoluciones: devoluciones,
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
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
    };
  }
}