import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facturacion_app/src/features/auth/presentation/auth_controller.dart';
import 'package:facturacion_app/src/features/auth/domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, current) {
      print('[LoginScreen.listener] ===== CAMBIO DE ESTADO DETECTADO =====');
      print('[LoginScreen.listener] Estado anterior: ${previous?.status}');
      print('[LoginScreen.listener] Estado actual: ${current.status}');
      print('[LoginScreen.listener] Error anterior: ${previous?.errorMessage}');
      print('[LoginScreen.listener] Error actual: ${current.errorMessage}');

      // MOSTRAR SIEMPRE UN DIÁLOGO CON EL ESTADO ACTUAL PARA DEBUGGING
      if (current.status == AuthStatus.unauthenticated && previous?.status == AuthStatus.loading) {
        // El login terminó pero quedó como no autenticado
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            title: Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange[400]),
                const SizedBox(width: 8),
                const Text('Debug: Login Fallido', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Estado: ${current.status}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Error: ${current.errorMessage ?? "Sin mensaje de error"}',
                    style: TextStyle(color: Colors.red[300])),
                  const SizedBox(height: 8),
                  Text('Estado anterior: ${previous?.status}', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        );
      }

      // Solo mostrar error si cambió de no-error a error
      if (current.errorMessage != null &&
          previous?.errorMessage != current.errorMessage) {
        print('[LoginScreen.listener] Mostrando SnackBar con error: ${current.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        print('[LoginScreen.listener] NO se muestra SnackBar (sin cambio de error)');
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo o icono
                  Icon(
                    Icons.receipt_long,
                    size: 100,
                    color: Colors.green[400],
                  ),
                  const SizedBox(height: 16),

                  // Título
                  Text(
                    'Sistema de Facturación',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // DEBUG INFO - Mostrar estado actual
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[900]?.withOpacity(0.3),
                      border: Border.all(color: Colors.orange[700]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEBUG INFO:',
                          style: TextStyle(
                            color: Colors.orange[300],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estado: ${authState.status}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Error: ${authState.errorMessage}',
                            style: TextStyle(color: Colors.red[300], fontSize: 11),
                          ),
                        ],
                        if (authState.user != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Usuario: ${authState.user}',
                            style: TextStyle(color: Colors.green[300], fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo Email
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.email, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[400]!, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu email';
                      }
                      if (!value.contains('@')) {
                        return 'Por favor ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Password
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.lock, color: Colors.grey[400]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[400]!, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (value.length < 4) {
                        return 'La contraseña debe tener al menos 4 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botón de Login
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authState.status == AuthStatus.loading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                ref.read(authControllerProvider.notifier).login(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        disabledBackgroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: authState.status == AuthStatus.loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
