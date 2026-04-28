import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Servicio central de base de datos SQLite
/// Gestiona la creación, actualización y acceso a la base de datos local
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite no está disponible en web. La funcionalidad offline solo funciona en móviles.');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'facturacion_offline.db');

    return await openDatabase(
      path,
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea todas las tablas necesarias
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        codigo_barras TEXT,
        stock INTEGER NOT NULL DEFAULT 0,
        categoria_id INTEGER,
        imagen_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        nombre_establecimiento TEXT NOT NULL,
        propietario TEXT,
        email TEXT,
        telefono TEXT,
        direccion TEXT,
        ciudad TEXT,
        departamento TEXT,
        codigo_postal TEXT,
        pais TEXT NOT NULL DEFAULT 'Colombia',
        codigo_cliente TEXT,
        nota TEXT,
        puntos INTEGER NOT NULL DEFAULT 0,
        visitas INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE listas_precios (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE precios (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        producto_id INTEGER NOT NULL,
        lista_id INTEGER NOT NULL,
        precio REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE CASCADE,
        FOREIGN KEY (lista_id) REFERENCES listas_precios (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        rol TEXT NOT NULL,
        lista_id INTEGER,
        activo INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (lista_id) REFERENCES listas_precios (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE descuentos (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        porcentaje REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE facturas (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        numero_factura TEXT NOT NULL UNIQUE,
        usuario_id INTEGER NOT NULL,
        cliente_id INTEGER,
        descuento_id INTEGER,
        subtotal REAL NOT NULL,
        descuento REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        estado TEXT NOT NULL DEFAULT 'completada',
        fecha TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        pending_sync INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id),
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE facturas_items (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        factura_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        comentario TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (factura_id) REFERENCES facturas (id) ON DELETE CASCADE,
        FOREIGN KEY (producto_id) REFERENCES productos (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE devoluciones (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        factura_id INTEGER NOT NULL,
        usuario_id INTEGER NOT NULL,
        motivo TEXT,
        total REAL NOT NULL,
        fecha TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        pending_sync INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (factura_id) REFERENCES facturas (id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE devoluciones_items (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        devolucion_id INTEGER NOT NULL,
        factura_item_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (devolucion_id) REFERENCES devoluciones (id) ON DELETE CASCADE,
        FOREIGN KEY (factura_item_id) REFERENCES facturas_items (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cargues (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        numero_cargue TEXT,
        usuario_id INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        estado TEXT NOT NULL DEFAULT 'pendiente',
        comentario TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        pending_sync INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cargues_detalles (
        id INTEGER PRIMARY KEY,
        uuid TEXT NOT NULL UNIQUE,
        cargue_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        cantidad_original INTEGER,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        comentario TEXT,
        despachado INTEGER NOT NULL DEFAULT 0,
        faltante INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (cargue_id) REFERENCES cargues (id) ON DELETE CASCADE,
        FOREIGN KEY (producto_id) REFERENCES productos (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE equipos (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        activo INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabla para gestionar la cola de sincronización
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_uuid TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        UNIQUE(entity_type, entity_uuid, operation)
      )
    ''');

    // Tabla para metadatos de sincronización
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Índices para mejorar el rendimiento
    await db.execute('CREATE INDEX idx_productos_uuid ON productos(uuid)');
    await db.execute('CREATE INDEX idx_clientes_uuid ON clientes(uuid)');
    await db.execute('CREATE INDEX idx_facturas_uuid ON facturas(uuid)');
    await db.execute('CREATE INDEX idx_facturas_pending ON facturas(pending_sync)');
    await db.execute('CREATE INDEX idx_cargues_uuid ON cargues(uuid)');
    await db.execute('CREATE INDEX idx_cargues_pending ON cargues(pending_sync)');
    await db.execute('CREATE INDEX idx_sync_queue_entity ON sync_queue(entity_type, entity_uuid)');
  }

  /// Actualiza la base de datos a una nueva versión
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migración de versión 1 a 2: Agregar tablas de cargues
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cargues (
          id INTEGER PRIMARY KEY,
          uuid TEXT NOT NULL UNIQUE,
          numero_cargue TEXT,
          usuario_id INTEGER NOT NULL,
          fecha TEXT NOT NULL,
          total REAL NOT NULL,
          estado TEXT NOT NULL DEFAULT 'pendiente',
          comentario TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0,
          pending_sync INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS cargues_detalles (
          id INTEGER PRIMARY KEY,
          uuid TEXT NOT NULL UNIQUE,
          cargue_id INTEGER NOT NULL,
          producto_id INTEGER NOT NULL,
          cantidad INTEGER NOT NULL,
          cantidad_original INTEGER,
          precio_unitario REAL NOT NULL,
          subtotal REAL NOT NULL,
          comentario TEXT,
          despachado INTEGER NOT NULL DEFAULT 0,
          faltante INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (cargue_id) REFERENCES cargues (id) ON DELETE CASCADE,
          FOREIGN KEY (producto_id) REFERENCES productos (id)
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_cargues_uuid ON cargues(uuid)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cargues_pending ON cargues(pending_sync)');
    }

    // Migración de versión 2 a 3: Agregar columna estado a facturas
    if (oldVersion < 3) {
      print('[DatabaseService] Migrando de versión $oldVersion a 3: Agregando columna estado a facturas');
      await db.execute('''
        ALTER TABLE facturas ADD COLUMN estado TEXT NOT NULL DEFAULT 'completada'
      ''');
      print('[DatabaseService] Migración completada: columna estado agregada');
    }

    // Migración de versión 3 a 4: Agregar codigo_barras a productos
    if (oldVersion < 4) {
      print('[DatabaseService] Migrando de versión $oldVersion a 4: Agregando columna codigo_barras a productos');
      await db.execute('''
        ALTER TABLE productos ADD COLUMN codigo_barras TEXT
      ''');
      print('[DatabaseService] Migración completada: columna codigo_barras agregada');
    }

    // Migración de versión 4 a 5: Agregar descuento_id a facturas
    if (oldVersion < 5) {
      print('[DatabaseService] Migrando de versión $oldVersion a 5: Agregando columna descuento_id a facturas');
      await db.execute('''
        ALTER TABLE facturas ADD COLUMN descuento_id INTEGER
      ''');
      print('[DatabaseService] Migración completada: columna descuento_id agregada');
    }

    // Migración de versión 5 a 6: Eliminar columna descripcion de listas_precios (recrear tabla)
    if (oldVersion < 6) {
      print('[DatabaseService] Migrando de versión $oldVersion a 6: Eliminando columna descripcion de listas_precios');

      // Crear tabla temporal
      await db.execute('''
        CREATE TABLE listas_precios_new (
          id INTEGER PRIMARY KEY,
          uuid TEXT NOT NULL UNIQUE,
          nombre TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Copiar datos (sin la columna descripcion)
      await db.execute('''
        INSERT INTO listas_precios_new (id, uuid, nombre, created_at, updated_at, synced)
        SELECT id, uuid, nombre, created_at, updated_at, synced FROM listas_precios
      ''');

      // Eliminar tabla antigua
      await db.execute('DROP TABLE listas_precios');

      // Renombrar tabla nueva
      await db.execute('ALTER TABLE listas_precios_new RENAME TO listas_precios');

      print('[DatabaseService] Migración completada: columna descripcion eliminada de listas_precios');
    }

    // Migración de versión 6 a 7: Agregar comentario a facturas_items
    if (oldVersion < 7) {
      print('[DatabaseService] Migrando de versión $oldVersion a 7: Agregando columna comentario a facturas_items');
      await db.execute('''
        ALTER TABLE facturas_items ADD COLUMN comentario TEXT
      ''');
      print('[DatabaseService] Migración completada: columna comentario agregada a facturas_items');
    }

    // Migración de versión 7 a 8: Agregar tabla descuentos
    if (oldVersion < 8) {
      print('[DatabaseService] Migrando de versión $oldVersion a 8: Agregando tabla descuentos');
      await db.execute('''
        CREATE TABLE descuentos (
          id INTEGER PRIMARY KEY,
          uuid TEXT NOT NULL UNIQUE,
          nombre TEXT NOT NULL,
          porcentaje REAL NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
      print('[DatabaseService] Migración completada: tabla descuentos creada');
    }

    // Migración de versión 8 a 9: Agregar tabla equipos
    if (oldVersion < 9) {
      print('[DatabaseService] Migrando de versión $oldVersion a 9: Agregando tabla equipos');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS equipos (
          id INTEGER PRIMARY KEY,
          nombre TEXT NOT NULL,
          descripcion TEXT,
          activo INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
      print('[DatabaseService] Migración completada: tabla equipos creada');
    }

    // Migración de versión 9 a 10: Agregar tablas sync_queue y sync_metadata
    if (oldVersion < 10) {
      print('[DatabaseService] Migrando de versión $oldVersion a 10: Agregando tablas de sincronización');

      // Tabla para gestionar la cola de sincronización
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entity_type TEXT NOT NULL,
          entity_uuid TEXT NOT NULL,
          operation TEXT NOT NULL,
          data TEXT NOT NULL,
          created_at TEXT NOT NULL,
          retry_count INTEGER NOT NULL DEFAULT 0,
          last_error TEXT,
          UNIQUE(entity_type, entity_uuid, operation)
        )
      ''');

      // Tabla para metadatos de sincronización
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Índice para mejorar búsquedas en sync_queue
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_entity ON sync_queue(entity_type, entity_uuid)');

      print('[DatabaseService] Migración completada: tablas sync_queue y sync_metadata creadas');
    }
  }

  /// Limpia toda la base de datos (útil para logout o reset)
  Future<void> clearDatabase() async {
    final db = await database;
    final tables = [
      'productos',
      'clientes',
      'categorias',
      'listas_precios',
      'precios',
      'usuarios',
      'descuentos',
      'equipos',
      'facturas',
      'facturas_items',
      'devoluciones',
      'devoluciones_items',
      'cargues',
      'cargues_detalles',
      'sync_queue',
      'sync_metadata',
    ];

    for (final table in tables) {
      await db.delete(table);
    }
  }

  /// Cierra la conexión a la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Verifica si hay operaciones pendientes de sincronización
  Future<bool> hasPendingSync() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sync_queue
    ''');
    final count = result.first['count'] as int;
    return count > 0;
  }

  /// Obtiene el número de operaciones pendientes de sincronización
  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sync_queue
    ''');
    return result.first['count'] as int;
  }
}
