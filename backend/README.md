
# SGI-U Backend - Sistema de Gestión Integral

Backend desarrollado con Spring Boot 3.5.13 y Java 21. Provee una API REST para gestionar productos, inventario, ventas y movimientos financieros.

## Características

- Gestión de especificaciones de productos
- Control de inventario en tiempo real
- Procesamiento de ventas y pagos
- Registro de movimientos financieros
- Auditoría automática
- Despliegue con Docker Compose
- Base de datos H2 (testing) y MariaDB (desarrollo)

## Requisitos Previos

- Java JDK 21
- Maven 3.6+
- Docker Engine 20.10+ y Docker Compose V2

## Configuración

### Variables de Entorno (archivo `.env`)

```
MARIADB_ROOT_PASSWORD=Lucio1234
MARIADB_DATABASE=sgiu_db
MARIADB_USER=sgiu_user
MARIADB_PASSWORD=sgiu_1234
```

> **Importante**: El archivo `.env` no debe versionarse.

## Instalación y Ejecución

### Opción A: Docker Compose (Recomendada)

```bash
docker compose up -d
```

- Backend API: `http://localhost:8080`
- MariaDB: `localhost:3306`

**Comandos útiles:**

| Acción | Comando |
|--------|---------|
| Ver estado | `docker compose ps` |
| Detener | `docker compose stop` |
| Ver logs | `docker compose logs -f backend` |
| Eliminar (conservando datos) | `docker compose down` |
| Eliminar todo | `docker compose down -v` |

### Opción B: Maven Local

```bash
cd backend/sgiu/
./mvnw clean package
./mvnw spring-boot:run
```

## Estructura del Proyecto

```
backend/
├── sgiu/
│   ├── src/main/java/com/sgiu_group/sgiu/
│   │   ├── config/
│   │   ├── models/
│   │   │   ├── entities/
│   │   │   ├── base/
│   │   │   └── audit/
│   │   └── repositories/
│   └── resources/
│       ├── application.yml
│       └── data.sql
├── Dockerfile
├── docker-compose.yml
└── .env
```

## Modelo de Datos

| Entidad | Descripción |
|---------|-------------|
| `EspProducto` | Especificación técnica y precio de un producto |
| `ArticuloStock` | Inventario disponible por producto |
| `Venta` | Encabezado de una transacción de venta |
| `LineaVenta` | Detalle de productos dentro de una venta |
| `PagoVenta` | Pagos asociados a una venta |
| `MovFinanciero` | Movimientos de caja/banco (ingresos y egresos) |

## Sistema de Auditoría

Todas las entidades heredan de `BaseEntity`, que incluye `created_at` y `updated_at` gestionados automáticamente por JPA.

## Datos Iniciales

Se cargan automáticamente desde `data.sql` al iniciar:

- 5 productos (`PROD-001` a `PROD-005`) con precios entre $75.25 y $320.00
- Stock inicial entre 20 y 100 unidades por producto

## Verificación Post-Instalación

```bash
# Health check
curl -s http://localhost:8080/actuator/health

# Listar productos
curl -s http://localhost:8080/api/esp-productos
```

## Solución de Problemas

| Síntoma | Solución |
|---------|----------|
| Error de conexión a BD | Verificar `docker compose ps mariadb` y credenciales en `.env` |
| Puerto 8080 en uso | `lsof -i :8080` → `kill -9 <PID>` |
| Datos no persisten | No usar `docker compose down -v` |
| OutOfMemoryError en Maven | `export MAVEN_OPTS="-Xmx2g"` |

---

**Stack:** Spring Boot 3.5.13, Java 21, MariaDB 
