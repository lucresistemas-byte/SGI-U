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

1. Al finalizar una tarea, el desarrollador abre un Pull Request (PR) desde su rama hacia `develop`.
2. El PR debe describir la solución implementada y referenciar el issue correspondiente.
3. Es obligatorio que al menos un miembro del equipo, distinto al autor, revise el código, lo apruebe y ejecute el merge.

### 1.5. Sincronización Diaria

Antes de crear una rama nueva o comenzar a programar, es obligatorio actualizar el entorno local para mitigar conflictos de integración:

```bash
git checkout develop
git pull origin develop
```

---

## 2. Contratos de Integración (API)

Para garantizar el desarrollo en paralelo, el Frontend (Flutter) y el Backend (Spring Boot) se comunicarán estrictamente mediante los siguientes contratos JSON.

### Contrato 1: Catálogo de Productos

Endpoint: `GET /api/productos`  
Descripción: El backend retorna la lista de productos disponibles.

```json
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
```

### Contrato 2: Registro de Ticket de Venta

Endpoint: `POST /api/ventas`  
Descripción: El frontend envía los datos de la transacción para su procesamiento atómico.

```json
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
```

---

## 3. Estructura del Repositorio (Monorepo)

El proyecto utiliza una arquitectura de Monorepo para consolidar el código fuente y la documentación.

```
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
```

## 4. Guía de Supervivencia Git - Equipo SGI-U

Esta guía detalla los comandos exactos y los procedimientos que utilizaremos día a día para desarrollar el SGI-U. Si tienes dudas sobre cómo proceder, consulta este documento antes de ejecutar comandos destructivos.

### 4.1. El Flujo de Trabajo Diario (El Camino Feliz)

Este es el proceso exacto que debes seguir cada vez que tomes una tarea del tablero (Issue).

**Paso 1: Sincronizar tu entorno**  
Antes de escribir una sola línea de código, asegúrate de tener la última versión de Integración.

```bash
git checkout develop
git pull origin develop
```

**Paso 2: Crear tu rama de trabajo**  
Nombra la rama según la convención: `tipo/numero-issue-descripcion`.

```bash
# Ejemplo: Tomaste la tarea #3 (Endpoint GET Catálogo)
git checkout -b feat/3-endpoint-get-catalogo
```

**Paso 3: Trabajar y registrar cambios (Commits)**  
Haz commits pequeños y lógicos. Usa Conventional Commits.

```bash
git add .
git commit -m "feat: agrega controlador y servicio para obtener catálogo"
```

**Paso 4: Subir tu trabajo**  
Sube tu rama al repositorio remoto en GitHub.

```bash
git push -u origin feat/3-endpoint-get-catalogo
```

**Paso 5: Pull Request (PR)**  
Ve a la interfaz web de GitHub y abre un PR de tu rama hacia `develop`. Asigna a un compañero como revisor. Una vez aprobado, se fusionará.

---

### 4.2. Resolución de Problemas (Escenarios Reales)

**Escenario A: Conflictos de Merge**

El problema: GitHub te informa que tu PR tiene conflictos y no se puede fusionar automáticamente. Esto ocurre porque alguien más modificó el mismo archivo que tú.

La solución: Debes traer los cambios de `develop` a tu rama y resolver la colisión localmente en tu IDE (VS Code / IntelliJ).

```bash
# 1. Asegúrate de estar en tu rama
git checkout feat/3-endpoint-get-catalogo

# 2. Trae los últimos cambios de develop
git pull origin develop

# 3. Abre tu IDE. Verás los conflictos marcados. 
# Elige qué código conservar (el tuyo, el de develop, o una mezcla).
# Una vez resueltos todos los archivos:

# 4. Registra la resolución y sube
git add .
git commit -m "fix: resuelve conflictos de merge con develop"
git push origin feat/3-endpoint-get-catalogo
```

El PR en GitHub se actualizará automáticamente y te permitirá hacer el merge.

---

**Escenario B: Un Bug Urgente en Producción (Hotfix)**

El problema: El código en `main` tiene un error crítico (ej. el sistema no calcula bien el total) y no podemos esperar a la próxima iteración de `develop` para arreglarlo.

La solución: Creamos una rama tipo "hotfix" directamente desde `main`.

```bash
# 1. Ve a main y actualiza
git checkout main
git pull origin main

# 2. Crea la rama de emergencia
git checkout -b fix/error-calculo-total

# 3. Arregla el bug, haz commit y push
git add .
git commit -m "fix: corrige fallo crítico en cálculo del ticket"
git push -u origin fix/error-calculo-total
```

Abre un PR hacia `main`. Una vez aprobado y fusionado en `main`, es obligatorio hacer un PR desde `main` hacia `develop` para que el entorno de integración también tenga la corrección.

---

**Escenario C: Escribí código en la rama equivocada**

El problema: Empezaste a programar y te diste cuenta de que sigues en la rama `develop`, y no has hecho ningún commit todavía.

La solución: Mueve tus cambios a una rama nueva sin perder tu progreso.

```bash
# Crea la rama correcta y muévete a ella. Tus cambios no guardados viajarán contigo.
git checkout -b feat/nueva-tarea

# Ahora puedes hacer commit de forma segura
git add .
git commit -m "feat: inicia nueva tarea"
```

---

### 4.3. Reglas de Oro

> ⚠️ **Nunca hagas `git push --force`.** Si crees que lo necesitas, consúltalo con el equipo primero.

> 🚫 **No comitees código roto.** Tu rama no tiene que estar terminada, pero al menos no debe romper la compilación del proyecto.

> 📁 **Ignora lo innecesario.** Respeta el archivo `.gitignore`. Nunca subas carpetas `/target`, `/build`, archivos `.idea` o contraseñas locales.
