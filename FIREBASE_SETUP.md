# 🔥 Configuración de Firebase para Notificaciones Push

## 📋 Requisitos Previos

- Cuenta de Google
- Proyecto de Flutter configurado
- Acceso a [Firebase Console](https://console.firebase.google.com/)

---

## 🚀 Paso 1: Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Click en **"Agregar proyecto"** (o selecciona un proyecto existente)
3. Nombre del proyecto: `facturacion-app` (o el que prefieras)
4. Deshabilita Google Analytics si no lo necesitas
5. Click en **"Crear proyecto"**

---

## 📱 Paso 2: Configurar Android

### 2.1 Agregar App Android a Firebase

1. En Firebase Console, click en el ícono de **Android**
2. Package name: `com.example.facturacion_app` (debe coincidir con `applicationId` en `android/app/build.gradle`)
3. App nickname (opcional): `Facturación App Android`
4. SHA-1 (opcional): Puedes agregarlo después
5. Click en **"Registrar app"**

### 2.2 Descargar google-services.json

1. Descarga el archivo `google-services.json`
2. Cópialo a: `android/app/google-services.json`

### 2.3 Configurar build.gradle

**Archivo**: `android/build.gradle`

```gradle
buildscript {
    dependencies {
        // Agregar esta línea
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**Archivo**: `android/app/build.gradle`

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

// Agregar AL FINAL del archivo
apply plugin: 'com.google.gms.google-services'
```

### 2.4 Configurar AndroidManifest.xml

**Archivo**: `android/app/src/main/AndroidManifest.xml`

Agregar dentro de `<application>`:

```xml
<application>
    <!-- ... otras configuraciones ... -->

    <!-- Firebase Cloud Messaging -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="cargues_channel" />

    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@drawable/ic_notification" />

    <meta-data
        android:name="com.google.firebase.messaging.default_notification_color"
        android:resource="@color/notification_color" />
</application>
```

### 2.5 Crear Icono de Notificación (Opcional)

Crea el archivo `android/app/src/main/res/drawable/ic_notification.xml`:

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="#FFFFFF">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M12,22c1.1,0 2,-0.9 2,-2h-4c0,1.1 0.9,2 2,2zM18,16v-5c0,-3.07 -1.63,-5.64 -4.5,-6.32V4c0,-0.83 -0.67,-1.5 -1.5,-1.5s-1.5,0.67 -1.5,1.5v0.68C7.64,5.36 6,7.92 6,11v5l-2,2v1h16v-1l-2,-2z"/>
</vector>
```

Y crea `android/app/src/main/res/values/colors.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#2196F3</color>
</resources>
```

---

## 🍎 Paso 3: Configurar iOS (Opcional)

### 3.1 Agregar App iOS a Firebase

1. En Firebase Console, click en el ícono de **iOS**
2. Bundle ID: `com.example.facturacionApp` (debe coincidir con el de Xcode)
3. Click en **"Registrar app"**

### 3.2 Descargar GoogleService-Info.plist

1. Descarga `GoogleService-Info.plist`
2. Abre `ios/Runner.xcworkspace` en Xcode
3. Arrastra el archivo a `Runner/Runner` en Xcode (asegúrate de marcar "Copy items if needed")

### 3.3 Configurar Capabilities en Xcode

1. Abre el proyecto en Xcode
2. Selecciona el target **Runner**
3. Ve a **Signing & Capabilities**
4. Click en **+ Capability**
5. Agrega **Push Notifications**
6. Agrega **Background Modes** y marca:
   - Remote notifications

### 3.4 Configurar APNs (Apple Push Notification service)

1. Ve a [Apple Developer](https://developer.apple.com/account/)
2. Certificates, Identifiers & Profiles → Keys
3. Crea una nueva key con **APNs** habilitado
4. Descarga la key (.p8)
5. En Firebase Console → Project Settings → Cloud Messaging → iOS app configuration
6. Sube el archivo .p8 y proporciona el Key ID y Team ID

---

## 🎯 Paso 4: Verificar Instalación

### 4.1 Instalar Dependencias

```bash
cd facturacion_app
flutter pub get
```

### 4.2 Verificar Configuración de Firebase

```bash
# Para Android
flutter run -d <android-device>

# Para iOS
flutter run -d <ios-device>
```

### 4.3 Probar Notificaciones

1. Ejecuta la app en un dispositivo físico (las notificaciones push NO funcionan en emuladores)
2. Inicia sesión como administrador
3. El token FCM se debería registrar automáticamente en el backend
4. Revisa los logs:

```
[PushNotificationService] FCM Token: xxxx...
[FCM] Token registrado exitosamente para usuario X
```

---

## 🧪 Paso 5: Probar Notificaciones desde Firebase Console

### Enviar Notificación de Prueba

1. Ve a Firebase Console → Cloud Messaging
2. Click en **"Nueva campaña"** → **"Mensajes de Firebase"**
3. Título: "Prueba"
4. Texto: "Notificación de prueba"
5. Click en **"Enviar mensaje de prueba"**
6. Pega el token FCM (lo puedes ver en los logs)
7. Click en **"Probar"**

Si recibes la notificación, ¡Firebase está configurado correctamente! ✅

---

## 📊 Paso 6: Configurar Backend

Sigue las instrucciones en [NOTIFICACIONES_PUSH_BACKEND.md](../backend/NOTIFICACIONES_PUSH_BACKEND.md) para:

1. Instalar `firebase-admin`
2. Descargar credenciales de servicio
3. Crear endpoints para registrar tokens y enviar notificaciones
4. Configurar la base de datos

---

## 🔍 Solución de Problemas

### No recibo notificaciones

1. **Verifica que estés en un dispositivo físico** (no emulador)
2. **Verifica permisos**: Asegúrate de haber aceptado los permisos de notificaciones
3. **Revisa los logs**: Busca errores en la consola
4. **Verifica el token**: Asegúrate de que el token se esté registrando en el backend

### Error: "Default FirebaseApp is not initialized"

- Asegúrate de llamar `Firebase.initializeApp()` antes de usar cualquier servicio de Firebase

### Error: "google-services.json not found"

- Verifica que el archivo esté en `android/app/google-services.json`
- Limpia y rebuild: `flutter clean && flutter pub get && flutter run`

### Notificaciones no aparecen cuando la app está abierta

- Es el comportamiento esperado. El código ya maneja esto mostrando notificaciones locales cuando la app está en foreground.

---

## 📚 Recursos Adicionales

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

---

## ✅ Checklist de Configuración

### Android:
- [ ] Proyecto creado en Firebase Console
- [ ] App Android agregada a Firebase
- [ ] `google-services.json` descargado y colocado en `android/app/`
- [ ] `build.gradle` configurado con google-services plugin
- [ ] `AndroidManifest.xml` configurado con metadata de FCM
- [ ] App ejecutándose en dispositivo físico
- [ ] Token FCM visible en logs

### iOS (Opcional):
- [ ] App iOS agregada a Firebase
- [ ] `GoogleService-Info.plist` agregado a Xcode
- [ ] Push Notifications capability agregada
- [ ] Background Modes → Remote notifications habilitado
- [ ] APNs key configurada en Firebase Console
- [ ] App ejecutándose en dispositivo físico

### Backend:
- [ ] `firebase-admin` instalado
- [ ] Credenciales de servicio descargadas
- [ ] Tabla `fcm_tokens` creada en MySQL
- [ ] Endpoints implementados (`/fcm-tokens`, `/notifications/new-cargue`)
- [ ] Backend probado con Postman/curl

---

## 🎉 Resultado Final

Cuando todo esté configurado, al crear un cargue como vendedor:

1. ✅ El cargue se guarda (online u offline)
2. ✅ Se envía una notificación al backend
3. ✅ El backend busca todos los tokens de administradores
4. ✅ Firebase envía notificaciones push a todos los administradores
5. ✅ Los administradores reciben: **"Nuevo Cargue Ingresado - Nuevo cargue ingresado por [Nombre del Vendedor]"**

¡Las notificaciones push están funcionando! 🚀
