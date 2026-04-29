-- =========================================================
-- DynamicBrands - Schema MySQL
-- Archivo: 02_dynamicbrands_schema_mysql.sql
-- Basado en el Markdown de DynamicBrands enviado por el usuario.
-- Correcciones aplicadas:
--   * BYTEA -> VARBINARY(255)
--   * JSONB -> JSON
--   * NUMERICAL -> DECIMAL(14,2)
--   * usuarios.id -> users.id
--   * country.id -> countries.id
--   * productsPublications.id -> product_publications.id
--   * publications.id -> product_publications.id
--   * transport.id / transaction.id inexistentes corregidos a transport_units.id / transactions.id
--   * Nombres normalizados a snake_case para evitar problemas por mayusculas/minusculas.
-- =========================================================

DROP DATABASE IF EXISTS DynamicBrandsCasoDos;
CREATE DATABASE DynamicBrandsCasoDos CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE DynamicBrandsCasoDos;

SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- ADDRESS PATTERN
-- =========================================================

CREATE TABLE countries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE states (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    country_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    CONSTRAINT fk_states_country
        FOREIGN KEY (country_id) REFERENCES countries(id)
) ENGINE=InnoDB;

CREATE TABLE cities (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    state_id BIGINT NOT NULL,
    name VARCHAR(90) NOT NULL,
    CONSTRAINT fk_cities_state
        FOREIGN KEY (state_id) REFERENCES states(id)
) ENGINE=InnoDB;

-- Se crea users despues de addresses en el MD, pero addresses necesita users.
-- Por eso created_by se agrega luego con ALTER TABLE.
CREATE TABLE addresses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    city_id BIGINT NOT NULL,
    zip_code VARCHAR(10),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    created_by BIGINT NULL,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_addresses_city
        FOREIGN KEY (city_id) REFERENCES cities(id)
) ENGINE=InnoDB;

-- =========================================================
-- USERS / AUDIT
-- =========================================================

CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE,
    contrasenna VARBINARY(255) NOT NULL,
    checksum VARBINARY(255),
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    country_id BIGINT NULL,
    CONSTRAINT fk_users_country
        FOREIGN KEY (country_id) REFERENCES countries(id)
) ENGINE=InnoDB;

ALTER TABLE addresses
    ADD CONSTRAINT fk_addresses_created_by
    FOREIGN KEY (created_by) REFERENCES users(id);

CREATE TABLE user_addresses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    address_id BIGINT NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    checksum VARBINARY(255),
    post_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_addresses_user
        FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_user_addresses_address
        FOREIGN KEY (address_id) REFERENCES addresses(id)
) ENGINE=InnoDB;

-- =========================================================
-- LOG
-- =========================================================

CREATE TABLE log_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE event_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE severities (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    level VARCHAR(10) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE sources (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE data_objects (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    log_type_id BIGINT NOT NULL,
    event_type_id BIGINT NOT NULL,
    severity_id BIGINT NOT NULL,
    source_id BIGINT NOT NULL,
    data_object_id BIGINT NOT NULL,
    description VARCHAR(100) NOT NULL,
    object_id1 BIGINT NULL,
    object_id2 BIGINT NULL,
    reference_id1 BIGINT NULL,
    reference_id2 BIGINT NULL,
    reference_description VARCHAR(100),
    user_id BIGINT NULL,
    computer VARBINARY(255),
    checksum VARBINARY(255),
    post_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_logs_log_type
        FOREIGN KEY (log_type_id) REFERENCES log_types(id),
    CONSTRAINT fk_logs_event_type
        FOREIGN KEY (event_type_id) REFERENCES event_types(id),
    CONSTRAINT fk_logs_severity
        FOREIGN KEY (severity_id) REFERENCES severities(id),
    CONSTRAINT fk_logs_source
        FOREIGN KEY (source_id) REFERENCES sources(id),
    CONSTRAINT fk_logs_data_object
        FOREIGN KEY (data_object_id) REFERENCES data_objects(id),
    CONSTRAINT fk_logs_user
        FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- =========================================================
-- CURRENCIES PATTERN
-- =========================================================

CREATE TABLE currencies (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE,
    symbol VARCHAR(5) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    post_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT NULL,
    country_id BIGINT NULL,
    CONSTRAINT fk_currencies_user
        FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_currencies_country
        FOREIGN KEY (country_id) REFERENCES countries(id)
) ENGINE=InnoDB;

CREATE TABLE exchange_rates (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    from_currency_id BIGINT NOT NULL,
    to_currency_id BIGINT NOT NULL,
    rate DECIMAL(18,6) NOT NULL,
    date DATE NOT NULL DEFAULT (CURRENT_DATE),
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    post_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT NULL,
    checksum VARBINARY(255),
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_exchange_rates_from_currency
        FOREIGN KEY (from_currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_exchange_rates_to_currency
        FOREIGN KEY (to_currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_exchange_rates_user
        FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT chk_exchange_rates_rate CHECK (rate > 0)
) ENGINE=InnoDB;

CREATE TABLE exchange_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    from_currency_id BIGINT NOT NULL,
    to_currency_id BIGINT NOT NULL,
    rate_to_usd DECIMAL(18,6) NOT NULL,
    start_date_time DATE NOT NULL,
    end_date_time DATE NULL,
    post_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    checksum VARBINARY(255),
    user_id BIGINT NULL,
    exchange_rate_id BIGINT NOT NULL,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_exchange_history_from_currency
        FOREIGN KEY (from_currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_exchange_history_to_currency
        FOREIGN KEY (to_currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_exchange_history_user
        FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_exchange_history_exchange_rate
        FOREIGN KEY (exchange_rate_id) REFERENCES exchange_rates(id),
    CONSTRAINT chk_exchange_history_rate CHECK (rate_to_usd > 0)
) ENGINE=InnoDB;

-- =========================================================
-- TAXES
-- =========================================================

CREATE TABLE tax_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE country_taxes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    country_id BIGINT NOT NULL,
    percentage DECIMAL(10,4) NULL,
    flat_fee DECIMAL(14,2) NULL,
    valid_from DATE NOT NULL,
    valid_to DATE NULL,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    created_by BIGINT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at DATE NULL,
    updated_by BIGINT NULL,
    CONSTRAINT fk_country_taxes_country
        FOREIGN KEY (country_id) REFERENCES countries(id),
    CONSTRAINT fk_country_taxes_created_by
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_country_taxes_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT chk_country_taxes_values CHECK (percentage IS NOT NULL OR flat_fee IS NOT NULL)
) ENGINE=InnoDB;

CREATE TABLE taxes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tax_type_id BIGINT NOT NULL,
    country_tax_id BIGINT NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE NULL,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    created_by BIGINT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at DATE NULL,
    updated_by BIGINT NULL,
    CONSTRAINT fk_taxes_tax_type
        FOREIGN KEY (tax_type_id) REFERENCES tax_types(id),
    CONSTRAINT fk_taxes_country_tax
        FOREIGN KEY (country_tax_id) REFERENCES country_taxes(id),
    CONSTRAINT fk_taxes_created_by
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_taxes_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- =========================================================
-- PRODUCT BASE CATALOGS
-- =========================================================

CREATE TABLE categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE brands (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60) NOT NULL,
    country_id BIGINT NOT NULL,
    CONSTRAINT fk_brands_country
        FOREIGN KEY (country_id) REFERENCES countries(id)
) ENGINE=InnoDB;

CREATE TABLE quantity_type (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE unit_measurement (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE product_characteristics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- =========================================================
-- TRANSPORT
-- =========================================================

CREATE TABLE transport_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(60),
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    created_by BIGINT NULL,
    CONSTRAINT fk_transport_types_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE carriers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(254),
    phone VARCHAR(15),
    regional_code VARCHAR(3),
    address_id BIGINT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    created_by BIGINT NULL,
    checksum VARBINARY(255),
    CONSTRAINT fk_carriers_address
        FOREIGN KEY (address_id) REFERENCES addresses(id),
    CONSTRAINT fk_carriers_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE carrier_locations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    carrier_id BIGINT NOT NULL,
    address_id BIGINT NOT NULL,
    city_id BIGINT NULL,
    code VARCHAR(30) NULL,
    description VARCHAR(80) NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    created_by BIGINT NULL,
    CONSTRAINT fk_carrier_locations_carrier
        FOREIGN KEY (carrier_id) REFERENCES carriers(id),
    CONSTRAINT fk_carrier_locations_address
        FOREIGN KEY (address_id) REFERENCES addresses(id),
    CONSTRAINT fk_carrier_locations_city
        FOREIGN KEY (city_id) REFERENCES cities(id),
    CONSTRAINT fk_carrier_locations_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE transport_units (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    carrier_id BIGINT NOT NULL,
    transport_type_id BIGINT NOT NULL,
    identifier VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NULL,
    capacity DECIMAL(14,2) NULL,
    unit_measurement_id BIGINT NULL,
    current_address_id BIGINT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    created_by BIGINT NULL,
    checksum VARBINARY(255),
    CONSTRAINT fk_transport_units_carrier
        FOREIGN KEY (carrier_id) REFERENCES carriers(id),
    CONSTRAINT fk_transport_units_transport_type
        FOREIGN KEY (transport_type_id) REFERENCES transport_types(id),
    CONSTRAINT fk_transport_units_unit_measurement
        FOREIGN KEY (unit_measurement_id) REFERENCES unit_measurement(id),
    CONSTRAINT fk_transport_units_current_address
        FOREIGN KEY (current_address_id) REFERENCES addresses(id),
    CONSTRAINT fk_transport_units_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- =========================================================
-- HUB
-- =========================================================

CREATE TABLE hub_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(60)
) ENGINE=InnoDB;

CREATE TABLE hubs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    capacity BIGINT NOT NULL,
    type_id BIGINT NOT NULL,
    created_by BIGINT NULL,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_hubs_type
        FOREIGN KEY (type_id) REFERENCES hub_types(id),
    CONSTRAINT fk_hubs_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- =========================================================
-- AI GENERATED SITES
-- =========================================================

CREATE TABLE languages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    description VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE ai_models (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    version VARCHAR(10) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE sites (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    model_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    url_physical_direction VARCHAR(100),
    ip_physical VARCHAR(100),
    country_id BIGINT NOT NULL,
    base_currency_id BIGINT NOT NULL,
    url_logo VARCHAR(100),
    site_config JSON,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_sites_model
        FOREIGN KEY (model_id) REFERENCES ai_models(id),
    CONSTRAINT fk_sites_country
        FOREIGN KEY (country_id) REFERENCES countries(id),
    CONSTRAINT fk_sites_base_currency
        FOREIGN KEY (base_currency_id) REFERENCES currencies(id)
) ENGINE=InnoDB;

CREATE TABLE languages_per_site (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    site_id BIGINT NOT NULL,
    language_id BIGINT NOT NULL,
    CONSTRAINT fk_languages_per_site_site
        FOREIGN KEY (site_id) REFERENCES sites(id),
    CONSTRAINT fk_languages_per_site_language
        FOREIGN KEY (language_id) REFERENCES languages(id),
    CONSTRAINT uq_languages_per_site UNIQUE (site_id, language_id)
) ENGINE=InnoDB;

CREATE TABLE brands_per_site (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    site_id BIGINT NOT NULL,
    brand_id BIGINT NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_brands_per_site_site
        FOREIGN KEY (site_id) REFERENCES sites(id),
    CONSTRAINT fk_brands_per_site_brand
        FOREIGN KEY (brand_id) REFERENCES brands(id),
    CONSTRAINT uq_brands_per_site UNIQUE (site_id, brand_id)
) ENGINE=InnoDB;

-- =========================================================
-- PRODUCTS
-- =========================================================

-- el supplier no existe pues son ellos mismos por el white brand
CREATE TABLE products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60) NOT NULL,
    description VARCHAR(500),
    brand_id BIGINT NOT NULL,
    hub_id BIGINT NOT NULL,
    current_price DECIMAL(14,2) NOT NULL,
    currency_id BIGINT NOT NULL,
    exchange_rate_id BIGINT NULL,
    checksum VARBINARY(255),
    created_by BIGINT NULL,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    updated_by BIGINT NULL,
    updated_at DATE NULL,
    unit_measurement_id BIGINT NOT NULL,
    quantity_type_id BIGINT NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_products_brand
        FOREIGN KEY (brand_id) REFERENCES brands(id),
    CONSTRAINT fk_products_hub
        FOREIGN KEY (hub_id) REFERENCES hubs(id),
    CONSTRAINT fk_products_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_products_exchange_rate
        FOREIGN KEY (exchange_rate_id) REFERENCES exchange_rates(id),
    CONSTRAINT fk_products_created_by
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_products_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_products_unit_measurement
        FOREIGN KEY (unit_measurement_id) REFERENCES unit_measurement(id),
    CONSTRAINT fk_products_quantity_type
        FOREIGN KEY (quantity_type_id) REFERENCES quantity_type(id),
    CONSTRAINT chk_products_price CHECK (current_price >= 0)
) ENGINE=InnoDB;

CREATE TABLE category_per_product (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    CONSTRAINT fk_category_per_product_category
        FOREIGN KEY (category_id) REFERENCES categories(id),
    CONSTRAINT fk_category_per_product_product
        FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT uq_category_per_product UNIQUE (category_id, product_id)
) ENGINE=InnoDB;

CREATE TABLE product_characteristic_per_product (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    product_characteristic_id BIGINT NOT NULL,
    value VARCHAR(100) NOT NULL,
    CONSTRAINT fk_product_characteristic_per_product_product
        FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_product_characteristic_per_product_characteristic
        FOREIGN KEY (product_characteristic_id) REFERENCES product_characteristics(id)
) ENGINE=InnoDB;

CREATE TABLE product_publications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    site_id BIGINT NOT NULL,
    name VARCHAR(60) NOT NULL,
    description VARCHAR(500) NULL,
    price DECIMAL(14,2) NOT NULL,
    currency_id BIGINT NOT NULL,
    exchange_rate_id BIGINT NULL,
    url_image VARCHAR(255) NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    updated_at DATE NULL,
    CONSTRAINT fk_product_publications_product
        FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_product_publications_site
        FOREIGN KEY (site_id) REFERENCES sites(id),
    CONSTRAINT fk_product_publications_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_product_publications_exchange_rate
        FOREIGN KEY (exchange_rate_id) REFERENCES exchange_rates(id),
    CONSTRAINT chk_product_publications_price CHECK (price >= 0)
) ENGINE=InnoDB;

-- Esta tabla es redundante porque product_publications ya tiene product_id,
-- pero se conserva porque aparece en el Markdown.
CREATE TABLE publications_per_product (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    publication_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    CONSTRAINT fk_publications_per_product_publication
        FOREIGN KEY (publication_id) REFERENCES product_publications(id),
    CONSTRAINT fk_publications_per_product_product
        FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT uq_publications_per_product UNIQUE (publication_id, product_id)
) ENGINE=InnoDB;

CREATE TABLE product_images (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_publication_id BIGINT NOT NULL,
    url VARCHAR(255) NOT NULL,
    alt_text VARCHAR(100) NULL,
    is_main BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_product_images_publication
        FOREIGN KEY (product_publication_id) REFERENCES product_publications(id)
) ENGINE=InnoDB;

CREATE TABLE product_reviews (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_publication_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    rating DECIMAL(2,1) NOT NULL,
    comment VARCHAR(500) NULL,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_product_reviews_publication
        FOREIGN KEY (product_publication_id) REFERENCES product_publications(id),
    CONSTRAINT fk_product_reviews_user
        FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT chk_product_reviews_rating CHECK (rating >= 1 AND rating <= 5)
) ENGINE=InnoDB;

CREATE TABLE product_prices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    price DECIMAL(14,2) NOT NULL,
    currency_id BIGINT NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE NULL,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    updated_by BIGINT NULL,
    CONSTRAINT fk_product_prices_product
        FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_product_prices_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_product_prices_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT chk_product_prices_price CHECK (price >= 0)
) ENGINE=InnoDB;

-- =========================================================
-- STATUS
-- =========================================================

CREATE TABLE status (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- =========================================================
-- ORDERS
-- =========================================================

CREATE TABLE orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_number DECIMAL(18,0) NOT NULL UNIQUE,
    order_date DATE NOT NULL,
    status_id BIGINT NOT NULL,
    discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
    currency_id BIGINT NOT NULL,
    created_by BIGINT NULL,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    checksum VARBINARY(255),
    CONSTRAINT fk_orders_status
        FOREIGN KEY (status_id) REFERENCES status(id),
    CONSTRAINT fk_orders_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_orders_created_by
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT chk_orders_amounts CHECK (discount_amount >= 0 AND tax_amount >= 0 AND total_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE order_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity DECIMAL(14,2) NOT NULL,
    unit_price DECIMAL(14,2) NOT NULL,
    discount DECIMAL(14,2) NOT NULL DEFAULT 0,
    amount DECIMAL(14,2) NOT NULL,
    total_amount DECIMAL(14,2) NOT NULL,
    total_taxes DECIMAL(14,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT chk_order_items_values CHECK (quantity > 0 AND unit_price >= 0 AND discount >= 0 AND amount >= 0 AND total_amount >= 0 AND total_taxes >= 0)
) ENGINE=InnoDB;

CREATE TABLE order_item_taxes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_item_id BIGINT NOT NULL,
    taxes_id BIGINT NOT NULL,
    total_amount DECIMAL(14,2) NOT NULL,
    CONSTRAINT fk_order_item_taxes_order_item
        FOREIGN KEY (order_item_id) REFERENCES order_items(id),
    CONSTRAINT fk_order_item_taxes_tax
        FOREIGN KEY (taxes_id) REFERENCES taxes(id),
    CONSTRAINT chk_order_item_taxes_total CHECK (total_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE order_address_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(60)
) ENGINE=InnoDB;

CREATE TABLE order_addresses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    sender_address_id BIGINT NOT NULL,
    receiver_address_id BIGINT NOT NULL,
    type_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    post_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_order_addresses_order
        FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_order_addresses_sender
        FOREIGN KEY (sender_address_id) REFERENCES addresses(id),
    CONSTRAINT fk_order_addresses_receiver
        FOREIGN KEY (receiver_address_id) REFERENCES addresses(id),
    CONSTRAINT fk_order_addresses_type
        FOREIGN KEY (type_id) REFERENCES order_address_types(id),
    CONSTRAINT fk_order_addresses_user
        FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- =========================================================
-- FINANCIAL TRANSACTIONS
-- =========================================================

CREATE TABLE transaction_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(60),
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    created_by BIGINT NULL,
    CONSTRAINT fk_transaction_types_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE transactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    type_id BIGINT NOT NULL,
    date DATE NOT NULL,
    description VARCHAR(80),
    amount DECIMAL(14,2) NOT NULL,
    currency_id BIGINT NOT NULL,
    exchange_rate_id BIGINT NULL,
    related_order_id BIGINT NULL,
    reference_type VARCHAR(30) NULL,
    reference_id BIGINT NULL,
    external_reference VARCHAR(80) NULL,
    created_by BIGINT NULL,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    checksum VARBINARY(255),
    CONSTRAINT fk_transactions_type
        FOREIGN KEY (type_id) REFERENCES transaction_types(id),
    CONSTRAINT fk_transactions_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_transactions_exchange_rate
        FOREIGN KEY (exchange_rate_id) REFERENCES exchange_rates(id),
    CONSTRAINT fk_transactions_order
        FOREIGN KEY (related_order_id) REFERENCES orders(id),
    CONSTRAINT fk_transactions_created_by
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT chk_transactions_amount CHECK (amount >= 0)
) ENGINE=InnoDB;

-- =========================================================
-- TRACKING
-- =========================================================

CREATE TABLE tracking (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    transport_unit_id BIGINT NULL,
    transaction_id BIGINT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tracking_order
        FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_tracking_transport_unit
        FOREIGN KEY (transport_unit_id) REFERENCES transport_units(id),
    CONSTRAINT fk_tracking_transaction
        FOREIGN KEY (transaction_id) REFERENCES transactions(id)
) ENGINE=InnoDB;

-- =========================================================
-- DEMAND TOWARDS ETHERIA
-- =========================================================

CREATE TABLE supply_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    country_id BIGINT NOT NULL,
    requested_quantity DECIMAL(14,2) NOT NULL,
    created_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    checksum VARBINARY(255),
    CONSTRAINT fk_supply_requests_product
        FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_supply_requests_country
        FOREIGN KEY (country_id) REFERENCES countries(id),
    CONSTRAINT chk_supply_requests_quantity CHECK (requested_quantity > 0)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;
