-- ============================================================
-- 13_trino_dashboard_federated_script.sql
-- Motor: Trino
--
-- Objetivo:
-- Cruzar las views creadas en Etheria/PostgreSQL y DynamicBrands/MySQL.
--
-- IMPORTANTE:
-- En los datos seed actuales los nombres no coinciden exactamente:
--   Etheria: Producto Etheria 1
--   DynamicBrands: Producto DynamicBrands 1
-- Por eso se cruza por el número final del producto usando regexp_extract().
-- ============================================================

-- ============================================================
-- 0. VALIDACIONES
-- ============================================================

SHOW CATALOGS;
SHOW SCHEMAS FROM postgresql;
SHOW SCHEMAS FROM mysql;
SHOW TABLES FROM postgresql.etheria;
SHOW TABLES FROM mysql.DynamicBrandsCasoDos;

SELECT * FROM postgresql.etheria.vw_import_costs LIMIT 10;
SELECT * FROM mysql.DynamicBrandsCasoDos.vw_dynamic_sales LIMIT 10;


-- ============================================================
-- 1. DATASET UNIFICADO BASE
-- Guardar en Superset como dataset:
--   unified_profitability_base
-- ============================================================

WITH dynamic_sales AS (
    SELECT
        CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
        dynamic_product_id,
        product_name AS dynamic_product_name,
        category_name,
        brand_name,
        site_name,
        country_name AS sale_country_name,
        sale_currency,
        sale_to_usd_rate,
        sale_price,
        sale_price_usd,
        quantity_sold,
        site_operating_cost_usd,
        created_at
    FROM mysql.DynamicBrandsCasoDos.vw_dynamic_sales
),
etheria_costs AS (
    SELECT
        CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
        etheria_product_id,
        product_name AS etheria_product_name,
        category_name AS import_category_name,
        brand_name AS import_brand_name,
        country_name AS import_country_name,
        cost_currency,
        cost_to_usd_rate,
        import_unit_cost,
        import_unit_cost_usd,
        shipping_cost_usd,
        permits_cost_usd,
        total_landed_cost_usd
    FROM postgresql.etheria.vw_import_costs
)
SELECT
    d.product_number,
    d.dynamic_product_id,
    e.etheria_product_id,
    d.dynamic_product_name,
    e.etheria_product_name,
    d.category_name,
    d.brand_name,
    d.site_name,
    d.sale_country_name,
    e.import_country_name,
    d.sale_currency,
    d.sale_price,
    d.sale_to_usd_rate,
    d.sale_price_usd,
    e.cost_currency,
    e.import_unit_cost,
    e.cost_to_usd_rate,
    e.import_unit_cost_usd,
    e.shipping_cost_usd,
    e.permits_cost_usd,
    e.total_landed_cost_usd,
    d.site_operating_cost_usd,
    ROUND(d.sale_price_usd - e.total_landed_cost_usd - d.site_operating_cost_usd, 2) AS real_profit_usd,
    ROUND(((d.sale_price_usd - e.total_landed_cost_usd - d.site_operating_cost_usd) / NULLIF(d.sale_price_usd, 0)) * 100, 2) AS margin_percentage,
    d.created_at
FROM dynamic_sales d
JOIN etheria_costs e ON d.product_number = e.product_number
ORDER BY d.product_number, d.site_name;


-- ============================================================
-- 2. RENTABILIDAD REAL POR CATEGORÍA
-- Pregunta: ¿Cuál es la rentabilidad real de una categoría
-- si el costo es en USD y la venta en COP o PEN?
-- Dataset Superset: profitability_by_category_currency
-- Chart: Bar Chart
-- X-axis: category_name
-- Group by: sale_currency
-- Metric: SUM(real_profit_usd)
-- ============================================================

WITH unified_data AS (
    WITH dynamic_sales AS (
        SELECT
            CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
            category_name,
            sale_currency,
            sale_price_usd,
            site_operating_cost_usd
        FROM mysql.DynamicBrandsCasoDos.vw_dynamic_sales
    ),
    etheria_costs AS (
        SELECT
            CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
            total_landed_cost_usd
        FROM postgresql.etheria.vw_import_costs
    )
    SELECT
        d.category_name,
        d.sale_currency,
        d.sale_price_usd,
        e.total_landed_cost_usd,
        d.site_operating_cost_usd,
        ROUND(d.sale_price_usd - e.total_landed_cost_usd - d.site_operating_cost_usd, 2) AS real_profit_usd
    FROM dynamic_sales d
    JOIN etheria_costs e ON d.product_number = e.product_number
)
SELECT
    category_name,
    sale_currency,
    COUNT(*) AS total_publications,
    ROUND(SUM(sale_price_usd), 2) AS total_sales_usd,
    ROUND(SUM(total_landed_cost_usd), 2) AS total_landed_cost_usd,
    ROUND(SUM(site_operating_cost_usd), 2) AS total_site_operating_cost_usd,
    ROUND(SUM(real_profit_usd), 2) AS real_profit_usd,
    ROUND((SUM(real_profit_usd) / NULLIF(SUM(sale_price_usd), 0)) * 100, 2) AS margin_percentage
FROM unified_data
WHERE sale_currency IN ('COP', 'PEN')
GROUP BY category_name, sale_currency
ORDER BY real_profit_usd DESC;


-- ============================================================
-- 3. MARCA IA MÁS EFECTIVA VS COSTOS DE IMPORTACIÓN
-- Dataset Superset: ai_brand_effectiveness_import_cost
-- Chart: Bar Chart o Table
-- X-axis: brand_name
-- Metric: MAX(effectiveness_ratio)
-- ============================================================

WITH unified_data AS (
    WITH dynamic_sales AS (
        SELECT
            CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
            brand_name,
            site_name,
            dynamic_product_id,
            sale_price_usd,
            site_operating_cost_usd
        FROM mysql.DynamicBrandsCasoDos.vw_dynamic_sales
    ),
    etheria_costs AS (
        SELECT
            CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
            total_landed_cost_usd
        FROM postgresql.etheria.vw_import_costs
    )
    SELECT
        d.brand_name,
        d.site_name,
        d.dynamic_product_id,
        d.sale_price_usd,
        e.total_landed_cost_usd,
        d.site_operating_cost_usd,
        ROUND(d.sale_price_usd - e.total_landed_cost_usd - d.site_operating_cost_usd, 2) AS gross_profit_usd
    FROM dynamic_sales d
    JOIN etheria_costs e ON d.product_number = e.product_number
)
SELECT
    brand_name,
    COUNT(DISTINCT site_name) AS total_sites,
    COUNT(DISTINCT dynamic_product_id) AS total_products,
    COUNT(*) AS total_publications,
    ROUND(SUM(sale_price_usd), 2) AS total_sales_usd,
    ROUND(SUM(total_landed_cost_usd), 2) AS total_landed_cost_usd,
    ROUND(SUM(site_operating_cost_usd), 2) AS total_site_operating_cost_usd,
    ROUND(SUM(gross_profit_usd), 2) AS gross_profit_usd,
    ROUND(SUM(sale_price_usd) / NULLIF(SUM(total_landed_cost_usd + site_operating_cost_usd), 0), 2) AS effectiveness_ratio
FROM unified_data
GROUP BY brand_name
ORDER BY effectiveness_ratio DESC;


-- ============================================================
-- 4. MARGEN POR PAÍS CON ENVÍO Y PERMISOS
-- Dataset Superset: margin_by_country_shipping_permits
-- Chart: Bar Chart
-- X-axis: sale_country_name
-- Metric: SUM(net_margin_usd)
-- ============================================================

WITH unified_data AS (
    WITH dynamic_sales AS (
        SELECT
            CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
            country_name AS sale_country_name,
            sale_price_usd,
            site_operating_cost_usd
        FROM mysql.DynamicBrandsCasoDos.vw_dynamic_sales
    ),
    etheria_costs AS (
        SELECT
            CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
            import_unit_cost_usd,
            shipping_cost_usd,
            permits_cost_usd,
            total_landed_cost_usd
        FROM postgresql.etheria.vw_import_costs
    )
    SELECT
        d.sale_country_name,
        d.sale_price_usd,
        e.import_unit_cost_usd,
        e.shipping_cost_usd,
        e.permits_cost_usd,
        e.total_landed_cost_usd,
        d.site_operating_cost_usd,
        ROUND(d.sale_price_usd - e.total_landed_cost_usd - d.site_operating_cost_usd, 2) AS net_margin_usd
    FROM dynamic_sales d
    JOIN etheria_costs e ON d.product_number = e.product_number
)
SELECT
    sale_country_name,
    COUNT(*) AS total_publications,
    ROUND(SUM(sale_price_usd), 2) AS total_sales_usd,
    ROUND(SUM(import_unit_cost_usd), 2) AS total_import_cost_usd,
    ROUND(SUM(shipping_cost_usd), 2) AS total_shipping_cost_usd,
    ROUND(SUM(permits_cost_usd), 2) AS total_permits_cost_usd,
    ROUND(SUM(site_operating_cost_usd), 2) AS total_site_operating_cost_usd,
    ROUND(SUM(net_margin_usd), 2) AS net_margin_usd,
    ROUND((SUM(net_margin_usd) / NULLIF(SUM(sale_price_usd), 0)) * 100, 2) AS net_margin_percentage
FROM unified_data
GROUP BY sale_country_name
ORDER BY net_margin_usd DESC;


-- ============================================================
-- 5. COMPARACIÓN COMPRA VS VENTA POR PRODUCTO
-- Dataset Superset: purchase_vs_sale_by_product
-- Chart: Bar Chart
-- X-axis: dynamic_product_name
-- Metrics:
--   AVG(avg_purchase_cost_usd)
--   AVG(avg_sale_price_usd)
-- ============================================================

WITH unified_data AS (
    WITH dynamic_sales AS (
        SELECT
            CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
            product_name AS dynamic_product_name,
            category_name,
            brand_name,
            site_name,
            sale_price_usd
        FROM mysql.DynamicBrandsCasoDos.vw_dynamic_sales
    ),
    etheria_costs AS (
        SELECT
            CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
            product_name AS etheria_product_name,
            total_landed_cost_usd
        FROM postgresql.etheria.vw_import_costs
    )
    SELECT
        d.dynamic_product_name,
        e.etheria_product_name,
        d.category_name,
        d.brand_name,
        d.site_name,
        d.sale_price_usd,
        e.total_landed_cost_usd
    FROM dynamic_sales d
    JOIN etheria_costs e ON d.product_number = e.product_number
)
SELECT
    dynamic_product_name,
    etheria_product_name,
    category_name,
    brand_name,
    site_name,
    ROUND(AVG(total_landed_cost_usd), 2) AS avg_purchase_cost_usd,
    ROUND(AVG(sale_price_usd), 2) AS avg_sale_price_usd,
    ROUND(AVG(sale_price_usd - total_landed_cost_usd), 2) AS avg_profit_usd
FROM unified_data
GROUP BY dynamic_product_name, etheria_product_name, category_name, brand_name, site_name
ORDER BY avg_profit_usd DESC;


-- ============================================================
-- 6. FUNNEL FEDERADO
-- Dataset Superset: federated_operational_funnel
-- Chart: Funnel Chart
-- Group by: stage
-- Metric: SUM(value)
-- ============================================================

SELECT
    stage,
    value,
    'Etheria' AS source
FROM postgresql.etheria.vw_funnel_import_process

UNION ALL

SELECT
    stage,
    value,
    'DynamicBrands' AS source
FROM mysql.DynamicBrandsCasoDos.vw_funnel_commercial_process;


-- ============================================================
-- 7. KPI GENERAL DEL DASHBOARD
-- Dataset Superset: executive_kpis
-- Chart: Big Number / KPI cards
-- ============================================================

WITH unified_data AS (
    WITH dynamic_sales AS (
        SELECT
            CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
            sale_price_usd,
            site_operating_cost_usd
        FROM mysql.DynamicBrandsCasoDos.vw_dynamic_sales
    ),
    etheria_costs AS (
        SELECT
            CAST(regexp_extract(product_name, '([0-9]+)$', 1) AS INTEGER) AS product_number,
            total_landed_cost_usd
        FROM postgresql.etheria.vw_import_costs
    )
    SELECT
        d.sale_price_usd,
        e.total_landed_cost_usd,
        d.site_operating_cost_usd,
        ROUND(d.sale_price_usd - e.total_landed_cost_usd - d.site_operating_cost_usd, 2) AS real_profit_usd
    FROM dynamic_sales d
    JOIN etheria_costs e ON d.product_number = e.product_number
)
SELECT
    ROUND(SUM(sale_price_usd), 2) AS total_sales_usd,
    ROUND(SUM(total_landed_cost_usd), 2) AS total_landed_cost_usd,
    ROUND(SUM(site_operating_cost_usd), 2) AS total_site_operating_cost_usd,
    ROUND(SUM(real_profit_usd), 2) AS total_real_profit_usd,
    ROUND((SUM(real_profit_usd) / NULLIF(SUM(sale_price_usd), 0)) * 100, 2) AS global_margin_percentage
FROM unified_data;
