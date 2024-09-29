-- Crear la base de datos
CREATE DATABASE potato_main;
\c potato_main

-- Extensión para generar UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabla de usuarios
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    contrasena_hash CHAR(60) NOT NULL,
    fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ultimo_acceso TIMESTAMP WITH TIME ZONE,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla de productos
CREATE TABLE productos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio NUMERIC(10, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de pedidos
CREATE TABLE pedidos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL,
    fecha_pedido TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) CHECK (estado IN ('pendiente', 'procesando', 'enviado', 'entregado', 'cancelado')) DEFAULT 'pendiente',
    total NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- Tabla de detalles de pedidos
CREATE TABLE detalles_pedido (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pedido_id UUID NOT NULL,
    producto_id UUID NOT NULL,
    cantidad INTEGER NOT NULL,
    precio_unitario NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id),
    FOREIGN KEY (producto_id) REFERENCES productos(id)
);

-- Insertar usuarios de ejemplo (las contraseñas están hasheadas)
INSERT INTO usuarios (nombre, apellido, email, contrasena_hash) VALUES
('Juan', 'Pérez', 'juan@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('María', 'García', 'maria@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('Carlos', 'Rodríguez', 'carlos@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

-- Insertar productos de ejemplo
INSERT INTO productos (nombre, descripcion, precio, stock) VALUES
('Patata Roja', 'Patatas rojas frescas', 2.50, 100),
('Patata Blanca', 'Patatas blancas de alta calidad', 2.00, 150),
('Patata Dulce', 'Batatas orgánicas', 3.00, 75);

-- Insertar pedidos de ejemplo
INSERT INTO pedidos (usuario_id, total)
SELECT id, 12.50 FROM usuarios WHERE email = 'juan@example.com'
UNION ALL
SELECT id, 10.00 FROM usuarios WHERE email = 'maria@example.com'
UNION ALL
SELECT id, 15.00 FROM usuarios WHERE email = 'carlos@example.com';

-- Insertar detalles de pedidos de ejemplo
INSERT INTO detalles_pedido (pedido_id, producto_id, cantidad, precio_unitario)
SELECT p.id, pr.id, 3, 2.50
FROM pedidos p
JOIN usuarios u ON p.usuario_id = u.id
CROSS JOIN productos pr
WHERE u.email = 'juan@example.com' AND pr.nombre = 'Patata Roja'
UNION ALL
SELECT p.id, pr.id, 2, 2.00
FROM pedidos p
JOIN usuarios u ON p.usuario_id = u.id
CROSS JOIN productos pr
WHERE u.email = 'juan@example.com' AND pr.nombre = 'Patata Blanca'
UNION ALL
SELECT p.id, pr.id, 5, 2.00
FROM pedidos p
JOIN usuarios u ON p.usuario_id = u.id
CROSS JOIN productos pr
WHERE u.email = 'maria@example.com' AND pr.nombre = 'Patata Blanca'
UNION ALL
SELECT p.id, pr.id, 5, 3.00
FROM pedidos p
JOIN usuarios u ON p.usuario_id = u.id
CROSS JOIN productos pr
WHERE u.email = 'carlos@example.com' AND pr.nombre = 'Patata Dulce';

-- Crear un rol con acceso limitado para la aplicación
CREATE ROLE potato_app LOGIN PASSWORD 'patata_segura_123';
GRANT CONNECT ON DATABASE potato_main TO potato_app;
GRANT USAGE ON SCHEMA public TO potato_app;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO potato_app;

-- Crear una vista para información limitada de usuarios
CREATE VIEW vista_usuarios_limitada AS
SELECT id, nombre, apellido, email, fecha_registro, ultimo_acceso, activo
FROM usuarios;

-- Otorgar acceso a la vista en lugar de la tabla completa
GRANT SELECT ON vista_usuarios_limitada TO potato_app;

-- Configurar la política de seguridad a nivel de fila (RLS) para la tabla de usuarios
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;

-- Crear una política que permita a los usuarios ver solo su propia información
CREATE POLICY usuarios_ver_propio ON usuarios
    FOR SELECT
    USING (id = current_user_id());

-- Función para obtener el ID del usuario actual (deberás implementar esto en tu aplicación)
CREATE OR REPLACE FUNCTION current_user_id() RETURNS UUID AS $$
BEGIN
    -- Esta es una función de ejemplo. En una aplicación real, 
    -- implementarías la lógica para obtener el ID del usuario actual.
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
