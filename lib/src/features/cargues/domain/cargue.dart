import 'detalle_cargue.dart';
import '../../usuarios/domain/vendedor.dart';

class Cargue {
  final int id;
  final String uuid;
  final String? numeroCargue;
  final int usuarioId;
  final DateTime fecha;
  final double total;
  final String estado; // 'pendiente', 'en_progreso', 'realizado'
  final String? comentario;
  final Vendedor? usuario;
  final List<DetalleCargue> detalles;

  Cargue({
    required this.id,
    required this.uuid,
    this.numeroCargue,
    required this.usuarioId,
    required this.fecha,
    required this.total,
    required this.estado,
    this.comentario,
    this.usuario,
    this.detalles = const [],
  });

  factory Cargue.fromJson(Map<String, dynamic> json) {
    // Buscar el usuario en cualquier variante (mayúscula o minúscula)
    final usuarioData = json['Usuario'] ?? json['usuario'] ?? json['User'] ?? json['user'];

    return Cargue(
      id: json['id'] as int,
      uuid: json['uuid'] as String? ?? 'cargue-${json['id']}',
      numeroCargue: json['numero_cargue'] as String?,
      usuarioId: json['usuario_id'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      estado: json['estado'] as String? ?? 'pendiente',
      comentario: json['comentario'] as String?,
      usuario: usuarioData != null
          ? Vendedor.fromJson(usuarioData)
          : null,
      detalles: json['detalles'] != null
          ? (json['detalles'] as List)
              .map((detalle) => DetalleCargue.fromJson(detalle))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'numero_cargue': numeroCargue,
      'usuario_id': usuarioId,
      'fecha': fecha.toIso8601String(),
      'total': total,
      'estado': estado,
      'comentario': comentario,
      'detalles': detalles.map((d) => d.toJson()).toList(),
    };
  }

  Cargue copyWith({
    int? id,
    String? uuid,
    String? numeroCargue,
    int? usuarioId,
    DateTime? fecha,
    double? total,
    String? estado,
    String? comentario,
    Vendedor? usuario,
    List<DetalleCargue>? detalles,
  }) {
    return Cargue(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      numeroCargue: numeroCargue ?? this.numeroCargue,
      usuarioId: usuarioId ?? this.usuarioId,
      fecha: fecha ?? this.fecha,
      total: total ?? this.total,
      estado: estado ?? this.estado,
      comentario: comentario ?? this.comentario,
      usuario: usuario ?? this.usuario,
      detalles: detalles ?? this.detalles,
    );
  }

  String get estadoTexto {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_progreso':
        return 'En Progreso';
      case 'realizado':
        return 'Realizado';
      default:
        return estado;
    }
  }

  bool get isPendiente => estado == 'pendiente';
  bool get isEnProgreso => estado == 'en_progreso';
  bool get isRealizado => estado == 'realizado';
}