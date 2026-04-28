# Implementación de Equipos de Vendedores

## Descripción
Sistema que permite a los administradores crear equipos de vendedores. Los vendedores que pertenecen al mismo equipo pueden ver las facturas entre ellos.

## Base de Datos

### 1. Modelos Sequelize

#### Archivo: `server/models/Equipo.js`

```javascript
const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Equipo = sequelize.define('Equipo', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    nombre: {
      type: DataTypes.STRING(100),
      allowNull: false,
      unique: true,
      validate: {
        notEmpty: {
          msg: 'El nombre del equipo es requerido'
        },
        len: {
          args: [1, 100],
          msg: 'El nombre debe tener entre 1 y 100 caracteres'
        }
      }
    },
    descripcion: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    activo: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
      allowNull: false
    }
  }, {
    tableName: 'equipos',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  return Equipo;
};
```

#### Archivo: `server/models/UsuarioEquipo.js`

```javascript
const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const UsuarioEquipo = sequelize.define('UsuarioEquipo', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    usuario_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'usuarios',
        key: 'id'
      }
    },
    equipo_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'equipos',
        key: 'id'
      }
    }
  }, {
    tableName: 'usuarios_equipos',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
      {
        unique: true,
        fields: ['usuario_id', 'equipo_id']
      },
      {
        fields: ['usuario_id']
      },
      {
        fields: ['equipo_id']
      }
    ]
  });

  return UsuarioEquipo;
};
```

### 2. Actualizar Asociaciones

#### Archivo: `server/models/index.js`

Agregar estas líneas después de definir todos los modelos:

```javascript
// Importar nuevos modelos
const Equipo = require('./Equipo')(sequelize);
const UsuarioEquipo = require('./UsuarioEquipo')(sequelize);

// Asociaciones de Equipos
Equipo.belongsToMany(Usuario, {
  through: UsuarioEquipo,
  foreignKey: 'equipo_id',
  otherKey: 'usuario_id',
  as: 'miembros'
});

Usuario.belongsToMany(Equipo, {
  through: UsuarioEquipo,
  foreignKey: 'usuario_id',
  otherKey: 'equipo_id',
  as: 'equipos'
});

// Exportar
module.exports = {
  sequelize,
  Usuario,
  Cliente,
  Producto,
  Categoria,
  Factura,
  DetalleFactura,
  Descuento,
  Equipo,
  UsuarioEquipo
};
```

### 3. Migración

Crear archivo: `server/migrations/YYYYMMDDHHMMSS-crear-equipos.js`

```javascript
'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Crear tabla equipos
    await queryInterface.createTable('equipos', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true
      },
      nombre: {
        type: Sequelize.STRING(100),
        allowNull: false,
        unique: true
      },
      descripcion: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      activo: {
        type: Sequelize.BOOLEAN,
        defaultValue: true,
        allowNull: false
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });

    // Crear tabla usuarios_equipos
    await queryInterface.createTable('usuarios_equipos', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true
      },
      usuario_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'usuarios',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      equipo_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'equipos',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });

    // Crear índices
    await queryInterface.addIndex('usuarios_equipos', ['usuario_id']);
    await queryInterface.addIndex('usuarios_equipos', ['equipo_id']);
    await queryInterface.addIndex('usuarios_equipos', ['usuario_id', 'equipo_id'], {
      unique: true,
      name: 'unique_usuario_equipo'
    });
    await queryInterface.addIndex('equipos', ['activo']);
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('usuarios_equipos');
    await queryInterface.dropTable('equipos');
  }
};
```

### 4. Seeders (Datos de Prueba)

Crear archivo: `server/seeders/YYYYMMDDHHMMSS-equipos-demo.js`

```javascript
'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Insertar equipos de ejemplo
    await queryInterface.bulkInsert('equipos', [
      {
        nombre: 'Equipo A',
        descripcion: 'Vendedores de la zona norte',
        activo: true,
        created_at: new Date(),
        updated_at: new Date()
      },
      {
        nombre: 'Equipo B',
        descripcion: 'Vendedores de la zona sur',
        activo: true,
        created_at: new Date(),
        updated_at: new Date()
      }
    ]);

    // Obtener IDs de equipos y usuarios para las relaciones
    // Nota: Ajustar según los IDs reales en tu base de datos
    await queryInterface.bulkInsert('usuarios_equipos', [
      {
        usuario_id: 2, // Ajustar según tu BD
        equipo_id: 1,
        created_at: new Date(),
        updated_at: new Date()
      },
      {
        usuario_id: 3,
        equipo_id: 1,
        created_at: new Date(),
        updated_at: new Date()
      },
      {
        usuario_id: 4,
        equipo_id: 2,
        created_at: new Date(),
        updated_at: new Date()
      }
    ]);
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.bulkDelete('usuarios_equipos', null, {});
    await queryInterface.bulkDelete('equipos', null, {});
  }
};
```

## Backend (Node.js / Express)

### 5. Archivo: `server/routes/equipos.js`

```javascript
const express = require('express');
const router = express.Router();
const { Equipo, UsuarioEquipo, Usuario } = require('../models');
const { authenticateToken, isAdmin } = require('../middleware/auth');

// ==================== ENDPOINTS PARA ADMINISTRADORES ====================

// GET /api/equipos - Listar todos los equipos
router.get('/', authenticateToken, isAdmin, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        e.*,
        COUNT(ue.usuario_id) as cantidad_miembros
      FROM equipos e
      LEFT JOIN usuarios_equipos ue ON e.id = ue.equipo_id
      GROUP BY e.id
      ORDER BY e.nombre ASC
    `);

    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener equipos:', error);
    res.status(500).json({ error: 'Error al obtener equipos' });
  }
});

// GET /api/equipos/:id - Obtener un equipo por ID
router.get('/:id', authenticateToken, isAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const equipoResult = await pool.query(
      'SELECT * FROM equipos WHERE id = $1',
      [id]
    );

    if (equipoResult.rows.length === 0) {
      return res.status(404).json({ error: 'Equipo no encontrado' });
    }

    res.json(equipoResult.rows[0]);
  } catch (error) {
    console.error('Error al obtener equipo:', error);
    res.status(500).json({ error: 'Error al obtener equipo' });
  }
});

// POST /api/equipos - Crear un nuevo equipo
router.post('/', authenticateToken, isAdmin, async (req, res) => {
  try {
    const { nombre, descripcion, activo = true } = req.body;

    if (!nombre || nombre.trim() === '') {
      return res.status(400).json({ error: 'El nombre del equipo es requerido' });
    }

    const result = await pool.query(
      `INSERT INTO equipos (nombre, descripcion, activo)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [nombre.trim(), descripcion || null, activo]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error al crear equipo:', error);

    // Error de nombre duplicado
    if (error.code === '23505') {
      return res.status(400).json({ error: 'Ya existe un equipo con ese nombre' });
    }

    res.status(500).json({ error: 'Error al crear equipo' });
  }
});

// PUT /api/equipos/:id - Actualizar un equipo
router.put('/:id', authenticateToken, isAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, descripcion, activo } = req.body;

    if (!nombre || nombre.trim() === '') {
      return res.status(400).json({ error: 'El nombre del equipo es requerido' });
    }

    const result = await pool.query(
      `UPDATE equipos
       SET nombre = $1, descripcion = $2, activo = $3
       WHERE id = $4
       RETURNING *`,
      [nombre.trim(), descripcion || null, activo, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Equipo no encontrado' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error al actualizar equipo:', error);

    // Error de nombre duplicado
    if (error.code === '23505') {
      return res.status(400).json({ error: 'Ya existe un equipo con ese nombre' });
    }

    res.status(500).json({ error: 'Error al actualizar equipo' });
  }
});

// DELETE /api/equipos/:id - Eliminar un equipo
router.delete('/:id', authenticateToken, isAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'DELETE FROM equipos WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Equipo no encontrado' });
    }

    res.json({ mensaje: 'Equipo eliminado exitosamente', equipo: result.rows[0] });
  } catch (error) {
    console.error('Error al eliminar equipo:', error);
    res.status(500).json({ error: 'Error al eliminar equipo' });
  }
});

// ==================== GESTIÓN DE MIEMBROS ====================

// GET /api/equipos/:id/miembros - Obtener miembros de un equipo
router.get('/:id/miembros', authenticateToken, isAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(`
      SELECT
        u.id,
        u.nombre,
        u.email,
        u.rol,
        ue.fecha_asignacion
      FROM usuarios u
      INNER JOIN usuarios_equipos ue ON u.id = ue.usuario_id
      WHERE ue.equipo_id = $1
      ORDER BY u.nombre ASC
    `, [id]);

    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener miembros del equipo:', error);
    res.status(500).json({ error: 'Error al obtener miembros del equipo' });
  }
});

// POST /api/equipos/:id/miembros - Agregar un vendedor a un equipo
router.post('/:id/miembros', authenticateToken, isAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { usuario_id } = req.body;

    if (!usuario_id) {
      return res.status(400).json({ error: 'El ID del usuario es requerido' });
    }

    // Verificar que el equipo existe
    const equipoResult = await pool.query(
      'SELECT id FROM equipos WHERE id = $1',
      [id]
    );

    if (equipoResult.rows.length === 0) {
      return res.status(404).json({ error: 'Equipo no encontrado' });
    }

    // Verificar que el usuario existe y es vendedor
    const usuarioResult = await pool.query(
      'SELECT id, rol FROM usuarios WHERE id = $1',
      [usuario_id]
    );

    if (usuarioResult.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    if (usuarioResult.rows[0].rol !== 'vendedor') {
      return res.status(400).json({ error: 'Solo se pueden agregar vendedores a equipos' });
    }

    // Agregar usuario al equipo
    const result = await pool.query(
      `INSERT INTO usuarios_equipos (usuario_id, equipo_id)
       VALUES ($1, $2)
       RETURNING *`,
      [usuario_id, id]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error al agregar miembro al equipo:', error);

    // Error de duplicado (usuario ya está en el equipo)
    if (error.code === '23505') {
      return res.status(400).json({ error: 'El usuario ya pertenece a este equipo' });
    }

    res.status(500).json({ error: 'Error al agregar miembro al equipo' });
  }
});

// DELETE /api/equipos/:id/miembros/:usuarioId - Quitar un vendedor de un equipo
router.delete('/:id/miembros/:usuarioId', authenticateToken, isAdmin, async (req, res) => {
  try {
    const { id, usuarioId } = req.params;

    const result = await pool.query(
      'DELETE FROM usuarios_equipos WHERE equipo_id = $1 AND usuario_id = $2 RETURNING *',
      [id, usuarioId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'El usuario no pertenece a este equipo' });
    }

    res.json({ mensaje: 'Usuario removido del equipo exitosamente' });
  } catch (error) {
    console.error('Error al remover miembro del equipo:', error);
    res.status(500).json({ error: 'Error al remover miembro del equipo' });
  }
});

// ==================== ENDPOINTS PARA VENDEDORES ====================

// GET /api/equipos/mis-equipos - Obtener equipos del usuario actual
router.get('/mis-equipos/lista', authenticateToken, async (req, res) => {
  try {
    const usuarioId = req.user.id;

    const result = await pool.query(`
      SELECT
        e.id,
        e.nombre,
        e.descripcion,
        COUNT(ue2.usuario_id) as cantidad_miembros
      FROM equipos e
      INNER JOIN usuarios_equipos ue ON e.id = ue.equipo_id
      LEFT JOIN usuarios_equipos ue2 ON e.id = ue2.equipo_id
      WHERE ue.usuario_id = $1 AND e.activo = true
      GROUP BY e.id
      ORDER BY e.nombre ASC
    `, [usuarioId]);

    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener mis equipos:', error);
    res.status(500).json({ error: 'Error al obtener mis equipos' });
  }
});

// GET /api/equipos/mis-companeros - Obtener compañeros de equipo
router.get('/mis-companeros/lista', authenticateToken, async (req, res) => {
  try {
    const usuarioId = req.user.id;

    const result = await pool.query(`
      SELECT DISTINCT
        u.id,
        u.nombre,
        u.email,
        array_agg(DISTINCT e.nombre) as equipos
      FROM usuarios u
      INNER JOIN usuarios_equipos ue ON u.id = ue.usuario_id
      INNER JOIN equipos e ON ue.equipo_id = e.id
      WHERE ue.equipo_id IN (
        SELECT equipo_id
        FROM usuarios_equipos
        WHERE usuario_id = $1
      )
      AND u.id != $1
      AND e.activo = true
      GROUP BY u.id, u.nombre, u.email
      ORDER BY u.nombre ASC
    `, [usuarioId]);

    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener compañeros:', error);
    res.status(500).json({ error: 'Error al obtener compañeros' });
  }
});

module.exports = router;
```

### 4. Archivo: `server/routes/facturas.js` (Modificación)

Agregar la siguiente lógica al endpoint GET `/api/facturas`:

```javascript
// Modificar el endpoint existente para incluir facturas de compañeros de equipo
router.get('/', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.rol;
    const { usuario_id, usuarios_ids } = req.query;

    let query = `
      SELECT
        f.*,
        c.nombre as cliente_nombre,
        u.nombre as usuario_nombre
      FROM facturas f
      LEFT JOIN clientes c ON f.cliente_id = c.id
      LEFT JOIN usuarios u ON f.usuario_id = u.id
      WHERE 1=1
    `;

    const params = [];

    // Si es admin
    if (userRole === 'admin') {
      // Admin puede filtrar por usuario específico o por lista de usuarios
      if (usuario_id) {
        params.push(usuario_id);
        query += ` AND f.usuario_id = $${params.length}`;
      } else if (usuarios_ids) {
        const idsArray = usuarios_ids.split(',').map(id => parseInt(id));
        params.push(idsArray);
        query += ` AND f.usuario_id = ANY($${params.length})`;
      }
      // Si no hay filtros, ver todas las facturas
    } else {
      // Si es vendedor, ver sus facturas Y las de sus compañeros de equipo
      params.push(userId);
      query += ` AND f.usuario_id IN (
        SELECT DISTINCT ue.usuario_id
        FROM usuarios_equipos ue
        WHERE ue.equipo_id IN (
          SELECT equipo_id
          FROM usuarios_equipos
          WHERE usuario_id = $${params.length}
        )
      )`;
    }

    query += ' ORDER BY f.fecha_creacion DESC';

    console.log('Query facturas:', query);
    console.log('Params:', params);

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener facturas:', error);
    res.status(500).json({ error: 'Error al obtener facturas' });
  }
});
```

### 5. Archivo: `server/middleware/auth.js` (Agregar función isAdmin)

```javascript
// Middleware para verificar que el usuario es admin
function isAdmin(req, res, next) {
  if (req.user.rol !== 'admin') {
    return res.status(403).json({ error: 'Acceso denegado. Se requieren permisos de administrador.' });
  }
  next();
}

module.exports = {
  authenticateToken,
  isAdmin
};
```

### 6. Archivo: `server/index.js` (Agregar ruta de equipos)

```javascript
// Agregar esta línea con las demás rutas
const equiposRoutes = require('./routes/equipos');

// Agregar esta línea con los demás app.use
app.use('/api/equipos', equiposRoutes);
```

## Próximos Pasos

Después de implementar el backend:
1. Crear los modelos en Flutter (Equipo, UsuarioEquipo)
2. Crear el repository para equipos
3. Crear pantalla de gestión de equipos (solo admin)
4. Actualizar la pantalla de facturas para mostrar facturas del equipo
5. Agregar indicadores visuales para distinguir facturas propias vs. de compañeros

## Notas de Implementación

- Los equipos se eliminan en cascada, lo que significa que si se elimina un equipo, se eliminan todas las relaciones usuarios_equipos
- Un vendedor puede pertenecer a múltiples equipos
- Solo los administradores pueden gestionar equipos
- Los vendedores automáticamente ven las facturas de sus compañeros de equipo
- El campo `activo` permite desactivar equipos sin perder los datos históricos
