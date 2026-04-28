import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../config/env.dart';
import 'cargues_polling_service.dart';

/// Provider que inicializa el polling cuando el usuario inicia sesión
final pollingInitializerProvider = Provider<void>((ref) {
  final authState = ref.watch(authControllerProvider);
  final pollingService = CarguesPollingService();

  // Solo iniciar si el usuario está autenticado y es admin
  if (authState.userId != null && authState.role == 'admin') {
    pollingService.initialize(
      baseUrl: Env.apiBaseUrl,
      token: authState.token,
      userId: authState.userId,
      userRole: authState.role,
    );
  } else {
    // Si no es admin o no está autenticado, detener polling
    pollingService.stop();
  }
});
