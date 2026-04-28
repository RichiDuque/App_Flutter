import 'dart:async';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../database/database_service.dart';
import '../network/connectivity_service.dart';
import 'local_notification_service.dart';

/// Servicio que consulta periódicamente nuevos cargues y muestra notificaciones
class CarguesPollingService {
  static final CarguesPollingService _instance = CarguesPollingService._internal();
  factory CarguesPollingService() => _instance;
  CarguesPollingService._internal();

  Timer? _pollingTimer;
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();
  final LocalNotificationService _notifications = LocalNotificationService();

  String? _baseUrl;
  String? _token;
  int? _userId;
  String? _userRole;

  /// Inicializa el servicio de polling
  void initialize({
    required String baseUrl,
    String? token,
    int? userId,
    String? userRole,
  }) {
    _baseUrl = baseUrl;
    _token = token;
    _userId = userId;
    _userRole = userRole;

    // Solo iniciar polling si es administrador
    if (userRole == 'admin' && !kIsWeb) {
      start();
    }
  }

  /// Inicia el polling cada 5 minutos
  void start() {
    if (kIsWeb) return;

    stop(); // Detener cualquier polling anterior

    // Primera consulta inmediata
    _checkNewCargues();

    // Luego cada 5 minutos
    _pollingTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkNewCargues(),
    );

    print('[CarguesPollingService] Polling iniciado (cada 5 minutos)');
  }

  /// Detiene el polling
  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('[CarguesPollingService] Polling detenido');
  }

  /// Consulta nuevos cargues y muestra notificaciones
  Future<void> _checkNewCargues() async {
    if (_baseUrl == null || _userId == null || _userRole != 'admin') {
      return;
    }

    // Verificar conexión a internet antes de intentar consultar
    if (!await _connectivity.checkConnection()) {
      print('[CarguesPollingService] Sin conexión a internet, omitiendo consulta');
      return;
    }

    try {
      print('[CarguesPollingService] Consultando nuevos cargues...');

      // Obtener el timestamp de la última consulta
      final lastCheck = await _getLastCheckTimestamp();

      // Consultar cargues creados después de la última consulta
      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl!,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          "Content-Type": "application/json",
          if (_token != null) "Authorization": "Bearer $_token",
        },
      ));

      final response = await dio.get('/cargues/nuevos', queryParameters: {
        'desde': lastCheck,
      });

      final List<dynamic> nuevosCargues = response.data ?? [];

      print('[CarguesPollingService] Nuevos cargues encontrados: ${nuevosCargues.length}');

      // Mostrar notificación para cada cargue nuevo
      for (final cargue in nuevosCargues) {
        final vendedorNombre = cargue['usuario_nombre'] ?? cargue['Usuario']?['nombre'] ?? 'Usuario';
        final numeroCargue = cargue['numero_cargue'] ?? 'Sin número';

        await _notifications.showNewCargueNotification(
          vendedorNombre: vendedorNombre,
          numeroCargue: numeroCargue,
        );

        // Guardar en la tabla de notificaciones para evitar duplicados
        await _saveNotifiedCargue(cargue['id']);
      }

      // Actualizar timestamp de última consulta
      await _updateLastCheckTimestamp();
    } catch (e) {
      print('[CarguesPollingService] Error al consultar nuevos cargues: $e');
      // No hacer nada, intentará de nuevo en el próximo ciclo
    }
  }

  /// Obtiene el timestamp de la última consulta
  Future<String> _getLastCheckTimestamp() async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'sync_metadata',
        where: 'key = ?',
        whereArgs: ['last_cargues_check'],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first['value'] as String;
      }
    } catch (e) {
      print('[CarguesPollingService] Error al obtener timestamp: $e');
    }

    // Si no existe, retornar hace 24 horas
    return DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
  }

  /// Actualiza el timestamp de la última consulta
  Future<void> _updateLastCheckTimestamp() async {
    try {
      final db = await _db.database;
      await db.insert(
        'sync_metadata',
        {
          'key': 'last_cargues_check',
          'value': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('[CarguesPollingService] Error al actualizar timestamp: $e');
    }
  }

  /// Guarda un cargue como notificado para evitar duplicados
  Future<void> _saveNotifiedCargue(int cargueId) async {
    try {
      final db = await _db.database;

      // Verificar si la tabla existe, si no crearla
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notified_cargues (
          cargue_id INTEGER PRIMARY KEY,
          notified_at TEXT NOT NULL
        )
      ''');

      await db.insert(
        'notified_cargues',
        {
          'cargue_id': cargueId,
          'notified_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      print('[CarguesPollingService] Error al guardar cargue notificado: $e');
    }
  }

  /// Libera recursos
  void dispose() {
    stop();
  }
}
