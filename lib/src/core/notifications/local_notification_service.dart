import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Servicio de notificaciones locales (sin Firebase)
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Inicializa el servicio de notificaciones locales
  Future<void> initialize() async {
    if (kIsWeb) {
      print('[LocalNotificationService] Notificaciones no disponibles en web');
      return;
    }

    if (_initialized) return;

    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      print('[LocalNotificationService] Inicializado correctamente');
    } catch (e) {
      print('[LocalNotificationService] Error al inicializar: $e');
    }
  }

  /// Muestra una notificación de nuevo cargue
  Future<void> showNewCargueNotification({
    required String vendedorNombre,
    required String numeroCargue,
  }) async {
    if (kIsWeb || !_initialized) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cargues_channel',
      'Cargues',
      channelDescription: 'Notificaciones de nuevos cargues',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Nuevo Cargue Ingresado',
      'Nuevo cargue ingresado por $vendedorNombre',
      notificationDetails,
      payload: numeroCargue,
    );

    print('[LocalNotificationService] Notificación mostrada: $vendedorNombre - $numeroCargue');
  }

  /// Callback cuando el usuario toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    print('[LocalNotificationService] Notificación tocada: ${response.payload}');
    // Aquí puedes navegar a una pantalla específica si es necesario
  }
}
