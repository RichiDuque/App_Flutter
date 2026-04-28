import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../data/auth_repository.dart' as data;
import '../../../config/env.dart';
import '../../../core/network/connectivity_service.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login({required String email, required String password});
  Future<void> logout(String token);
  Future<String?> getStoredToken();
  Future<Map<String, dynamic>> validateToken(String token);
  Future<void> saveToken(String token);
  Future<void> clearToken();
  Future<void> saveUserData(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getStoredUserData();
  Future<void> clearUserData();
}

class AuthRepositoryImpl implements AuthRepository {
  final data.AuthRepository _apiRepository;
  final FlutterSecureStorage _storage;
  final ConnectivityService _connectivity = ConnectivityService();

  AuthRepositoryImpl(this._apiRepository, this._storage);

  @override
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    print('[AuthRepositoryImpl] Intentando login...');

    try {
      // Intentar login online primero
      final response = await _apiRepository.login(email: email, password: password);

      print('[AuthRepositoryImpl] Login online exitoso');

      // Guardar el token si viene en la respuesta
      if (response['token'] != null) {
        await saveToken(response['token']);
      }

      // Guardar credenciales para autenticación offline futura
      await _saveCredentialsForOffline(email, password);

      return response;
    } catch (e) {
      print('[AuthRepositoryImpl] Error en login online: $e');

      // Si falla el login online, intentar autenticación offline
      if (e.toString().contains('No hay conexión') ||
          e.toString().contains('Tiempo de espera') ||
          e.toString().contains('conexión')) {

        print('[AuthRepositoryImpl] Intentando autenticación offline...');

        final offlineLogin = await _attemptOfflineLogin(email, password);
        if (offlineLogin != null) {
          print('[AuthRepositoryImpl] Autenticación offline exitosa');
          return offlineLogin;
        }
      }

      // Si no se pudo autenticar offline, lanzar el error original
      throw e;
    }
  }

  /// Guarda las credenciales hasheadas para autenticación offline
  Future<void> _saveCredentialsForOffline(String email, String password) async {
    final passwordHash = sha256.convert(utf8.encode(password)).toString();
    await _storage.write(key: '${Env.tokenKey}_email', value: email);
    await _storage.write(key: '${Env.tokenKey}_password_hash', value: passwordHash);
  }

  /// Intenta autenticar usando datos guardados localmente
  Future<Map<String, dynamic>?> _attemptOfflineLogin(String email, String password) async {
    try {
      // Leer credenciales guardadas
      final storedEmail = await _storage.read(key: '${Env.tokenKey}_email');
      final storedPasswordHash = await _storage.read(key: '${Env.tokenKey}_password_hash');
      final storedUserData = await getStoredUserData();
      final storedToken = await getStoredToken();

      // Verificar si las credenciales coinciden
      if (storedEmail == null || storedPasswordHash == null || storedUserData == null) {
        print('[AuthRepositoryImpl] No hay datos guardados para autenticación offline');
        return null;
      }

      final passwordHash = sha256.convert(utf8.encode(password)).toString();

      if (storedEmail == email && storedPasswordHash == passwordHash) {
        print('[AuthRepositoryImpl] Credenciales offline válidas');

        // Retornar datos del usuario guardados localmente
        return {
          'token': storedToken ?? 'offline-token-${DateTime.now().millisecondsSinceEpoch}',
          'usuario': storedUserData,
          'user': storedUserData,
          'offline_mode': true,
        };
      } else {
        print('[AuthRepositoryImpl] Credenciales offline no coinciden');
        return null;
      }
    } catch (e) {
      print('[AuthRepositoryImpl] Error en autenticación offline: $e');
      return null;
    }
  }

  @override
  Future<void> logout(String token) async {
    await _apiRepository.logout(token);
    await clearToken();
  }

  @override
  Future<String?> getStoredToken() async {
    return await _storage.read(key: Env.tokenKey);
  }

  @override
  Future<Map<String, dynamic>> validateToken(String token) async {
    return await _apiRepository.validateToken(token);
  }

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: Env.tokenKey, value: token);
  }

  @override
  Future<void> clearToken() async {
    await _storage.delete(key: Env.tokenKey);
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    // Guardar cada campo del usuario por separado para facilitar la lectura
    await _storage.write(key: '${Env.tokenKey}_user_id', value: userData['id']?.toString());
    await _storage.write(key: '${Env.tokenKey}_user_name', value: userData['nombre']?.toString());
    await _storage.write(key: '${Env.tokenKey}_user_email', value: userData['email']?.toString());
    await _storage.write(key: '${Env.tokenKey}_user_role', value: userData['rol']?.toString());
    await _storage.write(key: '${Env.tokenKey}_user_lista_precios', value: userData['lista_precios_id']?.toString());
  }

  @override
  Future<Map<String, dynamic>?> getStoredUserData() async {
    final userId = await _storage.read(key: '${Env.tokenKey}_user_id');

    if (userId == null) {
      return null;
    }

    final userName = await _storage.read(key: '${Env.tokenKey}_user_name');
    final userEmail = await _storage.read(key: '${Env.tokenKey}_user_email');
    final userRole = await _storage.read(key: '${Env.tokenKey}_user_role');
    final userListaPrecios = await _storage.read(key: '${Env.tokenKey}_user_lista_precios');

    return {
      'id': userId != null ? int.tryParse(userId) : null,
      'nombre': userName,
      'email': userEmail,
      'rol': userRole,
      'lista_precios_id': userListaPrecios != null ? int.tryParse(userListaPrecios) : null,
    };
  }

  @override
  Future<void> clearUserData() async {
    await _storage.delete(key: '${Env.tokenKey}_user_id');
    await _storage.delete(key: '${Env.tokenKey}_user_name');
    await _storage.delete(key: '${Env.tokenKey}_user_email');
    await _storage.delete(key: '${Env.tokenKey}_user_role');
    await _storage.delete(key: '${Env.tokenKey}_user_lista_precios');
    await _storage.delete(key: '${Env.tokenKey}_email');
    await _storage.delete(key: '${Env.tokenKey}_password_hash');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiRepository = data.AuthRepository(Env.apiBaseUrl);
  const storage = FlutterSecureStorage();
  return AuthRepositoryImpl(apiRepository, storage);
});