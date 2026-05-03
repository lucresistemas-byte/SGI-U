# SGI-U: Sistema de Gestion Inteligente Unificado

Primera version estable (MVP) del sistema de gestion comercial. Incluye catalogo de productos, punto de venta y motor transaccional con control de stock.

**Stack:** Flutter (Frontend) | Spring Boot / Java (Backend) | MariaDB (Base de Datos)

---

## Funcionalidades del MVP

- Catalogo dinamico de productos conectado a la base de datos en tiempo real.
- Interfaz de Punto de Venta (POS) con manejo de carrito de compras.
- Motor transaccional atomico: registra la venta, los movimientos financieros y descuenta el stock de forma simultanea.
- Validaciones de seguridad: limite de stock, carritos vacios y metodos de pago.

---

## Estructura del Repositorio

```
/sgi-u-monorepo
├── /frontend                  # Proyecto Flutter (Dart)
│   └── /lib
│       ├── /blocs             # Logica de presentacion y estado
│       ├── /screens           # Pantallas (POS)
│       ├── /widgets           # Componentes UI reutilizables
│       ├── /models            # Clases de datos en Dart
│       └── /services          # Clientes HTTP para consumir la API
│
├── /backend                   # Proyecto Spring Boot (Java)
│   └── /src/main/java/com/sgiu
│       ├── /controllers       # Endpoints REST
│       ├── /services          # Reglas de negocio y transaccionalidad
│       ├── /repositories      # Interfaces JPA (MariaDB)
│       └── /models            # Entidades de base de datos
│
├── .env                       # (No rastreado) Variables de entorno y credenciales
└── README.md
```

> No subir archivos `.env`, carpetas `target/`, `build/` ni `mariadb_data/`.

---

## API: Contratos de Integracion

### GET /api/productos
Retorna la lista de productos con stock actual.

```json
[
  {
    "codigo": "PROD-001",
    "nombre": "Arroz Integral 1kg",
    "precioUnitario": 100.00,
    "stockActual": 47
  }
]
```

### POST /api/ventas
Registra una transaccion. Retorna `201 Created` en caso de exito o `400 Bad Request` si hay errores de validacion (falta de stock, carrito vacio, etc.).

```json
{
  "metodoPago": "EFECTIVO",
  "lineas": [
    { "codigoProducto": "PROD-001", "cantidad": 3 },
    { "codigoProducto": "PROD-005", "cantidad": 1 }
  ]
}
```

---

## Flujo de Trabajo con Git

### Ramas principales

| Rama | Proposito |
|------|-----------|
| `main` | Produccion. No se permiten commits ni pushes directos. |
| `develop` | Integracion y pruebas. Base para todo desarrollo. |

### Ramas de trabajo

Todo desarrollo parte de `develop`. Nomenclatura obligatoria:

- `feat/[numero-issue]-[descripcion]` — nuevas funcionalidades
- `fix/[numero-issue]-[descripcion]` — correccion de errores

Ejemplos validos: `feat/5-post-registro-venta`, `fix/25-integracion`

### Convencion de commits

Seguimos el estandar [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: agrega buscador de productos en POS
fix: corrige calculo del subtotal con numeros negativos
docs: actualiza instrucciones de instalacion
refactor: optimiza controlador de ventas
```

### Pull Requests

Nadie fusiona su propio codigo. El flujo es:

1. Abrir un PR desde la rama de trabajo hacia `develop`.
2. Describir la solucion e incluir referencia al issue.
3. Al menos un miembro del equipo (distinto al autor) debe aprobar el PR antes del merge.

### Comandos habituales

```bash
# Antes de empezar a trabajar
git checkout develop
git pull origin develop

# Crear rama y registrar trabajo
git checkout -b feat/nueva-tarea
git add .
git commit -m "feat: descripcion del cambio"
git push -u origin feat/nueva-tarea
```

> No usar `git push --force`. No commitear codigo que impida la compilacion. Resolver conflictos localmente antes de actualizar el PR.
