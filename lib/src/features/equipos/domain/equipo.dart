class Equipo {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final int? cantidadMiembros;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Equipo({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activo,
    this.cantidadMiembros,
    this.createdAt,
    this.updatedAt,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool? ?? true,
      cantidadMiembros: json['cantidad_miembros'] != null
          ? int.tryParse(json['cantidad_miembros'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
    };
  }

  Equipo copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    bool? activo,
    int? cantidadMiembros,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Equipo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      cantidadMiembros: cantidadMiembros ?? this.cantidadMiembros,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}