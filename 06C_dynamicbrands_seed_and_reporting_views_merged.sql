-- ============================================================
-- SOURCE: 06_dynamicbrands_data_load_procedures_mysql_FIXED.sql
-- ============================================================

-- ============================================================
-- 06_dynamicbrands_data_load_procedures_mysql_FIXED.sql
-- Base: DynamicBrandsCasoDos
-- Motor: MySQL
--
-- Correcciones aplicadas:
--   1. Reemplaza OFFSET ((i - 1) MOD 5) por variable v_offset.
--   2. Usa LIMIT v_offset, 1.
--   3. Reinicia v_exchange_rate_id en cada vuelta para evitar valores viejos.
--   4. Mantiene SP transaccionales, logging y manejo de excepciones.
-- ============================================================

USE DynamicBrandsCasoDos;

-- ============================================================
-- 1. SP utilitario: registro de logs (sp_seed_log_step)
--    Permite registrar eventos,
--    incluyendo estado, acción realizada y detalle del resultado.
-- ============================================================

DELIMITER $$
-- Elimina el SP si existe 
DROP PROCEDURE IF EXISTS sp_seed_log_step $$
CREATE PROCEDURE sp_seed_log_step(
    IN p_process_name VARCHAR(80),
    IN p_target_table VARCHAR(80),
    IN p_action VARCHAR(30),
    IN p_rows_affected INT,
    IN p_status VARCHAR(20),
    IN p_message VARCHAR(100)
)
BEGIN
    DECLARE v_log_type_id BIGINT;
    DECLARE v_event_type_id BIGINT;
    DECLARE v_severity_id BIGINT;
    DECLARE v_source_id BIGINT;
    DECLARE v_data_object_id BIGINT;

    -- Inserta catálogos básicos de logging en caso de no existir
    INSERT IGNORE INTO log_types(code, description) VALUES ('SYSTEM', 'System process');
    INSERT IGNORE INTO event_types(code, description) VALUES ('SEED_DATA', 'Seed data execution');
    INSERT IGNORE INTO severities(code, level) VALUES ('INFO', '1');
    INSERT IGNORE INTO severities(code, level) VALUES ('ERROR', '3');
    INSERT IGNORE INTO sources(code, description) VALUES ('BATCH', 'Batch seed process');
    INSERT IGNORE INTO data_objects(code, description) VALUES ('SEED', 'Seed process data');

    -- Obtiene los IDs necesarios para registrar el log
    SELECT id INTO v_log_type_id FROM log_types WHERE code = 'SYSTEM' LIMIT 1;
    SELECT id INTO v_event_type_id FROM event_types WHERE code = 'SEED_DATA' LIMIT 1;

    -- Determina la severidad según el estado recibido
    IF UPPER(p_status) = 'ERROR' THEN
        SELECT id INTO v_severity_id FROM severities WHERE code = 'ERROR' LIMIT 1;
    ELSE
        SELECT id INTO v_severity_id FROM severities WHERE code = 'INFO' LIMIT 1;
    END IF;

    -- Obtiene el origen y objeto de datos
    SELECT id INTO v_source_id FROM sources WHERE code = 'BATCH' LIMIT 1;
    SELECT id INTO v_data_object_id FROM data_objects WHERE code = 'SEED' LIMIT 1;

    -- Inserta el registro en la tabla de logs
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
        LEFT(CONCAT(p_process_name, ' | ', p_action, ' | ', p_target_table), 100),
        p_rows_affected,
        LEFT(COALESCE(p_message, p_status), 100),
        CURRENT_TIMESTAMP
    );
END $$
DELIMITER ;


-- ============================================================
-- 2. SP transaccional: países base dinámicos
--    Inserta los países requeridos para el sistema
-- ============================================================

DELIMITER $$
-- Elimina el SP si existe 
DROP PROCEDURE IF EXISTS sp_seed_dynamicbrands_countries $$
CREATE PROCEDURE sp_seed_dynamicbrands_countries()
BEGIN
    DECLARE v_rows INT DEFAULT 0;

    -- Handler para errores: realiza rollback y registra el fallo
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        -- Escribe en el log que ocurrió un error en la inserción
        CALL sp_seed_log_step('sp_seed_dynamicbrands_countries','countries','ERROR',NULL,'ERROR','Error insertando paises');
        RESIGNAL;
    END;

    -- Inicia la transacción
    START TRANSACTION;

    -- Escribe en el log que se inició el proceso
    CALL sp_seed_log_step('sp_seed_dynamicbrands_countries', 'countries', 'START', NULL, 'OK', 'Inicio');

    -- Inserta los países base en caso de no existir
    INSERT IGNORE INTO countries(name)
    VALUES ('Costa Rica'), ('Colombia'), ('Peru'), ('Mexico'), ('Panama');

    -- Guarda la cantidad de filas afectadas
    SET v_rows = ROW_COUNT();

    -- Escribe en el log el resultado de la inserción
    CALL sp_seed_log_step('sp_seed_dynamicbrands_countries','countries','INSERT',v_rows,'OK','5 paises requeridos verificados');

    -- Confirma la transacción
    COMMIT;
END $$
DELIMITER ;


-- ============================================================
-- 3. SP transaccional: catálogos mínimos DynamicBrands
--    Inserta los catálogos base necesarios para el funcionamiento del sistema
-- ============================================================

DELIMITER $$
-- Elimina el SP si existe 
DROP PROCEDURE IF EXISTS sp_seed_dynamicbrands_required_catalogs $$
CREATE PROCEDURE sp_seed_dynamicbrands_required_catalogs()
BEGIN
    DECLARE v_user_id BIGINT;
    DECLARE v_usd_id BIGINT;

    -- Handler para errores: rollback y registro en logs
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        -- Escribe en el log que se inició el proceso
        CALL sp_seed_log_step('sp_seed_dynamicbrands_required_catalogs','catalogs','ERROR',NULL,'ERROR','Error insertando catalogos');
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Escribe en el log que se inició el proceso
    CALL sp_seed_log_step('sp_seed_dynamicbrands_required_catalogs', 'catalogs', 'START', NULL, 'OK', 'Inicio');

    -- Inserta el usuario admin en caso de no existir
    INSERT IGNORE INTO users(name, email, contrasenna, checksum, created_at, country_id)
    SELECT 'Admin DynamicBrands', 'admin.dynamic@example.com', X'00', X'00', CURRENT_DATE, c.id
    FROM countries c
    WHERE c.name = 'Costa Rica'
    LIMIT 1;

    -- Obtiene el id del usuario admin
    SELECT id INTO v_user_id FROM users WHERE email = 'admin.dynamic@example.com' LIMIT 1;


    -- Inserta estados por cada país
    INSERT INTO states(country_id, name)
    SELECT c.id, CONCAT(c.name, ' State')
    FROM countries c
    WHERE NOT EXISTS (
        SELECT 1 FROM states s
        WHERE s.country_id = c.id AND s.name = CONCAT(c.name, ' State')
    );

    -- Inserta ciudades por cada estado
    INSERT INTO cities(state_id, name)
    SELECT s.id, CONCAT(s.name, ' City')
    FROM states s
    WHERE NOT EXISTS (
        SELECT 1 FROM cities ci
        WHERE ci.state_id = s.id AND ci.name = CONCAT(s.name, ' City')
    );

    -- Inserta direcciones por cada ciudad
    INSERT INTO addresses(city_id, zip_code, latitude, longitude, created_by, created_at)
    SELECT ci.id, '00000', 9.9000000, -84.1000000, v_user_id, CURRENT_DATE
    FROM cities ci
    WHERE NOT EXISTS (SELECT 1 FROM addresses a WHERE a.city_id = ci.id);


    -- Inserta monedas base por país
    INSERT IGNORE INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'USD', '$', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id FROM countries c WHERE c.name = 'Costa Rica';

    INSERT IGNORE INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'COP', '$', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id FROM countries c WHERE c.name = 'Colombia';

    INSERT IGNORE INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'PEN', 'S/', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id FROM countries c WHERE c.name = 'Peru';

    INSERT IGNORE INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'MXN', '$', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id FROM countries c WHERE c.name = 'Mexico';

    INSERT IGNORE INTO currencies(name, symbol, enabled, post_time, user_id, country_id)
    SELECT 'PAB', 'B/.', TRUE, CURRENT_TIMESTAMP, v_user_id, c.id FROM countries c WHERE c.name = 'Panama';

    -- Obtiene el id del USD
    SELECT id INTO v_usd_id FROM currencies WHERE name = 'USD' LIMIT 1;

    -- Inserta tasas de cambio hacia USD
    INSERT INTO exchange_rates(from_currency_id, to_currency_id, rate, date, created_at, post_time, user_id, checksum, is_current)
    SELECT c.id,
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
           X'00',
           TRUE
    FROM currencies c
    WHERE c.id <> v_usd_id
      AND NOT EXISTS (
        SELECT 1 FROM exchange_rates er
        WHERE er.from_currency_id = c.id
          AND er.to_currency_id = v_usd_id
          AND er.is_current = TRUE
    );

    -- Categorías de productos
    INSERT IGNORE INTO categories(name) VALUES ('Aceites'), ('Belleza'), ('Tecnologia'), ('Hogar'), ('Salud');

    -- Tipos de cantidad

    INSERT IGNORE INTO quantity_type(code) VALUES ('unit'), ('bottle'), ('box'), ('pair'), ('pack');

    -- Unidades de medida
    INSERT IGNORE INTO unit_measurement(code) VALUES ('unit'), ('ml'), ('g'), ('kg'), ('cm');

    -- Inserta marcas basadas en países
    INSERT INTO brands(name, country_id)
    SELECT CONCAT('AI Brand ', c.name), c.id
    FROM countries c
    WHERE NOT EXISTS (
        SELECT 1 FROM brands b
        WHERE b.name = CONCAT('AI Brand ', c.name)
          AND b.country_id = c.id
    );

    -- Inserta tipo de hub
    INSERT IGNORE INTO hub_types(code, description) VALUES ('MAIN', 'Main hub');

    -- Crea el hub principal
    INSERT INTO hubs(name, capacity, type_id, created_by, created_at)
    SELECT 'Hub Principal DynamicBrands', 100000, ht.id, v_user_id, CURRENT_DATE
    FROM hub_types ht
    WHERE ht.code = 'MAIN'
      AND NOT EXISTS (SELECT 1 FROM hubs h WHERE h.name = 'Hub Principal DynamicBrands')
    LIMIT 1;

    -- Modelos de AI disponibles
    INSERT IGNORE INTO ai_models(name, version) VALUES ('GPT', '5.5'), ('BrandGen', '1.0'), ('MarketAI', '2.0');

    -- Idiomas soportados

    INSERT IGNORE INTO languages(description) VALUES ('Spanish'), ('English'), ('Portuguese');

    -- Estados del sistema (órdenes/logística)
    INSERT IGNORE INTO status(code) VALUES ('CREATED'), ('PAID'), ('SHIPPED'), ('DELIVERED');


    -- Registra finalización exitosa
    CALL sp_seed_log_step('sp_seed_dynamicbrands_required_catalogs','catalogs','INSERT',NULL,'OK','Catalogos minimos verificados');

    -- Confirma la transacción
    COMMIT;
END $$
DELIMITER ;


-- ============================================================
-- 4. SP transaccional: carga de 100 productos DynamicBrands
--    Genera productos de prueba distribuidos entre 5 países,
--    junto con sus relaciones (categorías y precios).
-- ============================================================

DELIMITER $$
-- Elimina el SP si existe 
DROP PROCEDURE IF EXISTS sp_seed_dynamicbrands_products_100 $$
CREATE PROCEDURE sp_seed_dynamicbrands_products_100()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE v_offset INT DEFAULT 0;
    DECLARE v_country_id BIGINT;
    DECLARE v_brand_id BIGINT;
    DECLARE v_currency_id BIGINT;
    DECLARE v_exchange_rate_id BIGINT DEFAULT NULL;
    DECLARE v_user_id BIGINT;
    DECLARE v_unit_id BIGINT;
    DECLARE v_quantity_type_id BIGINT;
    DECLARE v_hub_id BIGINT;
    DECLARE v_product_id BIGINT;
    DECLARE v_category_id BIGINT;
    DECLARE v_inserted INT DEFAULT 0;

    -- Handler para errores: rollback y registro en logs
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        -- Escribe en el log que se inició el proceso
        CALL sp_seed_log_step('sp_seed_dynamicbrands_products_100','products','ERROR',NULL,'ERROR','Error insertando productos');
        RESIGNAL;
    END;

    -- Inicia la transacción
    START TRANSACTION;

    -- Escribe en el log que se inició el proceso
    CALL sp_seed_log_step('sp_seed_dynamicbrands_products_100', 'products', 'START', NULL, 'OK', 'Inicio');

    -- Obtiene datos base necesarios
    SELECT id INTO v_user_id FROM users WHERE email = 'admin.dynamic@example.com' LIMIT 1;
    SELECT id INTO v_unit_id FROM unit_measurement WHERE code = 'unit' LIMIT 1;
    SELECT id INTO v_quantity_type_id FROM quantity_type WHERE code = 'unit' LIMIT 1;
    SELECT id INTO v_hub_id FROM hubs WHERE name = 'Hub Principal DynamicBrands' LIMIT 1;

    -- Itera para crear hasta 100 productos
    WHILE i <= 100 DO

        -- Verifica si el producto ya existe, si existe lo omite
        IF NOT EXISTS (SELECT 1 FROM products WHERE name = CONCAT('Producto DynamicBrands ', i)) THEN

            -- Calcula el offset para distribución cíclica entre 5 países
            SET v_offset = MOD(i - 1, 5);

            -- Reinicia la tasa de cambio
            SET v_exchange_rate_id = NULL;

            -- Selecciona un país de forma cíclica
            SELECT id INTO v_country_id
            FROM countries
            ORDER BY id
            LIMIT v_offset, 1;

            -- Obtiene la marca asociada al país
            SELECT id INTO v_brand_id
            FROM brands
            WHERE country_id = v_country_id
            LIMIT 1;

            -- Obtiene la moneda del país
            SELECT id INTO v_currency_id
            FROM currencies
            WHERE country_id = v_country_id
            LIMIT 1;

            -- Obtiene la tasa de cambio hacia USD
            SELECT (
                SELECT er.id
                FROM exchange_rates er
                WHERE er.from_currency_id = v_currency_id
                  AND er.to_currency_id = (SELECT id FROM currencies WHERE name = 'USD' LIMIT 1)
                  AND er.is_current = TRUE
                LIMIT 1
            ) INTO v_exchange_rate_id;

            -- Selecciona una categoría de forma cíclica
            SELECT id INTO v_category_id
            FROM categories
            ORDER BY id
            LIMIT v_offset, 1;

            -- Inserta el producto 
            INSERT INTO products(
                name,
                description,
                brand_id,
                hub_id,
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
                CONCAT('Producto DynamicBrands ', i),
                CONCAT('Producto ecommerce generado para prueba ', i),
                v_brand_id,
                v_hub_id,
                ROUND(20 + (RAND() * 180), 2),
                v_currency_id,
                v_exchange_rate_id,
                X'00',
                v_user_id,
                CURRENT_DATE,
                v_unit_id,
                v_quantity_type_id,
                TRUE
            );

            -- Obtiene el id del producto insertado
            SET v_product_id = LAST_INSERT_ID();

            -- Relaciona el producto con su categoría
            INSERT IGNORE INTO category_per_product(category_id, product_id)
            VALUES (v_category_id, v_product_id);

            -- Registra el precio del producto
            INSERT INTO product_prices(product_id, price, currency_id, valid_from, valid_to, created_at, updated_by)
            VALUES (v_product_id, ROUND(20 + (RAND() * 180), 2), v_currency_id, CURRENT_DATE, NULL, CURRENT_DATE, v_user_id);

            -- Incrementa el contador de productos insertados
            SET v_inserted = v_inserted + 1;
        END IF;

        -- Incrementa el contador del loop
        SET i = i + 1;
    END WHILE;

    -- Escribe en el log que el proceso finalizó correctamente
    CALL sp_seed_log_step('sp_seed_dynamicbrands_products_100','products','INSERT',v_inserted,'OK','Productos distribuidos entre 5 paises');

    -- Confirma la transacción
    COMMIT;
END $$
DELIMITER ;


-- ============================================================
-- 5. SP transaccional: creación de 9 sitios dinámicos
--    Genera sitios web dinámicos asociados a países, monedas,
--    marcas y configuración basada en IA.
-- ============================================================

DELIMITER $$
-- Elimina el SP si existe para asegurar su recreación
DROP PROCEDURE IF EXISTS sp_seed_dynamicbrands_sites_9 $$
CREATE PROCEDURE sp_seed_dynamicbrands_sites_9()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE v_offset INT DEFAULT 0;
    DECLARE v_model_id BIGINT;
    DECLARE v_country_id BIGINT;
    DECLARE v_currency_id BIGINT;
    DECLARE v_language_id BIGINT;
    DECLARE v_site_id BIGINT;
    DECLARE v_brand_id BIGINT;
    DECLARE v_inserted INT DEFAULT 0;

    -- Handler para errores: rollback y registro en logs
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        -- Escribe en el log que ocurrió un error en la inserción
        CALL sp_seed_log_step('sp_seed_dynamicbrands_sites_9','sites','ERROR',NULL,'ERROR','Error insertando sitios');
        RESIGNAL;
    END;

    -- Inicia la transacción
    START TRANSACTION;

    -- Escribe en el log que se inició el proceso
    CALL sp_seed_log_step('sp_seed_dynamicbrands_sites_9', 'sites', 'START', NULL, 'OK', 'Inicio');

    -- Obtiene modelo de AI base
    SELECT id INTO v_model_id FROM ai_models ORDER BY id LIMIT 1;

    -- Obtiene idioma base (Spanish)
    SELECT id INTO v_language_id FROM languages WHERE description = 'Spanish' LIMIT 1;

    -- Itera para crear hasta 9 sitios
    WHILE i <= 9 DO

        -- Verifica si el sitio ya existe, si existe lo omite
        IF NOT EXISTS (SELECT 1 FROM sites WHERE name = CONCAT('Dynamic Site ', i)) THEN

            -- Calcula el offset para distribución entre países
            SET v_offset = MOD(i - 1, 5);

            -- Selecciona un país de forma cíclica
            SELECT id INTO v_country_id
            FROM countries
            ORDER BY id
            LIMIT v_offset, 1;

            -- Obtiene la moneda base del país
            SELECT id INTO v_currency_id
            FROM currencies
            WHERE country_id = v_country_id
            LIMIT 1;

            -- Inserta el sitio web dinámico
            INSERT INTO sites(
                model_id,
                name,
                url_physical_direction,
                ip_physical,
                country_id,
                base_currency_id,
                url_logo,
                site_config,
                created_at,
                active
            )
            VALUES (
                v_model_id,
                CONCAT('Dynamic Site ', i),

                -- URL del sitio
                CONCAT('https://dynamic-site-', i, '.example.com'),

                -- IP simulada
                CONCAT('10.0.0.', i),

                v_country_id,
                v_currency_id,

                -- Logo del sitio
                CONCAT('https://dynamic-site-', i, '.example.com/logo.png'),

                -- Configuración dinámica en formato JSON
                JSON_OBJECT('theme', 'auto', 'aiGenerated', true, 'siteNumber', i),
                CURRENT_DATE,
                TRUE
            );
            -- Obtiene el id del sitio insertado
            SET v_site_id = LAST_INSERT_ID();


            -- Asocia el idioma al sitio
            INSERT IGNORE INTO languages_per_site(site_id, language_id)
            VALUES (v_site_id, v_language_id);

            -- Obtiene la marca asociada al país
            SELECT id INTO v_brand_id
            FROM brands
            WHERE country_id = v_country_id
            LIMIT 1;

            -- Asocia la marca al sitio
            INSERT IGNORE INTO brands_per_site(site_id, brand_id, enabled, created_at)
            VALUES (v_site_id, v_brand_id, TRUE, CURRENT_DATE);

            -- Incrementa el contador de sitios insertados
            SET v_inserted = v_inserted + 1;
        END IF;

        -- Incrementa el contador del loop
        SET i = i + 1;
    END WHILE;

    -- Escribe en el log que el proceso finalizó correctamente
    CALL sp_seed_log_step('sp_seed_dynamicbrands_sites_9','sites','INSERT',v_inserted,'OK','9 sitios web dinamicos verificados');

    -- Confirma la transacción
    COMMIT;
END $$
DELIMITER ;




-- ============================================================
-- SP transaccional: cargar publicaciones de productos
-- Necesario para que vw_dynamic_sales tenga datos.
-- ============================================================

DELIMITER $$
-- Elimina el SP si existe para asegurar su recreación
DROP PROCEDURE IF EXISTS sp_seed_dynamicbrands_product_publications $$
CREATE PROCEDURE sp_seed_dynamicbrands_product_publications()
BEGIN
    DECLARE v_inserted INT DEFAULT 0;


    -- Handler para errores: rollback y registro en logs
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        -- Escribe en el log que ocurrió un error en la inserción
        CALL sp_seed_log_step(
            'sp_seed_dynamicbrands_product_publications',
            'product_publications',
            'ERROR',
            NULL,
            'ERROR',
            'Error insertando publicaciones'
        );
        RESIGNAL;
    END;

    -- Inicia la transacción
    START TRANSACTION;

    -- Escribe en el log que se inició el proceso
    CALL sp_seed_log_step(
        'sp_seed_dynamicbrands_product_publications',
        'product_publications',
        'START',
        NULL,
        'OK',
        'Inicio'
    );

    -- Inserta publicaciones de productos por sitio
    INSERT INTO product_publications (
        product_id,
        site_id,
        name,
        description,
        price,
        currency_id,
        exchange_rate_id,
        url_image,
        active,
        created_at,
        updated_at
    )
    SELECT
        p.id,
        s.id,

        -- Nombre de la publicación (producto + sitio)
        CONCAT(p.name, ' - ', s.name),

        -- Descripción generada
        CONCAT('Publicacion generada para ', p.name),

        -- Precio con margen dinámico (25% + variación aleatoria)
        ROUND(p.current_price * (1.25 + RAND()), 2),
        s.base_currency_id,

        -- No se usa tasa de cambio en este punto
        NULL,

        -- URL simulada de imagen
        CONCAT('https://example.com/images/product-', p.id, '.png'),
        TRUE,
        CURRENT_DATE,
        NULL
    FROM products p

    -- Relación producto-sitio
    JOIN sites s
        ON MOD(p.id, 9) = MOD(s.id, 9)

    -- Evita duplicados de publicaciones
    WHERE NOT EXISTS (
        SELECT 1
        FROM product_publications pp
        WHERE pp.product_id = p.id
          AND pp.site_id = s.id
    );

    -- Guarda la cantidad de filas insertadas
    SET v_inserted = ROW_COUNT();

    -- Relaciona publicaciones con productos (tabla puente)
    INSERT IGNORE INTO publications_per_product(publication_id, product_id)
    SELECT
        pp.id,
        pp.product_id
    FROM product_publications pp;

    -- Escribe en el log que el proceso finalizó correctamente
    CALL sp_seed_log_step(
        'sp_seed_dynamicbrands_product_publications',
        'product_publications',
        'INSERT',
        v_inserted,
        'OK',
        'Publicaciones creadas para alimentar la vista del dashboard'
    );

    -- Confirma la transacción
    COMMIT;
END $$
DELIMITER ;


-- ============================================================
-- 7. SP orquestador general DynamicBrands
--    (sp_seed_dynamicbrands_all)
--    Ejecuta en orden todos los SP necesarios para realizar
--    la carga completa de datos del sistema, incluyendo
--    países, catálogos, productos, sitios y publicaciones.
-- ============================================================

DELIMITER $$
-- Elimina el SP si existe para asegurar su recreación
DROP PROCEDURE IF EXISTS sp_seed_dynamicbrands_all $$
CREATE PROCEDURE sp_seed_dynamicbrands_all()
BEGIN
    -- Escribe en el log que se inició el proceso general
    CALL sp_seed_log_step('sp_seed_dynamicbrands_all', 'all', 'START', NULL, 'OK', 'Inicio');

    -- Ejecuta la carga de países base
    CALL sp_seed_dynamicbrands_countries();

    -- Ejecuta la carga de catálogos mínimos
    CALL sp_seed_dynamicbrands_required_catalogs();

    -- Ejecuta la carga de productos
    CALL sp_seed_dynamicbrands_products_100();

    -- Ejecuta la creación de sitios dinámicos
    CALL sp_seed_dynamicbrands_sites_9();

    -- Ejecuta la generación de publicaciones de productos
    CALL sp_seed_dynamicbrands_product_publications();

    -- Escribe en el log que la carga completa finalizó correctamente
    CALL sp_seed_log_step('sp_seed_dynamicbrands_all','all','END',NULL,'OK','Carga completa DynamicBrands');
END $$

DELIMITER ;


-- ============================================================
-- SOURCE: 12_dynamicbrands_reporting_views_mysql.sql
-- ============================================================

-- ============================================================
-- 12_dynamicbrands_reporting_views_mysql.sql
-- Base: DynamicBrandsCasoDos
-- Motor: MySQL
--
-- Objetivo:
--   Crear vistas de DynamicBrands para exponer ventas, sitios,
--   marcas generadas por IA y publicaciones.
-- ============================================================

USE DynamicBrandsCasoDos;

-- ============================================================
-- 1. Vista base de ventas/publicaciones
-- ============================================================

-- Elimina la vista si existe para asegurar su recreación
DROP VIEW IF EXISTS vw_dynamic_sales;

-- Crea la vista de ventas dinámicas
CREATE VIEW vw_dynamic_sales AS
SELECT
    p.id AS dynamic_product_id,
    p.name AS product_name,
    c.name AS category_name,
    b.name AS brand_name,
    s.name AS site_name,
    co.name AS country_name,
    cu.name AS sale_currency,

    -- Tasa de conversión hacia USD (si no existe se asume 1)
    COALESCE(er.rate, 1) AS sale_to_usd_rate,

    -- Precio de venta en moneda original
    pp.price AS sale_price,

    -- Precio de venta convertido a USD
    ROUND(pp.price * COALESCE(er.rate, 1), 2) AS sale_price_usd,

    -- Cantidad vendida simulada (1 por registro)
    1 AS quantity_sold,

    -- Costo operativo del sitio (5% del precio en USD)
    ROUND(pp.price * COALESCE(er.rate, 1) * 0.05, 2) AS site_operating_cost_usd,

    -- Fecha de creación de la venta/publicación
    pp.created_at
FROM product_publications pp

-- Relación con producto y marca
JOIN products p ON p.id = pp.product_id
JOIN brands b ON b.id = p.brand_id

-- Relación con sitio y país
JOIN sites s ON s.id = pp.site_id
JOIN countries co ON co.id = s.country_id

-- Relación con moneda y tipo de cambio
JOIN currencies cu ON cu.id = pp.currency_id
LEFT JOIN exchange_rates er ON er.id = pp.exchange_rate_id

-- Relación con categorías (puede haber múltiples)
LEFT JOIN category_per_product cpp ON cpp.product_id = p.id
LEFT JOIN categories c ON c.id = cpp.category_id;


-- ============================================================
-- 2. Vista de efectividad por sitio
-- ============================================================

-- Elimina la vista si existe para asegurar su recreación
DROP VIEW IF EXISTS vw_site_effectiveness;

-- Crea la vista de efectividad de sitios
CREATE VIEW vw_site_effectiveness AS
SELECT
    site_name,
    country_name,

    -- Cantidad de productos únicos publicados en el sitio
    COUNT(DISTINCT dynamic_product_id) AS total_products_published,

    -- Total de publicaciones realizadas en el sitio
    COUNT(*) AS total_publications,

    -- Ventas estimadas en USD (suma de precios simulados)
    ROUND(SUM(sale_price_usd), 2) AS estimated_sales_usd,

    -- Precio promedio de venta en USD
    ROUND(AVG(sale_price_usd), 2) AS avg_sale_price_usd
FROM vw_dynamic_sales

-- Agrupación por sitio y país
GROUP BY site_name, country_name;


-- ============================================================
-- 3. Vista de efectividad por marca IA
-- ============================================================

-- Elimina la vista si existe para asegurar su recreación
DROP VIEW IF EXISTS vw_ai_brand_effectiveness;


-- Crea la vista de efectividad de marcas
CREATE VIEW vw_ai_brand_effectiveness AS
SELECT
    brand_name,
    country_name,

    -- Cantidad de sitios donde la marca está presente
    COUNT(DISTINCT site_name) AS total_sites,

    -- Cantidad de productos únicos por marca
    COUNT(DISTINCT dynamic_product_id) AS total_products,

    -- Total de publicaciones de la marca
    COUNT(*) AS total_publications,

    -- Ventas estimadas en USD
    ROUND(SUM(sale_price_usd), 2) AS estimated_sales_usd,

    -- Precio promedio de venta en USD
    ROUND(AVG(sale_price_usd), 2) AS avg_sale_price_usd
FROM vw_dynamic_sales

-- Agrupación por marca y país
GROUP BY brand_name, country_name;


-- ============================================================
-- 4. Vista de ventas por categoría
-- ============================================================

-- Elimina la vista si existe para asegurar su recreación
DROP VIEW IF EXISTS vw_sales_by_category;

-- Crea la vista de ventas por categoría
CREATE VIEW vw_sales_by_category AS
SELECT
    category_name,
    sale_currency,

    -- Cantidad de productos únicos por categoría
    COUNT(DISTINCT dynamic_product_id) AS total_products,

    -- Total de publicaciones por categoría
    COUNT(*) AS total_publications,

    -- Ventas totales en moneda original
    ROUND(SUM(sale_price), 2) AS total_sales_original_currency,

    -- Ventas totales convertidas a USD
    ROUND(SUM(sale_price_usd), 2) AS total_sales_usd
FROM vw_dynamic_sales

-- Agrupación por categoría y moneda
GROUP BY category_name, sale_currency;


-- ============================================================
-- 5. Funnel comercial de DynamicBrands
-- ============================================================

-- Elimina la vista si existe para asegurar su recreación
DROP VIEW IF EXISTS vw_funnel_commercial_process;

-- Crea la vista del funnel comercial
CREATE VIEW vw_funnel_commercial_process AS

-- 1. Total de productos registrados en el sistema
SELECT '1. Productos registrados' AS stage, COUNT(*) AS value
FROM products

UNION ALL

-- 2. Total de sitios dinámicos activos
SELECT '2. Sitios dinámicos activos' AS stage, COUNT(*) AS value
FROM sites
WHERE active = TRUE

UNION ALL

-- 3. Total de publicaciones creadas
SELECT '3. Publicaciones creadas' AS stage, COUNT(*) AS value
FROM product_publications

UNION ALL

-- 4. Total de productos que han sido publicados (únicos)
SELECT '4. Productos publicados' AS stage, COUNT(DISTINCT product_id) AS value
FROM product_publications

UNION ALL

-- 5. Total de marcas IA con presencia en publicaciones
SELECT '5. Marcas IA publicadas' AS stage, COUNT(DISTINCT brand_name) AS value
FROM vw_dynamic_sales;


-- ============================================================
-- Validaciones
-- ============================================================

SELECT COUNT(*) AS rows_vw_dynamic_sales
FROM vw_dynamic_sales;

SELECT *
FROM vw_dynamic_sales
LIMIT 20;

SELECT *
FROM vw_funnel_commercial_process;


-- ============================================================
-- EJECUCIÓN Y VALIDACIÓN FINAL
-- ============================================================

CALL sp_seed_dynamicbrands_all();

SELECT COUNT(*) AS total_countries
FROM countries;

SELECT COUNT(*) AS total_products
FROM products;

SELECT COUNT(*) AS total_sites
FROM sites;

SELECT COUNT(*) AS total_product_publications
FROM product_publications;

SELECT COUNT(*) AS rows_vw_dynamic_sales
FROM vw_dynamic_sales;

SELECT *
FROM vw_dynamic_sales
LIMIT 20;

SELECT *
FROM vw_funnel_commercial_process;

SELECT *
FROM logs
ORDER BY id DESC
LIMIT 20;