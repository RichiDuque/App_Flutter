import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../src/features/auth/presentation/auth_controller.dart';
import '../src/features/auth/presentation/login_screen.dart';
import '../src/features/home/presentation/home_screen.dart';
import '../src/features/auth/domain/auth_state.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    print('[AuthGate.build] ===== EVALUANDO ESTADO =====');
    print('[AuthGate.build] Estado actual: ${authState.status}');
    print('[AuthGate.build] Usuario: ${authState.user}');
    print('[AuthGate.build] Error: ${authState.errorMessage}');

    if (authState.status == AuthStatus.loading) {
      print('[AuthGate.build] Mostrando pantalla de carga');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Verificando sesión...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    } else if (authState.status == AuthStatus.authenticated) {
      print('[AuthGate.build] Mostrando HomeScreen (usuario autenticado)');
      return const HomeScreen();
    } else {
      print('[AuthGate.build] Mostrando LoginScreen (no autenticado)');
      return const LoginScreen();
    }
  }
}