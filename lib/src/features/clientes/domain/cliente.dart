class Cliente {
  final int id;
  final String uuid;
  final String nombreEstablecimiento;
  final String? propietario;
  final String? email;
  final String? telefono;
  final String? direccion;
  final String? ciudad;
  final String? departamento;
  final String? codigoPostal;
  final String? pais;
  final String? codigoCliente;
  final String? nota;
  final int puntos;
  final int visitas;
  final int? listaId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cliente({
    required this.id,
    required this.uuid,
    required this.nombreEstablecimiento,
    this.propietario,
    this.email,
    this.telefono,
    this.direccion,
    this.ciudad,
    this.departamento,
    this.codigoPostal,
    this.pais,
    this.codigoCliente,
    this.nota,
    required this.puntos,
    required this.visitas,
    this.listaId,
    this.createdAt,
    this.updatedAt,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      uuid: json['uuid'],
      nombreEstablecimiento: json['nombre_establecimiento'] ?? json['nombre'] ?? '',
      propietario: json['propietario'],
      email: json['email'],
      telefono: json['telefono'],
      direccion: json['direccion'],
      ciudad: json['ciudad'],
      departamento: json['departamento'],
      codigoPostal: json['codigo_postal'],
      pais: json['pais'],
      codigoCliente: json['codigo_cliente'],
      nota: json['nota'],
      puntos: json['puntos'] ?? 0,
      visitas: json['visitas'] ?? 0,
      listaId: json['lista_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'nombre_establecimiento': nombreEstablecimiento,
      'propietario': propietario,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'ciudad': ciudad,
      'departamento': departamento,
      'codigo_postal': codigoPostal,
      'pais': pais,
      'codigo_cliente': codigoCliente,
      'nota': nota,
      'puntos': puntos,
      'visitas': visitas,
      'lista_id': listaId,
    };
  }

  // Helper method para obtener dirección completa
  String get direccionCompleta {
    final partes = <String>[];
    if (direccion != null && direccion!.isNotEmpty) partes.add(direccion!);
    if (ciudad != null && ciudad!.isNotEmpty) partes.add(ciudad!);
    if (departamento != null && departamento!.isNotEmpty) partes.add(departamento!);
    if (codigoPostal != null && codigoPostal!.isNotEmpty) partes.add(codigoPostal!);
    if (pais != null && pais!.isNotEmpty) partes.add(pais!);
    return partes.join(', ');
  }

  // Helper method para obtener iniciales del nombre
  String get iniciales {
    final palabras = nombreEstablecimiento.trim().split(' ');
    if (palabras.isEmpty) return '';
    if (palabras.length == 1) {
      return palabras[0][0].toUpperCase();
    }
    return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
  }

  // Helper para obtener nombre a mostrar
  String get nombreCompleto {
    if (propietario != null && propietario!.isNotEmpty) {
      return '$nombreEstablecimiento - $propietario';
    }
    return nombreEstablecimiento;
  }
}
