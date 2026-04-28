import 'package:dio/dio.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(String baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            "Content-Type": "application/json",
          },
        ));

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/auth/login",
        data: {
          "email": email,
          "password": password,
        },
      );

      return response.data; // debería contener token + user
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ------------------------------------------------------------
  // VALIDAR TOKEN (opcional para carga inicial de la app)
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> validateToken(String token) async {
    try {
      final response = await _dio.get(
        "/auth/validate",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ------------------------------------------------------------
  // LOGOUT (si usas backend con invalidación de tokens)
  // ------------------------------------------------------------
  Future<void> logout(String token) async {
    try {
      await _dio.post(
        "/auth/logout",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ------------------------------------------------------------
  // Error handler elegante y claro
  // ------------------------------------------------------------
  Exception _handleError(DioException e) {
    if (e.response != null) {
      return Exception(
          e.response?.data["message"] ?? "Error desconocido en el servidor");
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception("No hay conexión con el servidor");
    }

    if (e.type == DioExceptionType.connectionTimeout) {
      return Exception("Tiempo de espera agotado");
    }

    return Exception("Error inesperado");
  }
}