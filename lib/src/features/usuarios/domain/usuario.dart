class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final int? listaPreciosId;
  final bool activo;
  final DateTime? createdAt;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.listaPreciosId,
    this.activo = true,
    this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? 'vendedor',
      listaPreciosId: json['lista_precios_id'] as int?,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'lista_precios_id': listaPreciosId,
      'activo': activo,
    };
  }

  Usuario copyWith({
    int? id,
    String? nombre,
    String? email,
    String? rol,
    int? listaPreciosId,
    bool? activo,
    DateTime? createdAt,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      listaPreciosId: listaPreciosId ?? this.listaPreciosId,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get rolDisplay {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'vendedor':
        return 'Vendedor';
      default:
        return rol;
    }
  }

  String get estadoDisplay => activo ? 'Activo' : 'Inactivo';
}