# CLAUDE.md — Facturación App

Guía para Claude Code al trabajar en este proyecto Flutter.

## Descripción del proyecto

App móvil de facturación para vendedores. Permite crear facturas, gestionar clientes/productos/cargues, operar offline y sincronizar con un backend Node.js/PostgreSQL. Soporta impresión Bluetooth.

## Comandos útiles

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en Android (debug)
flutter run

# Generar código (freezed, etc.)
dart run build_runner build --delete-conflicting-outputs

# Lint
flutter analyze

# Tests
flutter test
```

## Arquitectura

### Estructura de lib/

```
lib/
├── main.dart                   # Entry point: inicializa DB, conectividad, notificaciones
└── src/
    ├── config/
    │   ├── api_client.dart     # Dio + BaseOptions (timeout 8s)
    │   ├── dio_interceptor.dart# Agrega JWT a headers, maneja 401/403
    │   └── env.dart            # URL base del backend
    ├── core/                   # Servicios compartidos
    │   ├── app_router.dart     # GoRouter con lógica de redirect auth
    │   ├── auth_gate.dart      # Widget que decide Login vs Home
    │   ├── database/           # SQLite (sqflite) — singleton DatabaseService
    │   ├── network/            # ConnectivityService — monitorea conexión
    │   ├── notifications/      # LocalNotificationService + polling para admins
    │   ├── sync/               # SyncService + SyncQueueService — offline→online
    │   ├── theme/              # AppTheme (dark) + ThemeProvider
    │   └── widgets/            # ConnectivityIndicator
    └── features/               # Un directorio por módulo de negocio
        └── <feature>/
            ├── data/           # Repository (llama API + SQLite)
            ├── domain/         # Modelos de datos (clases Dart)
            └── presentation/   # Provider/Controller + Screens + Widgets
```

### State management

Riverpod en todas partes. Los providers siguen este patrón:
- **StateNotifier** para estados mutables (facturacion, auth, cargues)
- **Provider/FutureProvider** para repositorios y datos de solo lectura

### Offline / Sync

- `DatabaseService` — SQLite singleton (versión 10)
- `SyncQueueService` — encola operaciones pendientes cuando hay sin conexión
- `ConnectivityService` — stream de estado de red
- Los repositorios verifican conectividad antes de llamar al API; si no hay red, usan SQLite local

### Autenticación

- JWT guardado en `flutter_secure_storage`
- `AuthController` (StateNotifier) valida token al inicio y expone `AuthState`
- `app_router.dart` redirige según `AuthStatus`: loading → `/`, authenticated → `/home`, unauthenticated → `/login`

### Precios

La lista de precios asignada es **del vendedor** (`usuario.lista_id`), no del cliente. El `lista_id` del cliente es legacy y no se usa en facturación.

## Convenciones del código

- Español para nombres de dominio/negocio (clientes, facturas, cargues, etc.)
- Inglés para términos técnicos (provider, repository, controller, widget)
- Imports relativos dentro del proyecto (no `package:facturacion_app/...` salvo excepciones)
- No usar `freezed` para modelos nuevos salvo que ya exista en el feature

## Backend

- URL producción: `https://facturacion-backend-fdj0.onrender.com/api`
- URL desarrollo: `http://localhost:4000/api` (cambiar en `lib/src/config/env.dart`)
- Docs completos de endpoints en `docs/API_DOCUMENTATION.md`
- Schema PostgreSQL en `scripts/schema_postgres.sql`

## Plataformas objetivo

- Primario: **Android**
- Secundario: iOS
- SQLite y Bluetooth no funcionan en Web (guards con `kIsWeb`)
