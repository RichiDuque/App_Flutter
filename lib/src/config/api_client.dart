import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'env.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: Duration(seconds: Env.connectTimeout),
      receiveTimeout: Duration(seconds: Env.receiveTimeout),
    ),
  );

  static final storage = const FlutterSecureStorage();
  static Function()? onUnauthorized;

  static void setupInterceptors({Function()? onUnauthorizedCallback}) {
    onUnauthorized = onUnauthorizedCallback;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: Env.tokenKey);

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Manejar errores de autenticación (401) o acceso prohibido (403)
          if (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403) {
            // Usuario no autenticado o deshabilitado
            await storage.delete(key: Env.tokenKey);

            // Llamar callback para cerrar sesión
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }
}