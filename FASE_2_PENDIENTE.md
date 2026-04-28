# Fase 2: Implementación Offline Completa - Pendiente

## ✅ Completado Hasta Ahora

### Base de Datos
- ✅ Tablas de cargues agregadas a SQLite (`cargues`, `cargues_detalles`)
- ✅ Índices creados para rendimiento
- ✅ Migración de base de datos v1 → v2
- ✅ EntityType actualizado para incluir `cargue`
- ✅ Endpoints configurados en SyncService

### Módulos con Soporte Offline
- ✅ **Facturas**: Lectura y creación offline completa
- ✅ **Infraestructura**: Base de datos, conectividad, sincronización

## ⚠️ Pendiente de Implementación

### 1. CarguesRepository - Soporte Offline

**Archivo**: `lib/src/features/cargues/data/cargues_repository.dart`

#### Cambios Necesarios:

```dart
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../../../core/network/connectivity_service.dart';

class CarguesRepository {
  final Dio _dio;
  final DatabaseService _db = DatabaseService();
  final SyncQueueService _queue = SyncQueueService();
  final ConnectivityService _connectivity = ConnectivityService();

  // Modificar crearCargue() similar a crearFactura() en FacturacionRepository:
  // 1. Generar UUID
  // 2. Guardar en SQLite local (cargues + cargues_detalles)
  // 3. Agregar a sync_queue
  // 4. Intentar sincronizar si hay conexión
  // 5. Retornar cargue local si no hay conexión

  // Modificar getCargues() para leer primero de SQLite
  // similar a obtenerFacturas() en FacturasRepository
}
```

### 2. ProductosRepository - Lectura Offline

**Archivo**: `lib/src/features/productos/data/productos_repository.dart`

#### Cambios Necesarios:

```dart
import '../../../core/database/database_service.dart';
import '../../../core/network/connectivity_service.dart';

class ProductosRepository {
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  // Modificar getProductos() para:
  // 1. Leer primero de SQLite local
  // 2. Si hay conexión, sincronizar en background
  // 3. Si falla lectura local, obtener del servidor

  // Similar pattern a FacturasRepository.obtenerFacturas()
}
```

### 3. ClientesRepository - Lectura Offline

**Archivo**: `lib/src/features/clientes/data/clientes_repository.dart`

#### Cambios Necesarios:

```dart
import '../../../core/database/database_service.dart';
import '../../../core/network/connectivity_service.dart';

class ClientesRepository {
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  // Modificar getClientes() para lectura offline
  // Mismo patrón que ProductosRepository
}
```

### 4. SyncService - Descarga Inicial de Datos

**Archivo**: `lib/src/core/sync/sync_service.dart`

Ya existe el método `downloadData()` pero está incompleto.

#### Método Existente (línea ~207):

```dart
Future<void> downloadData() async {
  if (!await _connectivity.checkConnection()) {
    throw Exception('Sin conexión a Internet');
  }

  try {
    // Descargar productos ✅
    final productosResponse = await _dio.get('/productos');
    await _saveProductosToLocal(productosResponse.data);

    // Descargar clientes ✅
    final clientesResponse = await _dio.get('/clientes');
    await _saveClientesToLocal(clientesResponse.data);

    // Descargar categorías ✅
    final categoriasResponse = await _dio.get('/categorias');
    await _saveCategoriasToLocal(categoriasResponse.data);

    // Descargar listas de precios ✅
    final listasResponse = await _dio.get('/listas-precios');
    await _saveListasPreciosToLocal(listasResponse.data);

    // Descargar precios ✅
    final preciosResponse = await _dio.get('/precios');
    await _savePreciosToLocal(preciosResponse.data);

    // ⚠️ AGREGAR: Descargar cargues
    // final carguesResponse = await _dio.get('/cargues');
    // await _saveCarg uesToLocal(carguesResponse.data);

    await _updateSyncMetadata('last_download', DateTime.now().toIso8601String());
  } catch (e) {
    throw Exception('Error al descargar datos: $e');
  }
}
```

#### Agregar Método:

```dart
Future<void> _saveCarguesTo Local(List<dynamic> cargues) async {
  final db = await _db.database;
  final batch = db.batch();

  for (final cargue in cargues) {
    batch.insert(
      'cargues',
      {
        'id': cargue['id'],
        'uuid': cargue['uuid'],
        'numero_cargue': cargue['numero_cargue'],
        'usuario_id': cargue['usuario_id'],
        'fecha': cargue['fecha'],
        'total': cargue['total'],
        'estado': cargue['estado'],
        'comentario': cargue['comentario'],
        'created_at': cargue['created_at'],
        'updated_at': cargue['updated_at'],
        'synced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Guardar detalles si existen
    if (cargue['detalles'] != null && cargue['detalles'] is List) {
      for (final detalle in cargue['detalles']) {
        batch.insert(
          'cargues_detalles',
          {
            'id': detalle['id'],
            'uuid': detalle['uuid'],
            'cargue_id': detalle['cargue_id'],
            'producto_id': detalle['producto_id'],
            'cantidad': detalle['cantidad'],
            'cantidad_original': detalle['cantidad_original'],
            'precio_unitario': detalle['precio_unitario'],
            'subtotal': detalle['subtotal'],
            'comentario': detalle['comentario'],
            'despachado': detalle['despachado'] ? 1 : 0,
            'faltante': detalle['faltante'] ? 1 : 0,
            'created_at': detalle['created_at'],
            'updated_at': detalle['updated_at'],
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  await batch.commit(noResult: true);
}
```

### 5. Botón de Sincronización Inicial

Agregar un botón en la app para que el usuario pueda descargar todos los datos:

**Ubicación**: En el drawer o en una pantalla de configuración

```dart
ElevatedButton(
  onPressed: () async {
    final syncService = ref.read(syncServiceProvider);
    try {
      await syncService.downloadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos descargados exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: const Text('Sincronizar Datos Offline'),
)
```

## 📋 Resumen de Lo Que Falta

### Archivos a Modificar:

1. ✅ `lib/src/core/database/database_service.dart` - COMPLETADO
2. ✅ `lib/src/core/sync/sync_queue_service.dart` - COMPLETADO
3. ✅ `lib/src/core/sync/sync_service.dart` - Agregar `_saveCarguesTo Local()`
4. ⚠️ `lib/src/features/cargues/data/cargues_repository.dart` - Soporte offline
5. ⚠️ `lib/src/features/productos/data/productos_repository.dart` - Lectura offline
6. ⚠️ `lib/src/features/clientes/data/clientes_repository.dart` - Lectura offline
7. ⚠️ UI para botón de sincronización inicial

### Datos que se Almacenarán Localmente:

- ✅ Facturas (implementado)
- ✅ Cargues (tablas creadas, falta repositorio)
- ⚠️ Productos (falta implementar lectura)
- ⚠️ Clientes (falta implementar lectura)
- ✅ Categorías (descarga implementada en SyncService)
- ✅ Listas de Precios (descarga implementada)
- ✅ Precios (descarga implementada)

## 🎯 Próximos Pasos

1. Implementar `CarguesRepository` con soporte offline para creación
2. Implementar lectura offline en `ProductosRepository`
3. Implementar lectura offline en `ClientesRepository`
4. Agregar método `_saveCarguesTo Local()` en `SyncService`
5. Agregar botón de "Sincronizar Datos" en la UI
6. Probar flujo completo offline

## 📝 Nota Importante

Una vez completados estos pasos, la aplicación podrá:
- ✅ Crear facturas offline
- ✅ Crear cargues offline
- ✅ Ver productos offline
- ✅ Ver clientes offline
- ✅ Sincronizar automáticamente al recuperar conexión

**El vendedor podrá trabajar 100% sin conexión a Internet.**
