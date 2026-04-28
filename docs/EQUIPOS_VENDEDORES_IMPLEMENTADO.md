# ✅ Sistema de Equipos de Vendedores - Implementación Completada

## 📋 Resumen

Se implementó exitosamente el sistema de equipos de vendedores que permite a los administradores crear equipos y asignar vendedores. Los vendedores en el mismo equipo pueden ver las facturas entre ellos.

---

## ✅ Cambios Implementados

### 1. **Nuevos Modelos** ✅

#### Modelo Equipo
**Archivo:** `src/models/Equipo.js`

```javascript
{
  id: INTEGER (PK, AUTO INCREMENT),
  nombre: STRING(100) UNIQUE NOT NULL,
  descripcion: TEXT,
  activo: BOOLEAN DEFAULT true,
  created_at: TIMESTAMP,
  updated_at: TIMESTAMP
}
```

#### Modelo UsuarioEquipo (Tabla Intermedia)
**Archivo:** `src/models/UsuarioEquipo.js`

```javascript
{
  id: INTEGER (PK, AUTO INCREMENT),
  usuario_id: INTEGER NOT NULL,
  equipo_id: INTEGER NOT NULL,
  fecha_asignacion: TIMESTAMP,
  UNIQUE(usuario_id, equipo_id)
}
```

### 2. **Asociaciones Agregadas** ✅
**Archivo:** `src/models/associations.js`

- `Usuario.belongsToMany(Equipo)` - Relación muchos a muchos
- `Equipo.belongsToMany(Usuario)` - Relación muchos a muchos
- Tabla intermedia: `UsuarioEquipo`

### 3. **Middleware isAdmin** ✅
**Archivo:** `src/middleware/isAdmin.js`

Middleware para proteger endpoints que solo deben ser accesibles por administradores.

```javascript
export const isAdmin = (req, res, next) => {
  if (req.user.rol !== 'admin') {
    return res.status(403).json({
      message: "Acceso denegado. Se requieren permisos de administrador."
    });
  }
  next();
};
```

### 4. **Controlador de Equipos** ✅
**Archivo:** `src/controllers/equiposController.js`

**Endpoints para Administradores:**
- `getEquipos()` - Listar todos los equipos
- `getEquipoById()` - Obtener un equipo
- `createEquipo()` - Crear equipo
- `updateEquipo()` - Actualizar equipo
- `deleteEquipo()` - Eliminar equipo
- `getMiembrosEquipo()` - Listar miembros de un equipo
- `addMiembroEquipo()` - Agregar vendedor a equipo
- `removeMiembroEquipo()` - Quitar vendedor de equipo

**Endpoints para Vendedores:**
- `getMisEquipos()` - Obtener equipos del usuario actual
- `getMisCompaneros()` - Obtener compañeros de equipo

### 5. **Rutas de Equipos** ✅
**Archivo:** `src/routes/equiposRoutes.js`

| Método | Endpoint | Rol | Descripción |
|--------|----------|-----|-------------|
| GET | `/api/equipos` | Admin | Listar todos los equipos |
| GET | `/api/equipos/:id` | Admin | Obtener equipo por ID |
| POST | `/api/equipos` | Admin | Crear nuevo equipo |
| PUT | `/api/equipos/:id` | Admin | Actualizar equipo |
| DELETE | `/api/equipos/:id` | Admin | Eliminar equipo |
| GET | `/api/equipos/:id/miembros` | Admin | Listar miembros del equipo |
| POST | `/api/equipos/:id/miembros` | Admin | Agregar vendedor al equipo |
| DELETE | `/api/equipos/:id/miembros/:usuarioId` | Admin | Quitar vendedor del equipo |
| GET | `/api/equipos/mis-equipos` | Todos | Equipos del usuario actual |
| GET | `/api/equipos/mis-companeros` | Todos | Compañeros de equipo |

### 6. **Modificación en getFacturas** ✅
**Archivo:** `src/controllers/facturasController.js`

**Lógica implementada:**

```javascript
// Admin: ve todas las facturas (o filtra por usuario)
if (usuarioAutenticado.rol === 'admin') {
  // Puede filtrar por usuario_id o usuarios_ids
}

// Vendedor: ve sus facturas + facturas de compañeros de equipo
else if (usuarioAutenticado.rol === 'vendedor') {
  // 1. Obtener equipos del usuario
  // 2. Obtener compañeros de esos equipos
  // 3. Filtrar facturas de todos los compañeros (incluyéndose)
}
```

**Antes:**
- Vendedor veía solo sus propias facturas

**Después:**
- Vendedor ve sus facturas + facturas de sus compañeros de equipo

---

## 📡 API Endpoints

### Admin - Gestión de Equipos

#### Crear Equipo
```bash
POST /api/equipos
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "nombre": "Equipo Norte",
  "descripcion": "Vendedores zona norte",
  "activo": true
}
```

**Respuesta:**
```json
{
  "id": 1,
  "nombre": "Equipo Norte",
  "descripcion": "Vendedores zona norte",
  "activo": true,
  "created_at": "2025-11-11T10:00:00.000Z",
  "updated_at": "2025-11-11T10:00:00.000Z"
}
```

#### Agregar Vendedor a Equipo
```bash
POST /api/equipos/1/miembros
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "usuario_id": 2
}
```

**Validaciones:**
- ✅ Solo vendedores pueden ser agregados
- ✅ No permite duplicados (mismo usuario en mismo equipo)
- ✅ Verifica que equipo y usuario existan

#### Listar Miembros de Equipo
```bash
GET /api/equipos/1/miembros
Authorization: Bearer <admin_token>
```

**Respuesta:**
```json
[
  {
    "id": 2,
    "nombre": "Juan Vendedor",
    "email": "juan@example.com",
    "rol": "vendedor",
    "UsuarioEquipos": {
      "fecha_asignacion": "2025-11-11T10:00:00.000Z"
    }
  }
]
```

### Vendedor - Consultar Equipos

#### Mis Equipos
```bash
GET /api/equipos/mis-equipos
Authorization: Bearer <vendedor_token>
```

**Respuesta:**
```json
[
  {
    "id": 1,
    "nombre": "Equipo Norte",
    "descripcion": "Vendedores zona norte",
    "activo": true,
    "cantidad_miembros": "3"
  }
]
```

#### Mis Compañeros
```bash
GET /api/equipos/mis-companeros
Authorization: Bearer <vendedor_token>
```

**Respuesta:**
```json
[
  {
    "id": 3,
    "nombre": "María Vendedora",
    "email": "maria@example.com",
    "equipos": [
      {
        "nombre": "Equipo Norte"
      }
    ]
  }
]
```

### Facturas con Equipos

#### Vendedor ve facturas de su equipo
```bash
GET /api/facturas
Authorization: Bearer <vendedor_token>
```

**Comportamiento:**
- Si el vendedor está en un equipo: ve facturas de todos los miembros
- Si el vendedor NO está en equipo: solo ve sus propias facturas

---

## 🎯 Flujo de Uso

### Escenario 1: Admin crea equipo y asigna vendedores

```
1. Admin crea equipo "Equipo A"
   POST /api/equipos { "nombre": "Equipo A" }

2. Admin agrega vendedor ID 2 al equipo
   POST /api/equipos/1/miembros { "usuario_id": 2 }

3. Admin agrega vendedor ID 3 al equipo
   POST /api/equipos/1/miembros { "usuario_id": 3 }

4. Ahora vendedores 2 y 3 pueden ver facturas entre ellos
```

### Escenario 2: Vendedor consulta facturas

**Vendedor ID 2 (en Equipo A con vendedores 2 y 3):**

```
GET /api/facturas
Authorization: Bearer <token_vendedor_2>

Resultado:
- Facturas creadas por vendedor 2 ✅
- Facturas creadas por vendedor 3 ✅ (compañero)
- Facturas creadas por vendedor 4 ❌ (no está en equipo)
```

---

## 🔒 Seguridad

### Validaciones Implementadas

1. **Solo vendedores en equipos:**
   - No se puede agregar admin a un equipo
   - Validación en `addMiembroEquipo()`

2. **No duplicados:**
   - UNIQUE constraint en `(usuario_id, equipo_id)`
   - Validación adicional en código

3. **Protección de endpoints:**
   - Todos los endpoints de gestión requieren rol `admin`
   - Middleware `isAdmin` valida permisos

4. **Vendedor no puede manipular:**
   - Vendedor NO puede agregar/quitar miembros
   - Vendedor solo consulta (mis-equipos, mis-companeros)

5. **Cascada en delete:**
   - Al eliminar equipo, se eliminan las relaciones `usuarios_equipos`
   - Al eliminar usuario, se eliminan sus relaciones con equipos

---

## 📊 Casos de Uso

### Caso 1: Vendedor sin equipo

```
Usuario: Vendedor ID 5 (sin equipo)
GET /api/facturas
→ Solo ve sus propias facturas
```

### Caso 2: Vendedor en un equipo

```
Usuario: Vendedor ID 2 (Equipo A con 2, 3, 4)
GET /api/facturas
→ Ve facturas de vendedores 2, 3 y 4
```

### Caso 3: Vendedor en múltiples equipos

```
Usuario: Vendedor ID 2 (Equipo A con 2, 3 | Equipo B con 2, 5)
GET /api/facturas
→ Ve facturas de vendedores 2, 3 y 5
```

### Caso 4: Admin filtra por vendedor

```
Usuario: Admin
GET /api/facturas?usuario_id=2
→ Ve solo facturas del vendedor 2
```

---

## 📁 Archivos Creados/Modificados

| Archivo | Acción |
|---------|--------|
| `src/models/Equipo.js` | ✅ Creado |
| `src/models/UsuarioEquipo.js` | ✅ Creado |
| `src/models/associations.js` | ✏️ Modificado (asociaciones) |
| `src/middleware/isAdmin.js` | ✅ Creado |
| `src/controllers/equiposController.js` | ✅ Creado |
| `src/routes/equiposRoutes.js` | ✅ Creado |
| `src/controllers/facturasController.js` | ✏️ Modificado (getFacturas) |
| `src/app.js` | ✏️ Modificado (ruta equipos) |
| `create-equipos-tables.js` | ✅ Creado (script migración) |

---

## 🧪 Testing

### Test 1: Crear equipo (Admin)
```bash
curl -X POST http://localhost:4000/api/equipos \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Equipo Test","descripcion":"Equipo de prueba"}'
```

**Esperado:** Status 201, equipo creado

### Test 2: Agregar vendedor a equipo (Admin)
```bash
curl -X POST http://localhost:4000/api/equipos/1/miembros \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"usuario_id":2}'
```

**Esperado:** Status 201, vendedor agregado

### Test 3: Vendedor intenta agregar miembro (debe fallar)
```bash
curl -X POST http://localhost:4000/api/equipos/1/miembros \
  -H "Authorization: Bearer <vendedor_token>" \
  -H "Content-Type: application/json" \
  -d '{"usuario_id":3}'
```

**Esperado:** Status 403, acceso denegado

### Test 4: Vendedor ve facturas de equipo
```bash
curl -X GET http://localhost:4000/api/facturas \
  -H "Authorization: Bearer <vendedor_token>"
```

**Esperado:** Status 200, facturas del equipo

---

## 🚀 Scripts Disponibles

### Crear tablas de equipos
```bash
node create-equipos-tables.js
```

**Resultado:**
```
✅ Tabla 'equipos' creada/actualizada
✅ Tabla 'usuarios_equipos' creada/actualizada
✅ Equipo A creado
✅ Equipo B creado
```

---

## 📝 Notas Importantes

1. **Un vendedor puede pertenecer a múltiples equipos**
   - Relación muchos a muchos
   - Ve facturas de todos sus equipos

2. **Solo vendedores en equipos**
   - Admin no puede ser agregado a equipos
   - Validación en código y lógica de negocio

3. **Campo `activo` en equipos**
   - Permite desactivar equipos sin perder datos históricos
   - Equipos inactivos no se incluyen en consultas de vendedores

4. **Cascada en eliminación**
   - Eliminar equipo → elimina relaciones `usuarios_equipos`
   - Eliminar usuario → elimina sus relaciones con equipos

5. **Equipos en datos de prueba**
   - Se crearon "Equipo A" y "Equipo B" automáticamente
   - Admin puede crear/editar/eliminar según necesidad

---

## ✅ Checklist de Implementación

- [x] Modelo Equipo creado
- [x] Modelo UsuarioEquipo creado
- [x] Asociaciones many-to-many configuradas
- [x] Middleware isAdmin creado
- [x] Controlador de equipos con todos los endpoints
- [x] Rutas de equipos registradas
- [x] getFacturas modificado para incluir equipo
- [x] Script de migración creado y ejecutado
- [x] Tablas creadas en BD
- [x] Datos de prueba insertados
- [x] Documentación Swagger actualizada

---

## 🎉 Resultado Final

**Admin puede:**
- ✅ Crear/editar/eliminar equipos
- ✅ Agregar/quitar vendedores de equipos
- ✅ Ver todos los equipos y miembros
- ✅ Filtrar facturas por vendedor

**Vendedor puede:**
- ✅ Ver sus equipos
- ✅ Ver sus compañeros de equipo
- ✅ Ver facturas propias + facturas de compañeros
- ❌ NO puede gestionar equipos (solo admin)

**Fecha de implementación:** 2025-11-11
**Versión:** 1.3.0
**Estado:** ✅ COMPLETADO