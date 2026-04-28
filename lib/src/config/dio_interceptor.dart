import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/auth/presentation/auth_controller.dart';

/// Interceptor para detectar cuando el usuario está inactivo
/// y cerrar su sesión automáticamente
class InactiveUserInterceptor extends Interceptor {
  final Ref ref;

  InactiveUserInterceptor(this.ref);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Verificar si el error es 403 (Forbidden) con indicador de cuenta inactiva
    if (err.response?.statusCode == 403) {
      final data = err.response?.data;

      // Verificar si el backend indicó que la cuenta está inactiva
      if (data is Map<String, dynamic> && data['inactive'] == true) {
        // Cerrar sesión automáticamente
        ref.read(authControllerProvider.notifier).logout();

        // Puedes mostrar un mensaje al usuario si lo deseas
        print('⚠️ Cuenta deshabilitada - cerrando sesión automáticamente');
      }
    }

    // Continuar con el manejo normal del error
    super.onError(err, handler);
  }
}