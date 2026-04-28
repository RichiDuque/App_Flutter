# Documentación de API - Sistema de Facturación

**Base URL:** `http://localhost:4000/api`
**Versión:** 1.0.0

## Tabla de Contenidos

1. [Autenticación](#autenticación)
2. [Usuarios](#usuarios)
3. [Productos](#productos)
4. [Clientes](#clientes)
5. [Categorías](#categorías)
6. [Listas de Precios](#listas-de-precios)
7. [Precios](#precios)
8. [Descuentos](#descuentos)
9. [Facturas](#facturas)
10. [Devoluciones](#devoluciones)
11. [Códigos de Estado HTTP](#códigos-de-estado-http)

---

## Autenticación

### Login
Inicia sesión y obtiene un token JWT.

**Endpoint:** `POST /auth/login`

**Autenticación requerida:** No

**Request Body:**
```json
{
  "email": "usuario@example.com",
  "password": "contraseña123"
}
```

**Respuesta exitosa (200):**
```json
{
  "message": "Login exitoso",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "usuario": {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "nombre": "Juan Pérez",
    "email": "usuario@example.com",
    "rol": "admin"
  }
}
```

**Nota para Flutter:** El campo `usuario` también puede ser accesible como `user` para compatibilidad con la app móvil.

**Errores posibles:**
- `404`: Correo no registrado
- `400`: Contraseña incorrecta
- `500`: Error del servidor

---

### Validar Token
Verifica si un token JWT es válido y retorna información del usuario.

**Endpoint:** `GET /auth/validate`

**Autenticación requerida:** Sí (Bearer Token)

**Headers:**
```
Authorization: Bearer <token>
```

**Respuesta exitosa (200):**
```json
{
  "user": "Juan Pérez",
  "email": "usuario@example.com",
  "rol": "admin",
  "id": 1
}
```

**Errores posibles:**
- `401`: Token inválido o expirado
- `500`: Error del servidor

**Uso:** Este endpoint se utiliza automáticamente al abrir la app para verificar si la sesión sigue activa.

---

### Logout
Cierra la sesión del usuario e invalida el token.

**Endpoint:** `POST /auth/logout`

**Autenticación requerida:** Sí (Bearer Token)

**Headers:**
```
Authorization: Bearer <token>
```

**Respuesta exitosa (200):**
```json
{
  "message": "Logout exitoso"
}
```

**Errores posibles:**
- `401`: Token inválido
- `500`: Error del servidor

**Nota:** Después del logout, el token queda invalidado en el servidor y la app elimina el token del almacenamiento local.

---

## Usuarios

### Listar Usuarios
Obtiene todos los usuarios del sistema.

**Endpoint:** `GET /usuarios`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "nombre": "Juan Pérez",
    "email": "juan@example.com",
    "rol": "admin"
  }
]
```

### Crear Usuario
Crea un nuevo usuario.

**Endpoint:** `POST /usuarios`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`

**Request Body:**
```json
{
  "nombre": "María González",
  "email": "maria@example.com",
  "password": "contraseña123",
  "rol": "vendedor"
}
```

**Respuesta exitosa (201):**
```json
{
  "message": "Usuario creado",
  "usuario": {
    "id": 2,
    "uuid": "b2c3d4e5-f6g7-8901-2345-678901bcdefg",
    "nombre": "María González",
    "email": "maria@example.com",
    "rol": "vendedor"
  }
}
```

**Errores posibles:**
- `400`: El correo ya está registrado
- `500`: Error del servidor

### Actualizar Usuario
Actualiza un usuario existente.

**Endpoint:** `PUT /usuarios/{id}`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`

**Parámetros de ruta:**
- `id` (integer, requerido): ID del usuario

**Request Body:**
```json
{
  "nombre": "María González Actualizada",
  "email": "maria.nueva@example.com",
  "password": "nuevaContraseña123",
  "rol": "admin"
}
```

**Respuesta exitosa (200):**
```json
{
  "message": "Usuario actualizado",
  "usuario": { ... }
}
```

**Errores posibles:**
- `404`: Usuario no encontrado
- `500`: Error del servidor

### Eliminar Usuario
Elimina un usuario del sistema.

**Endpoint:** `DELETE /usuarios/{id}`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`

**Parámetros de ruta:**
- `id` (integer, requerido): ID del usuario

**Respuesta exitosa (200):**
```json
{
  "message": "Usuario eliminado"
}
```

**Errores posibles:**
- `404`: Usuario no encontrado
- `500`: Error del servidor

---

## Productos

### Listar Productos
Obtiene todos los productos.

**Endpoint:** `GET /productos`

**Autenticación requerida:** No

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "nombre": "Laptop HP",
    "descripcion": "Laptop HP 15 pulgadas",
    "precio": 15000.00,
    "stock": 25,
    "categoria_id": 1
  }
]
```

### Buscar Producto por Nombre
Obtiene un producto por su nombre.

**Endpoint:** `GET /productos/nombre/{nombre}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `nombre` (string, requerido): Nombre del producto

**Respuesta exitosa (200):**
```json
{
  "id": 1,
  "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "nombre": "Laptop HP",
  "descripcion": "Laptop HP 15 pulgadas",
  "precio": 15000.00,
  "stock": 25,
  "categoria_id": 1
}
```

**Errores posibles:**
- `404`: Producto no encontrado
- `500`: Error del servidor

---

## Clientes

### Listar Clientes
Obtiene todos los clientes.

**Endpoint:** `GET /clientes`

**Autenticación requerida:** No

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "nombre": "Empresa ABC S.A.",
    "contacto": "contacto@empresaabc.com",
    "direccion": "Av. Principal 123",
    "lista_id": 1
  }
]
```

### Obtener Cliente por ID
Obtiene un cliente específico.

**Endpoint:** `GET /clientes/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID del cliente

**Respuesta exitosa (200):**
```json
{
  "id": 1,
  "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "nombre": "Empresa ABC S.A.",
  "contacto": "contacto@empresaabc.com",
  "direccion": "Av. Principal 123",
  "lista_id": 1
}
```

**Errores posibles:**
- `404`: Cliente no encontrado
- `500`: Error del servidor

### Crear Cliente
Crea un nuevo cliente.

**Endpoint:** `POST /clientes`

**Autenticación requerida:** No

**Request Body:**
```json
{
  "nombre": "Empresa XYZ S.A.",
  "contacto": "contacto@empresaxyz.com",
  "direccion": "Calle Secundaria 456",
  "lista_id": 1
}
```

**Respuesta exitosa (201):**
```json
{
  "id": 2,
  "uuid": "b2c3d4e5-f6g7-8901-2345-678901bcdefg",
  "nombre": "Empresa XYZ S.A.",
  "contacto": "contacto@empresaxyz.com",
  "direccion": "Calle Secundaria 456",
  "lista_id": 1
}
```

### Actualizar Cliente
Actualiza un cliente existente.

**Endpoint:** `PUT /clientes/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID del cliente

**Request Body:**
```json
{
  "nombre": "Empresa XYZ Actualizada",
  "contacto": "nuevo@empresaxyz.com",
  "direccion": "Nueva dirección 789",
  "lista_id": 2
}
```

**Respuesta exitosa (200):**
```json
{
  "message": "Cliente actualizado",
  "cliente": { ... }
}
```

### Eliminar Cliente
Elimina un cliente.

**Endpoint:** `DELETE /clientes/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID del cliente

**Respuesta exitosa (200):**
```json
{
  "message": "Cliente eliminado correctamente"
}
```

---

## Categorías

### Listar Categorías
Obtiene todas las categorías.

**Endpoint:** `GET /categorias`

**Autenticación requerida:** No

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "nombre": "Electrónica",
    "descripcion": "Productos electrónicos"
  }
]
```

### Obtener Categoría por ID
Obtiene una categoría específica.

**Endpoint:** `GET /categorias/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID de la categoría

**Respuesta exitosa (200):**
```json
{
  "id": 1,
  "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "nombre": "Electrónica",
  "descripcion": "Productos electrónicos"
}
```

### Crear Categoría
Crea una nueva categoría.

**Endpoint:** `POST /categorias`

**Autenticación requerida:** No

**Request Body:**
```json
{
  "nombre": "Oficina",
  "descripcion": "Artículos de oficina"
}
```

**Respuesta exitosa (201):**
```json
{
  "id": 2,
  "uuid": "b2c3d4e5-f6g7-8901-2345-678901bcdefg",
  "nombre": "Oficina",
  "descripcion": "Artículos de oficina"
}
```

### Actualizar Categoría
Actualiza una categoría existente.

**Endpoint:** `PUT /categorias/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID de la categoría

**Request Body:**
```json
{
  "nombre": "Oficina Actualizada",
  "descripcion": "Nueva descripción"
}
```

**Respuesta exitosa (200):**
```json
{
  "message": "Categoría actualizada",
  "categoria": { ... }
}
```

### Eliminar Categoría
Elimina una categoría.

**Endpoint:** `DELETE /categorias/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID de la categoría

**Respuesta exitosa (200):**
```json
{
  "message": "Categoría eliminada correctamente"
}
```

---

## Listas de Precios

### Listar Listas de Precios
Obtiene todas las listas de precios.

**Endpoint:** `GET /listas-precios`

**Autenticación requerida:** No

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "nombre": "Lista Mayorista",
    "descripcion": "Precios para clientes mayoristas"
  }
]
```

### Obtener Lista de Precios por ID
Obtiene una lista de precios específica.

**Endpoint:** `GET /listas-precios/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID de la lista de precios

**Respuesta exitosa (200):**
```json
{
  "id": 1,
  "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "nombre": "Lista Mayorista",
  "descripcion": "Precios para clientes mayoristas"
}
```

### Crear Lista de Precios
Crea una nueva lista de precios.

**Endpoint:** `POST /listas-precios`

**Autenticación requerida:** No

**Request Body:**
```json
{
  "nombre": "Lista Minorista",
  "descripcion": "Precios para clientes minoristas"
}
```

**Respuesta exitosa (201):**
```json
{
  "id": 2,
  "uuid": "b2c3d4e5-f6g7-8901-2345-678901bcdefg",
  "nombre": "Lista Minorista",
  "descripcion": "Precios para clientes minoristas"
}
```

### Actualizar Lista de Precios
Actualiza una lista de precios existente.

**Endpoint:** `PUT /listas-precios/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID de la lista de precios

**Request Body:**
```json
{
  "nombre": "Lista Minorista Actualizada",
  "descripcion": "Nueva descripción"
}
```

**Respuesta exitosa (200):**
```json
{
  "message": "Lista de precios actualizada",
  "listaPrecios": { ... }
}
```

### Eliminar Lista de Precios
Elimina una lista de precios.

**Endpoint:** `DELETE /listas-precios/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID de la lista de precios

**Respuesta exitosa (200):**
```json
{
  "message": "Lista de precios eliminada correctamente"
}
```

---

## Precios

### Listar Precios
Obtiene todos los precios configurados.

**Endpoint:** `GET /precios`

**Autenticación requerida:** No

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "producto_id": 1,
    "lista_id": 1,
    "precio": 14000.00
  }
]
```

### Obtener Precio por ID
Obtiene un precio específico.

**Endpoint:** `GET /precios/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID del precio

**Respuesta exitosa (200):**
```json
{
  "id": 1,
  "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "producto_id": 1,
  "lista_id": 1,
  "precio": 14000.00
}
```

### Crear Precio
Crea un nuevo precio para un producto en una lista.

**Endpoint:** `POST /precios`

**Autenticación requerida:** No

**Request Body:**
```json
{
  "producto_id": 1,
  "lista_id": 2,
  "precio": 15500.00
}
```

**Respuesta exitosa (201):**
```json
{
  "id": 2,
  "uuid": "b2c3d4e5-f6g7-8901-2345-678901bcdefg",
  "producto_id": 1,
  "lista_id": 2,
  "precio": 15500.00
}
```

### Actualizar Precio
Actualiza un precio existente.

**Endpoint:** `PUT /precios/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID del precio

**Request Body:**
```json
{
  "producto_id": 1,
  "lista_id": 2,
  "precio": 16000.00
}
```

**Respuesta exitosa (200):**
```json
{
  "message": "Precio actualizado",
  "precio": { ... }
}
```

### Eliminar Precio
Elimina un precio.

**Endpoint:** `DELETE /precios/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID del precio

**Respuesta exitosa (200):**
```json
{
  "message": "Precio eliminado correctamente"
}
```

---

## Descuentos

### Listar Descuentos
Obtiene todos los descuentos.

**Endpoint:** `GET /descuentos`

**Autenticación requerida:** No

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "codigo": "VERANO2024",
    "descripcion": "Descuento de verano",
    "porcentaje": 15.0
  }
]
```

### Obtener Descuento por ID
Obtiene un descuento específico.

**Endpoint:** `GET /descuentos/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID del descuento

**Respuesta exitosa (200):**
```json
{
  "id": 1,
  "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "codigo": "VERANO2024",
  "descripcion": "Descuento de verano",
  "porcentaje": 15.0
}
```

### Crear Descuento
Crea un nuevo descuento.

**Endpoint:** `POST /descuentos`

**Autenticación requerida:** No

**Request Body:**
```json
{
  "codigo": "NAVIDAD2024",
  "descripcion": "Descuento navideño",
  "porcentaje": 20.0
}
```

**Respuesta exitosa (201):**
```json
{
  "id": 2,
  "uuid": "b2c3d4e5-f6g7-8901-2345-678901bcdefg",
  "codigo": "NAVIDAD2024",
  "descripcion": "Descuento navideño",
  "porcentaje": 20.0
}
```

### Actualizar Descuento
Actualiza un descuento existente.

**Endpoint:** `PUT /descuentos/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID del descuento

**Request Body:**
```json
{
  "codigo": "NAVIDAD2024",
  "descripcion": "Descuento navideño actualizado",
  "porcentaje": 25.0
}
```

**Respuesta exitosa (200):**
```json
{
  "message": "Descuento actualizado",
  "descuento": { ... }
}
```

### Eliminar Descuento
Elimina un descuento.

**Endpoint:** `DELETE /descuentos/{id}`

**Autenticación requerida:** No

**Parámetros de ruta:**
- `id` (integer, requerido): ID del descuento

**Respuesta exitosa (200):**
```json
{
  "message": "Descuento eliminado correctamente"
}
```

---

## Facturas

### Listar Facturas
Obtiene todas las facturas.

**Endpoint:** `GET /facturas`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`, `vendedor`

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "cliente_id": 1,
    "usuario_id": 1,
    "fecha": "2024-01-15T10:30:00.000Z",
    "total": 45000.00,
    "Cliente": {
      "nombre": "Empresa ABC S.A.",
      "contacto": "contacto@empresaabc.com",
      "direccion": "Av. Principal 123"
    },
    "DetalleFacturas": [
      {
        "id": 1,
        "producto_id": 1,
        "cantidad": 3,
        "precio_unitario": 15000.00,
        "subtotal": 45000.00,
        "Producto": {
          "nombre": "Laptop HP",
          "stock": 22
        }
      }
    ],
    "Descuento": {
      "nombre": "VERANO2024",
      "porcentaje": 15.0
    }
  }
]
```

### Obtener Factura por ID
Obtiene una factura específica con todos sus detalles.

**Endpoint:** `GET /facturas/{id}`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`, `vendedor`

**Parámetros de ruta:**
- `id` (integer, requerido): ID de la factura

**Respuesta exitosa (200):**
```json
{
  "id": 1,
  "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "cliente_id": 1,
  "usuario_id": 1,
  "fecha": "2024-01-15T10:30:00.000Z",
  "total": 45000.00,
  "Cliente": {
    "nombre": "Empresa ABC S.A.",
    "contacto": "contacto@empresaabc.com",
    "direccion": "Av. Principal 123"
  },
  "DetalleFacturas": [...],
  "Usuario": {
    "nombre": "Juan Pérez"
  },
  "Descuento": {
    "nombre": "VERANO2024",
    "porcentaje": 15.0
  }
}
```

**Errores posibles:**
- `404`: Factura no encontrada
- `500`: Error del servidor

### Crear Factura
Crea una nueva factura con sus detalles.

**Endpoint:** `POST /facturas`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`, `vendedor`

**Request Body:**
```json
{
  "cliente_id": 1,
  "usuario_id": 1,
  "descuento_id": 1,
  "items": [
    {
      "producto_id": 1,
      "cantidad": 2,
      "comentario": "Envío urgente"
    },
    {
      "producto_id": 2,
      "cantidad": 1,
      "comentario": ""
    }
  ]
}
```

**Notas importantes:**
- El precio se calcula automáticamente según la lista de precios asignada al cliente
- El stock se actualiza automáticamente
- Se registran movimientos de inventario
- El descuento se aplica al total de la factura (no por ítem)

**Respuesta exitosa (201):**
```json
{
  "mensaje": "Factura creada correctamente",
  "factura_id": 2,
  "total": 28000.00
}
```

**Errores posibles:**
- `404`: Cliente no encontrado o descuento no encontrado
- `400`: Cliente sin lista de precios asignada
- `500`: Error del servidor (puede incluir detalles sobre productos sin precio)

### Actualizar Factura
Actualiza una factura existente.

**Endpoint:** `PUT /facturas/{id}`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`

**Parámetros de ruta:**
- `id` (integer, requerido): ID de la factura

**Request Body:**
```json
{
  "cliente_id": 1,
  "usuario_id": 1,
  "detalles": [
    {
      "producto_id": 1,
      "cantidad": 5
    }
  ]
}
```

**Respuesta exitosa (200):**
```json
{
  "message": "Factura actualizada correctamente",
  "factura_id": 1,
  "total": 75000.00
}
```

**Errores posibles:**
- `404`: Factura no encontrada
- `400`: Cliente sin lista de precios
- `500`: Error del servidor

### Eliminar Factura
Elimina una factura y sus detalles.

**Endpoint:** `DELETE /facturas/{id}`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`

**Parámetros de ruta:**
- `id` (integer, requerido): ID de la factura

**Respuesta exitosa (200):**
```json
{
  "message": "🗑️ Factura eliminada correctamente"
}
```

**Errores posibles:**
- `404`: Factura no encontrada
- `500`: Error del servidor

---

## Devoluciones

### Listar Devoluciones
Obtiene todas las devoluciones.

**Endpoint:** `GET /devoluciones`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`, `vendedor`

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "factura_id": 1,
    "fecha": "2024-01-20T14:30:00.000Z",
    "motivo": "Producto defectuoso",
    "total_devuelto": 15000.00
  }
]
```

### Obtener Devolución por ID
Obtiene una devolución específica.

**Endpoint:** `GET /devoluciones/{id}`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`, `vendedor`

**Parámetros de ruta:**
- `id` (integer, requerido): ID de la devolución

**Respuesta exitosa (200):**
```json
{
  "id": 1,
  "uuid": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "factura_id": 1,
  "fecha": "2024-01-20T14:30:00.000Z",
  "motivo": "Producto defectuoso",
  "total_devuelto": 15000.00
}
```

**Errores posibles:**
- `404`: Devolución no encontrada
- `500`: Error del servidor

### Crear Devolución
Crea una nueva devolución asociada a una factura.

**Endpoint:** `POST /devoluciones`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`, `vendedor`

**Request Body:**
```json
{
  "factura_id": 1,
  "motivo": "Producto defectuoso",
  "items": [
    {
      "producto_id": 1,
      "cantidad": 1
    }
  ]
}
```

**Respuesta exitosa (201):**
```json
{
  "message": "Devolución creada exitosamente",
  "devolucion": { ... }
}
```

**Errores posibles:**
- `404`: Factura no encontrada
- `400`: Datos inválidos
- `500`: Error del servidor

### Anular Devolución
Anula una devolución y revierte el inventario.

**Endpoint:** `DELETE /devoluciones/{id}`

**Autenticación requerida:** Sí (Bearer Token)

**Roles permitidos:** `admin`

**Parámetros de ruta:**
- `id` (integer, requerido): ID de la devolución

**Respuesta exitosa (200):**
```json
{
  "message": "Devolución anulada correctamente"
}
```

**Errores posibles:**
- `404`: Devolución no encontrada
- `500`: Error del servidor

---

## Autenticación con Bearer Token

Para endpoints que requieren autenticación, debes incluir el token JWT en el header de la solicitud:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Ejemplo en Flutter/Dart:**
```dart
final response = await http.get(
  Uri.parse('http://localhost:4000/api/facturas'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
);
```

**Ejemplo en JavaScript:**
```javascript
fetch('http://localhost:4000/api/facturas', {
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  }
})
```

---

## Códigos de Estado HTTP

| Código | Significado | Descripción |
|--------|-------------|-------------|
| 200 | OK | Solicitud exitosa |
| 201 | Created | Recurso creado exitosamente |
| 400 | Bad Request | Solicitud con datos inválidos |
| 401 | Unauthorized | Token inválido o faltante |
| 403 | Forbidden | No tienes permisos para esta acción |
| 404 | Not Found | Recurso no encontrado |
| 500 | Internal Server Error | Error del servidor |

---

## Roles de Usuario

El sistema maneja dos roles principales:

| Rol | Descripción | Permisos |
|-----|-------------|----------|
| `admin` | Administrador | Acceso completo a todos los endpoints |
| `vendedor` | Vendedor | Acceso a facturas, devoluciones (lectura/escritura limitada) |

---

## Configuración para Flutter/Dart

### Configuración de Base URL

Para Flutter, se recomienda usar variables de entorno según la plataforma:

```dart
class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:4000/api';
    } else {
      // Para móvil/desktop, usa la IP de tu servidor
      return 'http://192.168.1.12:4000/api';
    }
  }
}
```

### Ejemplo de Login

```dart
Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Login fallido');
  }
}
```

### Ejemplo de Crear Factura

```dart
Future<Map<String, dynamic>> crearFactura(
  int clienteId,
  int usuarioId,
  List<Map<String, dynamic>> items,
  {int? descuentoId}
) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/facturas'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'cliente_id': clienteId,
      'usuario_id': usuarioId,
      'descuento_id': descuentoId,
      'items': items,
    }),
  );

  if (response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Error al crear factura');
  }
}
```

---

## Notas Importantes

1. **CORS**: El backend está configurado para aceptar peticiones desde:
   - `http://localhost:52000` (Flutter Web)
   - `http://localhost:55425` (Flutter Web)
   - `http://127.0.0.1:52000`
   - `http://127.0.0.1:54321`

2. **Swagger**: Puedes acceder a la documentación interactiva en:
   ```
   http://localhost:4000/api-docs
   ```

3. **Transacciones**: Las operaciones de facturación y devoluciones usan transacciones de base de datos para garantizar la integridad de los datos.

4. **Inventario**: El stock se actualiza automáticamente al crear facturas y devoluciones.

5. **Precios**: Los precios se calculan según la lista de precios asignada al cliente. Asegúrate de que los clientes tengan una lista asignada antes de crear facturas.

---

## Soporte

Para reportar problemas o solicitar nuevas funcionalidades, contacta al equipo de desarrollo.

**Versión del documento:** 1.0.0
**Última actualización:** 2025-11-09