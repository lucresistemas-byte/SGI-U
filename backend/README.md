# Infraestructura de Base de Datos - SGI-U

Este repositorio contiene la configuración necesaria para desplegar una instancia de MariaDB mediante Docker Compose, garantizando un entorno de desarrollo aislado y persistente.

## Requisitos del Sistema

* Docker Engine 20.10+
* Docker Compose V2
* Cliente SQL (ej. DBeaver, TablePlus o entorno de consola)

## Configuración de Variables de Entorno

El despliegue depende de un archivo `.env` ubicado en la raíz del proyecto. Este archivo no debe ser incluido en el control de versiones. Se deben definir las siguientes variables:

* MARIADB_ROOT_PASSWORD: Contraseña del superusuario root.
* MARIADB_DATABASE: Nombre de la base de datos inicial.
* MARIADB_USER: Nombre del usuario para la aplicación.
* MARIADB_PASSWORD: Contraseña del usuario de la aplicación.

## Instrucciones de Despliegue

Para iniciar el contenedor en modo segundo plano (detached), ejecute:

docker compose up -d

### Gestión del Ciclo de Vida

* Detener servicios: docker compose stop
* Detener y eliminar contenedores/redes: docker compose down
* Eliminar contenedores y volúmenes de datos: docker compose down -v
* Ver estado de salud del servicio: docker ps

## Parámetros de Conexión

La base de datos es accesible a través de los siguientes parámetros:

* Host: localhost
* Puerto: 3306
* Motor: MariaDB 10.11

## Estructura de Persistencia

Se ha configurado un volumen de Docker denominado 'mariadb_data' que mapea al directorio interno '/var/lib/mysql'. Esto asegura que la información de las tablas y registros permanezca disponible tras el reinicio o la recreación del contenedor.

## Monitoreo y Logs

Para auditar el comportamiento del servidor de base de datos o diagnosticar errores de conexión, utilice:

docker logs -f sgiu-mariadb
