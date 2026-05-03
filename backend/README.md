# SGI-U Backend - Sistema de Gestión Integral

Backend robusto desarrollado con **Spring Boot 3.5.13** y **Java 21**. Esta API REST centraliza la lógica de negocio para la gestión de productos, inventario, ventas y movimientos financieros, optimizando las operaciones de emprendedores locales.

---

## Características Principales

* **Motor Transaccional (Nuevo):** Procesamiento de ventas atómico que garantiza la integridad entre inventario, ventas y finanzas.
* **Catálogo "Caja Negra":** Endpoint optimizado con cálculo de stock proyectado en tiempo real.
* **Gestión de Inventario:** Control granular de existencias mediante `ArticuloStock`.
* **Flujo Financiero:** Registro automático de **Ingresos** en `MovFinanciero` tras cada venta confirmada.
* **Auditoría Nativa:** Trazabilidad completa (`created_at`, `updated_at`) mediante **JPA Auditing**.
* **Arquitectura:** Diseño por capas (Controller-Service-Repository) con uso de DTOs (Java Records).

---

## Estructura del Proyecto

```text
backend/sgiu/
├── src/main/java/com/sgiu_group/sgiu/
│   ├── config/         # Seguridad, CORS y JPA Auditing
│   ├── controllers/    # Endpoints REST (VentaController agregado)
│   ├── services/       # Lógica transaccional (VentaService con @Transactional)
│   ├── repositories/   # Consultas JPA (ArticuloStockRepository actualizado)
│   └── models/
│       ├── entities/   # Entidades (Venta, LineaVenta, PagoVenta, MovFinanciero)
│       ├── dtos/       # Data Transfer Objects (VentaRequestDTO, LineaVentaDTO)
│       └── base/       # Clases abstractas y auditoría
```

---

## API Reference - Módulos Principales

### 1. Catálogo de Productos
`GET /api/productos` -> Retorna el catálogo unificado con stock calculado.

### 2. Motor de Ventas (Transaccional)
`POST /api/ventas` -> Registra una venta completa y actualiza el sistema.

**Reglas de Negocio Implementadas:**
* **RN02 (Validación de Stock):** Si la cantidad solicitada supera el stock actual, se lanza una excepción y se ejecuta un **rollback** automático de toda la operación.
* **RN05 (Integridad de Precios):** El sistema ignora precios enviados por el frontend; consulta y recalcula subtotales basándose exclusivamente en el `precio_unitario` de la base de datos.

**Request Example (201 Created):**
```json
{ 
  "metodoPago": "EFECTIVO", 
  "lineas": [ 
    { "codigoProducto": "PROD-001", "cantidad": 3 } 
  ] 
}
```

---

## Configuración y Despliegue

### 1. Ejecución con Docker (Recomendado)
```bash
docker compose up -d --build
```

### 2. Ejecución Local (Maven)
```bash
./mvnw clean spring-boot:run
```

---

## Verificación y Troubleshooting

### Comandos de Verificación
```bash
# Health Check del Sistema
curl -s http://localhost:8080/actuator/health

# Probar registro de venta (Linux/Bash)
curl -X POST http://localhost:8080/api/ventas \
     -H "Content-Type: application/json" \
     -d '{"metodoPago":"EFECTIVO","lineas":[{"codigoProducto":"PROD-001","cantidad":1}]}'
```

### Solución de Problemas Comunes

| Síntoma | Posible Causa | Solución |
| :--- | :--- | :--- |
| **Error 400 en Ventas** | Stock insuficiente (RN02) | Verificar existencias en `articulos_stock`. |
| **Compilation Error (Autowired)** | Falta de imports en Service/Controller | Usar inyección por constructor o importar `org.springframework.beans.factory.annotation.Autowired`. |
| **Error de Conexión BD** | Contenedor MariaDB caído | `docker compose ps` y verificar logs. |

---

> [!NOTE]
> **Integridad Referencial:** Cada venta genera automáticamente registros vinculados en las tablas `ventas`, `lineas_venta`, `pagos_venta` y `movimientos_financieros` de forma indivisible.
