CREATE DATABASE facturacion_db;
\c facturacion_db;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================
-- TABLAS BASE
-- ============================

CREATE TABLE Usuarios (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    rol VARCHAR(50) NOT NULL,  -- Ej: 'admin', 'vendedor', 'cliente_web'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE ListasPrecios (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE Clientes (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    contacto VARCHAR(100),
    direccion TEXT,
    lista_id INT REFERENCES ListasPrecios(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE Categorias (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE Productos (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    imagen_url TEXT,
    categoria_id INT REFERENCES Categorias(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE Precios (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    producto_id INT REFERENCES Productos(id) ON DELETE CASCADE,
    lista_id INT REFERENCES ListasPrecios(id) ON DELETE CASCADE,
    precio DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE Descuentos (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    porcentaje DECIMAL(5,2) NOT NULL,  -- Ej: 5.00 = 5%
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================
-- FACTURACIÓN
-- ============================

CREATE TABLE Facturas (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    cliente_id INT REFERENCES Clientes(id) ON DELETE CASCADE,
    usuario_id INT REFERENCES Usuarios(id),
    fecha TIMESTAMP DEFAULT NOW(),
    descuento_id INT REFERENCES Descuentos(id),
    total DECIMAL(12,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE DetalleFactura (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    factura_id INT REFERENCES Facturas(id) ON DELETE CASCADE,
    producto_id INT REFERENCES Productos(id),
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2),
    descuento_id INT REFERENCES Descuentos(id),
    subtotal DECIMAL(12,2),
    comentario TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================
-- DEVOLUCIONES
-- ============================

CREATE TABLE Devoluciones (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    cliente_id INT REFERENCES Clientes(id),
    usuario_id INT REFERENCES Usuarios(id),
    factura_id INT REFERENCES Facturas(id),
    fecha TIMESTAMP DEFAULT NOW(),
    motivo TEXT,
    total DECIMAL(12,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE DetalleDevolucion (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    devolucion_id INT REFERENCES Devoluciones(id) ON DELETE CASCADE,
    producto_id INT REFERENCES Productos(id),
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2),
    subtotal DECIMAL(12,2),
    comentario TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para búsquedas rápidas
CREATE INDEX idx_productos_nombre ON Productos(nombre);
CREATE INDEX idx_clientes_nombre ON Clientes(nombre);
CREATE INDEX idx_facturas_fecha ON Facturas(fecha);

-- Índices para sincronización por timestamps
CREATE INDEX idx_productos_updated ON Productos(updated_at);
CREATE INDEX idx_facturas_updated ON Facturas(updated_at);
CREATE INDEX idx_devoluciones_updated ON Devoluciones(updated_at);

INSERT INTO Usuarios (nombre, email, password_hash, rol)
VALUES ('Admin', 'admin@demo.com', 'hash123', 'admin');

INSERT INTO ListasPrecios (nombre) VALUES ('General'), ('Mayorista');

INSERT INTO Categorias (nombre, descripcion)
VALUES ('Bebidas', 'Bebidas en general'),
       ('Snacks', 'Productos de paquete');

INSERT INTO Productos (nombre, stock, imagen_url, categoria_id)
VALUES ('Coca-Cola 500ml', 100, 'https://cdn.demo.com/coca.jpg', 1),
       ('Papas Fritas', 200, 'https://cdn.demo.com/papas.jpg', 2);

INSERT INTO Precios (producto_id, lista_id, precio)
VALUES (1, 1, 3500), (1, 2, 3200),
       (2, 1, 2500), (2, 2, 2200);

-- Ver productos con su categoría y precios
SELECT p.nombre AS producto, c.nombre AS categoria, pr.precio
FROM Productos p
JOIN Categorias c ON c.id = p.categoria_id
JOIN Precios pr ON pr.producto_id = p.id;

-- Crear factura rápida (sin backend)
INSERT INTO Facturas (cliente_id, usuario_id, total)
VALUES (1, 1, 15000)
RETURNING id;

INSERT INTO DetalleFactura (factura_id, producto_id, cantidad, precio_unitario, subtotal)
VALUES (1, 1, 3, 3500, 10500),
       (1, 2, 2, 2500, 5000);

DELETE FROM Facturas WHERE id = 1;
-- Debería eliminar también los DetalleFactura asociados.
