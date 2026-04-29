-- =========================================================
-- Etheria - Script de declaracion de tablas para PostgreSQL
-- Caso 2
-- Fuente: Markdown de Etheria corregido por el profesor.
-- =========================================================

-- Nota de normalizacion aplicada:
-- 1. Se usa snake_case para evitar problemas de mayusculas/minusculas en PostgreSQL.
-- 2. Se corrigieron referencias inconsistentes del Markdown:
--    adresses -> addresses
--    hub -> hubs
--    zone -> hub_zones
--    usuarios -> users
--    currency -> currencies
--    unitMeasurement -> unit_measurements
--    quantityType -> quantity_types
-- 3. NUMERICAL se interpreta como NUMERIC.
-- 4. Las tablas con FK circulares se crean primero sin algunas FK y luego se agregan con ALTER TABLE.

DROP SCHEMA IF EXISTS etheria CASCADE;
CREATE SCHEMA etheria;
SET search_path TO etheria;

-- =========================================================
-- USUARIOS / AUDITORIA
-- =========================================================

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE,
    contrasennia BYTEA NOT NULL,
    checksum BYTEA,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by BIGINT NULL
);

ALTER TABLE users
ADD CONSTRAINT fk_users_created_by
FOREIGN KEY (created_by) REFERENCES users(id);

-- =========================================================
-- ADDRESS PATTERN
-- =========================================================

CREATE TABLE countries (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE states (
    id BIGSERIAL PRIMARY KEY,
    country_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    CONSTRAINT fk_states_country
        FOREIGN KEY (country_id) REFERENCES countries(id),
    CONSTRAINT uq_states_country_name
        UNIQUE (country_id, name)
);

CREATE TABLE cities (
    id BIGSERIAL PRIMARY KEY,
    state_id BIGINT NOT NULL,
    name VARCHAR(90) NOT NULL,
    CONSTRAINT fk_cities_state
        FOREIGN KEY (state_id) REFERENCES states(id),
    CONSTRAINT uq_cities_state_name
        UNIQUE (state_id, name)
);

CREATE TABLE addresses (
    id BIGSERIAL PRIMARY KEY,
    city_id BIGINT NOT NULL,
    zip_code VARCHAR(10),
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    created_by BIGINT,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT fk_addresses_city
        FOREIGN KEY (city_id) REFERENCES cities(id),
    CONSTRAINT fk_addresses_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- =========================================================
-- LOG
-- =========================================================

CREATE TABLE log_types (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(100) NOT NULL
);

CREATE TABLE event_types (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(100) NOT NULL
);

CREATE TABLE severities (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    level VARCHAR(10) NOT NULL
);

CREATE TABLE sources (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(100) NOT NULL
);

CREATE TABLE data_objects (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(100) NOT NULL
);

CREATE TABLE logs (
    id BIGSERIAL PRIMARY KEY,
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
    computer BYTEA,
    checksum BYTEA,
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
);

-- =========================================================
-- HUB
-- =========================================================

CREATE TABLE hub_types (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(60) NOT NULL
);

CREATE TABLE hubs (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    capacity BIGINT NOT NULL CHECK (capacity >= 0),
    address_id BIGINT NOT NULL,
    type_id BIGINT NOT NULL,
    created_by BIGINT,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT fk_hubs_address
        FOREIGN KEY (address_id) REFERENCES addresses(id),
    CONSTRAINT fk_hubs_type
        FOREIGN KEY (type_id) REFERENCES hub_types(id),
    CONSTRAINT fk_hubs_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE hub_zones (
    id BIGSERIAL PRIMARY KEY,
    hub_id BIGINT NOT NULL,
    code VARCHAR(20) NOT NULL,
    description VARCHAR(60) NOT NULL,
    CONSTRAINT fk_hub_zones_hub
        FOREIGN KEY (hub_id) REFERENCES hubs(id),
    CONSTRAINT uq_hub_zones_hub_code
        UNIQUE (hub_id, code)
);

CREATE TABLE hub_locations (
    id BIGSERIAL PRIMARY KEY,
    hub_id BIGINT NOT NULL,
    zone_id BIGINT NOT NULL,
    rack VARCHAR(20),
    level VARCHAR(20),
    checksum BYTEA,
    CONSTRAINT fk_hub_locations_hub
        FOREIGN KEY (hub_id) REFERENCES hubs(id),
    CONSTRAINT fk_hub_locations_zone
        FOREIGN KEY (zone_id) REFERENCES hub_zones(id)
);

-- =========================================================
-- PROVEEDORES
-- =========================================================

CREATE TABLE suppliers (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country_id BIGINT NOT NULL,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_suppliers_country
        FOREIGN KEY (country_id) REFERENCES countries(id),
    CONSTRAINT uq_suppliers_name_country
        UNIQUE (name, country_id)
);

CREATE TABLE supplier_contacts (
    id BIGSERIAL PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    contact_name VARCHAR(100) NOT NULL,
    email VARCHAR(254),
    phone VARCHAR(15),
    regional_code VARCHAR(3),
    CONSTRAINT fk_supplier_contacts_supplier
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);

-- =========================================================
-- CURRENCIES PATTERN
-- =========================================================

CREATE TABLE currencies (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE,
    symbol VARCHAR(5) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    post_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT,
    country_id BIGINT NOT NULL,
    CONSTRAINT fk_currencies_user
        FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_currencies_country
        FOREIGN KEY (country_id) REFERENCES countries(id)
);

CREATE TABLE exchange_rates (
    id BIGSERIAL PRIMARY KEY,
    from_currency_id BIGINT NOT NULL,
    to_currency_id BIGINT NOT NULL,
    rate NUMERIC(18, 6) NOT NULL CHECK (rate > 0),
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    post_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT,
    checksum BYTEA,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_exchange_rates_from_currency
        FOREIGN KEY (from_currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_exchange_rates_to_currency
        FOREIGN KEY (to_currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_exchange_rates_user
        FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT chk_exchange_rates_different_currency
        CHECK (from_currency_id <> to_currency_id)
);

CREATE INDEX idx_exchange_rates_pair_current
ON exchange_rates(from_currency_id, to_currency_id, is_current);

CREATE TABLE exchange_history (
    id BIGSERIAL PRIMARY KEY,
    from_currency_id BIGINT NOT NULL,
    to_currency_id BIGINT NOT NULL,
    rate_to_usd NUMERIC(18, 6) NOT NULL CHECK (rate_to_usd > 0),
    start_date_time DATE NOT NULL,
    end_date_time DATE,
    post_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    checksum BYTEA,
    user_id BIGINT,
    exchange_rate_id BIGINT NOT NULL,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_exchange_history_from_currency
        FOREIGN KEY (from_currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_exchange_history_to_currency
        FOREIGN KEY (to_currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_exchange_history_user
        FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_exchange_history_exchange_rate
        FOREIGN KEY (exchange_rate_id) REFERENCES exchange_rates(id)
);

-- =========================================================
-- IMPUESTOS
-- =========================================================

CREATE TABLE tax_types (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    description VARCHAR(100)
);

CREATE TABLE country_taxes (
    id BIGSERIAL PRIMARY KEY,
    country_id BIGINT NOT NULL,
    percentage NUMERIC(8, 4) NULL,
    flat_fee NUMERIC(14, 2) NULL,
    valid_from DATE NOT NULL,
    valid_to DATE,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by BIGINT,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at DATE,
    updated_by BIGINT,
    CONSTRAINT fk_country_taxes_country
        FOREIGN KEY (country_id) REFERENCES countries(id),
    CONSTRAINT fk_country_taxes_created_by
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_country_taxes_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT chk_country_taxes_value
        CHECK (percentage IS NOT NULL OR flat_fee IS NOT NULL)
);

CREATE TABLE taxes (
    id BIGSERIAL PRIMARY KEY,
    tax_type_id BIGINT NOT NULL,
    country_tax_id BIGINT NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by BIGINT,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at DATE,
    updated_by BIGINT,
    CONSTRAINT fk_taxes_tax_type
        FOREIGN KEY (tax_type_id) REFERENCES tax_types(id),
    CONSTRAINT fk_taxes_country_tax
        FOREIGN KEY (country_tax_id) REFERENCES country_taxes(id),
    CONSTRAINT fk_taxes_created_by
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_taxes_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id)
);

-- =========================================================
-- PRODUCTOS
-- =========================================================

CREATE TABLE categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE brands (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(60) NOT NULL,
    country_id BIGINT NOT NULL,
    CONSTRAINT fk_brands_country
        FOREIGN KEY (country_id) REFERENCES countries(id),
    CONSTRAINT uq_brands_name_country
        UNIQUE (name, country_id)
);

CREATE TABLE quantity_types (
    id BIGSERIAL PRIMARY KEY,
    description VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE unit_measurements (
    id BIGSERIAL PRIMARY KEY,
    description VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE product_characteristics (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(60) NOT NULL,
    description VARCHAR(500),
    brand_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    current_price NUMERIC(14, 2) NOT NULL CHECK (current_price >= 0),
    currency_id BIGINT NOT NULL,
    exchange_rate_id BIGINT,
    checksum BYTEA,
    created_by BIGINT,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    updated_by BIGINT NULL,
    updated_at DATE NULL,
    unit_measurement_id BIGINT NOT NULL,
    quantity_type_id BIGINT NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_products_brand
        FOREIGN KEY (brand_id) REFERENCES brands(id),
    CONSTRAINT fk_products_supplier
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
    CONSTRAINT fk_products_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_products_exchange_rate
        FOREIGN KEY (exchange_rate_id) REFERENCES exchange_rates(id),
    CONSTRAINT fk_products_created_by
        FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_products_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(id),
    CONSTRAINT fk_products_unit_measurement
        FOREIGN KEY (unit_measurement_id) REFERENCES unit_measurements(id),
    CONSTRAINT fk_products_quantity_type
        FOREIGN KEY (quantity_type_id) REFERENCES quantity_types(id)
);

CREATE TABLE category_per_product (
    id BIGSERIAL PRIMARY KEY,
    category_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    CONSTRAINT fk_category_per_product_category
        FOREIGN KEY (category_id) REFERENCES categories(id),
    CONSTRAINT fk_category_per_product_product
        FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT uq_category_per_product
        UNIQUE (category_id, product_id)
);

CREATE TABLE product_characteristic_per_product (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    product_characteristic_id BIGINT NOT NULL,
    value VARCHAR(100) NOT NULL,
    CONSTRAINT fk_product_characteristic_product
        FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_product_characteristic_characteristic
        FOREIGN KEY (product_characteristic_id) REFERENCES product_characteristics(id),
    CONSTRAINT uq_product_characteristic_per_product
        UNIQUE (product_id, product_characteristic_id)
);

CREATE TABLE product_prices (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    price NUMERIC(14, 2) NOT NULL CHECK (price >= 0),
    currency_id BIGINT NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT fk_product_prices_product
        FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_product_prices_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(id)
);

-- =========================================================
-- TRANSPORTE
-- Se coloca despues de productos porque transport_units usa unit_measurements.
-- =========================================================

CREATE TABLE transport_types (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(60) NOT NULL,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by BIGINT,
    CONSTRAINT fk_transport_types_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE carriers (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(254),
    phone VARCHAR(15),
    regional_code VARCHAR(3),
    address_id BIGINT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by BIGINT,
    checksum BYTEA,
    CONSTRAINT fk_carriers_address
        FOREIGN KEY (address_id) REFERENCES addresses(id),
    CONSTRAINT fk_carriers_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE carrier_locations (
    id BIGSERIAL PRIMARY KEY,
    carrier_id BIGINT NOT NULL,
    address_id BIGINT NOT NULL,
    city_id BIGINT NULL,
    code VARCHAR(30) NULL,
    description VARCHAR(80) NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by BIGINT,
    CONSTRAINT fk_carrier_locations_carrier
        FOREIGN KEY (carrier_id) REFERENCES carriers(id),
    CONSTRAINT fk_carrier_locations_address
        FOREIGN KEY (address_id) REFERENCES addresses(id),
    CONSTRAINT fk_carrier_locations_city
        FOREIGN KEY (city_id) REFERENCES cities(id),
    CONSTRAINT fk_carrier_locations_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE transport_units (
    id BIGSERIAL PRIMARY KEY,
    carrier_id BIGINT NOT NULL,
    transport_type_id BIGINT NOT NULL,
    identifier VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NULL,
    capacity NUMERIC(14, 2) NULL CHECK (capacity IS NULL OR capacity >= 0),
    unit_measurement_id BIGINT NULL,
    current_address_id BIGINT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by BIGINT,
    checksum BYTEA,
    CONSTRAINT fk_transport_units_carrier
        FOREIGN KEY (carrier_id) REFERENCES carriers(id),
    CONSTRAINT fk_transport_units_transport_type
        FOREIGN KEY (transport_type_id) REFERENCES transport_types(id),
    CONSTRAINT fk_transport_units_unit_measurement
        FOREIGN KEY (unit_measurement_id) REFERENCES unit_measurements(id),
    CONSTRAINT fk_transport_units_current_address
        FOREIGN KEY (current_address_id) REFERENCES addresses(id),
    CONSTRAINT fk_transport_units_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- =========================================================
-- INVENTARIO Y LOTES
-- =========================================================

CREATE TABLE product_lots (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    hub_id BIGINT NOT NULL,
    quantity NUMERIC(14, 2) NOT NULL CHECK (quantity >= 0),
    unit_cost NUMERIC(14, 2) NOT NULL CHECK (unit_cost >= 0),
    currency_id BIGINT NOT NULL,
    arrival_date DATE NOT NULL,
    checksum BYTEA,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT fk_product_lots_product
        FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_product_lots_supplier
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
    CONSTRAINT fk_product_lots_hub
        FOREIGN KEY (hub_id) REFERENCES hubs(id),
    CONSTRAINT fk_product_lots_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(id)
);

CREATE TABLE lot_locations (
    id BIGSERIAL PRIMARY KEY,
    lot_id BIGINT NOT NULL,
    hub_location_id BIGINT NOT NULL,
    quantity NUMERIC(14, 2) NOT NULL CHECK (quantity >= 0),
    CONSTRAINT fk_lot_locations_lot
        FOREIGN KEY (lot_id) REFERENCES product_lots(id),
    CONSTRAINT fk_lot_locations_hub_location
        FOREIGN KEY (hub_location_id) REFERENCES hub_locations(id)
);

CREATE TABLE lot_movement_types (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(60) NOT NULL
);

CREATE TABLE lot_movements (
    id BIGSERIAL PRIMARY KEY,
    lot_id BIGINT NOT NULL,
    movement_type_id BIGINT NOT NULL,
    from_hub_location_id BIGINT NULL,
    to_hub_location_id BIGINT NULL,
    quantity NUMERIC(14, 2) NOT NULL CHECK (quantity > 0),
    reference_type VARCHAR(30) NULL,
    reference_id BIGINT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    checksum BYTEA,
    CONSTRAINT fk_lot_movements_lot
        FOREIGN KEY (lot_id) REFERENCES product_lots(id),
    CONSTRAINT fk_lot_movements_type
        FOREIGN KEY (movement_type_id) REFERENCES lot_movement_types(id),
    CONSTRAINT fk_lot_movements_from_location
        FOREIGN KEY (from_hub_location_id) REFERENCES hub_locations(id),
    CONSTRAINT fk_lot_movements_to_location
        FOREIGN KEY (to_hub_location_id) REFERENCES hub_locations(id),
    CONSTRAINT fk_lot_movements_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE transformation_types (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(40) NOT NULL
);

CREATE TABLE lot_transformations (
    id BIGSERIAL PRIMARY KEY,
    transformation_type_id BIGINT NOT NULL,
    performed_by BIGINT,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    checksum BYTEA,
    CONSTRAINT fk_lot_transformations_type
        FOREIGN KEY (transformation_type_id) REFERENCES transformation_types(id),
    CONSTRAINT fk_lot_transformations_performed_by
        FOREIGN KEY (performed_by) REFERENCES users(id)
);

CREATE TABLE lot_transformation_inputs (
    id BIGSERIAL PRIMARY KEY,
    transformation_id BIGINT NOT NULL,
    lot_id BIGINT NOT NULL,
    quantity NUMERIC(14, 2) NOT NULL CHECK (quantity > 0),
    CONSTRAINT fk_lot_transformation_inputs_transformation
        FOREIGN KEY (transformation_id) REFERENCES lot_transformations(id),
    CONSTRAINT fk_lot_transformation_inputs_lot
        FOREIGN KEY (lot_id) REFERENCES product_lots(id)
);

CREATE TABLE lot_transformation_outputs (
    id BIGSERIAL PRIMARY KEY,
    transformation_id BIGINT NOT NULL,
    lot_id BIGINT NOT NULL,
    quantity NUMERIC(14, 2) NOT NULL CHECK (quantity > 0),
    CONSTRAINT fk_lot_transformation_outputs_transformation
        FOREIGN KEY (transformation_id) REFERENCES lot_transformations(id),
    CONSTRAINT fk_lot_transformation_outputs_lot
        FOREIGN KEY (lot_id) REFERENCES product_lots(id)
);

-- =========================================================
-- INCOTERMS / ESTADO
-- =========================================================

CREATE TABLE incoterms (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    description VARCHAR(100) NOT NULL
);

CREATE TABLE status (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(100)
);

-- =========================================================
-- ORDENES
-- =========================================================

CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    order_number NUMERIC(18, 0) NOT NULL UNIQUE,
    incoterm_id BIGINT NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status_id BIGINT NOT NULL,
    discount_amount NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    tax_amount NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    currency_id BIGINT NOT NULL,
    created_by BIGINT,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    checksum BYTEA,
    CONSTRAINT fk_orders_incoterm
        FOREIGN KEY (incoterm_id) REFERENCES incoterms(id),
    CONSTRAINT fk_orders_status
        FOREIGN KEY (status_id) REFERENCES status(id),
    CONSTRAINT fk_orders_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_orders_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity NUMERIC(14, 2) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(14, 2) NOT NULL CHECK (unit_price >= 0),
    discount NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
    amount NUMERIC(14, 2) NOT NULL CHECK (amount >= 0),
    total_amount NUMERIC(14, 2) NOT NULL CHECK (total_amount >= 0),
    total_taxes NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (total_taxes >= 0),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE order_item_taxes (
    id BIGSERIAL PRIMARY KEY,
    order_item_id BIGINT NOT NULL,
    taxes_id BIGINT NOT NULL,
    total_amount NUMERIC(14, 2) NOT NULL CHECK (total_amount >= 0),
    CONSTRAINT fk_order_item_taxes_order_item
        FOREIGN KEY (order_item_id) REFERENCES order_items(id),
    CONSTRAINT fk_order_item_taxes_tax
        FOREIGN KEY (taxes_id) REFERENCES taxes(id)
);

CREATE TABLE order_address_types (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(60) NOT NULL
);

CREATE TABLE order_addresses (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    sender_address_id BIGINT NOT NULL,
    receiver_address_id BIGINT NOT NULL,
    type_id BIGINT NOT NULL,
    user_id BIGINT,
    post_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_order_addresses_order
        FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_order_addresses_sender_address
        FOREIGN KEY (sender_address_id) REFERENCES addresses(id),
    CONSTRAINT fk_order_addresses_receiver_address
        FOREIGN KEY (receiver_address_id) REFERENCES addresses(id),
    CONSTRAINT fk_order_addresses_type
        FOREIGN KEY (type_id) REFERENCES order_address_types(id),
    CONSTRAINT fk_order_addresses_user
        FOREIGN KEY (user_id) REFERENCES users(id)
);

-- =========================================================
-- TRANSACCIONES FINANCIERAS
-- =========================================================

CREATE TABLE transaction_types (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(60) NOT NULL,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by BIGINT,
    CONSTRAINT fk_transaction_types_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    type_id BIGINT NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    description VARCHAR(80),
    amount NUMERIC(14, 2) NOT NULL CHECK (amount >= 0),
    currency_id BIGINT NOT NULL,
    exchange_rate_id BIGINT,
    related_order_id BIGINT NULL,
    reference_type VARCHAR(30) NULL,
    reference_id BIGINT NULL,
    external_reference VARCHAR(80) NULL,
    created_by BIGINT,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    checksum BYTEA,
    CONSTRAINT fk_transactions_type
        FOREIGN KEY (type_id) REFERENCES transaction_types(id),
    CONSTRAINT fk_transactions_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(id),
    CONSTRAINT fk_transactions_exchange_rate
        FOREIGN KEY (exchange_rate_id) REFERENCES exchange_rates(id),
    CONSTRAINT fk_transactions_related_order
        FOREIGN KEY (related_order_id) REFERENCES orders(id),
    CONSTRAINT fk_transactions_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
);

-- =========================================================
-- TRAZABILIDAD
-- =========================================================

CREATE TABLE lot_shipments (
    id BIGSERIAL PRIMARY KEY,
    lot_id BIGINT NOT NULL,
    carrier_id BIGINT NOT NULL,
    transport_unit_id BIGINT NULL,
    from_address_id BIGINT NOT NULL,
    to_address_id BIGINT NOT NULL,
    departure_date DATE NOT NULL,
    estimated_arrival_date DATE NULL,
    arrival_date DATE NULL,
    status_id BIGINT NOT NULL,
    tracking_number BIGSERIAL UNIQUE,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by BIGINT,
    checksum BYTEA,
    CONSTRAINT fk_lot_shipments_lot
        FOREIGN KEY (lot_id) REFERENCES product_lots(id),
    CONSTRAINT fk_lot_shipments_carrier
        FOREIGN KEY (carrier_id) REFERENCES carriers(id),
    CONSTRAINT fk_lot_shipments_transport_unit
        FOREIGN KEY (transport_unit_id) REFERENCES transport_units(id),
    CONSTRAINT fk_lot_shipments_from_address
        FOREIGN KEY (from_address_id) REFERENCES addresses(id),
    CONSTRAINT fk_lot_shipments_to_address
        FOREIGN KEY (to_address_id) REFERENCES addresses(id),
    CONSTRAINT fk_lot_shipments_status
        FOREIGN KEY (status_id) REFERENCES status(id),
    CONSTRAINT fk_lot_shipments_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE tracking (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    order_address_id BIGINT NOT NULL,
    status_id BIGINT NOT NULL,
    carrier_id BIGINT NULL,
    transport_unit_id BIGINT NULL,
    handled_by BIGINT,
    transaction_id BIGINT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    lot_shipment_id BIGINT NOT NULL,
    notes VARCHAR(150) NULL,
    CONSTRAINT fk_tracking_order
        FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_tracking_order_address
        FOREIGN KEY (order_address_id) REFERENCES order_addresses(id),
    CONSTRAINT fk_tracking_status
        FOREIGN KEY (status_id) REFERENCES status(id),
    CONSTRAINT fk_tracking_carrier
        FOREIGN KEY (carrier_id) REFERENCES carriers(id),
    CONSTRAINT fk_tracking_transport_unit
        FOREIGN KEY (transport_unit_id) REFERENCES transport_units(id),
    CONSTRAINT fk_tracking_handled_by
        FOREIGN KEY (handled_by) REFERENCES users(id),
    CONSTRAINT fk_tracking_transaction
        FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    CONSTRAINT fk_tracking_lot_shipment
        FOREIGN KEY (lot_shipment_id) REFERENCES lot_shipments(id)
);

-- =========================================================
-- INDICES RECOMENDADOS
-- =========================================================

CREATE INDEX idx_products_supplier ON products(supplier_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_product_lots_product ON product_lots(product_id);
CREATE INDEX idx_lot_movements_lot ON lot_movements(lot_id);
CREATE INDEX idx_orders_status ON orders(status_id);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_transactions_order ON transactions(related_order_id);
CREATE INDEX idx_tracking_order ON tracking(order_id);
CREATE INDEX idx_tracking_lot_shipment ON tracking(lot_shipment_id);

-- =========================================================
-- FIN DEL SCRIPT
-- =========================================================
