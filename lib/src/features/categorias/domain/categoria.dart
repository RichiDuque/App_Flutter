class Categoria {
  final int id;
  final String uuid;
  final String nombre;
  final String? descripcion;

  Categoria({
    required this.id,
    required this.uuid,
    required this.nombre,
    this.descripcion,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as int,
      uuid: json['uuid'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Sin nombre',
      descripcion: json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}
