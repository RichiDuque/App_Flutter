import 'package:flutter/foundation.dart' show kIsWeb;

class Env {
  // URL base de la API
  // Usa el backend desplegado en Render
  static String get apiBaseUrl {
    // Producción: Backend en Render
    return 'https://facturacion-backend-fdj0.onrender.com/api';

    // Desarrollo local (descomenta para usar localhost):
    // if (kIsWeb) {
    //   return 'http://localhost:4000/api';
    // } else {
    //   return 'http://192.168.0.107:4000/api';
    // }
  }

  // Timeout de conexion en segundos
  static const int connectTimeout = 8;
  static const int receiveTimeout = 8;

  // Keys para almacenamiento seguro
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}