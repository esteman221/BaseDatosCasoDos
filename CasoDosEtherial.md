# A todas las descripciones les puse 100, no se si es mucho o poco. (Ante la duda 100 ayuda, no 50, 50 es muy IApoco)
# Hice uso de CODE en lugar de nombre varchar, se supone que es mejor y mas escalable cuando se supone que cada tipo es UNIQUE.

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

# EL userId se pone aca pues no necesariamente la direccion del que pidio la orden es la direccion a la que debe llegar. Desde Panama puedo pedir un envio a CR
# ORDER ADDRESSES 
orderAddresses
- id (PK)
- orderId (FK -> orders.id)
- senderAddressId (FK -> addresses.id)
- receiverAddressId (FK -> addresses.id)
- typeId (FK -> orderAddressTypes.id)
- userId
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

# Los users labels solo existen porque me dio TOC, aunque su unico uso podria ser para empresas no separadas legalmente de su duennio,
# haciendo que el duennio/usuario tenga que hacer las importaciones a su nombre y direccion propia. Ademas de caracteristicas escalables
# para una hipotetica GUI.

# USER ADDRESS LABELS
userAddressLabels
- id (PK)
- code varchar(20) (UNIQUE)   -- HOME, WORK, OFFICE
- description varchar(100)

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

# usuarios, simplemente separados de los auditores por un simple rol
## USERS
users
- id (PK)
- name varchar (100)
- email varchar (100)
- roles.id (FK -> roles.id)
- contrasennia BYTEA -- proteccion
- checkSum BYTEA -- proteccion (no me reganniaron de su existencia a si que lo pongo)
- createdAt DATE

# permite la separacion entre auditor y usuario normal
# ROLES
roles
- id (PK)
- code varchar(20) (UNIQUE)
- description varchar(100)


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

# TODO: todo lo demas BUUU (exchange pattern, incoterms, transactions etc)
