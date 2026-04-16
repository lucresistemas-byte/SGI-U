# SGI-U Backend - Sistema de Gestión Integral

Backend robusto desarrollado con **Spring Boot 3.5.13** y **Java 21**. Esta API REST centraliza la lógica de negocio para la gestión de productos, inventario, ventas y movimientos financieros, optimizando las operaciones de emprendedores locales.

---

## Características Principales

* **Catálogo "Caja Negra":** Endpoint optimizado con cálculo de stock proyectado en tiempo real.
* **Gestión de Inventario:** Control granular de existencias mediante `ArticuloStock`.
* **Módulo Transaccional:** Procesamiento de ventas con múltiples líneas de detalle y registro de pagos.
* **Flujo Financiero:** Seguimiento automático de ingresos y egresos vinculados a la caja.
* **Auditoría Nativa:** Trazabilidad completa (`created_at`, `updated_at`) mediante **JPA Auditing**.
* **Arquitectura:** Diseño por capas (Controller-Service-Repository) con uso de DTOs (Java Records).

---

## Stack Tecnológico

* **Lenguaje:** Java 21 (LTS)
* **Framework:** Spring Boot 3.5.13
* **Persistencia:** Spring Data JPA + Hibernate
* **Base de Datos:** MariaDB (Producción/Dev) & H2 (Testing)
* **Contenedores:** Docker & Docker Compose
* **Documentación/Salud:** Spring Boot Actuator

---

## Estructura del Proyecto

```text
backend/sgiu/
├── src/main/java/com/sgiu_group/sgiu/
│   ├── config/         # Seguridad, CORS y JPA Auditing
│   ├── controllers/    # Endpoints REST
│   ├── services/       # Lógica de negocio y transaccionalidad
│   ├── repositories/   # Consultas JPA (Derivadas y @Query)
│   └── models/
│       ├── entities/   # Entidades del dominio
│       ├── dtos/       # Data Transfer Objects (Records)
│       └── base/       # Clases abstractas y auditoría
└── src/main/resources/
    ├── application.yml # Configuración de perfiles
    └── data.sql        # Seed de datos (5 productos iniciales)
```

---

## Configuración y Despliegue

### 1. Variables de Entorno
Crea un archivo `.env` en la raíz del proyecto (basado en el ejemplo siguiente):

```ini
MARIADB_ROOT_PASSWORD=Lucio1234
MARIADB_DATABASE=sgiu_db
MARIADB_USER=sgiu_user
MARIADB_PASSWORD=sgiu_1234
```

### 2. Ejecución con Docker (Recomendado)
Levanta la infraestructura completa (BD + API) con un solo comando:

```bash
docker compose up -d --build
```

* **API:** `http://localhost:8080`
* **BD:** `localhost:3306`
* **CORS:** Habilitado para `http://localhost:5173` (Frontend default)

### 3. Ejecución Local (Maven)
Si prefieres correrlo sin Docker para desarrollo rápido:

```bash
./mvnw clean spring-boot:run
```

---

## API Reference - Catálogo

### Obtener Productos (Caja Negra)
Retorna el catálogo unificado con el stock actual calculado.

`GET /api/productos`

**Response Example (200 OK):**
```json
[
  {
    "codigo": "PROD-001",
    "nombre": "Producto PROD-001",
    "precioUnitario": 1500.0,
    "stockActual": 25
  }
]
```

---

## Verificación y Troubleshooting

### Comandos de Verificación
```bash
# Health Check del Sistema
curl -s http://localhost:8080/actuator/health

# Listado rápido de productos
curl -s http://localhost:8080/api/productos
```

### Solución de Problemas Comunes

| Síntoma | Posible Causa | Solución |
| :--- | :--- | :--- |
| **Error de Conexión BD** | Contenedor MariaDB caído | `docker compose ps` y verificar logs. |
| **SemanticException** | Error en HQL/JPQL | Revisar las rutas de los DTOs en las `@Query`. |
| **Datos no persisten** | Volumen eliminado | Evitar `docker compose down -v` si deseas mantener la BD. |
| **Error de Compilación** | Binarios antiguos | Ejecutar `./mvnw clean compile`. |

---

> [!NOTE]
> **Datos iniciales:** Al iniciar, el sistema carga automáticamente 5 productos de prueba (`PROD-001` a `PROD-005`) con stock precargado para facilitar el testing del frontend.