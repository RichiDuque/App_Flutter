class MiembroEquipo {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final DateTime? fechaAsignacion;
  final List<String>? equipos; // Para el endpoint de compañeros

  MiembroEquipo({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.fechaAsignacion,
    this.equipos,
  });

  factory MiembroEquipo.fromJson(Map<String, dynamic> json) {
    // Manejar la fecha de asignación que puede venir en diferentes formatos
    DateTime? fechaAsig;
    try {
      // Intentar obtener de UsuarioEquipos primero (cuando viene de equipos/:id/miembros)
      if (json['UsuarioEquipos'] != null) {
        final usuarioEquipos = json['UsuarioEquipos'];
        if (usuarioEquipos is Map<String, dynamic> &&
            usuarioEquipos['fecha_asignacion'] != null) {
          final fechaValue = usuarioEquipos['fecha_asignacion'];
          if (fechaValue is String) {
            fechaAsig = DateTime.parse(fechaValue);
          }
        }
      }
      // Si no viene en UsuarioEquipos, intentar del nivel raíz
      if (fechaAsig == null && json['fecha_asignacion'] != null) {
        final fechaValue = json['fecha_asignacion'];
        if (fechaValue is String) {
          fechaAsig = DateTime.parse(fechaValue);
        }
      }
    } catch (e) {
      // Si hay error parseando la fecha, simplemente la dejamos como null
      print('Error parseando fecha_asignacion: $e');
      fechaAsig = null;
    }

    // Manejar equipos (para el endpoint de compañeros)
    List<String>? equiposList;
    try {
      if (json['equipos'] != null && json['equipos'] is List) {
        equiposList = (json['equipos'] as List)
            .where((e) => e != null && e is Map<String, dynamic>)
            .map((e) => (e as Map<String, dynamic>)['nombre']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('Error parseando equipos: $e');
      equiposList = null;
    }

    // Parsear id de manera segura
    int id;
    if (json['id'] is int) {
      id = json['id'] as int;
    } else if (json['id'] is String) {
      id = int.parse(json['id'] as String);
    } else {
      throw Exception('Campo id inválido en JSON de MiembroEquipo');
    }

    return MiembroEquipo(
      id: id,
      nombre: json['nombre']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      rol: json['rol']?.toString() ?? 'vendedor',
      fechaAsignacion: fechaAsig,
      equipos: equiposList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      if (fechaAsignacion != null)
        'fecha_asignacion': fechaAsignacion!.toIso8601String(),
    };
  }
}