# Mini log de cambios
# Se hicieron las correcciones del profesor

# =========================
# Address Pattern
# =========================

## COUNTRIES
countries
- id (PK)
- name varchar(60) --pais mas largo contiene 50 caracteres

# STATES
states
- id (PK)
- countryId (FK -> countries.id) 
- name varchar(100) -- estado mas largo contiene 85 caracteres

# CITIES
cities
- id (PK)
- stateId (FK -> states.id) 
- name varchar(90) -- ciudad mas largo contiene 60 caracteres

# ADDRESSES
addresses
- id (PK)
- cityId (FK -> cities.id)
- zipCode varchar(10)
- latitude  -- en cambio de la geoposicion se posee la latitud y longitud
- longitude
- createdBy (FK -> users.id)
- createdAt DATE

# ===================
# TRANSPORTE 
# ===================

# Para hacer escalabilidad se decidio simplificar puertos y aeropuertos en transporte y los couriers, por si deciden hacer un dia un 
# uberImportacionEats O hacen avances tecnologicos (REVISALO)

# TRANSPORT 

## TRANSPORT TYPES
# Catálogo de tipos generales de transporte.

transportTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- TRUCK, PLANE, BOAT, MOTORBIKE
- description varchar(60)
- createdAt DATE
- createdBy (FK -> users.id)

## CARRIERS
# Empresa o entidad que presta el servicio logístico o de transporte.
# Ejemplos: FedEx, DHL, Maersk, Correos de Costa Rica.

carriers
- id (PK)
- name varchar(100)
- email varchar(254)
- phone varchar(15)
- regionalCode varchar(3)
- addressId (FK -> addresses.id) allows null
- enabled BOOLEAN
- createdAt DATE
- createdBy (FK -> users.id)
- checkSum BYTEA

## CARRIER LOCATIONS
# Sedes, sucursales, terminales, puertos, aeropuertos o centros operativos
# asociados a un carrier.
# Un mismo carrier puede operar en varias ubicaciones.

carrierLocations
- id (PK)
- carrierId (FK -> carriers.id)
- addressId (FK -> addresses.id)
- cityId (FK -> cities.id) allows null
- code varchar(30) allows null
- description varchar(80) allows null
- enabled BOOLEAN
- createdAt DATE
- createdBy (FK -> users.id)

## TRANSPORT UNITS
# Unidad física específica utilizada para mover la carga.
# Representa el medio concreto de transporte, no la empresa.
# Ejemplos: camión con placa X, barco con código Y, avión con matrícula Z.

transportUnits
- id (PK)
- carrierId (FK -> carriers.id)
- transportTypeId (FK -> transportTypes.id)
- identifier varchar(100) (UNIQUE)
- name varchar(100) allows null
- capacity DECIMAL allows null
- unitMeasurementId (FK -> unitMeasurement.id) allows null
- currentAddressId (FK -> addresses.id) allows null
- enabled BOOLEAN
- createdAt DATE
- createdBy (FK -> users.id)
- checkSum BYTEA

# =========================
# USUARIOS / AUDITORIA
# =========================

## USERS
users
- id (PK)
- name varchar (80)
- email varchar (254)
- contrasenna BYTEA -- proteccion
- checkSum BYTEA -- proteccion (no me reganniaron de su existencia a si que lo pongo)
- createdAt DATE
- countryId (FK -> country.id)

# USER ADDRESSES
userAddresses
- id (PK)
- userId (FK -> users.id)
- addressId (FK -> addresses.id)
- isDefault (BOOLEAN)
- active (BOOLEAN)
- createdAt DATE
- checkSum BYTEA --porteccion
- postTime TIMESTAMP

# ==========================
# LOG (puse todo lo del profe, no obstante, revisa si se requiere todo en verdad, eso veremos tras la cita)
# ==========================

# Log types 
logTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- USER, AI, SYSTEM, SECURITY
- description varchar(100)

# Event
eventTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- CREATE_ORDER, LOGIN, AI_GENERATION, UPDATE_PRICE
- description varchar(100)

# SEv
severities
- id (PK)
- code varchar(20) (UNIQUE)   -- INFO, WARNING, ERROR, CRITICAL
- level varchar(10)

# Sources
sources
- id (PK)
- code (UNIQUE)   -- BACKEND, FRONTEND, AI_ENGINE, API, BATCH
- description varchar(100)

# DataObjects
dataObjects
- id (PK)
- code (UNIQUE)   -- USER, ORDER, PRODUCT, SITE, AI_MODEL
- description varchar(100)

# logs
logs
- id (PK)
- logTypeId (FK -> logTypes.id)
- eventTypeId (FK -> eventTypes.id)
- severityId (FK -> severities.id)
- sourceId (FK -> sources.id)
- dataObjectId (FK -> dataObjects.id)
- description varchar(100)
- objectId1 BIGINT NULL
- objectId2 BIGINT NULL
- referenceId1 BIGINT NULL
- referenceId2 BIGINT NULL
- referenceDescription varchar(100)
- userId (FK -> users.id, NULL)
- computer BYTEA
- checksum BYTEA
- postTime TIMESTAMP


# =========================
# CURRENCIES PATTERN
# =========================

# CURRENCIES
currencies
- id (PK) 
- name varchar(20)
- symbol varchar(5)
- enabled BOOLEAN
- postTime TIMESTAMP
- userId (FK -> users.id)
- countryId (FK -> countries.id)

# EXCHANGERATES
exchangeRates
- id (PK)
- fromCurrencyId (FK -> currencies.id)
- toCurrencyId (FK -> currencies.id)
- rate DECIMAL
- date DATE
- createdAt DATE
- postTime TIMESTAMP
- userId (FK -> users.id)
- checkSum BYTEA
- iscurrent BOOLEAN

# EXCHANGEHISTORY
exchangeHistory
- id (PK)
- fromCurrencyId (FK -> currencies.id)
- toCurrencyId (FK -> currencies.id)
- rateToUsd DECIMAL
- startDateTime DATE
- endDateTime DATE
- postTime TIMESTAMP
- checkSum BYTEA
- userId (FK -> users.id)
- exchangeRateId (FK -> exchangeRates.id)
- iscurrent BOOLEAN

# =========================
# IMPUESTOS
# =========================

# Datos historicos de los paises

taxTypes
- id (PK)
- code varchar(30) (UNIQUE)  -- VAT, IMPORT_DUTY, SALES_TAX

countryTaxes 
- id (PK)
- countryId (FK -> countries.id)
- percentage DECIMAL NULL 
- flatflee DECIMAL NULL
- validFrom DATE
- validTo DATE
- createdAt DATE
- createdBy (FK -> users.id)
- enabled BOOLEAN
- updatedAt DATE
- updatedBy (FK -> users.id)

taxes
- id (PK)
- taxTypeId (FK -> taxTypes.id)
- countryTaxId (FK -> countryTaxes.id)
- validFrom DATE
- validTo DATE
- createdAt DATE
- createdBy (FK -> users.id)
- enabled BOOLEAN
- updatedAt DATE
- updatedBy (FK -> users.id)


# ===================
# Producto
# ===================

# A diferencia de Etherial no le interesa los HUbs donde estan los lotes del producto, pero si le interesa de que HUB debe sacar X producto

# =========================
# HUB (Centro de Distribucion Costero)
# =========================

# HUB TYPES -- REVISAR? Ya deberia estar manteniendo un disenno simple, pero no se. 
hubTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- MAIN, WAREHOUSE, DISTRIBUTION_CENTER, PICKUP_POINT, RETURN_CENTER
- description varchar(60)

# HUBS
hubs
- id (PK)
- name varchar(80)
- capacity BIGINT
- typeId (FK -> hubTypes.id)
- createdBy (FK -> users.id)
- createdAt DATE

# =========================
# PRODUCTOS
# =========================

# EL producto debe poseer su categoria, brand, supplier y proteccion.
# Como este modulo funciona como ecommerce, el producto necesita
# caracteristicas variables, descripcion amplia y precio actual.
# El historico de precios se mantiene aparte en productPrices.

# CATEGORIES
categories
- id (PK)
- name varchar(60)

# BRANDS
brands
- id (PK)
- name varchar(60)
- countryId (FK -> countries.id)

# QUANTITY TYPE
quantityType
- id (PK)
- code varchar(20) (UNIQUE) -- bottles, pair

# UNIT OF MEASUREMENT
unitMeasurement
- id (PK)
- code varchar(20) (UNIQUE) -- cm, dl, om

# PRODUCT CHARACTERISTICS
# Catalogo de caracteristicas variables que puede tener un producto.
# Ejemplo: color, material, tamaño, capacidad, RAM, CPU

productCharacteristics
- id (PK)
- name varchar(60)

# Se decidio meter el quantityType dentro de products,
# asi los lotes solo poseerian un quantity numerical
# y no les importaria el tipo, pues ya esta en el producto.

# PRODUCTS
# Se agrega una descripcion mas amplia.
# Se agrega el precio actual con moneda y tipo de cambio
# para no tener que consultarlo siempre en el historico.
# Las caracteristicas variables se manejan mediante
# productCharacteristicPerProduct.

products
- id (PK)
- name varchar(60)
- description varchar(500)
- brandId (FK -> brands.id)
- supplierId (FK -> suppliers.id)
- hubId (FK -> hubs.id)
- currentPrice DECIMAL
- currencyId (FK -> currencies.id)
- exchangeRateId (FK -> exchangeRates.id)
- checksum BYTEA
- createdBy (FK -> users.id)
- createdAt DATE
- updatedBy (FK -> users.id) allows null
- updatedAt DATE allows null
- unitMeasurementId (FK -> unitMeasurement.id)
- quantityTypeId (FK -> quantityType.id)
- enabled BOOLEAN

# CATEGORY PER PRODUCT
categoryperproduct
- id (PK)
- categoryId (FK -> categories.id)
- productId (FK -> products.id)

# PRODUCT CHARACTERISTIC PER PRODUCT
# Relacion entre el producto y sus caracteristicas variables.
# Ejemplo: Laptop -> RAM = 16GB

productCharacteristicPerProduct
- id (PK)
- productId (FK -> products.id)
- productCharacteristicId (FK -> productCharacteristics.id)
- value varchar(100)

# PRODUCT PUBLICATIONS
# Un mismo producto puede tener distintas publicaciones
# segun la tienda o sitio donde se publique,
# cambiando precio, moneda, presentacion o estado.

productPublications
- id (PK)
- productId (FK -> products.id)
- siteId (FK -> sites.id)
- name varchar(60)
- description varchar(500) allows null
- price DECIMAL
- currencyId (FK -> currencies.id)
- exchangeRateId (FK -> exchangeRates.id) allows null
- urlImage varchar(255) allows null
- active BOOLEAN
- createdAt DATE
- updatedAt DATE allows null

# balance un producto puede tener muchas publicaciones
publicationsPerProduct
- id (PK)
- publicationId (FK -> publications.id)
- productId (FK -> products.id)

# PRODUCT IMAGES
# Fotografias del producto para el ecommerce.

productImages
- id (PK)
- productPublicationId (FK -> productsPublications.id)
- url varchar(255)
- altText varchar(100) allows null
- isMain BOOLEAN
- createdAt DATE

# PRODUCT REVIEWS
# Resenas u opiniones dejadas por usuarios sobre el producto.

productReviews
- id (PK)
- productPublicationId (FK -> productsPublications.id)
- userId (FK -> users.id)
- rating DECIMAL
- comment varchar(500) allows null
- createdAt DATE
- enabled BOOLEAN

# Se esta pensando que los reviews estan asociados a una sola publicacion  igual las imagenes
# =========================
# PRECIOS HISTORICOS
# =========================

# Se debe poseer el product prices

productPrices
- id (PK)
- productId (FK -> products.id)
- price DECIMAL
- currencyId (FK -> currencies.id)
- validFrom DATE
- validTo DATE
- createdAt DATE
- updatedBy (FK -> users.id) allows null

# A dynamic Brands solo le interesa la orden para enviarsela al usuario mediante su transporte

# ===================
# ESTADO
# ====================
status
- id (PK)
- code varchar(20) (UNIQUE) -- Puerto etc


# =========================
# SITIOS GENERADOS POR IA
# =========================

# LANGUAGES
language
- id (PK)
- description varchar(20)

# AI MODELS
aiModels
- id (PK)
- name varchar(20)
- version varchar(10)

# SITES (site config se agrego por el profesor)
sites
- id (PK)
- modelId (FK -> aiModels.id)
- name varchar(100)
- urlPhysicalDirection varchar(100)
- ipPhysical varchar(100)
- countryId (FK -> countries.id)
- baseCurrencyId (FK -> currencies.id)
- urlLogo varchar(100)
- siteConfig JSONB 
- createdAt DATE
- active BOOLEAN

languagesPerSite
- id (PK)
- siteId (FK -> sites.id)
- languageId (FK -> language.id)

# BRANDS PER SITE
# Relacion entre los sitios ecommerce y las marcas que publica cada tienda.
# No todas las marcas se venden en todos los sitios.

brandsPerSite
- id (PK)
- siteId (FK -> sites.id)
- brandId (FK -> brands.id)
- enabled BOOLEAN
- createdAt DATE

# =========================
# ORDENES
# =========================

# Ordenes
 
orders
- id (PK)
- orderNumber decimal
- orderDate DATE
- statusId (FK -> status.id)
- discountAmount DECIMAL
- taxAmount DECIMAL -- SUM de todas las taxes de todos los items
- totalAmount DECIMAL
- currencyId (FK -> currencies.id)
- createdBy (FK -> users.id)
- createdAt DATE
- checkSum BYTEA

# Items de la orden, la order puede poseer multiples suppliers, no se pone lote pues el lote se crea despues pues es un metodo de entrega.
# Primero se piden los items, y luego se entregan en lotes del HUB y finalmente se envian asi, pero la orden solo se sabe que se pidieron x 
# de tal producto

orderItems
- id (PK)
- orderId (FK → orders.id)
- productId (FK → products.id)
- quantity DECIMAL
- unitPrice DECIMAL
- discount DECIMAL
- amount DECIMAL
- totalAmount DECIMAL -- SUM todas taxes del item
- totalTaxes DECIMAL -- SUM todas taxes del item


# Este posee las taxes especificas de los productos
orderItemTaxes
- id (PK)
- orderItemId (FK -> orderItems.id)
- taxesId (FK -> taxes.id)
- totalAmount DECIMAL

# ORDER ADDRESS TYPES
orderAddressTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- SHIPPING, BILLING
- description varchar(60)

# Justificacion de la existencia de estos Labels:
# A diferencia de Etherial este agarra o necesita solamente la direccion del usuario y la direccion del pedido para su track

# EL userId se pone aca pues no necesariamente la direccion del que pidio la orden es la direccion a la que debe llegar. Desde Panama puedo pedir un envio a CR
# ORDER ADDRESSES 
orderAddresses
- id (PK)
- orderId (FK -> orders.id)
- senderAddressId (FK -> addresses.id)
- receiverAddressId (FK -> addresses.id)
- typeId (FK -> orderAddressTypes.id)
- userId (FK -> usuarios.id)
- postTime TIMESTAMP
- active (BOOLEAN)

# =========================
# TRANSACCIONES FINANCIERAS
# =========================

# Justificacion: Se dice que debe estar prrsente en documento dado por el profe.

# TRANSACTION TYPES
transactionTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- SALE, PURCHASE, SHIPPING_COST, TAX
- description

# TRANSACTIONS
transactions
- id (PK)
- typeId (FK -> transactionTypes.id)
- date DATE
- description varchar(80)
- amount DECIMAL   -- positivo ingreso, negativo egreso
- currencyId (FK -> currencies.id)
- relatedOrderId (FK -> orders.id)
- createdBy (FK -> users.id)
- createdAt DATE
- checkSum BYTEA

# ===============
# TRAZABILIDAD 
# ===============

# Tracing
Tracking
- id (PK)
- orderId (FK -> orders.id)
- transportId  (FK -> transport.id)
- transactionId (FK -> transaction.id)
- timestamp TIMESTAMP

# =========================
# DEMANDA HACIA ETHERIA
# =========================

supplyRequests
- id (PK)
- productId (FK -> products.id)
- countryId (FK -> countries.id)
- requestedQuantity NUMERICAL
- createdAt DATE
- checksum BYTEA