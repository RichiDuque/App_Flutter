# Contexto del Proyecto - Sistema de Facturación

## Descripción General

Sistema de facturación completo con arquitectura cliente-servidor:
- **Frontend**: Aplicación móvil Flutter (Android/iOS)
- **Backend**: API REST con Node.js + Express + Sequelize
- **Base de datos**: PostgreSQL

## Arquitectura del Proyecto

```
SistemaFacturacion/
├── facturacion_app/          # Aplicación Flutter
│   └── lib/
│       └── src/
│           ├── features/      # Funcionalidades por módulo
│           ├── core/          # Servicios compartidos
│           └── utils/         # Utilidades
└── backend/                   # API Node.js
    └── src/
        ├── controllers/       # Lógica de negocio
        ├── models/           # Modelos Sequelize
        ├── routes/           # Rutas API
        └── middleware/       # Middleware (auth, errors)
```

## Stack Tecnológico

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **Gestión de estado**: Riverpod
- **HTTP Client**: Dio
- **Navegación**: go_router
- **Tema**: Material Design con tema oscuro personalizado
  - Primary: Colors.grey[900]
  - Surface: Colors.grey[850]
  - Cards: Colors.grey[800]

### Backend (Node.js)
- **Runtime**: Node.js con ES Modules
- **Framework**: Express
- **ORM**: Sequelize
- **Autenticación**: JWT (jsonwebtoken)
- **Validación**: express-validator
- **Base de datos**: PostgreSQL

## Modelos de Datos Principales

### Usuario
- Vendedores y administradores del sistema
- **Campos importantes**:
  - `rol`: 'admin' | 'vendedor'
  - `lista_id`: Lista de precios asignada al vendedor (NUEVA LÓGICA)
  - `equipo_id`: Referencia al equipo del vendedor

### Cliente
- Clientes que compran productos
- **Campos importantes**:
  - `nombre`, `contacto`, `direccion`
  - `lista_id`: ⚠️ Ya no se usa para facturación (legacy, se usa lista del vendedor)

### Producto
- Productos disponibles para venta
- **Campos importantes**:
  - `nombre`, `descripcion`, `codigo_barras`
  - `stock`: Inventario actual
  - `categoria_id`: Categoría del producto

### Precio
- Precios de productos según lista
- **Campos importantes**:
  - `producto_id`
  - `lista_id`: Referencia a la lista de precios
  - `precio`: Precio del producto en esa lista

### ListaPrecio
- Listas de precios (Ej: "Mayorista", "Minorista", "Distribuidor")
- **Campos importantes**:
  - `nombre`, `descripcion`

### Factura
- Facturas de venta
- **Campos importantes**:
  - `cliente_id`: Cliente que compra
  - `usuario_id`: Vendedor que crea la factura
  - `numero_factura`: Formato "USUARIO_ID-00001" (consecutivo por vendedor)
  - `total`: Total de la factura
  - `descuento_id`: Descuento aplicado (opcional)
  - `estado`: 'pagada' | 'reembolsada'
  - `fecha`: Fecha de creación

### DetalleFactura
- Productos incluidos en una factura
- **Campos importantes**:
  - `factura_id`
  - `producto_id`
  - `cantidad`
  - `precio_unitario`: Precio al momento de la venta
  - `subtotal`: cantidad × precio_unitario
  - `comentario`: Comentarios adicionales

### Devolucion
- Devoluciones/reembolsos de facturas
- **Campos importantes**:
  - `factura_id`: Factura original
  - `cliente_id`, `usuario_id`
  - `motivo`
  - `total`: Total devuelto
  - `fecha`: Fecha de la devolución

### DetalleDevolucion
- Productos devueltos
- **Campos importantes**:
  - `devolucion_id`
  - `producto_id`
  - `cantidad`: Cantidad devuelta
  - `precio_unitario`, `subtotal`

### Equipo
- Equipos de vendedores
- **Campos importantes**:
  - `nombre`, `descripcion`

### UsuarioEquipo
- Relación muchos a muchos entre usuarios y equipos
- **Campos importantes**:
  - `usuario_id`
  - `equipo_id`

### Descuento
- Descuentos aplicables a facturas
- **Campos importantes**:
  - `nombre`: Nombre del descuento
  - `porcentaje`: Porcentaje de descuento (0-100)
  - `uuid`: Identificador único

### Categoria
- Categorías de productos
- **Campos importantes**:
  - `nombre`: Nombre de la categoría
  - `descripcion`: Descripción (opcional)
  - `uuid`: Identificador único

## Lógica de Negocio Importante

### 1. Asignación de Precios (CAMBIO RECIENTE)
**✅ LÓGICA ACTUAL**: Los precios de las facturas se toman de la lista de precios asignada al **vendedor** que crea la factura.

- El vendedor tiene un `lista_id` asignado
- Al crear una factura, se buscan los precios en `Precio` usando `usuario.lista_id`
- El `cliente.lista_id` ya **NO** se usa para facturación (campo legacy)

**Funciones afectadas**:
- `createFactura()`: Valida que el vendedor tenga `lista_id`, busca precios con `usuario.lista_id`
- `actualizarFactura()`: Busca precios con `usuario.lista_id`

### 2. Numeración de Facturas
- Formato: `"USUARIO_ID-00001"`
- Consecutivo por vendedor (cada vendedor tiene su propia secuencia)
- Función: `generarNumeroFactura(usuarioId, transaction)`

### 3. Devoluciones/Reembolsos
**Reglas**:
- ✅ **Restricción de mismo día removida**: Se pueden hacer devoluciones en cualquier momento
- Se pueden devolver cantidades parciales de productos (no todo o nada)
- Al procesar devolución:
  1. Se crea registro en `Devolucion` y `DetalleDevolucion`
  2. Se repone el inventario (`Producto.stock += cantidad`)
  3. Si se devuelve el total de la factura, `factura.estado = 'reembolsada'`
- Pantalla de detalle de reembolso con información completa

**Endpoint**: `POST /api/facturas/:id/devolucion`
**Body**: `{ detalles: [{ detalle_id: number, cantidad: number }] }`

### 4. Gestión de Inventario
- Al crear factura: Se registra movimiento en `MovimientosInventario` tipo "venta"
- Al procesar devolución: Se incrementa el stock del producto
- **Nota**: El backend NO decrementa stock automáticamente al vender (esto puede ser una mejora futura)

### 5. Permisos y Roles
- **Admin**: Ve todas las facturas, puede filtrar por usuario(s)
- **Vendedor**: Ve sus facturas + facturas de compañeros de equipo
- Autenticación mediante JWT (middleware `verifyToken`)
- Middleware `checkRole(['admin', 'vendedor'])` para endpoints protegidos

### 6. Equipos de Vendedores
- Un vendedor puede pertenecer a múltiples equipos
- Los vendedores ven las facturas de todos sus compañeros de equipo
- Relación: `Usuario` ↔ `UsuarioEquipo` ↔ `Equipo`

## Estructura de la App Flutter

### Core
- **Providers**: Riverpod providers globales (auth, theme, etc.)
- **Services**: Servicios compartidos (API client, storage)

### Features (Módulos)
Cada feature sigue arquitectura por capas:
```
feature/
├── data/
│   └── [feature]_repository.dart    # Comunicación con API
├── domain/
│   └── [feature].dart                # Modelos de datos
└── presentation/
    ├── [feature]_screen.dart         # Pantallas
    └── widgets/                      # Widgets específicos
```

**Features principales**:
- `auth`: Login, registro, autenticación
- `clientes`: Gestión de clientes
- `productos`: Gestión de productos (CRUD, búsqueda por código de barras)
- `facturas`: Creación y listado de facturas, devoluciones
- `facturacion`: Creación de facturas con edición de cantidades y swipe-to-delete
- `home`: Pantalla principal, drawer de navegación
- `usuarios`: Gestión de usuarios/vendedores
- `categorias`: Gestión de categorías de productos
- `descuentos`: Gestión de descuentos
- `configuracion`: Pantalla de gestión (categorías y descuentos)

## Endpoints API Importantes

### Autenticación
- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Registro

### Facturas
- `GET /api/facturas` - Listar facturas (filtros: usuario_id, usuarios_ids)
- `GET /api/facturas/:id` - Detalle de factura
- `POST /api/facturas` - Crear factura
- `PUT /api/facturas/:id` - Actualizar factura
- `DELETE /api/facturas/:id` - Eliminar factura
- `POST /api/facturas/:id/devolucion` - Procesar devolución

### Productos
- `GET /api/productos` - Listar productos
- `GET /api/productos/:id` - Detalle de producto
- `POST /api/productos` - Crear producto
- `PUT /api/productos/:id` - Actualizar producto
- `DELETE /api/productos/:id` - Eliminar producto

### Clientes
- `GET /api/clientes` - Listar clientes
- `POST /api/clientes` - Crear cliente
- `PUT /api/clientes/:id` - Actualizar cliente

### Precios
- `GET /api/precios` - Listar precios (filtros: producto_id, lista_id)
- `POST /api/precios` - Crear precio
- `PUT /api/precios/:id` - Actualizar precio

### Usuarios
- `GET /api/usuarios` - Listar usuarios
- `POST /api/usuarios` - Crear usuario
- `PUT /api/usuarios/:id` - Actualizar usuario

### Categorías
- `GET /api/categorias` - Listar categorías
- `POST /api/categorias` - Crear categoría
- `PUT /api/categorias/:id` - Actualizar categoría
- `DELETE /api/categorias/:id` - Eliminar categoría

### Descuentos
- `GET /api/descuentos` - Listar descuentos
- `GET /api/descuentos/:id` - Obtener descuento por ID
- `POST /api/descuentos` - Crear descuento
- `PUT /api/descuentos/:id` - Actualizar descuento
- `DELETE /api/descuentos/:id` - Eliminar descuento

## Funcionalidades Implementadas

### ✅ Completadas

1. **Sistema de Autenticación**
   - Login con JWT
   - Registro de usuarios
   - Middleware de autenticación

2. **Gestión de Productos**
   - CRUD completo
   - Búsqueda por código de barras
   - Control de inventario

3. **Gestión de Clientes**
   - CRUD completo
   - Sin dependencia de lista de precios para facturación

4. **Facturación**
   - Crear facturas con múltiples productos
   - Numeración consecutiva por vendedor
   - Aplicación de descuentos
   - Precios según lista del vendedor
   - Comentarios por producto
   - Edición de cantidad por clic (además de botones +/-)
   - Swipe-to-delete para remover productos
   - Footer scrollable (no fijo)
   - Cliente por defecto (ID 1) si no se selecciona

5. **Devoluciones/Reembolsos**
   - Selección de cantidades parciales
   - ✅ Sin restricción de mismo día
   - Reposición automática de inventario
   - UI con controles +/- para cantidades
   - Pantalla de detalle de reembolso

6. **Gestión de Precios**
   - Múltiples listas de precios
   - Asignación de precios por producto y lista
   - Precios tomados del vendedor (no del cliente)

7. **Equipos de Vendedores**
   - Creación y gestión de equipos
   - Visibilidad de facturas entre compañeros

8. **Gestión de Categorías y Descuentos**
   - CRUD completo de categorías
   - CRUD completo de descuentos
   - Pantalla "Gestión" con tabs (solo admin)
   - Validaciones de datos

9. **UI/UX**
   - Tema oscuro personalizado
   - Drawer de navegación con menú lateral persistente
   - Pantallas de detalle de facturas y reembolsos
   - Formularios de creación/edición
   - Diálogos de confirmación para operaciones críticas

### Pantallas Principales

1. **Login** (`login_screen.dart`)
2. **Home** (`home_screen.dart`)
3. **Productos** (`productos_screen.dart`, `producto_form_screen.dart`)
4. **Clientes** (`clientes_screen.dart`, `cliente_form_screen.dart`)
5. **Facturas** (`facturas_screen.dart`, `factura_detalle_screen.dart`)
6. **Facturación** (`factura_detail_screen.dart` - creación de facturas)
7. **Usuarios** (`usuarios_screen.dart`, `usuario_form_screen.dart`)
8. **Gestión** (`gestion_screen.dart` con `categorias_tab.dart` y `descuentos_tab.dart`)
9. **Reembolsos** (`reembolso_detalle_screen.dart`)

### Drawer de Navegación
Opciones disponibles:
- Inicio
- Productos
- Clientes
- Facturas
- Listas de Precio
- Usuarios (solo admin)
- Vendedores (solo admin)
- Gestión (solo admin) ⭐ NUEVO
- Equipos
- ~~Historial~~ (removido)
- ~~Descuentos~~ (movido a Gestión)

## Configuración del Proyecto

### Backend
```javascript
// Puerto por defecto
PORT=3000

// Base de datos
DB_HOST=localhost
DB_PORT=5432
DB_NAME=facturacion
DB_USER=postgres
DB_PASSWORD=your_password

// JWT
JWT_SECRET=your_secret_key
```

### Frontend
```dart
// Base URL del API
const String baseUrl = 'http://localhost:3000/api';
```

## Convenciones de Código

### Backend
- ES Modules (`import/export`)
- Async/await con `asyncHandler` middleware
- Transacciones Sequelize para operaciones críticas
- Validación de datos con express-validator
- Manejo de errores centralizado

### Frontend
- Dart 3.x
- Riverpod para state management
- `ConsumerWidget` / `ConsumerStatefulWidget`
- Repositorios para comunicación con API
- Manejo de errores con try/catch y DioException

## Problemas Conocidos y Soluciones

### 1. Tipos de Datos PostgreSQL
**Problema**: Los campos `DECIMAL` se devuelven como `String` en JSON.
**Solución**: Parsear con `double.tryParse()` o `parseFloat()` según el lenguaje.

### 2. Flutter Analyze
- 44 warnings/info (mayoría son estilo)
- 2 unnecessary cast warnings
- Múltiples `avoid_print` (debug statements)
- No hay errores críticos

### 3. Gestión de Stock
**Nota**: Actualmente el stock NO se decrementa automáticamente al crear factura.
Solo se registra en `MovimientosInventario`.
Esto puede requerir implementación futura.

## Cambios Recientes Importantes

### Cambio de Lógica de Precios (2025-11-29)
- **Antes**: Los precios se tomaban del `cliente.lista_id`
- **Ahora**: Los precios se toman del `usuario.lista_id` (vendedor)
- **Archivos modificados**:
  - `backend/src/controllers/facturasController.js` (createFactura, actualizarFactura)

### Mejoras en Devoluciones (2025-11-29)
- **Antes**: Selección todo/nada con checkboxes
- **Ahora**: Selección de cantidades con botones +/-
- **Formato UI**: "X / Y" (cantidad a devolver / cantidad total)
- **Archivos modificados**:
  - `facturacion_app/lib/src/features/facturas/presentation/factura_detalle_screen.dart`
  - `facturacion_app/lib/src/features/facturas/data/facturas_repository.dart`
  - `backend/src/controllers/facturasController.js` (procesarDevolucion)
  - `backend/src/routes/facturasRoutes.js`

### Cambios en UI (2025-11-29)
1. **Detalle de Factura**:
   - Removida línea "TPV"
   - "Empleado" ahora muestra nombre del vendedor real (no "Propietario")

2. **Navegación**:
   - Removido "Historial" del drawer

### Mejoras en Facturación (2025-12-03)
1. **Edición de cantidades**:
   - Click en cantidad abre diálogo para editar directamente
   - Mantiene botones +/- para incremento/decremento
   - Validación de cantidad > 0

2. **Interfaz de productos**:
   - Footer scrollable (no fijo) en pantalla de creación de factura
   - Swipe-to-delete para remover productos de la lista
   - Confirmación antes de eliminar

3. **Cliente por defecto**:
   - Si no se selecciona cliente, usa automáticamente ID 1

**Archivos modificados**:
- `facturacion_app/lib/src/features/facturacion/presentation/screens/factura_detail_screen.dart`
- `facturacion_app/lib/src/features/facturacion/presentation/facturacion_controller.dart`

### Implementación de Gestión de Categorías y Descuentos (2025-12-03)
1. **Nueva pantalla "Gestión"**:
   - Tabs para Categorías y Descuentos
   - Solo visible para administradores
   - CRUD completo para ambas entidades
   - Menú lateral persistente

2. **Categorías**:
   - Crear, editar, eliminar
   - Campos: nombre, descripción (opcional)
   - Validaciones frontend y backend

3. **Descuentos**:
   - Crear, editar, eliminar
   - Campos: nombre, porcentaje (0-100)
   - Validación de porcentaje
   - Modelo actualizado para coincidir con backend (solo `nombre` y `porcentaje`)

**Archivos creados**:
- `facturacion_app/lib/src/features/configuracion/presentation/screens/gestion_screen.dart`
- `facturacion_app/lib/src/features/configuracion/presentation/screens/widgets/categorias_tab.dart`
- `facturacion_app/lib/src/features/configuracion/presentation/screens/widgets/descuentos_tab.dart`

**Archivos modificados**:
- `facturacion_app/lib/src/features/descuentos/domain/descuento.dart` (actualizado modelo)
- `facturacion_app/lib/src/features/descuentos/data/descuentos_repository.dart` (CRUD completo)
- `facturacion_app/lib/src/features/categorias/data/categorias_repository.dart` (CRUD completo)
- `facturacion_app/lib/src/features/categorias/presentation/categorias_provider.dart`
- `facturacion_app/lib/src/features/home/presentation/widgets/app_drawer.dart` (agregado item "Gestión")
- `facturacion_app/lib/src/features/facturacion/presentation/widgets/descuento_selector_dialog.dart`

### Restricción de Devoluciones Removida (2025-12-03)
- **Antes**: Solo se permitían devoluciones el mismo día de la factura
- **Ahora**: Se pueden procesar devoluciones en cualquier momento
- Backend actualizado para remover validación de fecha

## Próximas Mejoras Sugeridas

1. **Inventario**: Implementar decremento automático de stock al crear factura
2. **Reportes**: Agregar módulo de reportes y estadísticas
3. **Búsqueda**: Mejorar búsqueda de productos y clientes
4. **Validaciones**: Agregar más validaciones frontend (stock disponible, etc.)
5. **Optimización**: Reducir warnings de flutter analyze
6. **Testing**: Agregar tests unitarios e integración
7. **Sincronización**: Implementar sincronización offline

## Contacto y Documentación

- Documentación de implementación: Ver `IMPLEMENTAR_EQUIPOS_VENDEDORES.md`
- Contexto del proyecto: Este archivo

## Notas para Contexto Futuro

### Al continuar trabajando en este proyecto:
1. **Revisar este documento** para entender la arquitectura actual
2. **Verificar la lógica de precios**: Ahora se usa `usuario.lista_id`, no `cliente.lista_id`
3. **Transacciones**: Siempre usar transacciones Sequelize para operaciones críticas
4. **Validaciones**: Validar datos tanto en frontend como backend
5. **Estados**: Usar Riverpod providers para gestión de estado
6. **Errores**: Manejar `DioException` en Flutter, `asyncHandler` en backend

### Comandos Útiles

```bash
# Backend
cd backend
npm install
npm run dev

# Flutter
cd facturacion_app
flutter pub get
flutter run
flutter analyze

# Base de datos
# Ejecutar migraciones/seeds si existen
```

---

**Última actualización**: 2025-12-03
**Versión del documento**: 2.0