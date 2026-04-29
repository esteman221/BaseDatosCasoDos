

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
-- Ejecución opcional inmediata
-- ============================================================

CALL sp_create_etheria_dashboard_views();

-- Validación:
SELECT COUNT(*) AS total_rows_vw_import_costs
FROM etheria.vw_import_costs;

SELECT *
FROM etheria.vw_import_costs
LIMIT 20;


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
