# Mini log de cambios
# Se hicieron las correcciones del profesor

# =========================
# USUARIOS / AUDITORIA
# =========================

## USERS
users
- id (PK)
- name varchar (80)
- email varchar (254)
- contrasennia BYTEA -- proteccion
- checkSum BYTEA -- proteccion (no me reganniaron de su existencia a si que lo pongo)
- createdAt DATE
- createdBy (FK -> users.id)

# ==========================
# LOG (Puesto por solicitud del profesor)
# ==========================

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
# HUB (Centro de Distribucion Costero)
# =========================

# Justificacion de la existencia de estos Labels:
# Una orden o address o importacion puede ir a distintas zonas en especifico, aunque pueden ser definidas por el incoterm, el incoterm posee
# otras caracteristicas mas importantes fuera del destino final o tipo del orden. Estos tipos de orden u oficina definen y dejan de forma 
# trazable lo que se realizo. Es decir, Se realizo una orden que es solo de SHIPPING, y se deja en el PICKUP_POINT del puerto X. El tipo de # incoterm fue FOB. Este incoterm solo da caracteristicas del contrato mas no caracteristicas del tipo de orden ni oficina.


# HUB TYPES
hubTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- MAIN, WAREHOUSE, DISTRIBUTION_CENTER, PICKUP_POINT, RETURN_CENTER
- description varchar(60)

# HUBS  
hubs
- id (PK)
- name varchar(80)
- capacity BIGINT
- addressId (FK -> adresses.id)
- typeId (FK -> hubTypes.id)
- createdBy (FK -> users.id)
- createdAt DATE

# HUB ZONES
hubZones
- id (PK)
- hubId (FK -> hub.id)
- code varchar(20) (UNIQUE)   -- STORAGE, RECEIVING_AREA
- description varchar(60)

# sitio donde esta el producto DENTRO de hub
# HUBLOCATIONS 
hubLocations
- id (PK)
- hubId (FK -> hubs.id)
- zone (FK -> zone.id)
- rack varchar(20) 
- level varchar(20) 
- checkSum BYTEA

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



# Order Addresses y Types esta con las OrderTables

# =========================
# PROVEEDORES
# =========================

# Suppliers
suppliers
- id (PK)
- name varchar(100)
- countryId (FK -> countries.id)
- createdAt DATE
- enabled BOOLEAN

# supplierContacts
supplierContacts
- id (PK)
- supplierId (FK -> suppliers.id)
- contactName varchar(100)
- email varchar(254)
- phone varchar(15)
- regionalCode varchar(3)

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
- description varchar(20) (UNIQUE) -- bottles, pair

# UNIT OF MEASUREMENT
unitMeasurement
- id (PK)
- description varchar(20) (UNIQUE) -- cm, dl, om

# PRODUCT CHARACTERISTICS (Pedido por profesor)
# Catalogo de caracteristicas variables que puede tener un producto.
# Ejemplo: color, material, tamaño, capacidad, RAM, CPU

productCharacteristics
- id (PK)
- name varchar(60)

# Se decidio meter el quantityTYpe dentro de productos, asi los lotes solo poseerian un quantity Numerical y no les importaria el tipo, pues ya esta en el producto.

# prodcuts , -- agreguemos un description más amplio y usa modelo de caracteristicas variables que asocias a las categorias tambien. metele el precio actual con currency y exchagerate para que no haya que ir a consultarlo al historico 
products
- id (PK)
- name varchar(60)
- description varchar(500)
- brandId (FK -> brands.id)
- supplierId (FK -> suppliers.id)
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

# CATEGORYPERPRODUCT
categoryperproduct
- id (PK)
- categoryId (FK -> categories.id)
- productId (FK -> products.id)

# PRODUCT CHARACTERISTIC PER PRODUCT
# Relacion entre el producto y sus caracteristicas variables.
# Producto Laptop -> RAM = 16GB (Para cumplir con lo pedido, creo que se hizo con esto)

productCharacteristicPerProduct
- id (PK)
- productId (FK -> products.id)
- productCharacteristicId (FK -> productCharacteristics.id)
- value varchar(100)

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


# =========================
# INVENTARIO Y LOTES
# =========================

# Debido a que son por lotes los productos, y Etheria se le indica cuanto debe entonces se va por Lotes
# el precio esta congelado 

# Product Lots 
# Debe poseer el monto y en la moneda original el lote
productLots 
- id (PK)
- productId (FK -> products.id)
- supplierId (FK -> suppliers.id)
- hubId (FK -> hubs.id)
- quantity NUMERICAL
- unitCost DECIMAL
- currencyId (FK -> currency.id)
- arrivalDate DATE
- checksum BYTEA
- createdAt DATE

# Se decidio separar mejor, lo que contiene es las diferentes direcciones de los lotes. Dentro del HUB
lotLocations
- id (PK)
- lotId (FK -> productLots.id)
- hubLocationId (FK -> hubLocations.id)
- quantity NUMERICAL

# Transformaciones que puede sufrir el lote
# Debido a que en un HUB pueden suceder combinaciones o separaciones o accidentes se debe llevar un registro
# de las transformaciones que sufre el lote entonces, esto es lo que soluciona estas 4 tablas

# LOT MOVEMENT TYPES
# Tipos de movimientos que puede tener un lote. (Normalizacion)

lotMovementTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- IN, OUT, TRANSFER, ADJUSTMENT, RESERVE, RELEASE
- description varchar(60)

# LOT MOVEMENTS
# Registra cada movimiento realizado sobre un lote sin modificar
# el registro original de productLots.
# Se maneja con enfoque append-only, donde cada cambio se guarda
# como un nuevo registro mediante INSERT, manteniendo trazabilidad
# completa del inventario y su historial. (agregado por el profe)

lotMovements
- id (PK)
- lotId (FK -> productLots.id)
- movementTypeId (FK -> lotMovementTypes.id)
- fromHubLocationId (FK -> hubLocations.id) allows null
- toHubLocationId (FK -> hubLocations.id) allows null
- quantity DECIMAL
- referenceType varchar(30) allows null
- referenceId BIGINT allows null
- timestamp TIMESTAMP
- createdBy (FK -> users.id)
- checkSum BYTEA


# tipos de transformacion
transformationTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- SPLIT, MERGE, REPACK, LOSS, ADJUSTMENT
- description varchar(40)

# Trabsformations
lotTransformations
- id (PK)
- transformationTypeId (FK -> transformationTypes.id)
- performedBy (FK -> users.id)
- timestamp TIMESTAMP
- checkSum BYTEA
# quiantity es cantidad del producto
# Como un lote se puede separar en dos o mas entonces aca se da la informacion 
# En esta entra un lote llamemoslo A (con 100 de cantidad de producto) su transformacion es tipo SPLIT hecha por Paco un abril 3

# Inputs
lotTransformationInputs
- id (PK)
- transformationId (FK → lotTransformations.id)
- lotId (FK → productLots.id)
- quantity NUMERICAL

# Luego se separa en dos partes uno B y C de diferente cantidad del mismo producto 60 y 40 respectivamente. Se traza la separacion.
# Outputs
lotTransformationOutputs
- id (PK)
- transformationId (FK → lotTransformations.id)
- lotId (FK → productLots.id)
- quantity NUMERICAL 


# =========================
# INCOTERMS
# =========================

incoterms
- id (PK)
- code varchar(10) (UNIQUE)
- description varchar(100)

# ===================
# ESTADO
# ====================
status
- id (PK)
- code varchar(20) (UNIQUE) -- Puerto etc

# =========================
# ORDENES
# =========================

# Ordenes
 
orders
- id (PK)
- orderNumber decimal
- incotermId (FK -> incoterms.id)
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

# Este posee las taxes especificas de los productos
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
- description varchar(60)
- createdAt DATE
- createdBy (FK -> users.id)

# TRANSACTIONS (modificado segun profesor)
transactions
- id (PK)
- typeId (FK -> transactionTypes.id)
- date DATE
- description varchar(80)
- amount DECIMAL
- currencyId (FK -> currencies.id)
- exchangeRateId (FK -> exchangeRates.id)
- relatedOrderId (FK -> orders.id) allows null
- referenceType varchar(30) allows null
- referenceId BIGINT allows null
- externalReference varchar(80) allows null
- createdBy (FK -> users.id)
- createdAt DATE
- checkSum BYTEA

# =========================
# TRAZABILIDAD
# =========================

# Emula los movimientos de transporte y de los tipos de transporte
lotShipments
- id (PK)
- lotId (FK -> productLots.id)
- carrierId (FK -> carriers.id)
- transportUnitId (FK -> transportUnits.id) allows null
- fromAddressId (FK -> addresses.id)
- toAddressId (FK -> addresses.id)
- departureDate DATE
- estimatedArrivalDate DATE allows null
- arrivalDate DATE allows null
- statusId (FK -> status.id)
- trackingNumber serial increment
- createdAt DATE
- createdBy (FK -> users.id)
- checkSum BYTEA

# Con esto el tracking posee
# que transporta, su estatus, donde esta, quien lo lleva, a donde va al final, que incoterm posee
# Ademas de ello el tracking posee indirectmente con lotShipments los lotes que se estan transportando.
tracking
- id (PK)
- orderId (FK -> orders.id)
- orderAddressId (FK -> orderAddresses.id)
- statusId (FK -> status.id)
- carrierId (FK -> carriers.id) allows null
- transportUnitId (FK -> transportUnits.id) allows null
- handledBy (FK -> users.id)
- transactionId (FK -> transactions.id) allows null
- timestamp TIMESTAMP
- lotShipmentId (FK -> lotShipments.id)
- notes varchar(150) allows null