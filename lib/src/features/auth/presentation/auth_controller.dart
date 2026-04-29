import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/auth/domain/auth_repository.dart';
import 'package:facturacion_app/src/features/auth/domain/auth_state.dart';
import '../../../core/sync/sync_all_provider.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authRepositoryProvider), ref);
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._ref) : super(const AuthState()) {
    _loadStoredToken();
  }

  final AuthRepository _repo;
  final Ref _ref;

  Future<void> _loadStoredToken() async {
    state = state.copyWith(status: AuthStatus.loading);
    final token = await _repo.getStoredToken();

    if (token != null) {
      print('[AuthController] Token encontrado, intentando validar...');

      // Primero intentar cargar datos guardados localmente
      final storedUserData = await _repo.getStoredUserData();
      print('[AuthController] Datos locales: ${storedUserData != null ? "encontrados" : "no encontrados"}');

      if (storedUserData != null) {
        // Si hay datos locales, intentar validar el token con el servidor
        try {
          print('[AuthController] Validando token con servidor...');
          final data = await _repo.validateToken(token);
          print('[AuthController] Token validado exitosamente');

          // Token válido, actualizar con datos del servidor
          state = state.copyWith(
            status: AuthStatus.authenticated,
            token: token,
            user: data['user'] ?? data['nombre'],
            userId: data['id'],
            role: data['rol'] ?? data['role'] ?? 'vendedor',
            listaPreciosId: data['lista_precios_id'] ?? data['lista_id'],
          );
          _sincronizarDatosDespuesDeLogin();
        } catch (e) {
          // No hay conexión o token expirado
          // Usar datos locales para permitir acceso offline
          print('[AuthController] No se pudo validar token, usando datos locales: $e');
          state = state.copyWith(
            status: AuthStatus.authenticated,
            token: token,
            user: storedUserData['nombre'] ?? 'Usuario',
            userId: storedUserData['id'],
            role: storedUserData['rol'] ?? 'vendedor',
            listaPreciosId: storedUserData['lista_precios_id'],
          );
        }
      } else {
        // No hay datos locales, intentar validar con el servidor
        try {
          print('[AuthController] No hay datos locales, validando token con servidor...');
          final data = await _repo.validateToken(token);
          print('[AuthController] Token validado exitosamente, guardando datos...');

          // Guardar datos del usuario para la próxima vez
          if (data['user'] != null || data['nombre'] != null) {
            await _repo.saveUserData({
              'id': data['id'],
              'nombre': data['user'] ?? data['nombre'],
              'email': data['email'],
              'rol': data['rol'] ?? data['role'],
              'lista_precios_id': data['lista_precios_id'] ?? data['lista_id'],
            });
          }

          state = state.copyWith(
            status: AuthStatus.authenticated,
            token: token,
            user: data['user'] ?? data['nombre'],
            userId: data['id'],
            role: data['rol'] ?? data['role'] ?? 'vendedor',
            listaPreciosId: data['lista_precios_id'] ?? data['lista_id'],
          );
          _sincronizarDatosDespuesDeLogin();
        } catch (e) {
          // Token inválido y no hay datos locales, limpiar todo
          print('[AuthController] Token inválido y sin datos locales: $e');
          await _repo.clearToken();
          await _repo.clearUserData();
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      }
    } else {
      print('[AuthController] No hay token guardado');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    print('[AuthController.login] ===== INICIO LOGIN =====');
    print('[AuthController.login] Email: $email');
    print('[AuthController.login] Estado actual: ${state.status}');

    // Limpiar error anterior y cambiar a loading
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
    );

    print('[AuthController.login] Estado cambiado a loading');

    try {
      print('[AuthController.login] Llamando a _repo.login...');
      final response = await _repo.login(email: email, password: password);
      print('[AuthController.login] Respuesta recibida: ${response.keys}');

      final usuario = response['usuario'] ?? response['user'];
      print('[AuthController.login] Usuario extraído: ${usuario is Map ? usuario['nombre'] : usuario}');

      print('[AuthController.login] Login exitoso para: ${usuario is Map ? usuario['nombre'] : 'usuario'}');

      // Guardar datos del usuario para acceso offline
      if (usuario is Map) {
        await _repo.saveUserData({
          'id': usuario['id'],
          'nombre': usuario['nombre'],
          'email': usuario['email'],
          'rol': usuario['rol'] ?? usuario['role'],
          'lista_precios_id': usuario['lista_precios_id'] ?? usuario['lista_id'],
        });
      }

      print('[AuthController.login] Actualizando estado a authenticated');
      print('[AuthController.login] Token: ${response['token']?.substring(0, 10)}...');
      print('[AuthController.login] User: ${usuario is Map ? usuario['nombre'] : usuario}');
      print('[AuthController.login] Role: ${usuario is Map ? (usuario['rol'] ?? usuario['role']) : 'vendedor'}');

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: response['token'],
        user: usuario is Map ? usuario['nombre'] : usuario?.toString() ?? 'Usuario',
        userId: usuario is Map ? usuario['id'] : null,
        role: usuario is Map ? (usuario['rol'] ?? usuario['role'] ?? 'vendedor') : 'vendedor',
        listaPreciosId: usuario is Map ? (usuario['lista_precios_id'] ?? usuario['lista_id']) : null,
        clearError: true,
      );

      print('[AuthController.login] ===== LOGIN COMPLETADO EXITOSAMENTE =====');
      print('[AuthController.login] Estado final: ${state.status}');

      // Sincronizar datos automáticamente después del login
      _sincronizarDatosDespuesDeLogin();
    } catch (e) {
      print('[AuthController.login] ===== ERROR EN LOGIN =====');
      print('[AuthController.login] Error completo: $e');
      print('[AuthController.login] Tipo de error: ${e.runtimeType}');

      // Extraer mensaje de error más legible
      String errorMessage = 'Error al iniciar sesión';

      final errorString = e.toString();
      if (errorString.contains('Exception:')) {
        errorMessage = errorString.replaceAll('Exception:', '').trim();
      } else if (errorString.contains('No hay conexión')) {
        errorMessage = 'No hay conexión con el servidor';
      } else {
        errorMessage = errorString;
      }

      print('[AuthController.login] Mensaje de error procesado: $errorMessage');

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMessage,
      );

      print('[AuthController.login] Estado actualizado a unauthenticated con error');
      print('[AuthController.login] ===== FIN LOGIN CON ERROR =====');
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = state.token;
      if (token != null) {
        // Intentar cerrar sesión en el servidor
        try {
          await _repo.logout(token);
        } catch (e) {
          // Ignorar errores del servidor al hacer logout
          print('Error al cerrar sesión en el servidor: $e');
        }
      }
      // Limpiar token y datos del usuario del almacenamiento local
      await _repo.clearToken();
      await _repo.clearUserData();
      // Actualizar estado a no autenticado
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      print('Error al cerrar sesión: $e');
      // Forzar logout aunque haya error
      await _repo.clearToken();
      await _repo.clearUserData();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void _sincronizarDatosDespuesDeLogin() {
    print('[AuthController] Iniciando sincronización automática...');
    _ref.read(syncAllProvider).syncAll().then((_) {
      print('[AuthController] Sincronización automática completada');
    }).catchError((e) {
      print('[AuthController] Error en sincronización automática: $e');
    });
  }
}