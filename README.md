# SGI-U: Sistema de Gestión Inteligente Unificado

Bienvenido al repositorio central de SGI-U. Este documento establece las directrices arquitectónicas y el protocolo de control de versiones para el desarrollo del Mínimo Producto Viable (MVP). 

Todos los integrantes del equipo (Amarilla, Chesani, Czajkowski y Mencia) deben adherirse estrictamente a estas normativas para garantizar la integridad del código, evitar conflictos destructivos y mantener un flujo de integración continuo.

---

## 1. Protocolo de Trabajo en GitHub

Para mantener la estabilidad del sistema, utilizamos un flujo de trabajo basado en la integración continua sobre una rama de desarrollo.

### 1.1. Estructura de Ramas Principales

* **main**: Representa el entorno de Producción. Es sagrada. Queda estrictamente prohibido hacer un commit o un push directo a esta rama. El código en `main` debe compilar perfectamente y estar libre de errores críticos.
* **develop**: Representa el entorno de Integración y Pruebas. Todas las nuevas funcionalidades y correcciones convergen aquí. Es la rama base para el trabajo diario.

### 1.2. Estrategia de Ramas de Trabajo (Feature Branches)

Todo desarrollo nuevo o corrección se realiza en una rama separada que **nace exclusivamente de `develop`**. Las ramas deben tener nombres descriptivos en minúsculas, separados por guiones, y utilizar los siguientes prefijos referenciando el número de issue del tablero:

* `feat/[numero-issue]-[descripcion-corta]`: Para nuevas funcionalidades.
* `fix/[numero-issue]-[descripcion-corta]`: Para correcciones de errores.

Ejemplos correctos: 
* `feat/5-post-registro-venta`
* `fix/12-calculo-subtotal-negativo`

Ejemplos inaceptables: `rama-lucrecia`, `test`, `arreglos-finales`.

### 1.3. Convención de Commits

Un commit debe documentar qué cambió y por qué. Utilizaremos el estándar de **Conventional Commits**:

* `feat: agrega buscador de productos en POS` (Nueva característica)
* `fix: corrige cálculo del subtotal con números negativos` (Corrección de error)
* `docs: actualiza instrucciones de instalación` (Documentación)
* `refactor: optimiza controlador de ventas` (Mejora estructural de código existente)

### 1.4. Pull Requests (PR) y Revisiones de Código

Nadie fusiona (`merge`) su propio código directamente a `develop` ni a `main`.

1.  Al finalizar una tarea, el desarrollador abre un Pull Request (PR) desde su rama hacia `develop`.
2.  El PR debe describir la solución implementada y referenciar el issue correspondiente.
3.  Es obligatorio que al menos un miembro del equipo, distinto al autor, revise el código, lo apruebe y ejecute el merge.

### 1.5. Sincronización Diaria

Antes de crear una rama nueva o comenzar a programar, es obligatorio actualizar el entorno local para mitigar conflictos de integración:

git checkout develop
git pull origin develop

---

## 2. Contratos de Integración (API)

Para garantizar el desarrollo en paralelo, el Frontend (Flutter) y el Backend (Spring Boot) se comunicarán estrictamente mediante los siguientes contratos JSON.

### Contrato 1: Catálogo de Productos
Endpoint: `GET /api/productos`
Descripción: El backend retorna la lista de productos disponibles.

[
  {
    "codigo": "1001",
    "nombre": "Arroz Integral 1kg",
    "precioUnitario": 1500.0,
    "stockActual": 25
  },
  {
    "codigo": "1003",
    "nombre": "Cerveza Brahma",
    "precioUnitario": 3000.0,
    "stockActual": 15
  }
]

### Contrato 2: Registro de Ticket de Venta
Endpoint: `POST /api/ventas`
Descripción: El frontend envía los datos de la transacción para su procesamiento atómico.

{
  "metodoPago": "EFECTIVO",
  "lineas": [
    {
      "codigoProducto": "1003",
      "cantidad": 3
    },
    {
      "codigoProducto": "1004",
      "cantidad": 1
    }
  ]
}

---

## 3. Estructura del Repositorio (Monorepo)

El proyecto utiliza una arquitectura de Monorepo para consolidar el código fuente y la documentación.

/sgi-u-monorepo
├── /frontend               # Proyecto Flutter (Dart)
│   ├── /lib
│   │   ├── /blocs          # Máquinas de estado y lógica de presentación
│   │   ├── /screens        # Pantallas completas (POS, Catálogo, Balance)
│   │   ├── /widgets        # Componentes UI reutilizables
│   │   ├── /models         # Clases de datos en Dart
│   │   └── /services       # Clientes HTTP (Dio/http) para consumir la API REST
│   ├── pubspec.yaml        # Gestor de dependencias de Flutter
│   └── .gitignore          # Reglas de exclusión para Flutter
│
├── /backend                # Proyecto Spring Boot (Java)
│   ├── /src/main/java/com/sgiu
│   │   ├── /controllers    # Endpoints de la API REST
│   │   ├── /services       # Reglas de negocio y transaccionalidad
│   │   ├── /repositories   # Interfaces JPA (PostgreSQL)
│   │   ├── /models         # Entidades de Base de Datos
│   │   └── /config         # Configuraciones globales (CORS, Seguridad)
│   ├── /src/main/resources
│   │   └── application.yml # Credenciales y configuración del servidor
│   ├── pom.xml             # Gestor de dependencias (Maven)
│   └── .gitignore          # Reglas de exclusión para Java
│
├── /docs                   # Documentación técnica
│   ├── Analisis_Funcional.pdf
│   ├── /diagramas          # DER, Secuencia, etc.
│   └── /mockups            # Diseños UI
│
├── README.md               # Este documento
└── .gitignore              # Gitignore global
