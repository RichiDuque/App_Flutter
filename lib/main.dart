import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/app_router.dart';
import 'src/features/configuracion/data/impresoras_repository.dart';
import 'src/features/configuracion/presentation/impresoras_provider.dart';
import 'src/core/database/database_service.dart';
import 'src/core/network/connectivity_service.dart';
import 'src/core/notifications/local_notification_service.dart';
import 'src/core/notifications/polling_provider.dart';
import 'src/core/theme/theme_provider.dart';
import 'src/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar modo edge-to-edge para evitar que la barra de navegación tape botones
  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  // Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Inicializar base de datos local (SQLite) - solo en plataformas móviles/desktop
  if (!kIsWeb) {
    await DatabaseService().database;
  }

  // Inicializar servicio de conectividad
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  // Inicializar servicio de notificaciones locales
  if (!kIsWeb) {
    final notificationService = LocalNotificationService();
    await notificationService.initialize();
  }

  runApp(
    ProviderScope(
      overrides: [
        // Proporcionar el repositorio de impresoras
        impresorasRepositoryProvider.overrideWithValue(
          ImpresorasRepository(prefs),
        ),
      ],
      child: const App(),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Inicializar polling de notificaciones para admins
    ref.watch(pollingInitializerProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Facturación App',
      // Configuración de localización en español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés (fallback)
      ],
      locale: const Locale('es', 'ES'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) => SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: child!,
      ),
    );
  }
}