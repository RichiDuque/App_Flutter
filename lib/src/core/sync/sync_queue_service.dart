import 'dart:convert';
import '../database/database_service.dart';

/// Tipos de operaciones que se pueden sincronizar
enum SyncOperation {
  create,
  update,
  delete,
}

/// Tipos de entidades que se sincronizan
enum EntityType {
  factura,
  devolucion,
  cliente,
  producto,
  cargue,
}

/// Item en la cola de sincronización
class SyncQueueItem {
  final int? id;
  final EntityType entityType;
  final String entityUuid;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  SyncQueueItem({
    this.id,
    required this.entityType,
    required this.entityUuid,
    required this.operation,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
    this.lastError,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'entity_type': entityType.name,
      'entity_uuid': entityUuid,
      'operation': operation.name,
      'data': jsonEncode(data),
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int?,
      entityType: EntityType.values.firstWhere((e) => e.name == map['entity_type']),
      entityUuid: map['entity_uuid'] as String,
      operation: SyncOperation.values.firstWhere((e) => e.name == map['operation']),
      data: jsonDecode(map['data'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(map['created_at'] as String),
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }
}

/// Servicio para gestionar la cola de sincronización
class SyncQueueService {
  final DatabaseService _db = DatabaseService();

  /// Agrega un item a la cola de sincronización
  Future<void> addToQueue(SyncQueueItem item) async {
    final db = await _db.database;

    // Verificar si ya existe un item con el mismo tipo, uuid y operación
    final existing = await db.query(
      'sync_queue',
      where: 'entity_type = ? AND entity_uuid = ? AND operation = ?',
      whereArgs: [item.entityType.name, item.entityUuid, item.operation.name],
    );

    if (existing.isNotEmpty) {
      // Actualizar el item existente
      await db.update(
        'sync_queue',
        {
          'data': jsonEncode(item.data),
          'retry_count': 0, // Resetear contador al actualizar
          'last_error': null,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // Insertar nuevo item
      await db.insert('sync_queue', item.toMap());
    }
  }

  /// Obtiene todos los items pendientes de sincronización
  Future<List<SyncQueueItem>> getPendingItems({int? limit}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return maps.map((map) => SyncQueueItem.fromMap(map)).toList();
  }

  /// Obtiene items pendientes por tipo de entidad
  Future<List<SyncQueueItem>> getPendingItemsByType(EntityType type) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_queue',
      where: 'entity_type = ?',
      whereArgs: [type.name],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => SyncQueueItem.fromMap(map)).toList();
  }

  /// Elimina un item de la cola después de sincronizarlo exitosamente
  Future<void> removeFromQueue(int id) async {
    final db = await _db.database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un item por UUID y tipo
  Future<void> removeByUuid(EntityType type, String uuid) async {
    final db = await _db.database;
    await db.delete(
      'sync_queue',
      where: 'entity_type = ? AND entity_uuid = ?',
      whereArgs: [type.name, uuid],
    );
  }

  /// Marca un item como fallido y incrementa el contador de reintentos
  Future<void> markAsFailed(int id, String error) async {
    final db = await _db.database;
    final item = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (item.isEmpty) return;

    final retryCount = (item.first['retry_count'] as int? ?? 0) + 1;

    // Si supera 5 reintentos, se podría considerar eliminar o marcar como error permanente
    if (retryCount > 5) {
      // Por ahora solo actualizamos el error
      await db.update(
        'sync_queue',
        {
          'retry_count': retryCount,
          'last_error': 'Max retries exceeded: $error',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.update(
        'sync_queue',
        {
          'retry_count': retryCount,
          'last_error': error,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Obtiene el número total de items pendientes
  Future<int> getPendingCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
    return result.first['count'] as int;
  }

  /// Limpia toda la cola (usar con precaución)
  Future<void> clearQueue() async {
    final db = await _db.database;
    await db.delete('sync_queue');
  }

  /// Obtiene items que han fallado múltiples veces
  Future<List<SyncQueueItem>> getFailedItems() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_queue',
      where: 'retry_count >= ?',
      whereArgs: [3],
      orderBy: 'retry_count DESC',
    );

    return maps.map((map) => SyncQueueItem.fromMap(map)).toList();
  }
}
