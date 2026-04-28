class ListaPrecio {
  final int id;
  final String uuid;
  final String nombre;

  ListaPrecio({
    required this.id,
    required this.uuid,
    required this.nombre,
  });

  factory ListaPrecio.fromJson(Map<String, dynamic> json) {
    return ListaPrecio(
      id: json['id'] as int,
      uuid: json['uuid'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Sin nombre',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'nombre': nombre,
    };
  }
}