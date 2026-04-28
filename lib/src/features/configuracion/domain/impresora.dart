class Impresora {
  final String id;
  final String nombre;
  final String modelo;
  final String interfaz; // 'Bluetooth', 'USB', 'WiFi'
  final String? direccionBluetooth; // MAC address
  final int anchoPapel; // en mm: 58, 80
  final bool imprimirRecibos;

  const Impresora({
    required this.id,
    required this.nombre,
    required this.modelo,
    required this.interfaz,
    this.direccionBluetooth,
    required this.anchoPapel,
    this.imprimirRecibos = false,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'modelo': modelo,
      'interfaz': interfaz,
      'direccionBluetooth': direccionBluetooth,
      'anchoPapel': anchoPapel,
      'imprimirRecibos': imprimirRecibos,
    };
  }

  // Crear desde JSON
  factory Impresora.fromJson(Map<String, dynamic> json) {
    return Impresora(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      modelo: json['modelo'] as String,
      interfaz: json['interfaz'] as String,
      direccionBluetooth: json['direccionBluetooth'] as String?,
      anchoPapel: json['anchoPapel'] as int,
      imprimirRecibos: json['imprimirRecibos'] as bool? ?? false,
    );
  }

  // Copiar con modificaciones
  Impresora copyWith({
    String? id,
    String? nombre,
    String? modelo,
    String? interfaz,
    String? direccionBluetooth,
    int? anchoPapel,
    bool? imprimirRecibos,
  }) {
    return Impresora(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      modelo: modelo ?? this.modelo,
      interfaz: interfaz ?? this.interfaz,
      direccionBluetooth: direccionBluetooth ?? this.direccionBluetooth,
      anchoPapel: anchoPapel ?? this.anchoPapel,
      imprimirRecibos: imprimirRecibos ?? this.imprimirRecibos,
    );
  }

  String get modeloDisplay {
    switch (modelo) {
      case 'Otro modelo':
        return 'Genérica';
      default:
        return modelo;
    }
  }

  String get interfazDisplay {
    switch (interfaz) {
      case 'Bluetooth':
        return 'Bluetooth';
      case 'USB':
        return 'USB';
      case 'WiFi':
        return 'WiFi';
      default:
        return interfaz;
    }
  }

  String get anchoPapelDisplay {
    return '$anchoPapel mm';
  }
}