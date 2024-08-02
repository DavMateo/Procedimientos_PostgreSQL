-- Crear la base de datos "miscompras"
CREATE DATABASE miscompras;

/*
DROP DATABASE miscompras;
DROP TABLE categorias;
DROP TABLE productos;
DROP TABLE clientes;
DROP TABLE compras;
DROP TABLE compras_productos;
*/


-- Creando la Tabla "categorias"
CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    descripcion VARCHAR(45),
    estado SMALLINT
);
INSERT INTO categorias(descripcion, estado) VALUES
    ('Categoría de productos tecnológicos', 1);

-- Creando la Tabla "productos"
CREATE TABLE productos (
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(45),
    id_categoria INT,
    codigo_barras VARCHAR(150),
    precio_venta NUMERIC(16,2),
    cantidad_stock INT,
    estado SMALLINT,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
);

-- Creando la Tabla "clientes"
CREATE TABLE clientes (
    id VARCHAR(20) PRIMARY KEY,
    nombre VARCHAR(40),
    apellidos VARCHAR(100),
    celular NUMERIC(10,0),
    direccion VARCHAR(80),
    correo_electronico VARCHAR(70)
);

-- Creando la Tabla "compras"
CREATE TABLE compras (
    id_compra SERIAL PRIMARY KEY,
    id_cliente VARCHAR(20),
    fecha TIMESTAMP,
    medio_pago CHAR(1),
    comentario VARCHAR(300),
    estado CHAR(1),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id)
);

-- Creando la Tabla "compras_productos"
CREATE TABLE compras_productos (
    id_compra INT,
    id_producto INT,
    cantidad INT,
    total NUMERIC(16,2),
    estado SMALLINT,
    PRIMARY KEY (id_compra, id_producto),
    FOREIGN KEY (id_compra) REFERENCES compras(id_compra),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);



-- Creando el procedimiento n°1
CREATE OR REPLACE FUNCTION insertar_nuevo_cliente(
    p_id VARCHAR(20),
    p_nombre VARCHAR(40),
    p_apellidos VARCHAR(100),
    p_celular NUMERIC(10,0),
    p_direccion VARCHAR(80),
    p_correo_electronico VARCHAR(70)
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO clientes (id, nombre, apellidos, celular, direccion, correo_electronico) VALUES
        (p_id, p_nombre, p_apellidos, p_celular, p_direccion, p_correo_electronico);
END;
$$ LANGUAGE plpgsql;
-- Usando el procedimiento y verificando su funcionamiento
SELECT insertar_nuevo_cliente('001', 'David', 'Carreño', 1234567890, 'Calle 76 #92-21c', 'davcarreno@gmail.com');
SELECT id, nombre, apellidos, celular, direccion, correo_electronico
    FROM clientes;


-- Creando el procedimiento n°2
CREATE OR REPLACE FUNCTION actualizar_cliente(
    p_id VARCHAR(20),
    p_nombre VARCHAR(40),
    p_apellidos VARCHAR(100),
    p_celular DECIMAL(10,0),
    p_direccion VARCHAR(80),
    p_correo_electronico VARCHAR(70)
)
RETURNS VOID AS $$
BEGIN
    UPDATE clientes
    SET nombre = p_nombre, apellidos = p_apellidos, celular = p_celular, direccion = p_direccion, correo_electronico = p_correo_electronico
    WHERE id = p_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cliente con ID % no encontrado', p_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
-- Usando el procedimiento y verificando su funcionamiento
SELECT actualizar_cliente('001', 'David Mateo', 'Carreño Diaz', 9876543210, 'Cra 32 #65-12 av.23', 'davmateo@protonmail.com');
SELECT id, nombre, apellidos, celular, direccion, correo_electronico
    FROM clientes;


-- Creando el procedimiento n°3
CREATE OR REPLACE FUNCTION eliminar_cliente(p_id VARCHAR(20))
RETURNS VOID AS $$
DECLARE
    cliente_existe BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM clientes WHERE id = p_id) INTO cliente_existe;

    IF NOT cliente_existe THEN
        RAISE EXCEPTION 'Cliente con ID % no encontrado', p_id;
    END IF;

    DELETE FROM clientes
    WHERE id = p_id;
    RAISE NOTICE 'Cliente con ID % eliminado exitosamente', p_id;
END;
$$ LANGUAGE plpgsql;
-- Usando el procedimiento y verificando su funcionamiento
SELECT eliminar_cliente('001');
SELECT id, nombre, apellidos, celular, direccion, correo_electronico
    FROM clientes;


-- Creando el procedimiento n°4
CREATE OR REPLACE FUNCTION insertar_nueva_compra(
    p_id_cliente VARCHAR(20),
    p_fecha TIMESTAMP,
    p_medio_pago CHAR(1),
    p_comentario VARCHAR(300),
    p_estado CHAR(1)
)
RETURNS VOID AS $$
DECLARE
    v_id_compra INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE id = p_id_cliente) THEN
        RAISE EXCEPTION 'Cliente con ID % no encontrado', p_id_cliente;
    END IF;

    INSERT INTO compras (id_cliente, fecha, medio_pago, comentario, estado) VALUES
        (p_id_cliente, p_fecha, p_medio_pago, p_comentario, p_estado);
    RAISE NOTICE 'Nueva compra insertada con ID: %', v_id_compra;
END;
$$ LANGUAGE plpgsql;
-- Usando el procedimiento y verificando su funcionamiento
SELECT insertar_nueva_compra('001', '2024-03-21', 'E', 'Compra en tienda física TechPoint', 'A');
SELECT insertar_nueva_compra('001', '2023-12-02 16:58:47', 'D', 'Compra digital en la tienda de Xiaomi', 'A');
SELECT id_cliente, fecha, medio_pago, comentario, estado
    FROM compras;


-- Creando el procedimiento n°5
CREATE OR REPLACE FUNCTION insertar_producto_en_compra(
    p_id_compra INT,
    p_id_producto INT,
    p_cantidad INT,
    p_total NUMERIC(16,2),
    p_estado SMALLINT
)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM compras WHERE id_compra = p_id_compra) THEN
        RAISE EXCEPTION 'Compra con ID % no encontrada', p_id_compra;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        RAISE EXCEPTION 'Producto con ID % no encontrado', p_id_producto;
    END IF;

    INSERT INTO compras_productos (id_compra, id_producto, cantidad, total, estado) VALUES
        (p_id_compra, p_id_producto, p_cantidad, p_total, p_estado);
    RAISE NOTICE 'Producto % insertado en la compra %', p_id_producto, p_id_compra;
END;
$$ LANGUAGE plpgsql;
-- Usando el procedimiento y verificando su funcionamiento
SELECT insertar_producto_en_compra(1, 100, 5, 250.00, 1);
SELECT id_compra, id_producto, cantidad, total, estado
    FROM compras_productos;


-- Creando el procedimiento n°6
CREATE OR REPLACE FUNCTION obtener_info_compra(p_id_compra INT)
RETURNS TABLE (
    id_compra INT,
    id_cliente VARCHAR(20),
    fecha TIMESTAMP,
    medio_pago CHAR(1),
    comentario VARCHAR(300),
    estado CHAR(1)
) AS $$
BEGIN
    RETURN QUERY
        SELECT c.id_compra, c.id_cliente, c.fecha, c.medio_pago, c.comentario, c.estado
        FROM compras c
        WHERE c.id_compra = p_id_compra;
    RAISE NOTICE 'Información de la compra % obtenida', p_id_compra;
END;
$$ LANGUAGE plpgsql;
-- Usando el procedimiento y verificando su funcionamiento
SELECT * FROM obtener_info_compra(2);


-- Creando el procedimiento n°7
CREATE OR REPLACE FUNCTION insertar_nuevo_producto(
    p_nombre VARCHAR(45),
    p_id_categoria INT,
    p_codigo_barras VARCHAR(150),
    p_precio_venta NUMERIC(16,2),
    p_cantidad_stock INT,
    p_estado SMALLINT
)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'Categoría con ID % no encontrada', p_id_categoria;
    END IF;

    INSERT INTO productos (nombre, id_categoria, codigo_barras, precio_venta, cantidad_stock, estado)
        VALUES (p_nombre, p_id_categoria, p_codigo_barras, p_precio_venta, p_cantidad_stock, p_estado);
END;
$$ LANGUAGE plpgsql;
-- Usando el procedimiento y verificando su funcionamiento
SELECT insertar_nuevo_producto('Redmi Note 7', 1, '1234567890', 99.99, 100, 1);


-- Creando el procedimiento n°8
CREATE OR REPLACE FUNCTION actualizar_producto(
    p_id_producto INT,
    p_nombre VARCHAR(45),
    p_id_categoria INT,
    p_codigo_barras VARCHAR(150),
    p_precio_venta NUMERIC(16,2),
    p_cantidad_stock INT,
    p_estado SMALLINT
)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        RAISE EXCEPTION 'Producto con ID % no encontrado', p_id_producto;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM categorias WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'Categoría con ID % no encontrada', p_id_categoria;
    END IF;

    UPDATE productos
    SET nombre = p_nombre,
        id_categoria = p_id_categoria,
        codigo_barras = p_codigo_barras,
        precio_venta = p_precio_venta,
        cantidad_stock = p_cantidad_stock,
        estado = p_estado
    WHERE id_producto = p_id_producto;

    RAISE NOTICE 'Producto con ID % actualizado exitosamente', p_id_producto;
END;
$$ LANGUAGE plpgsql;
-- Usando el procedimiento y verificando su funcionamiento
SELECT actualizar_producto(1, 'Redmi Note 7 Lavender', 2, '9876543210', 149.99, 200, 1);


-- Creando el procedimiento n°9
CREATE OR REPLACE FUNCTION obtener_productos_por_categoria(
    p_id_categoria INT
)
RETURNS TABLE (
    id_producto INT,
    nombre VARCHAR(45),
    precio_venta NUMERIC(16,2),
    cantidad_stock INT,
    estado SMALLINT
) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'Categoría con ID % no encontrada', p_id_categoria;
    END IF;

    RETURN QUERY
        SELECT p.id_producto, p.nombre, p.precio_venta, p.cantidad_stock, p.estado
        FROM productos p
        WHERE p.id_categoria = p_id_categoria;
    RAISE NOTICE 'Productos de la categoría % obtenidos', p_id_categoria;
END;
$$ LANGUAGE plpgsql;
-- Usando el procedimiento y verificando su funcionamiento
SELECT * FROM obtener_productos_por_categoria(1);
