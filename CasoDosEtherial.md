# Log de cambios en comparacion de la v2:
# Se elimino user addres types y user addresses, pues la demanda viene DESDE, Dynamic Brands, Etherial solo importa a Nicaragua a oficinas (HUBS) en especifico. Los cuales se mantuvieron por escalabilidad.
# Se elimino la tabla de roles, pues, Dynamic Brands es quien tiene usuarios diferentes no Etherial

# A todas las descripciones les puse 100, no se si es mucho o poco. (Ante la duda 100 ayuda, no 50, 50 es muy IApoco)
# Hice uso de CODE en lugar de nombre varchar, se supone que es mejor y mas escalable cuando se supone que cada tipo es UNIQUE.
# Queda de 39 tablas.

# Flujo:
# Usuario desde Dyanmic Brands pide importacion - se define orden, producto, contrato, precios impuestos y transaccion - se realiza address # pattern segun incoterm hasta final

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

# Tipos de Addresses que vienen en el Address Pattern


# EL userId se pone aca pues no necesariamente la direccion del que pidio la orden es la direccion a la que debe llegar. Desde Panama puedo pedir un envio a CR

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

# OFFICE ADDRESSES
officeAddresses
- id (PK)
- hubId (FK -> hubs.id)
- addressId (FK -> addresses.id)
- typeId (FK -> officeTypes.id)

# Justificacion de la existencia de estos Labels:
# Una orden o address o importacion puede ir a distintas zonas en especifico, aunque pueden ser definidas por el incoterm, el incoterm posee
# otras caracteristicas mas importantes fuera del destino final o tipo del orden. Estos tipos de orden u oficina definen y dejan de forma 
# trazable lo que se realizo. Es decir, Se realizo una orden que es solo de SHIPPING, y se deja en el PICKUP_POINT del puerto X. El tipo de # incoterm fue FOB. Este incoterm solo da caracteristicas del contrato mas no caracteristicas del tipo de orden ni oficina.


# OFFICE TYPES
officeTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- MAIN, WAREHOUSE, DISTRIBUTION_CENTER, PICKUP_POINT, RETURN_CENTER
- description varchar(100)

# ORDER ADDRESS TYPES
orderAddressTypes
- id (PK)
- code varchar(20) (UNIQUE)   -- SHIPPING, BILLING
- description varchar(100)

# ========================= =========================================
# TRANSPORTE 
# Esta dentro de Address asi que debe existir

# Para hacer escalabilidad se decidio simplificar puertos y aeropuertos en transporte y los couriers, por si deciden hacer un dia un 
# uberImportacionEats O hacen avances tecnologicos (REVISALO)

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
# USUARIOS / AUDITORIA
# =========================


## USERS
users
- id (PK)
- name varchar (100)
- email varchar (100)
- contrasennia BYTEA -- proteccion
- checkSum BYTEA -- proteccion (no me reganniaron de su existencia a si que lo pongo)
- createdAt DATE




# =========================
# HUB (Centro de Distribucion Costero)
# =========================

# HUBS
hubs
- id (PK)
- name varchar(100)
- capacity varchar (100)
- createdBy (FK -> users.id)
- createdAt DATE

# sitio donde esta el producto DENTRO de hub
# HUBLOCATIONS
hubLocations
- id (PK)
- hubId (FK -> hubs.id)
- zone varchar(20) 
- rack varchar(20) 
- level varchar(20) 
- checkSum BYTEA

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

# Justificacion: Se dice que debe estar prrsente en documento dado por el profe.

# TRANSACTION TYPES
transactionTypes
- id (PK)
- code (UNIQUE)   -- SALE, PURCHASE, SHIPPING_COST, TAX
- description

# TRANSACTIONS
transactions
- id (PK)
- typeId (FK -> transactionTypes.id)
- date DATE
- description varchar(100)
- amount   -- positivo ingreso, negativo egreso
- currencyId (FK -> currencies.id)
- relatedOrderId (FK -> orders.id)
- createdBy (FK -> users.id)
- createdAt DATE
- checkSum BYTEA

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
- email varchar(60)
- phone NUMERICAL


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

# prodcuts
products
- id (PK)
- name varchar(60)
- categoryId (FK -> categories.id)
- brandId (FK -> brands.id)
- supplierId (FK -> suppliers.id)
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


# =========================
# INVENTARIO Y LOTES
# =========================

# Debido a que son por lotes los productos, y Etheria se le indica cuanto debe entonces se va por Lotes
# el precio esta congelado 

# Product Lots
# Debe poseer el monto y en la moneda original el lote
productLots
- id
- productId (FK -> products.id)
- supplierId (FK -> suppliers.id)
- hubId (FK -> hubs.id)
- quantity
- unitCost
- currencyId
- arrivalDate
- checksum
- createdAt

# Se decidio separar mejor, lo que contiene es las diferentes direcciones de los lotes. Dentro del HUB
lotLocations
- id (PK)
- lotId (FK -> productLots.id)
- hubLocationId (FK -> hubLocations.id)
- quantity


# Transformaciones que puede sufrir el lote
# Debido a que en un HUB pueden suceder combinaciones o separaciones o accidentes se debe llevar un registro
# de las transformaciones que sufre el lote entonces, esto es lo que soluciona estas 4 tablas

# tipos de transformacion
transformationTypes
- id (PK)
- code (UNIQUE)   -- SPLIT, MERGE, REPACK, LOSS, ADJUSTMENT
- description varcha(40)

# Trabsformations
lotTransformations
- id (PK)
- transformationTypeId (FK -> transformationTypes.id)
- performedBy (FK -> users.id)
- timestamp
- checkSum BYTEA
# quiantity es cantidad del producto
# Como un lote se puede separar en dos o mas entonces aca se da la informacion 
# En esta entra un lote llamemoslo A (con 100 de cantidad de producto) su transformacion es tipo SPLIT hecha por Paco un abril 3

# Inputs
lotTransformationInputs
- id (PK)
- transformationId (FK → lotTransformations.id)
- lotId (FK → productLots.id)
- quantity

# Luego se separa en dos partes uno B y C de diferente cantidad del mismo producto 60 y 40 respectivamente. Se traza la separacion.
# Outputs
lotTransformationOutputs
- id (PK)
- transformationId (FK → lotTransformations.id)
- lotId (FK → productLots.id)
- quantity


# =========================
# INCOTERMS
# =========================

incoterms
- id (PK)
- code varchar(10)
- description varchar(100)


# =========================
# ORDENES
# =========================

# Ordenes

 
orders
- id (PK)
- orderNumber
- incotermId (FK -> incoterms.id)
- orderDate
- statusId (FK -> status.id)
- discountAmount
- taxAmount -- SUM de todas las taxes
- totalAmount
- currencyId (FK -> currencies.id)
- createdBy (FK -> users.id)
- createdAt

# ESTADO
status
- id (PK)
- code varchar(20)  -- Puerto etc

# Items de la orden, la order puede poseer multiples suppliers, no se pone lote pues el lote se crea despues pues es un metodo de entrega.
# Primero se piden los items, y luego se entregan en lotes del HUB y finalmente se envian asi, pero la orden solo se sabe que se pidieron x 
# de tal producto

orderItems
- id (PK)
- orderId (FK → orders.id)
- productId (FK → products.id)
- quantity
- unitPrice
- discount
- orderItemTaxesId (FK -> orderItemsTaxes.id)
- amount

# Este posee las taxes especificas de los productos
orderItemTaxes
- id (PK)
- orderItemId (FK -> orderItems.id)
- taxTypeId (FK -> taxTypes.id)
- percentage
- amount


# =========================
# TRAZABILIDAD
# =========================

# Con esto el tracking posee
# que transporta, su estatus, donde esta, quien lo lleva, a donde va al final, que incoterm posee
# Ademas de ello el tracking posee indirectmente con lotShipments los lotes que se estan transportando.
Tracking
- id (PK)
- orderId (FK -> orders.id)
- orderAddressId (FK -> orderAddress.id)
- statusId (FK -> status.id)
- transportId  (FK -> transport.id)
- handledBy (FK -> users.id)
- transactionId (FK -> transaction.id)
- timestamp
- lotShipmentsId (FK -> lotShipments.id)

# Emula los movimientos de transporte y de los tipos de transporte
lotShipments
- id (PK)
- lotId (FK -> productLots.id)
- transportId (FK -> transport.id)
- fromAddressId (FK -> addresses.id)
- toAddressId (FK -> addresses.id)
- departureDate
- arrivalDate
- statusId (FK -> status.id)
- trackingNumber

# =========================
# IMPUESTOS
# =========================

# Datos historicos de los paises

taxTypes
- id (PK)
- code (UNIQUE)  -- VAT, IMPORT_DUTY, SALES_TAX
- description

countryTaxes
- id (PK)
- countryId (FK -> countries.id)
- taxTypeId (FK -> taxTypes.id)
- percentage
- validFrom
- validTo



