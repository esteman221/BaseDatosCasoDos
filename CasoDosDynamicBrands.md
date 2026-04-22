# Mini log de cambios
# * Se agregaron cosas de Etheria Necesarias para el funcionamiento de Dynamic
# * Se ordeno de menos dependencia a mas dependencia 
# * Se cambiaron los tamannios de los campos varchar
# * Discutir con profesor que mas cosas necesarias de Etherial se requieren

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

# TRANSPORT TYPE 
transportType
- id (PK)
- code varchar(20) (UNIQUE) -- PLANE, BOAT, TRUCK

# TRANSPORT, -- lo mismo que el anterior, pero aqui nos interesa más el courier  REVISARREVISAR
transport
- id (PK)
- transportTypeId (FK -> transportType.Id)
- name varchar(100)
- identifier varchar(100)
- cityId (FK -> cities.id) allows null
- contactEmail varchar(254) -- curiosamente este es el limite practico segun RFC 2821
- phone varchar(15)
- regionalCode varchar(3)

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

# Log types -- este modelo de logs te hizo falta en la otra REVISARREVISAR
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
- code varchar(20) (UNIQUE)  -- VAT, IMPORT_DUTY, SALES_TAX
- description varchar(60)

countryTaxes -- misma observacion que el otro modelo REVISARREVISAR
- id (PK)
- countryId (FK -> countries.id)
- taxTypeId (FK -> taxTypes.id)
- percentage DECIMAL
- validFrom DATE
- validTo DATE

taxes
- id (PK)
- taxTypeId (FK -> taxTypes.id)
- countryTaxId (FK -> countryTaxes.id)


# ===================
# Producto
# ===================

# A diferencia de Etherial no le interesa los HUbs donde estan los lotes del producto, pero si le interesa de que HUB debe sacar X producto

# =========================
# HUB (Centro de Distribucion Costero)
# =========================

# HUB TYPES -- para esta gente el hub es indiferente, ellos sabe q el producto está y que se los tienen q enviar nada mas no sabe como lo guardan REVISARREVISAR
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

# EL producto debe poseer su categoria, brand, supplier y proteccion

# categorias 
categories
- id (PK)
- name varchar(60)

# brands
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

# Se decidio meter el quantityTYpe dentro de productos, asi los lotes solo poseerian un quantity Numerical y no les importaria el tipo, pues ya esta en el producto.

# prodcuts, -- hace falta caracteristicas variables por categoria, fotografías, reviews, etc porque este es el ecommerce. Los productos pueden tener N presentaciones dependiendo de la tienda y asi cambian los precios monedas etc segun la tienda donde se publique cada producto.  REVISARREVISAR
products
- id (PK)
- name varchar(60)
- brandId (FK -> brands.id)
- hubId (FK -> hubs.id)
- checksum BYTEA
- createdBy (FK -> users.id)
- createdAt DATE
- unitMeasurement (FK -> unitMeasurement.id)
- quantityType (FK -> quantityType)
- enabled BOOLEAN

# CATEGORYPERPRODUCT
categoryperproduct
- id (PK)
- categoryId (FK -> categories.id)
- productId (FK -> products.id)

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

language
- id (PK)
- descripcion varchar(20) 

aiModels
- id (PK)
- name varchar(20)
- version varchar(10)

sites -- esto hay que ligarlo a los brands de productos por tienda, agrega una config json para los settings del site REVISARREVISAR
- id (PK)
- modelId (FK -> aiModels.id)
- name varchar(100)
- urlPhysicalDirection varchar(100)
- ipPhysical varchar(100)
- countryId (FK -> countries.id)
- baseCurrencyId (FK -> currencies.id)
- urlLogo varchar(20)
- createdAt DATE
- activo boolean

languagespersite
- siteId (FK -> sites.id)
- languageId (FK -> language.id)

# =========================
# IA GENERADORA DE SITIOS
# =========================



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