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

SET search_path TO etheria;

-- ============================================================
-- 1. SP independiente de logging
-- ============================================================

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
    INSERT INTO log_types(code, description)
    VALUES ('SYSTEM', 'System process')
    ON CONFLICT (code) DO NOTHING;

    INSERT INTO event_types(code, description)
    VALUES ('SEED_DATA', 'Seed data execution')
    ON CONFLICT (code) DO NOTHING;

    INSERT INTO severities(code, level)
    VALUES ('INFO', '1')
    ON CONFLICT (code) DO NOTHING;

    INSERT INTO severities(code, level)
    VALUES ('ERROR', '3')
    ON CONFLICT (code) DO NOTHING;

    INSERT INTO sources(code, description)
    VALUES ('BATCH', 'Batch seed process')
    ON CONFLICT (code) DO NOTHING;

    INSERT INTO data_objects(code, description)
    VALUES ('SEED', 'Seed process data')
    ON CONFLICT (code) DO NOTHING;

    SELECT id INTO v_log_type_id FROM log_types WHERE code = 'SYSTEM';
    SELECT id INTO v_event_type_id FROM event_types WHERE code = 'SEED_DATA';

    IF UPPER(p_status) = 'ERROR' THEN
        SELECT id INTO v_severity_id FROM severities WHERE code = 'ERROR';
    ELSE
        SELECT id INTO v_severity_id FROM severities WHERE code = 'INFO';
    END IF;

    SELECT id INTO v_source_id FROM sources WHERE code = 'BATCH';
    SELECT id INTO v_data_object_id FROM data_objects WHERE code = 'SEED';

    v_description := LEFT(
        p_process_name || ' | ' || p_action || ' | ' || p_target_table,
        100
    );

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

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'No se pudo registrar log de seed: %', SQLERRM;
END;
$$;


-- ============================================================
-- 2. SP transaccional: cargar 5 países
-- ============================================================

CREATE OR REPLACE PROCEDURE sp_seed_etheria_countries()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows INTEGER;
BEGIN
    CALL sp_seed_log_step('sp_seed_etheria_countries', 'countries', 'START');

    INSERT INTO countries(name)
    VALUES
        ('Costa Rica'),
        ('Colombia'),
        ('Peru'),
        ('Mexico'),
        ('Panama')
    ON CONFLICT (name) DO NOTHING;

    GET DIAGNOSTICS v_rows = ROW_COUNT;

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

CREATE OR REPLACE PROCEDURE sp_seed_etheria_required_catalogs()
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
    v_usd_id BIGINT;
    v_rows INTEGER;
BEGIN
    CALL sp_seed_log_step('sp_seed_etheria_required_catalogs', 'catalogs', 'START');

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

    SELECT id INTO v_user_id
    FROM users
    WHERE email = 'admin.etheria@example.com'
    LIMIT 1;

    INSERT INTO states(country_id, name)
    SELECT c.id, c.name || ' State'
    FROM countries c
    WHERE NOT EXISTS (
        SELECT 1
        FROM states s
        WHERE s.country_id = c.id
          AND s.name = c.name || ' State'
    );

    INSERT INTO cities(state_id, name)
    SELECT s.id, s.name || ' City'
    FROM states s
    WHERE NOT EXISTS (
        SELECT 1
        FROM cities ci
        WHERE ci.state_id = s.id
          AND ci.name = s.name || ' City'
    );

    INSERT INTO addresses(city_id, zip_code, latitude, longitude, created_by, created_at)
    SELECT ci.id, '00000', 9.9000000, -84.1000000, v_user_id, CURRENT_DATE
    FROM cities ci
    WHERE NOT EXISTS (
        SELECT 1
        FROM addresses a
        WHERE a.city_id = ci.id
    );

    INSERT INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'USD', '$', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id
    FROM countries c
    WHERE c.name = 'Costa Rica'
      AND NOT EXISTS (SELECT 1 FROM currencies WHERE name = 'USD');

    INSERT INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'COP', '$', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id
    FROM countries c
    WHERE c.name = 'Colombia'
      AND NOT EXISTS (SELECT 1 FROM currencies WHERE name = 'COP');

    INSERT INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'PEN', 'S/', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id
    FROM countries c
    WHERE c.name = 'Peru'
      AND NOT EXISTS (SELECT 1 FROM currencies WHERE name = 'PEN');

    INSERT INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'MXN', '$', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id
    FROM countries c
    WHERE c.name = 'Mexico'
      AND NOT EXISTS (SELECT 1 FROM currencies WHERE name = 'MXN');

    INSERT INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'PAB', 'B/.', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id
    FROM countries c
    WHERE c.name = 'Panama'
      AND NOT EXISTS (SELECT 1 FROM currencies WHERE name = 'PAB');

    SELECT id INTO v_usd_id
    FROM currencies
    WHERE name = 'USD'
    LIMIT 1;

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

    INSERT INTO categories(name)
    VALUES
        ('Aceites'),
        ('Belleza'),
        ('Tecnologia'),
        ('Hogar'),
        ('Salud')
    ON CONFLICT (name) DO NOTHING;

    INSERT INTO quantity_types(description)
    VALUES
        ('unit'),
        ('bottle'),
        ('box'),
        ('pair'),
        ('pack')
    ON CONFLICT (description) DO NOTHING;

    INSERT INTO unit_measurements(description)
    VALUES
        ('unit'),
        ('ml'),
        ('g'),
        ('kg'),
        ('cm')
    ON CONFLICT (description) DO NOTHING;

    INSERT INTO brands(name, country_id)
    SELECT 'Marca ' || c.name, c.id
    FROM countries c
    WHERE NOT EXISTS (
        SELECT 1
        FROM brands b
        WHERE b.name = 'Marca ' || c.name
          AND b.country_id = c.id
    );

    INSERT INTO suppliers(name, country_id, created_at, enabled)
    SELECT 'Supplier ' || c.name, c.id, CURRENT_DATE, TRUE
    FROM countries c
    WHERE NOT EXISTS (
        SELECT 1
        FROM suppliers s
        WHERE s.name = 'Supplier ' || c.name
          AND s.country_id = c.id
    );

    INSERT INTO hub_types(code, description)
    VALUES ('MAIN', 'Main hub')
    ON CONFLICT (code) DO NOTHING;

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

    GET DIAGNOSTICS v_rows = ROW_COUNT;

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
    CALL sp_seed_log_step('sp_seed_etheria_products_100', 'products', 'START');

    SELECT id INTO v_user_id
    FROM users
    WHERE email = 'admin.etheria@example.com'
    LIMIT 1;

    SELECT id INTO v_unit_id
    FROM unit_measurements
    WHERE description = 'unit'
    LIMIT 1;

    SELECT id INTO v_quantity_type_id
    FROM quantity_types
    WHERE description = 'unit'
    LIMIT 1;

    SELECT id INTO v_hub_id
    FROM hubs
    WHERE name = 'Hub Principal Etheria'
    LIMIT 1;

    FOR i IN 1..100 LOOP
        IF EXISTS (
            SELECT 1
            FROM products
            WHERE name = 'Producto Etheria ' || i
        ) THEN
            CONTINUE;
        END IF;

        SELECT id INTO v_country_id
        FROM countries
        ORDER BY id
        OFFSET ((i - 1) % 5)
        LIMIT 1;

        SELECT id INTO v_brand_id
        FROM brands
        WHERE country_id = v_country_id
        LIMIT 1;

        SELECT id INTO v_supplier_id
        FROM suppliers
        WHERE country_id = v_country_id
        LIMIT 1;

        SELECT id INTO v_currency_id
        FROM currencies
        WHERE country_id = v_country_id
        LIMIT 1;

        SELECT er.id INTO v_exchange_rate_id
        FROM exchange_rates er
        WHERE er.from_currency_id = v_currency_id
          AND er.to_currency_id = (
              SELECT id FROM currencies WHERE name = 'USD' LIMIT 1
          )
          AND er.is_current = TRUE
        LIMIT 1;

        SELECT id INTO v_category_id
        FROM categories
        ORDER BY id
        OFFSET ((i - 1) % 5)
        LIMIT 1;

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
        RETURNING id INTO v_product_id;

        INSERT INTO category_per_product(category_id, product_id)
        VALUES (v_category_id, v_product_id)
        ON CONFLICT (category_id, product_id) DO NOTHING;

        INSERT INTO product_prices(product_id, price, currency_id, valid_from, valid_to, created_at)
        VALUES (
            v_product_id,
            ROUND((20 + random() * 180)::numeric, 2),
            v_currency_id,
            CURRENT_DATE,
            NULL,
            CURRENT_DATE
        );

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

        v_inserted := v_inserted + 1;
    END LOOP;

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

CREATE OR REPLACE PROCEDURE sp_seed_etheria_all()
LANGUAGE plpgsql
AS $$
BEGIN
    CALL sp_seed_log_step('sp_seed_etheria_all', 'all', 'START');

    CALL sp_seed_etheria_countries();
    CALL sp_seed_etheria_required_catalogs();
    CALL sp_seed_etheria_products_100();

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

SET search_path TO etheria;

-- ============================================================
-- SP: crear vista de costos de importación para dashboard
-- ============================================================

CREATE OR REPLACE PROCEDURE sp_create_etheria_dashboard_views()
LANGUAGE plpgsql
AS $$
BEGIN
    CALL sp_seed_log_step(
        'sp_create_etheria_dashboard_views',
        'vw_import_costs',
        'START',
        NULL,
        'OK',
        'Creando vista de costos de importacion'
    );

    DROP VIEW IF EXISTS etheria.vw_import_costs CASCADE;

    CREATE VIEW etheria.vw_import_costs AS
    SELECT
        p.id AS etheria_product_id,
        p.name AS product_name,
        c.name AS category_name,
        b.name AS brand_name,
        co.name AS country_name,
        cu.name AS cost_currency,
        COALESCE(er.rate, 1) AS cost_to_usd_rate,
        COALESCE(AVG(pl.unit_cost), p.current_price) AS import_unit_cost,
        ROUND((COALESCE(AVG(pl.unit_cost), p.current_price) * 0.08), 2) AS shipping_cost_usd,
        ROUND((COALESCE(AVG(pl.unit_cost), p.current_price) * 0.04), 2) AS permits_cost_usd
    FROM etheria.products p
    JOIN etheria.brands b ON b.id = p.brand_id
    JOIN etheria.countries co ON co.id = b.country_id
    JOIN etheria.currencies cu ON cu.id = p.currency_id
    LEFT JOIN etheria.exchange_rates er ON er.id = p.exchange_rate_id
    LEFT JOIN etheria.category_per_product cpp ON cpp.product_id = p.id
    LEFT JOIN etheria.categories c ON c.id = cpp.category_id
    LEFT JOIN etheria.product_lots pl ON pl.product_id = p.id
    GROUP BY
        p.id,
        p.name,
        c.name,
        b.name,
        co.name,
        cu.name,
        er.rate,
        p.current_price;

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

CREATE OR REPLACE PROCEDURE sp_seed_etheria_all()
LANGUAGE plpgsql
AS $$
BEGIN
    CALL sp_seed_log_step('sp_seed_etheria_all', 'all', 'START');

    CALL sp_seed_etheria_countries();
    CALL sp_seed_etheria_required_catalogs();
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

SET search_path TO etheria;

-- ============================================================
-- 1. Vista base de costos de importación
-- ============================================================

DROP VIEW IF EXISTS etheria.vw_import_costs CASCADE;

CREATE VIEW etheria.vw_import_costs AS
SELECT
    p.id AS etheria_product_id,
    p.name AS product_name,
    c.name AS category_name,
    b.name AS brand_name,
    co.name AS country_name,
    cu.name AS cost_currency,
    COALESCE(er.rate, 1) AS cost_to_usd_rate,
    COALESCE(AVG(pl.unit_cost), p.current_price) AS import_unit_cost,
    ROUND((COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1)), 2) AS import_unit_cost_usd,
    ROUND((COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1) * 0.08), 2) AS shipping_cost_usd,
    ROUND((COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1) * 0.04), 2) AS permits_cost_usd,
    ROUND(
        (COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1))
        + (COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1) * 0.08)
        + (COALESCE(AVG(pl.unit_cost), p.current_price) * COALESCE(er.rate, 1) * 0.04),
        2
    ) AS total_landed_cost_usd
FROM etheria.products p
JOIN etheria.brands b ON b.id = p.brand_id
JOIN etheria.countries co ON co.id = b.country_id
JOIN etheria.currencies cu ON cu.id = p.currency_id
LEFT JOIN etheria.exchange_rates er ON er.id = p.exchange_rate_id
LEFT JOIN etheria.category_per_product cpp ON cpp.product_id = p.id
LEFT JOIN etheria.categories c ON c.id = cpp.category_id
LEFT JOIN etheria.product_lots pl ON pl.product_id = p.id
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

DROP VIEW IF EXISTS etheria.vw_import_costs_by_category CASCADE;

CREATE VIEW etheria.vw_import_costs_by_category AS
SELECT
    category_name,
    COUNT(*) AS total_products,
    ROUND(AVG(import_unit_cost_usd), 2) AS avg_import_cost_usd,
    ROUND(SUM(import_unit_cost_usd), 2) AS total_import_cost_usd,
    ROUND(SUM(shipping_cost_usd), 2) AS total_shipping_cost_usd,
    ROUND(SUM(permits_cost_usd), 2) AS total_permits_cost_usd,
    ROUND(SUM(total_landed_cost_usd), 2) AS total_landed_cost_usd
FROM etheria.vw_import_costs
GROUP BY category_name;


-- ============================================================
-- 3. Vista resumen de costos por país
-- ============================================================

DROP VIEW IF EXISTS etheria.vw_import_costs_by_country CASCADE;

CREATE VIEW etheria.vw_import_costs_by_country AS
SELECT
    country_name,
    COUNT(*) AS total_products,
    ROUND(AVG(import_unit_cost_usd), 2) AS avg_import_cost_usd,
    ROUND(SUM(import_unit_cost_usd), 2) AS total_import_cost_usd,
    ROUND(SUM(shipping_cost_usd), 2) AS total_shipping_cost_usd,
    ROUND(SUM(permits_cost_usd), 2) AS total_permits_cost_usd,
    ROUND(SUM(total_landed_cost_usd), 2) AS total_landed_cost_usd
FROM etheria.vw_import_costs
GROUP BY country_name;


-- ============================================================
-- 4. Funnel operativo de Etheria
-- ============================================================

DROP VIEW IF EXISTS etheria.vw_funnel_import_process CASCADE;

CREATE VIEW etheria.vw_funnel_import_process AS
SELECT '1. Proveedores activos' AS stage, COUNT(DISTINCT supplier_id) AS value
FROM etheria.products

UNION ALL

SELECT '2. Productos registrados' AS stage, COUNT(*) AS value
FROM etheria.products

UNION ALL

SELECT '3. Lotes importados' AS stage, COUNT(*) AS value
FROM etheria.product_lots

UNION ALL

SELECT '4. Productos con costo calculado' AS stage, COUNT(*) AS value
FROM etheria.vw_import_costs

UNION ALL

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