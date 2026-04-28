class Vendedor {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final int? listaPreciosId;

  Vendedor({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.listaPreciosId,
  });

  factory Vendedor.fromJson(Map<String, dynamic> json) {
    return Vendedor(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? 'vendedor',
      listaPreciosId: json['lista_precios_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'lista_precios_id': listaPreciosId,
    };
  }

  Vendedor copyWith({
    int? id,
    String? nombre,
    String? email,
    String? rol,
    int? listaPreciosId,
  }) {
    return Vendedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      listaPreciosId: listaPreciosId ?? this.listaPreciosId,
    );
  }
}
