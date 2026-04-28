import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/connectivity_service.dart';
import 'sync_service.dart';
import '../../config/env.dart';
import '../../features/auth/presentation/auth_controller.dart';

/// Provider del servicio de conectividad (singleton)
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.initialize();
  return service;
});

/// Provider del estado de conectividad
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectionStream;
});

/// Provider del servicio de sincronización
final syncServiceProvider = Provider<SyncService>((ref) {
  // Usa la URL configurada en env.dart (Render en producción)
  final baseUrl = Env.apiBaseUrl;

  // Obtener el token del estado de autenticación
  final authState = ref.watch(authControllerProvider);
  final token = authState.token;

  final service = SyncService(
    baseUrl: baseUrl,
    token: token,
  );

  service.initialize();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider del estado de sincronización
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.statusStream;
});

/// Provider del contador de items pendientes
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.pendingCountStream;
});

/// Provider para verificar si hay items pendientes
final hasPendingSyncProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(syncServiceProvider);
  final count = await service.getPendingCount();
  return count > 0;
});
