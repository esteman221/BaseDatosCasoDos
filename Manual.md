
Manual de Instalación
=====================

# Puntos Clave
    * Se agregó el Manual de instalación para:
    *   - Setear el contenedor
    *   - Setear el pgAdmin
    *       - Conexión pgAdmin con PostgreSQL
    *       - Setear el PostgreSQL
    *       - Crear BD y Tablas
    *       - Llenar Tablas
    *   - Setear el phpMyAdmin
    *       - Conexión phpMyAdmin con MySQL
    *       - Setear el MySQL
    *       - Crear BD y Tablas
    *       - Llenar Tablas

<h2>Setear el contenedor</h2>

En la carpeta del proyecto usar los siguientes comandos:
    * docker compose up -d

* * * 

<h2>Setear el pgAdmin</h2>


En el navegador abrir el enlace [http://localhost/browser/]
Si pide registro, estas son las credenciales:
    * Usuario: admin@correo.com
    * Pass: 123

<h3>Conexión pgAdmin con PostgreSQL</h3>

    * En la barra de la izquierda, click derecho sobre Servers y seleccionar Register > Server
    * Ponerle nombre a gusto
    * Ir a la pestañita de connection
    * Host name: postgres
    * Port: 5432
    * Username: root
    * Password: root











    http://localhost:8080/index.php