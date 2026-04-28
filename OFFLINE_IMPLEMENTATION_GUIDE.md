# Guía de Implementación - Sistema Offline

## Infraestructura Creada ✅

La infraestructura base para el funcionamiento offline ya está completamente implementada:

### 1. **Base de Datos Local (SQLite)**
- **Archivo**: `lib/src/core/database/database_service.dart`
- **Función**: Almacena todos los datos localmente
- **Tablas creadas**:
  - `productos`, `clientes`, `categorias`, `listas_precios`, `precios`
  - `usuarios`, `facturas`, `facturas_items`
  - `devoluciones`, `devoluciones_items`
  - `sync_queue` (cola de sincronización)
  - `sync_metadata` (metadatos de sincronización)

### 2. **Servicio de Conectividad**
- **Archivo**: `lib/src/core/network/connectivity_service.dart`
- **Función**: Detecta y monitorea la conexión a Internet
- **Características**:
  - Detección en tiempo real
  - Stream de cambios de conectividad
  - Verificación de acceso real a Internet

### 3. **Sistema de Cola de Sincronización**
- **Archivo**: `lib/src/core/sync/sync_queue_service.dart`
- **Función**: Gestiona operaciones pendientes de sincronización
- **Características**:
  - Cola persistente en SQLite
  - Reintentos automáticos
  - Manejo de errores

### 4. **Servicio de Sincronización**
- **Archivo**: `lib/src/core/sync/sync_service.dart`
- **Función**: Coordina la sincronización bidireccional
- **Características**:
  - Descarga de datos desde el servidor
  - Subida de datos pendientes
  - Sincronización periódica automática (cada 5 minutos)
  - Sincronización automática al recuperar conexión

### 5. **Providers de Riverpod**
- **Archivo**: `lib/src/core/sync/sync_provider.dart`
- **Providers disponibles**:
  - `connectivityServiceProvider`: Servicio de conectividad
  - `connectivityStatusProvider`: Stream del estado de conexión
  - `syncServiceProvider`: Servicio de sincronización
  - `syncStatusProvider`: Stream del estado de sincronización
  - `pendingSyncCountProvider`: Stream del contador de items pendientes
  - `hasPendingSyncProvider`: Verifica si hay items pendientes

### 6. **Widgets Visuales**
- **Archivo**: `lib/src/core/widgets/connectivity_indicator.dart`
- **Widgets**:
  - `ConnectivityIndicator`: Banner superior con estado de conexión/sincronización
  - `ConnectivityIcon`: Icono pequeño para AppBar

---

## Cómo Implementar por Módulo

### Paso 1: Modificar un Repositorio para Soporte Offline

**Ejemplo con FacturasRepository:**

```dart
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../../../core/network/connectivity_service.dart';

class FacturasRepository {
  final Dio _dio;
  final DatabaseService _db = DatabaseService();
  final SyncQueueService _queue = SyncQueueService();
  final ConnectivityService _connectivity = ConnectivityService();

  // Crear factura (funciona online y offline)
  Future<Factura> crearFactura({
    required int usuarioId,
    int? clienteId,
    required List<FacturaItem> items,
    double descuento = 0,
  }) async {
    final uuid = const Uuid().v4();
    final now = DateTime.now();

    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final total = subtotal - descuento;

    final facturaData = {
      'uuid': uuid,
      'numero_factura': 'TEMP-$uuid', // Se actualizará al sincronizar
      'usuario_id': usuarioId,
      'cliente_id': clienteId,
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'fecha': now.toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'synced': 0,
      'pending_sync': 1,
    };

    // Guardar en base de datos local
    final db = await _db.database;
    final facturaId = await db.insert('facturas', facturaData);

    // Guardar items
    for (final item in items) {
      await db.insert('facturas_items', {
        'uuid': const Uuid().v4(),
        'factura_id': facturaId,
        'producto_id': item.productoId,
        'cantidad': item.cantidad,
        'precio_unitario': item.precioUnitario,
        'subtotal': item.subtotal,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'synced': 0,
      });
    }

    // Agregar a cola de sincronización
    await _queue.addToQueue(SyncQueueItem(
      entityType: EntityType.factura,
      entityUuid: uuid,
      operation: SyncOperation.create,
      data: {
        ...facturaData,
        'items': items.map((i) => i.toJson()).toList(),
      },
    ));

    // Intentar sincronizar inmediatamente si hay conexión
    if (await _connectivity.checkConnection()) {
      try {
        // Intentar crear en el servidor
        final response = await _dio.post('/facturas', data: facturaData);

        // Actualizar con ID real del servidor
        await db.update(
          'facturas',
          {
            'id': response.data['id'],
            'numero_factura': response.data['numero_factura'],
            'synced': 1,
            'pending_sync': 0,
          },
          where: 'uuid = ?',
          whereArgs: [uuid],
        );

        // Remover de cola
        await _queue.removeByUuid(EntityType.factura, uuid);
      } catch (e) {
        // Si falla, quedará en la cola para sincronización posterior
      }
    }

    // Retornar factura desde la base de datos local
    return _getFacturaByUuid(uuid);
  }

  // Obtener facturas (primero de local, luego sincronizar en background)
  Future<List<Factura>> getFacturas() async {
    final db = await _db.database;

    // Obtener de base de datos local
    final List<Map<String, dynamic>> maps = await db.query(
      'facturas',
      orderBy: 'created_at DESC',
    );

    final facturas = maps.map((map) => Factura.fromMap(map)).toList();

    // Si hay conexión, actualizar en background
    if (await _connectivity.checkConnection()) {
      _syncFacturasInBackground();
    }

    return facturas;
  }

  Future<void> _syncFacturasInBackground() async {
    try {
      final response = await _dio.get('/facturas');
      final db = await _db.database;

      for (final factura in response.data) {
        await db.insert(
          'facturas',
          {
            ...factura,
            'synced': 1,
            'pending_sync': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      // Ignorar errores de sincronización en background
    }
  }
}
```

### Paso 2: Agregar Indicadores Visuales

**En tu AppBar:**

```dart
AppBar(
  title: const Text('Facturas'),
  actions: [
    const ConnectivityIcon(), // Icono de estado
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () {
        ref.invalidate(facturasProvider);
      },
    ),
  ],
)
```

**En el Scaffold:**

```dart
Scaffold(
  appBar: AppBar(...),
  body: Column(
    children: [
      const ConnectivityIndicator(), // Banner de estado
      Expanded(
        child: // Tu contenido aquí
      ),
    ],
  ),
)
```

### Paso 3: Inicializar en main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar base de datos
  await DatabaseService().database;

  // Inicializar conectividad
  await ConnectivityService().initialize();

  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}
```

---

## Flujo de Trabajo Offline

### 1. **Sin Conexión**
- Usuario crea factura
- Se guarda en SQLite local
- Se agrega a `sync_queue`
- Usuario ve confirmación inmediata
- Banner muestra "Sin conexión - Modo offline"

### 2. **Recupera Conexión**
- `ConnectivityService` detecta conexión
- `SyncService` sincroniza automáticamente
- Items en `sync_queue` se envían al servidor
- Banner muestra "Sincronizando datos..."
- Una vez completo, muestra "X items sincronizados"

### 3. **Con Conexión**
- Usuario crea factura
- Se guarda en SQLite local
- Se intenta sincronizar inmediatamente
- Si tiene éxito, se marca como `synced = 1`
- Si falla, queda en cola para reintento

---

## Estado de Implementación

### ✅ Fase 1: Facturas Offline - COMPLETADA
1. ✅ Servicios inicializados en `main.dart`
2. ✅ `FacturasRepository` modificado para leer de SQLite primero
3. ✅ `FacturacionRepository.crearFactura()` modificado con soporte offline
4. ✅ `ConnectivityIndicator` agregado en `FacturasScreen`
5. ✅ Cola de sincronización implementada
6. ⚠️ Pendiente: Pruebas en dispositivo real sin conexión

**Archivos modificados:**
- `lib/main.dart` - Inicialización de servicios
- `lib/src/features/facturas/data/facturas_repository.dart` - Lectura offline
- `lib/src/features/facturacion/data/facturacion_repository.dart` - Creación offline
- `lib/src/features/facturas/presentation/facturas_screen.dart` - Indicadores visuales

## Próximos Pasos Recomendados

### Fase 2: Implementar Productos y Clientes (DATOS DE LECTURA)
1. Modificar repositorios para leer de SQLite primero
2. Implementar descarga inicial de datos
3. Actualizar en background cuando hay conexión

### Fase 3: Implementar Devoluciones Offline
1. Similar a facturas
2. Agregar a cola de sincronización

### Fase 4: Optimizaciones
1. Compresión de datos
2. Sincronización inteligente (solo cambios)
3. Resolución de conflictos
4. Indicadores de progreso más detallados

---

## Comandos Útiles

### Verificar base de datos (desde Bash)
```bash
# Ubicación de la base de datos
cd data/data/com.example.facturacion_app/databases/
sqlite3 facturacion_offline.db

# Ver tablas
.tables

# Ver datos de facturas
SELECT * FROM facturas;

# Ver cola de sincronización
SELECT * FROM sync_queue;
```

### Limpiar base de datos (para testing)
```dart
await DatabaseService().clearDatabase();
```

### Forzar sincronización
```dart
final syncService = ref.read(syncServiceProvider);
await syncService.syncPendingData();
```

### Descargar datos del servidor
```dart
final syncService = ref.read(syncServiceProvider);
await syncService.downloadData();
```

---

## Consideraciones Importantes

1. **UUIDs**: Todas las entidades usan UUIDs para evitar conflictos de ID
2. **Timestamps**: Usar ISO 8601 para todas las fechas
3. **Flags de sincronización**:
   - `synced = 1`: Dato sincronizado con servidor
   - `pending_sync = 1`: Operación pendiente de enviar
4. **Reintentos**: Máximo 5 reintentos antes de marcar como error permanente
5. **Conflictos**: Por ahora, "server wins" (el servidor tiene la verdad)

---

## Soporte y Debugging

### Logs de sincronización
Los servicios ya incluyen logging básico. Para más detalle, agregar:

```dart
print('DEBUG: Sincronizando item $uuid');
```

### Verificar estado
```dart
// Ver items pendientes
final queue = SyncQueueService();
final pending = await queue.getPendingItems();
print('Pendientes: ${pending.length}');

// Ver estado de conexión
final connectivity = ConnectivityService();
final isConnected = await connectivity.checkConnection();
print('Conectado: $isConnected');
```

---

## Resumen

La infraestructura está lista. Ahora solo necesitas:

1. **Modificar repositorios** para guardar/leer de SQLite
2. **Agregar widgets visuales** donde los necesites
3. **Probar** el flujo completo

¡El sistema está diseñado para funcionar de forma transparente tanto online como offline!
