# =========================
# Address Pattern
# =========================

# Es la creacion del address pattern

## COUNTRIES
countries
- id (PK)
- name varchar(100) --pais mas largo contiene 50 caracteres
- isoCode
- createdAt DATE

# STATES
states
- id (PK)
- countryId (FK -> countries.id) 
- name varchar (170) -- estado mas largo contiene 85 caracteres

# CITIES
cities
- id (PK)
- stateId (FK -> states.id) 
- name (120) -- ciudad mas largo contiene 60 caracteres

# ADDRESSES
addresses
- id (PK)
- cityId (FK -> cities.id)
- zipCode
- latitude  -- en cambio de la geoposicion se posee la latitud y longitud
- longitude
- createdBy (FK -> users.id)
- createdAt DATE

# Se requiere la direccion de la orden y su user

# ORDER ADDRESSES 
orderAddresses
- id (PK)
- orderId (FK -> orders.id)
- senderAddressId (FK -> addresses.id)
- receiverAddressId (FK -> addresses.id)
- typeId (FK -> orderAddressTypes.id)
- userId (FK -> usuarios.id)
- postTime
- active (BOOLEAN)

# USER ADDRESSES
userAddresses
- id (PK)
- userId (FK -> users.id)
- addressId (FK -> addresses.id)
- labelId (FK -> userAddressLabels.id)
- isDefault (BOOLEAN)
- active (BOOLEAN)
- createdAt DATE
- checkSum BYTEA --porteccion
- postTime

# Justificacion de la existencia de estos Labels:
# A diferencia de Etherial este agarra o necesita solamente la direccion del usuario y la direccion del pedido para su track

# ORDER ADDRESS TYPES
orderAddressTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- SHIPPING, BILLING
- description varchar(100)

# TRANSPORTE, pues a Dynamic Brands necesita el courier que le dara al usuario lo que pidio

# TRANSPORT
transport
- id (PK)
- transportTypeId (FK -> transportType.Id)
- name varchar(100)
- cityId (FK -> cities.id)
- contactEmail varchar(100)
- phone NUMERICAL

# TRANSPORT TYPE 
transportType
- id (PK)
- code varchar(20) -- PLANE, BOAT, TRUCK

# =========================
# CURRENCIES PATTERN
# =========================

# CURRENCIES
currencies
- id (PK) 
- name varchar(20)
- symbol
- enabled BOOLEAN
- postTime
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
- postTime
- userId (FK -> users.id)
- checkSum BYTEA

# EXCHANGEHISTORY
exchangeHistory
- id (PK)
- fromCurrencyId (FK -> currencies.id)
- toCurrencyId (FK -> currencies.id)
- rateToUsd DECIMAL
- startDateTime DATE
- endDateTime DATE
- postTime
- checkSum BYTEA
- userId (FK -> users.id)
- exchangeRateId (FK -> exchangeRates.id)

# =========================
# TRANSACCIONES FINANCIERAS
# =========================

# TRANSACTIONS
transactions
- id (PK)
- typeId (FK -> transactionTypes.id)
- date DATE
- description varchar(100)
- amount 
- currencyId (FK -> currencies.id)
- relatedOrderId (FK -> orders.id)
- doneBy (FK -> users.id)
- createdAt DATE
- checkSum BYTEA

# 13 Tablas

# ========================================
# Cosas acorde al producto y ordenes
# ==========================================

# A diferencia de Etherial no le interesa los HUbs donde estan los lotes del producto, pero si le interesa de que HUB debe sacar X producto

# HUBS
hubs
- id (PK)
- name varchar(100)
- capacity varchar (100)
- createdBy (FK -> users.id)
- createdAt DATE

# categorias 
categories
- id (PK)
- name varchar(60)

# brands
brands
- id (PK)
- name varchar(60)
- countryId (FK -> countries.id)

# prodcuts
products
- id (PK)
- name varchar(60)
- categoryId (FK -> categories.id)
- brandId (FK -> brands.id)
- hubId (FK -> hubs.id)
- checksum BYTEA
- createdBy (FK -> users.id)
- createdAt DATE

# =========================
# PRECIOS HISTORICOS
# =========================

# Se debe poseer el product prices 
productPrices
- id (PK)
- productId (FK -> products.id)
- price
- currencyId (FK -> currencies.id)
- validFrom
- validTo
- createdAt DATE

# A dynamic Brands solo le interesa la orden para enviarsela al usuario mediante su transporte

# Orders
orders
- id (PK)
- orderNumber
- orderDate
- orderAddressId (FK -> orderAddress.id)
- discountAmount
- taxAmount 
- totalAmount
- currencyId (FK -> currencies.id)
- requestedBy (FK -> users.id)
- createdAt DATE

# TRAZABILIDAD PARA ACTUALIZAR DONDE ESTA LA ORDEN Y MOSTRARSELO AL USUARIO

# Tracing
Tracking
- id (PK)
- orderId (FK -> orders.id)
- transportId  (FK -> transport.id)
- transactionId (FK -> transaction.id)
- timestamp

# 20 Tablas hasta aca

## USERS
users
- id (PK)
- name varchar (100)
- email varchar (100)
- contrasennia BYTEA -- proteccion
- checkSum BYTEA -- proteccion (no me reganniaron de su existencia a si que lo pongo)
- createdAt DATE
- countryId (FK -> country.id)

# LOG IN (puse todo lo del profe, no obstante, revisa si se requiere todo en verdad, eso veremos tras la cita)

# Log types
logTypes
- id (PK)
- code (UNIQUE)   -- USER, AI, SYSTEM, SECURITY
- description

# Event
eventTypes
- id (PK)
- code (UNIQUE)   -- CREATE_ORDER, LOGIN, AI_GENERATION, UPDATE_PRICE
- description

# SEv
severities
- id (PK)
- code (UNIQUE)   -- INFO, WARNING, ERROR, CRITICAL
- level

# Sources
sources
- id (PK)
- code (UNIQUE)   -- BACKEND, FRONTEND, AI_ENGINE, API, BATCH
- description

# DataObjects
dataObjects
- id (PK)
- code (UNIQUE)   -- USER, ORDER, PRODUCT, SITE, AI_MODEL
- description

# logs
logs
- id (PK)

- logTypeId (FK -> logTypes.id)
- eventTypeId (FK -> eventTypes.id)
- severityId (FK -> severities.id)
- sourceId (FK -> sources.id)
- dataObjectId (FK -> dataObjects.id)

- description

- objectId1 BIGINT NULL
- objectId2 BIGINT NULL

- referenceId1 BIGINT NULL
- referenceId2 BIGINT NULL

- referenceDescription

- userId (FK -> users.id, NULL)
- computer BYTEA
- checksum BYTEA

- postTime

# 27 BUUU

# =========================
# SITIOS GENERADOS POR IA
# =========================

sites
- id (PK)
- name
- countryId (FK -> countries.id)
- baseCurrencyId (FK -> currencies.id)
- createdAt

siteConfigurations
- id (PK)
- siteId (FK -> sites.id)
- logoUrl (FK -> logo.id)
- theme
- language (FK -> language.id)
- createdAt

logo
- id (PK)
- code varchar(20)

language
- id (PK)
- code varchar(20) UNIQYUE

# =========================
# IA GENERADORA DE SITIOS
# =========================

aiModels
- id (PK)
- name varchar(20)
- version 

siteGeneration
- id (PK)
- modelId (FK -> aiModels.id)
- countryId (FK -> countries.id)
- inputParameters (JSON)  -- logo, enfoque, etc.
- createdAt

# =========================
# DEMANDA HACIA ETHERIA
# =========================

supplyRequests
- id (PK)
- productId (FK -> products.id)
- countryId (FK -> countries.id)
- requestedQuantity
- createdAt DATE
- checksum BYTEA

# 34 en total