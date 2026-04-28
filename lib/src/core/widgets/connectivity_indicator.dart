import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/sync_provider.dart';
import '../sync/sync_service.dart';

/// Indicador visual del estado de conexión y sincronización
/// Muestra un banner en la parte superior cuando está offline o sincronizando
class ConnectivityIndicator extends ConsumerWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final syncStatusAsync = ref.watch(syncStatusProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);

    return connectivityAsync.when(
      data: (isConnected) {
        // Si está conectado, mostrar estado de sincronización
        return syncStatusAsync.when(
          data: (syncStatus) {
            if (syncStatus == SyncStatus.syncing) {
              return _buildSyncingBanner(context);
            }

            // Mostrar contador de items pendientes si hay alguno
            return pendingCountAsync.when(
              data: (count) {
                if (count > 0 && isConnected) {
                  return _buildPendingBanner(context, count, ref);
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _buildOfflineBanner(context),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange[700],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sin conexión - Modo offline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sincronizando datos...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBanner(BuildContext context, int count, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber[700],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.sync, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'item pendiente' : 'items pendientes'} de sincronizar',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final service = ref.read(syncServiceProvider);
              await service.syncPendingData();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text(
              'SINCRONIZAR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icono pequeño de estado de conexión (para AppBar)
class ConnectivityIcon extends ConsumerWidget {
  const ConnectivityIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);

    return connectivityAsync.when(
      data: (isConnected) {
        if (!isConnected) {
          return const Tooltip(
            message: 'Sin conexión',
            child: Icon(Icons.cloud_off, color: Colors.orange, size: 20),
          );
        }

        return pendingCountAsync.when(
          data: (count) {
            if (count > 0) {
              return Tooltip(
                message: '$count pendientes',
                child: Stack(
                  children: [
                    const Icon(Icons.cloud_queue, color: Colors.amber, size: 20),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            return const Tooltip(
              message: 'Conectado',
              child: Icon(Icons.cloud_done, color: Colors.green, size: 20),
            );
          },
          loading: () => const SizedBox(width: 20),
          error: (_, __) => const Icon(Icons.cloud, color: Colors.grey, size: 20),
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(Icons.cloud_off, color: Colors.red, size: 20),
    );
  }
}
