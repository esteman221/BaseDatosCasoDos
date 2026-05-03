-- ============================================================
-- 05D_etheria_seed_full_with_reporting_views_FINAL.sql
-- Base: EtheriaCasoDos
-- Schema: etheria
-- Motor: PostgreSQL
--
-- Archivo único final:
--   1. Stored Procedures transaccionales de llenado de datos.
--   2. SP independiente de logging.
--   3. Carga de 5 países.
--   4. Catálogos mínimos.
--   5. 100 productos distribuidos entre 5 países.
--   6. Lotes de productos para costos de importación.
--   7. Views de reporting para Superset/Trino.
--   8. Orquestador final sp_seed_etheria_all().
--
-- Ejecutar después del script de creación de tablas de Etheria.
-- ============================================================

-- ============================================================
-- 05_etheria_data_load_procedures_postgresql.sql
-- Base: EtheriaCasoDos
-- Schema: etheria
-- Motor: PostgreSQL
--
-- Entregable:
--   Stored Procedures transaccionales para llenado de datos.
--
-- Carga:
--   - 5 países
--   - Catálogos mínimos necesarios para poder insertar productos
--   - 100 productos distribuidos entre los 5 países
--
-- Nota:
--   Etheria NO tiene tabla de sitios web en el modelo enviado.
--   Los 9 sitios web dinámicos corresponden a DynamicBrands.
-- ============================================================


-- ============================================================
-- 1. SP independiente de logging
-- ============================================================

-- El SP recibe como mínimo 3 datos: 
--      El nombre del procedure que lo llama
--      El nombre de la tabla que es afectada
--      El nombre de la acción que se está haciendo
-- Opcionalmente recibe: 
--      # de filas que fueron afectadas (por defecto nulo)
--      Cómo salio la acción (por defecto OK)
--      Mensaje asociado al resultado (por defecto nulo)
SET search_path TO etheria;
CREATE OR REPLACE PROCEDURE sp_seed_log_step(
    p_process_name VARCHAR,
    p_target_table VARCHAR,
    p_action VARCHAR,
    p_rows_affected INTEGER DEFAULT NULL,
    p_status VARCHAR DEFAULT 'OK',
    p_message VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_log_type_id BIGINT;
    v_event_type_id BIGINT;
    v_severity_id BIGINT;
    v_source_id BIGINT;
    v_data_object_id BIGINT;
    v_description VARCHAR(100);
BEGIN
    -- Agrega el tipo "SYSTEM" en caso de que no exista, si existe lo omite
    INSERT INTO log_types(code, description)
    VALUES ('SYSTEM', 'System process')
    ON CONFLICT (code) DO NOTHING;

    -- Agrega el tipo "SEED_DATA" en caso de que no exista, si existe lo omite
    INSERT INTO event_types(code, description)
    VALUES ('SEED_DATA', 'Seed data execution')
    ON CONFLICT (code) DO NOTHING;

    -- Agrega la severidad "INFO" en caso de que no exista, si existe lo omite
    INSERT INTO severities(code, level)
    VALUES ('INFO', '1')
    ON CONFLICT (code) DO NOTHING;

    -- Agrega la severidad "ERROR" en caso de que no exista, si existe lo omite
    INSERT INTO severities(code, level)
    VALUES ('ERROR', '3')
    ON CONFLICT (code) DO NOTHING;

    -- Agrega "BATCH" a "sources", en caso de que no exista, si existe lo omite
    INSERT INTO sources(code, description)
    VALUES ('BATCH', 'Batch seed process')
    ON CONFLICT (code) DO NOTHING;

    -- Agrega "SEED" a "data_objects", en caso de que no exista, si existe lo omite
    INSERT INTO data_objects(code, description)
    VALUES ('SEED', 'Seed process data')
    ON CONFLICT (code) DO NOTHING;

    -- Guarda los id de los tipos SYSTEM y SEED_DATA
    SELECT id INTO v_log_type_id FROM log_types WHERE code = 'SYSTEM';
    SELECT id INTO v_event_type_id FROM event_types WHERE code = 'SEED_DATA';

    -- Guarda el id de la severidad segun el estatus que reicibió 
    IF UPPER(p_status) = 'ERROR' THEN
        SELECT id INTO v_severity_id FROM severities WHERE code = 'ERROR';
    ELSE
        SELECT id INTO v_severity_id FROM severities WHERE code = 'INFO';
    END IF;

    -- Guarda los id de BATCH y SEED
    SELECT id INTO v_source_id FROM sources WHERE code = 'BATCH';
    SELECT id INTO v_data_object_id FROM data_objects WHERE code = 'SEED';

    -- Genera la descripción para el log y la guarda en la variable
    v_description := LEFT(
        p_process_name || ' | ' || p_action || ' | ' || p_target_table,
        100
    );

    -- Hace la inserción el logs
    INSERT INTO logs(
        log_type_id,
        event_type_id,
        severity_id,
        source_id,
        data_object_id,
        description,
        object_id1,
        reference_description,
        post_time
    )
    VALUES (
        v_log_type_id,
        v_event_type_id,
        v_severity_id,
        v_source_id,
        v_data_object_id,
        v_description,
        p_rows_affected,
        LEFT(COALESCE(p_message, p_status), 100),
        CURRENT_TIMESTAMP
    );

-- En caso de culauqier error, despliega ese mensaje en la consola. 
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'No se pudo registrar log de seed: %', SQLERRM;
END;
$$;


-- ============================================================
-- 2. SP transaccional: cargar 5 países
-- ============================================================

SET search_path TO etheria;
CREATE OR REPLACE PROCEDURE sp_seed_etheria_countries()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows INTEGER;
BEGIN
    -- Escribe en el log que se empezó el SP sp_seed_etheria_countries
    CALL sp_seed_log_step('sp_seed_etheria_countries', 'countries', 'START');

    -- Agrega 5 países a countries, si ya existen omite la instrucción
    INSERT INTO countries(name)
    VALUES
        ('Costa Rica'),
        ('Colombia'),
        ('Peru'),
        ('Mexico'),
        ('Panama')
    ON CONFLICT (name) DO NOTHING;

    -- Obtiene el numero de columnas que fueron agregadas
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    -- Escribe en el log que se agregaron los registros a countries
    CALL sp_seed_log_step(
        'sp_seed_etheria_countries',
        'countries',
        'INSERT',
        v_rows,
        'OK',
        '5 paises requeridos verificados'
    );

EXCEPTION
    WHEN OTHERS THEN

        -- Escribe en el log que el SP sp_seed_etheria_countries falló
        CALL sp_seed_log_step(
            'sp_seed_etheria_countries',
            'countries',
            'ERROR',
            NULL,
            'ERROR',
            SQLERRM
        );
        RAISE;
END;
$$;


-- ============================================================
-- 3. SP transaccional: catálogos mínimos
--    Necesarios para poder cumplir con la carga de 100 productos.
-- ============================================================

SET search_path TO etheria;
CREATE OR REPLACE PROCEDURE sp_seed_etheria_required_catalogs()
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
    v_usd_id BIGINT;
    v_rows INTEGER;
BEGIN
    -- Escribe en el log que se empezó el SP sp_seed_etheria_required_catalogs
    CALL sp_seed_log_step('sp_seed_etheria_required_catalogs', 'catalogs', 'START');

    -- Agrega el usuario admin en caso de que no exista, si existe lo omite
    INSERT INTO users(name, email, contrasennia, checksum, created_at, created_by)
    VALUES (
        'Admin Etheria',
        'admin.etheria@example.com',
        decode('00','hex'),
        decode('00','hex'),
        CURRENT_DATE,
        NULL
    )
    ON CONFLICT (email) DO NOTHING;

    -- obtiene el id del admin
    SELECT id INTO v_user_id
    FROM users
    WHERE email = 'admin.etheria@example.com'
    LIMIT 1;

    -- Agrega estados a todos los países
    INSERT INTO states(country_id, name)
    SELECT c.id, c.name || ' State'
    FROM countries c
    WHERE NOT EXISTS (
        SELECT 1
        FROM states s
        WHERE s.country_id = c.id
          AND s.name = c.name || ' State'
    );

    -- Agrega ciudades a todos los estados
    INSERT INTO cities(state_id, name)
    SELECT s.id, s.name || ' City'
    FROM states s
    WHERE NOT EXISTS (
        SELECT 1
        FROM cities ci
        WHERE ci.state_id = s.id
          AND ci.name = s.name || ' City'
    );

    -- Agrega direcciones para las ciudades
    INSERT INTO addresses(city_id, zip_code, latitude, longitude, created_by, created_at)
    SELECT ci.id, '00000', 9.9000000, -84.1000000, v_user_id, CURRENT_DATE
    FROM cities ci
    WHERE NOT EXISTS (
        SELECT 1
        FROM addresses a
        WHERE a.city_id = ci.id
    );

    -- Currencies
        -- Aquí agrega las currencie a los 5 países base

    -- Agrega el currencie de Costa Rica
    INSERT INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'USD', '$', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id
    FROM countries c
    WHERE c.name = 'Costa Rica'
      AND NOT EXISTS (SELECT 1 FROM currencies WHERE name = 'USD');

    -- Agrega el currencie de Colombia
    INSERT INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'COP', '$', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id
    FROM countries c
    WHERE c.name = 'Colombia'
      AND NOT EXISTS (SELECT 1 FROM currencies WHERE name = 'COP');

    -- Agrega el currencie de Peru
    INSERT INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'PEN', 'S/', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id
    FROM countries c
    WHERE c.name = 'Peru'
      AND NOT EXISTS (SELECT 1 FROM currencies WHERE name = 'PEN');

    -- Agrega el currencie de Mexico
    INSERT INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'MXN', '$', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id
    FROM countries c
    WHERE c.name = 'Mexico'
      AND NOT EXISTS (SELECT 1 FROM currencies WHERE name = 'MXN');

    -- Agrega el currencie de Panama
    INSERT INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'PAB', 'B/.', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id
    FROM countries c
    WHERE c.name = 'Panama'
      AND NOT EXISTS (SELECT 1 FROM currencies WHERE name = 'PAB');

    -- Guarda el id del USD en la variable 
    SELECT id INTO v_usd_id
    FROM currencies
    WHERE name = 'USD'
    LIMIT 1;

    -- Registra las tasas de cambio de los paises
    INSERT INTO exchange_rates(
        from_currency_id,
        to_currency_id,
        rate,
        date,
        created_at,
        post_time,
        user_id,
        checksum,
        is_current
    )
    SELECT
        c.id,
        v_usd_id,
        -- Elige la tasa segun el nombre de la moneda
        CASE c.name
            WHEN 'COP' THEN 0.000250
            WHEN 'PEN' THEN 0.270000
            WHEN 'MXN' THEN 0.058000
            WHEN 'PAB' THEN 1.000000
            ELSE 1.000000
        END,
        CURRENT_DATE,
        CURRENT_DATE,
        CURRENT_TIMESTAMP,
        v_user_id,
        decode('00','hex'),
        TRUE
    FROM currencies c
    WHERE c.id <> v_usd_id
      AND NOT EXISTS (
        SELECT 1
        FROM exchange_rates er
        WHERE er.from_currency_id = c.id
          AND er.to_currency_id = v_usd_id
          AND er.is_current = TRUE
    );

    -- Registra 5 categorías en caso de no existir y si existe lo omite 
    INSERT INTO categories(name)
    VALUES
        ('Aceites'),
        ('Belleza'),
        ('Tecnologia'),
        ('Hogar'),
        ('Salud')
    ON CONFLICT (name) DO NOTHING;

    -- Registra 5 categorías en caso de no existir y si existe lo omite 
    INSERT INTO quantity_types(description)
    VALUES
        ('unit'),
        ('bottle'),
        ('box'),
        ('pair'),
        ('pack')
    ON CONFLICT (description) DO NOTHING;

    -- Registra 5 unidades de medida en caso de no existir y si existe lo omite 
    INSERT INTO unit_measurements(description)
    VALUES
        ('unit'),
        ('ml'),
        ('g'),
        ('kg'),
        ('cm')
    ON CONFLICT (description) DO NOTHING;

    -- Crea las Marcas basándose en los países
    INSERT INTO brands(name, country_id)
    SELECT 'Marca ' || c.name, c.id
    FROM countries c
    WHERE NOT EXISTS (
        SELECT 1
        FROM brands b
        WHERE b.name = 'Marca ' || c.name
          AND b.country_id = c.id
    );

    -- Crea los suppliers basándose en los países
    INSERT INTO suppliers(name, country_id, created_at, enabled)
    SELECT 'Supplier ' || c.name, c.id, CURRENT_DATE, TRUE
    FROM countries c
    WHERE NOT EXISTS (
        SELECT 1
        FROM suppliers s
        WHERE s.name = 'Supplier ' || c.name
          AND s.country_id = c.id
    );

    -- Registra el hub type (MAIN) en caso de no existir y si existe lo omite 
    INSERT INTO hub_types(code, description)
    VALUES ('MAIN', 'Main hub')
    ON CONFLICT (code) DO NOTHING;

    -- Crea un hub por cada dirección en la base de datos
    INSERT INTO hubs(name, capacity, address_id, type_id, created_by, created_at)
    SELECT 'Hub Principal Etheria', 100000, a.id, ht.id, v_user_id, CURRENT_DATE
    FROM addresses a
    CROSS JOIN hub_types ht
    WHERE ht.code = 'MAIN'
      AND NOT EXISTS (
          SELECT 1
          FROM hubs h
          WHERE h.name = 'Hub Principal Etheria'
      )
    LIMIT 1;

    -- Guarda en una variable la cantidad de filas afectadas
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    -- Escribe en el log que "sp_seed_etheria_required_catalogs" insertó todos los datos de forma adecuada
    CALL sp_seed_log_step(
        'sp_seed_etheria_required_catalogs',
        'catalogs',
        'INSERT',
        v_rows,
        'OK',
        'Catalogos minimos verificados'
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Escribe en el log que el SP sp_seed_etheria_required_catalogs falló
        CALL sp_seed_log_step(
            'sp_seed_etheria_required_catalogs',
            'catalogs',
            'ERROR',
            NULL,
            'ERROR',
            SQLERRM
        );
        RAISE;
END;
$$;


-- ============================================================
-- 4. SP transaccional: cargar 100 productos
--    Distribuidos entre los 5 países mediante marca/proveedor/moneda.
-- ============================================================

SET search_path TO etheria;
CREATE OR REPLACE PROCEDURE sp_seed_etheria_products_100()
LANGUAGE plpgsql
AS $$
DECLARE
    i INT;
    v_country_id BIGINT;
    v_brand_id BIGINT;
    v_supplier_id BIGINT;
    v_currency_id BIGINT;
    v_exchange_rate_id BIGINT;
    v_user_id BIGINT;
    v_unit_id BIGINT;
    v_quantity_type_id BIGINT;
    v_product_id BIGINT;
    v_category_id BIGINT;
    v_hub_id BIGINT;
    v_inserted INTEGER := 0;
BEGIN
    -- Escribe en el log que se empezó el SP sp_seed_etheria_products_100
    CALL sp_seed_log_step('sp_seed_etheria_products_100', 'products', 'START');

    -- Obtiene el id del usuario administrador
    SELECT id INTO v_user_id
    FROM users
    WHERE email = 'admin.etheria@example.com'
    LIMIT 1;

    -- Obtiene la unidad de medida "unit"
    SELECT id INTO v_unit_id
    FROM unit_measurements
    WHERE description = 'unit'
    LIMIT 1;

    -- Obtiene el tipo de cantidad "unit"
    SELECT id INTO v_quantity_type_id
    FROM quantity_types
    WHERE description = 'unit'
    LIMIT 1;

    -- Obtiene el hub principal
    SELECT id INTO v_hub_id
    FROM hubs
    WHERE name = 'Hub Principal Etheria'
    LIMIT 1;

    -- Itera para crear hasta 100 productos
    FOR i IN 1..100 LOOP

        -- Verifica si el producto ya existe, si existe lo omite
        IF EXISTS (
            SELECT 1
            FROM products
            WHERE name = 'Producto Etheria ' || i
        ) THEN
            CONTINUE;
        END IF;

        -- Selecciona un país de forma cíclica (distribución entre 5 países)
        SELECT id INTO v_country_id
        FROM countries
        ORDER BY id
        OFFSET ((i - 1) % 5)
        LIMIT 1;


        -- Obtiene la marca asociada al país
        SELECT id INTO v_brand_id
        FROM brands
        WHERE country_id = v_country_id
        LIMIT 1;

        -- Obtiene el proveedor asociado al país
        SELECT id INTO v_supplier_id
        FROM suppliers
        WHERE country_id = v_country_id
        LIMIT 1;

        -- Obtiene la moneda del país
        SELECT id INTO v_currency_id
        FROM currencies
        WHERE country_id = v_country_id
        LIMIT 1;

        -- Obtiene la tasa de cambio hacia USD
        SELECT er.id INTO v_exchange_rate_id
        FROM exchange_rates er
        WHERE er.from_currency_id = v_currency_id
          AND er.to_currency_id = (
              SELECT id FROM currencies WHERE name = 'USD' LIMIT 1
          )
          AND er.is_current = TRUE
        LIMIT 1;

        -- Selecciona una categoría de forma cíclica
        SELECT id INTO v_category_id
        FROM categories
        ORDER BY id
        OFFSET ((i - 1) % 5)
        LIMIT 1;

        -- Inserta el producto principal
        INSERT INTO products(
            name,
            description,
            brand_id,
            supplier_id,
            current_price,
            currency_id,
            exchange_rate_id,
            checksum,
            created_by,
            created_at,
            unit_measurement_id,
            quantity_type_id,
            enabled
        )
        VALUES (
            'Producto Etheria ' || i,
            'Producto de prueba para carga inicial ' || i,
            v_brand_id,
            v_supplier_id,
            -- precio entre 20 y 200
            ROUND((20 + random() * 180)::numeric, 2),
            v_currency_id,
            v_exchange_rate_id,
            decode('00','hex'),
            v_user_id,
            CURRENT_DATE,
            v_unit_id,
            v_quantity_type_id,
            TRUE
        )
        -- Obtiene el id que se le asignó al producto
        RETURNING id INTO v_product_id;

        -- Relaciona el producto con su categoría
        INSERT INTO category_per_product(category_id, product_id)
        VALUES (v_category_id, v_product_id)
        ON CONFLICT (category_id, product_id) DO NOTHING;

        -- Registra el precio histórico del producto
        INSERT INTO product_prices(product_id, price, currency_id, valid_from, valid_to, created_at)
        VALUES (
            v_product_id,
            ROUND((20 + random() * 180)::numeric, 2),
            v_currency_id,
            CURRENT_DATE,
            NULL,
            CURRENT_DATE
        );

        -- Crea un lote de inventario para el producto
        INSERT INTO product_lots(
            product_id,
            supplier_id,
            hub_id,
            quantity,
            unit_cost,
            currency_id,
            arrival_date,
            checksum,
            created_at
        )
        VALUES (
            v_product_id,
            v_supplier_id,
            v_hub_id,
            ROUND((20 + random() * 200)::numeric, 2),
            ROUND((5 + random() * 90)::numeric, 2),
            v_currency_id,
            CURRENT_DATE,
            decode('00','hex'),
            CURRENT_DATE
        );

        -- Incrementa el contador de productos insertados
        v_inserted := v_inserted + 1;
    END LOOP;

    -- Escribe en el log que el SP insertó los productos correctamente
    CALL sp_seed_log_step(
        'sp_seed_etheria_products_100',
        'products',
        'INSERT',
        v_inserted,
        'OK',
        'Productos distribuidos entre 5 paises'
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Escribe en el log que el SP falló
        CALL sp_seed_log_step(
            'sp_seed_etheria_products_100',
            'products',
            'ERROR',
            NULL,
            'ERROR',
            SQLERRM
        );
        RAISE;
END;
$$;


-- ============================================================
-- 5. SP orquestador general Etheria
-- ============================================================

SET search_path TO etheria;
CREATE OR REPLACE PROCEDURE sp_seed_etheria_all()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Escribe en el log que se empezó el SP sp_seed_etheria_all
    CALL sp_seed_log_step('sp_seed_etheria_all', 'all', 'START');

    -- Ejecuta la carga de países base
    CALL sp_seed_etheria_countries();

    -- Ejecuta la carga de catálogos mínimos necesarios
    CALL sp_seed_etheria_required_catalogs();

    -- Ejecuta la carga de 100 productos de prueba
    CALL sp_seed_etheria_products_100();

    -- Escribe en el log que la carga completa finalizó correctamente
    CALL sp_seed_log_step(
        'sp_seed_etheria_all',
        'all',
        'END',
        NULL,
        'OK',
        'Carga completa Etheria'
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Escribe en el log que el SP falló
        CALL sp_seed_log_step(
            'sp_seed_etheria_all',
            'all',
            'ERROR',
            NULL,
            'ERROR',
            SQLERRM
        );
        RAISE;
END;
$$;


-- ============================================================
-- REPORTING VIEWS + ORQUESTADOR ACTUALIZADO
-- ============================================================

-- SOURCE: 05B_etheria_add_dashboard_view_to_seed.sql
-- ============================================================

-- ============================================================
-- 05B_etheria_add_dashboard_view_to_seed.sql
-- Ejecutar DESPUÉS de 05_etheria_data_load_procedures_postgresql.sql
--
-- Agrega al proceso completo de Etheria:
--   1. SP para crear/recrear la vista etheria.vw_import_costs.
--   2. Actualiza sp_seed_etheria_all() para llamar ese SP al final.
--
-- La vista sirve como fuente de costos/importación para Superset y Trino.
-- ============================================================


-- ============================================================
-- SP: crear vista de costos de importación para dashboard
-- ============================================================

SET search_path TO etheria;
CREATE OR REPLACE PROCEDURE sp_create_etheria_dashboard_views()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Escribe en el log que se inició la creación de la vista de costos de importación
    CALL sp_seed_log_step(
        'sp_create_etheria_dashboard_views',
        'vw_import_costs',
        'START',
        NULL,
        'OK',
        'Creando vista de costos de importacion'
    );

    -- Elimina la vista si existe para asegurar su recreación
    DROP VIEW IF EXISTS etheria.vw_import_costs CASCADE;

    -- Crea la vista de costos de importación
    CREATE VIEW etheria.vw_import_costs AS
    SELECT
        p.id AS etheria_product_id,
        p.name AS product_name,
        c.name AS category_name,
        b.name AS brand_name,
        co.name AS country_name,
        cu.name AS cost_currency,
        -- Tasa de conversión hacia USD (si no existe se asume 1)
        COALESCE(er.rate, 1) AS cost_to_usd_rate,

        -- Costo base de importación (promedio de lotes o precio actual)
        COALESCE(AVG(pl.unit_cost), p.current_price) AS import_unit_cost,

        -- Costo estimado de envío (8% del costo base)
        ROUND((COALESCE(AVG(pl.unit_cost), p.current_price) * 0.08), 2) AS shipping_cost_usd,

        -- Costo estimado de permisos (4% del costo base)
        ROUND((COALESCE(AVG(pl.unit_cost), p.current_price) * 0.04), 2) AS permits_cost_usd
    FROM etheria.products p

    -- Relación con marca y país de origen
    JOIN etheria.brands b ON b.id = p.brand_id
    JOIN etheria.countries co ON co.id = b.country_id

    -- Relación con moneda y tipo de cambio
    JOIN etheria.currencies cu ON cu.id = p.currency_id
    LEFT JOIN etheria.exchange_rates er ON er.id = p.exchange_rate_id

    -- Relación con categorías (puede tener múltiples)
    LEFT JOIN etheria.category_per_product cpp ON cpp.product_id = p.id
    LEFT JOIN etheria.categories c ON c.id = cpp.category_id

    -- Relación con lotes para cálculo de costos reales
    LEFT JOIN etheria.product_lots pl ON pl.product_id = p.id

    -- Agrupación necesaria por uso de funciones agregadas
    GROUP BY
        p.id,
        p.name,
        c.name,
        b.name,
        co.name,
        cu.name,
        er.rate,
        p.current_price;

    -- Escribe en el log que la vista fue creada correctamente
    CALL sp_seed_log_step(
        'sp_create_etheria_dashboard_views',
        'vw_import_costs',
        'CREATE_VIEW',
        NULL,
        'OK',
        'Vista etheria.vw_import_costs creada correctamente'
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Escribe en el log que ocurrió un error en la creación de la vista
        CALL sp_seed_log_step(
            'sp_create_etheria_dashboard_views',
            'vw_import_costs',
            'ERROR',
            NULL,
            'ERROR',
            SQLERRM
        );
        RAISE;
END;
$$;


-- ============================================================
-- Reemplazo del orquestador general para incluir la vista
-- ============================================================

SET search_path TO etheria;
CREATE OR REPLACE PROCEDURE sp_seed_etheria_all()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Escribe en el log que se empezó el SP sp_seed_etheria_all
    CALL sp_seed_log_step('sp_seed_etheria_all', 'all', 'START');

    -- Ejecuta la carga de países base
    CALL sp_seed_etheria_countries();

    -- Ejecuta la carga de catálogos mínimos necesarios
    CALL sp_seed_etheria_required_catalogs();

    -- Ejecuta la carga de 100 productos de prueba
    CALL sp_seed_etheria_products_100();

    -- Crea la vista para dashboard después de llenar productos y lotes.
    CALL sp_create_etheria_dashboard_views();

    CALL sp_seed_log_step(
        'sp_seed_etheria_all',
        'all',
        'END',
        NULL,
        'OK',
        'Carga completa Etheria con vista de dashboard'
    );
EXCEPTION
    WHEN OTHERS THEN
        -- Escribe en el log que el SP falló
        CALL sp_seed_log_step(
            'sp_seed_etheria_all',
            'all',
            'ERROR',
            NULL,
            'ERROR',
            SQLERRM
        );
        RAISE;
END;
$$;

-- ============================================================
-- SOURCE: 11_etheria_reporting_views_postgresql.sql
-- ============================================================

-- ============================================================
-- 11_etheria_reporting_views_postgresql.sql
-- Base: EtheriaCasoDos
-- Schema: etheria
-- Motor: PostgreSQL
--
-- Objetivo:
--   Crear vistas de Etheria para exponer costos de importación,
--   gastos estimados y funnel operativo.
-- ============================================================


-- ============================================================
-- 1. Vista base de costos de importación
-- ============================================================

SET search_path TO etheria;

-- Elimina la vista si existe 
DROP VIEW IF EXISTS etheria.vw_import_costs CASCADE;

-- Crea la vista de costos de importación
CREATE VIEW etheria.vw_import_costs AS
SELECT
    p.id AS etheria_product_id,
    p.name AS product_name,
    c.name AS category_name,
    b.name AS brand_name,
    co.name AS country_name,
    cu.name AS cost_currency,

    -- Tasa de conversión hacia USD (si no existe se asume 1)
    COALESCE(er.rate, 1) AS cost_to_usd_rate,

    -- Costo base de importación en moneda original
    COALESCE(AVG(pl.unit_cost), p.current_price) AS import_unit_cost,

    -- Costo base convertido a USD
    ROUND((COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1)), 2) AS import_unit_cost_usd,

    -- Costo estimado de envío (8% del costo base en USD)
    ROUND((COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1) * 0.08), 2) AS shipping_cost_usd,

    -- Costo estimado de permisos (4% del costo base en USD)
    ROUND((COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1) * 0.04), 2) AS permits_cost_usd,

    -- Costo total de importación (landed cost en USD)
    ROUND(
        (COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1))
        + (COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1) * 0.08)
        + (COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1) * 0.04),
        2
    ) AS total_landed_cost_usd
FROM etheria.products p

-- Relación con marca y país de origen
JOIN etheria.brands b ON b.id = p.brand_id
JOIN etheria.countries co ON co.id = b.country_id

-- Relación con moneda y tipo de cambio
JOIN etheria.currencies cu ON cu.id = p.currency_id
LEFT JOIN etheria.exchange_rates er ON er.id = p.exchange_rate_id

-- Relación con categorías (puede tener múltiples)
LEFT JOIN etheria.category_per_product cpp ON cpp.product_id = p.id
LEFT JOIN etheria.categories c ON c.id = cpp.category_id

-- Relación con lotes para cálculo de costos reales
LEFT JOIN etheria.product_lots pl ON pl.product_id = p.id

-- Agrupación necesaria por uso de funciones agregadas
GROUP BY
    p.id,
    p.name,
    c.name,
    b.name,
    co.name,
    cu.name,
    er.rate,
    p.current_price;


-- ============================================================
-- 2. Vista resumen de costos por categoría
-- ============================================================


SET search_path TO etheria;

-- Elimina la vista si existe 
DROP VIEW IF EXISTS etheria.vw_import_costs_by_category CASCADE;

-- Crea la vista costos de importación por categoría
CREATE VIEW etheria.vw_import_costs_by_category AS
SELECT
    category_name,

    -- Cantidad total de productos por categoría
    COUNT(*) AS total_products,

    -- Costo promedio de importación en USD por producto
    ROUND(AVG(import_unit_cost_usd), 2) AS avg_import_cost_usd,

    -- Costo total de importación (sin adicionales)
    ROUND(SUM(import_unit_cost_usd), 2) AS total_import_cost_usd,

    -- Costo total de envío
    ROUND(SUM(shipping_cost_usd), 2) AS total_shipping_cost_usd,

    -- Costo total de permisos
    ROUND(SUM(permits_cost_usd), 2) AS total_permits_cost_usd,

    -- Costo total de importación (landed cost)
    ROUND(SUM(total_landed_cost_usd), 2) AS total_landed_cost_usd
FROM etheria.vw_import_costs

-- Agrupa los resultados por categoría
GROUP BY category_name;


-- ============================================================
-- 3. Vista resumen de costos por país
-- ============================================================

SET search_path TO etheria;

-- Elimina la vista si existe 
DROP VIEW IF EXISTS etheria.vw_import_costs_by_country CASCADE;

-- Crea la vista agregada por país
CREATE VIEW etheria.vw_import_costs_by_country AS
SELECT
    country_name,

    -- Cantidad total de productos por país
    COUNT(*) AS total_products,

    -- Costo promedio de importación en USD por producto
    ROUND(AVG(import_unit_cost_usd), 2) AS avg_import_cost_usd,

    -- Costo total de importación (sin adicionales)
    ROUND(SUM(import_unit_cost_usd), 2) AS total_import_cost_usd,

    -- Costo total de envío
    ROUND(SUM(shipping_cost_usd), 2) AS total_shipping_cost_usd,

    -- Costo total de permisos
    ROUND(SUM(permits_cost_usd), 2) AS total_permits_cost_usd,

    -- Costo total de importación (landed cost)
    ROUND(SUM(total_landed_cost_usd), 2) AS total_landed_cost_usd
FROM etheria.vw_import_costs

-- Agrupa los resultados por país de origen
GROUP BY country_name;


-- ============================================================
-- 4. Funnel operativo de Etheria
-- ============================================================


SET search_path TO etheria;

-- Elimina la vista si existe para asegurar su recreación
DROP VIEW IF EXISTS etheria.vw_funnel_import_process CASCADE;

-- Crea la vista tipo funnel
CREATE VIEW etheria.vw_funnel_import_process AS

-- 1era parte: Proveedores activos (productos asociados)
SELECT '1. Proveedores activos' AS stage, COUNT(DISTINCT supplier_id) AS value
FROM etheria.products

UNION ALL

-- 2da parte: Productos registrados en el sistema
SELECT '2. Productos registrados' AS stage, COUNT(*) AS value
FROM etheria.products

UNION ALL

-- 3ra parte: Lotes importados (inventario disponible)
SELECT '3. Lotes importados' AS stage, COUNT(*) AS value
FROM etheria.product_lots

UNION ALL

-- 4ta parte: Productos con costo de importación calculado
SELECT '4. Productos con costo calculado' AS stage, COUNT(*) AS value
FROM etheria.vw_import_costs

UNION ALL

-- 5ta parte: Productos con costos logísticos completos
SELECT '5. Productos con costo logístico' AS stage, COUNT(*) AS value
FROM etheria.vw_import_costs
WHERE shipping_cost_usd > 0
  AND permits_cost_usd > 0;


-- ============================================================
-- Validaciones
-- ============================================================

SELECT COUNT(*) AS rows_vw_import_costs
FROM etheria.vw_import_costs;

SELECT *
FROM etheria.vw_import_costs
LIMIT 20;

SELECT *
FROM etheria.vw_funnel_import_process;

-- ============================================================
-- EJECUCIÓN Y VALIDACIÓN FINAL
-- ============================================================

SET search_path TO etheria;
CALL sp_seed_etheria_all();

SELECT COUNT(*) AS total_countries
FROM etheria.countries;

SELECT COUNT(*) AS total_products
FROM etheria.products;

SELECT COUNT(*) AS total_product_lots
FROM etheria.product_lots;

SELECT COUNT(*) AS total_logs
FROM etheria.logs;

SELECT COUNT(*) AS rows_vw_import_costs
FROM etheria.vw_import_costs;

SELECT *
FROM etheria.vw_import_costs
LIMIT 20;

SELECT *
FROM etheria.vw_funnel_import_process;

SELECT *
FROM etheria.logs
ORDER BY id DESC
LIMIT 20;