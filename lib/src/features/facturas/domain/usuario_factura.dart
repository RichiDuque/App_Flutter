class UsuarioFactura {
  final int id;
  final String nombre;
  final String email;
  final String rol;

  UsuarioFactura({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory UsuarioFactura.fromJson(Map<String, dynamic> json) {
    return UsuarioFactura(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: json['rol'] ?? json['role'] ?? 'vendedor',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
    };
  }
}