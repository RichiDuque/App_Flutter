import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_gate.dart';
import '../src/features/home/presentation/home_screen.dart';
import '../src/features/auth/presentation/login_screen.dart';
import '../src/features/auth/presentation/auth_controller.dart';
import '../src/features/auth/domain/auth_state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.loading;
      final isOnLoginPage = state.matchedLocation == '/login';
      final isOnRootPage = state.matchedLocation == '/';

      print('[Router.redirect] ===== EVALUANDO REDIRECCIÓN =====');
      print('[Router.redirect] Estado auth: ${authState.status}');
      print('[Router.redirect] Ubicación actual: ${state.matchedLocation}');
      print('[Router.redirect] isAuthenticated: $isAuthenticated');
      print('[Router.redirect] isLoading: $isLoading');

      // Si está cargando, permitir acceso
      if (isLoading) {
        print('[Router.redirect] Está cargando, permitir acceso sin redirección');
        return null;
      }

      // Si no está autenticado y no está en login ni en root, redirigir a login
      if (!isAuthenticated && !isOnLoginPage && !isOnRootPage) {
        print('[Router.redirect] No autenticado, redirigiendo a /login');
        return '/login';
      }

      // Si está autenticado y está en login, redirigir a home
      if (isAuthenticated && isOnLoginPage) {
        print('[Router.redirect] Autenticado en login page, redirigiendo a /home');
        return '/home';
      }

      print('[Router.redirect] No hay redirección necesaria');
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});