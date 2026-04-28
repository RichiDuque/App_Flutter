# Facturación App

Aplicación móvil de facturación construida con Flutter. Permite a vendedores crear facturas, gestionar clientes y productos, y operar sin conexión a internet.

## Stack tecnológico

- **Flutter** 3.x — Android / iOS
- **Estado**: Riverpod (StateNotifier + Provider)
- **Navegación**: go_router
- **HTTP**: Dio con interceptor JWT
- **Base de datos local**: SQLite (sqflite)
- **Backend**: API REST Node.js + Express + PostgreSQL
- **Impresión**: Bluetooth (flutter_bluetooth_serial)

## Estructura del proyecto

```
lib/
├── main.dart
└── src/
    ├── config/          # Cliente HTTP, interceptor, variables de entorno
    ├── core/            # Servicios compartidos (DB, red, notificaciones, sync, tema)
    │   ├── app_router.dart
    │   ├── auth_gate.dart
    │   ├── database/
    │   ├── network/
    │   ├── notifications/
    │   ├── sync/
    │   ├── theme/
    │   └── widgets/
    └── features/        # Módulos de negocio (cada uno con data/domain/presentation)
        ├── auth/
        ├── cargues/
        ├── categorias/
        ├── clientes/
        ├── configuracion/
        ├── descuentos/
        ├── equipos/
        ├── facturacion/
        ├── facturas/
        ├── home/
        ├── listas_precios/
        ├── productos/
        └── usuarios/
```

## Documentación

Ver la carpeta [`docs/`](docs/) para guías de arquitectura, API, implementación offline y más.

## Scripts y base de datos

Ver la carpeta [`scripts/`](scripts/) para el schema PostgreSQL, scripts de importación y configuración del entorno Android.

## Requisitos previos

- Flutter SDK ^3.9.2
- Dart SDK ^3.9.2
- Android SDK (para compilar en Android)

## Instalación

```bash
flutter pub get
flutter run
```

## Variables de entorno

La URL del backend se configura en [lib/src/config/env.dart](lib/src/config/env.dart).
