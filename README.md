# 🚀 SGI-U: Sistema de Gestión Inteligente Unificado

Bienvenido al repositorio central de **SGI-U**. Para mantener el orden y la calidad del código durante el desarrollo del MVP, todos los integrantes (Amarilla, Chesani, Czajkowski y Mencia) debemos seguir estas directrices.

---
# 📜 Protocolo de Trabajo en GitHub - Equipo SGI-U

Este repositorio contendrá el código fuente del Sistema de Gestión Inteligente Unificado (SGI-U). Para garantizar la integridad de la arquitectura y evitar conflictos destructivos, todo el equipo (Frontend, Backend, BD y QA) debe adherirse estrictamente a las siguientes reglas de control de versiones.

## 1. La rama `main` es SAGRADA
**Queda estrictamente prohibido hacer un `commit` o un `push` directo a la rama `main`.** La rama `main` representa el código de producción. Si el código está aquí, significa que compila perfectamente y pasó las pruebas del MVP.

## 2. Estrategia de Ramas (Feature Branches)
Todo desarrollo nuevo o corrección se hace en una rama separada que nace de `main`. Las ramas deben tener nombres descriptivos en minúsculas, separados por guiones, y utilizar los siguientes prefijos:
* `feature/nombre-de-la-tarea` (Para nuevas funcionalidades).
* `bugfix/nombre-del-error` (Para corregir errores).

❌ **Inaceptable:** `rama-lucre`, `prueba123`, `test`, `pantallaNueva`.
✅ **Correcto:** `feature/pos-ui-cobro`, `feature/db-connection`, `bugfix/calculo-subtotal`.

## 3. Convención de Commits
Un commit debe contar la historia de qué cambió y por qué. Se prohíben mensajes basura como *"arreglos"*, *"ahora sí funciona"*, o *"asdf"*. Utilizaremos **Conventional Commits**:
* `feat: agrega buscador de productos en POS` (Nueva característica)
* `fix: corrige cálculo del subtotal con números negativos` (Corrección de error)
* `docs: actualiza el README con instrucciones de instalación` (Documentación)
* `refactor: limpia código muerto en el controlador de ventas` (Mejora estructural)

## 4. Pull Requests (PR) y Revisiones de Código
**Nadie fusiona (`merge`) su propio código a `main`.**
1. Cuando termines tu tarea en tu rama, abre un **Pull Request (PR)** hacia `main`.
2. El PR debe describir brevemente qué se hizo y qué partes del código se tocaron.
3. **Obligatorio:** Al menos **un** miembro del equipo distinto al autor debe revisar el código, aprobarlo y ejecutar el Merge.

## 5. Mantenerse Actualizado (Sincronización Diaria)
Antes de crear una rama nueva, o antes de empezar a programar, debes actualizar tu entorno local para evitar conflictos dolorosos (*Merge Conflicts*):
```bash
git checkout main
git pull origin main

## 📂 Estructura del Repositorio

Utilizamos una estructura de **Monorepo** para facilitar la gestión de los componentes de la aplicación:

```text
/sgi-u-monorepo
├── /frontend               # Proyecto Flutter (Dart)
│   ├── /lib
│   │   ├── /blocs          # Máquinas de estado y lógica de presentación (Statecharts)
│   │   ├── /screens        # Pantallas completas (POS, Catálogo, Balance)
│   │   ├── /widgets        # Componentes UI reutilizables (Botón Cobrar, Tarjetas de Stock)
│   │   ├── /models         # Clases de datos en Dart (Producto, Venta, Movimiento)
│   │   └── /services       # Clientes HTTP (Dio/http) para consumir la API REST
│   ├── pubspec.yaml        # Gestor de dependencias de Flutter (¡NO package.json!)
│   └── .gitignore          # Ignora /build, .dart_tool, etc.
│
├── /backend                # Proyecto Spring Boot (Java)
│   ├── /src/main/java/com/sgiu
│   │   ├── /controllers    # Endpoints de la API REST (Reciben peticiones HTTP)
│   │   ├── /services       # AQUÍ VIVEN LAS REGLAS DE NEGOCIO (Validaciones, Atomicidad)
│   │   ├── /repositories   # Interfaces JPA para hablar con PostgreSQL
│   │   ├── /models         # Entidades de Base de Datos (Clases Java mapeadas a tablas)
│   │   └── /config         # Configuraciones globales (CORS, Base de datos)
│   ├── /src/main/resources
│   │   └── application.yml # Credenciales de PostgreSQL, puerto del servidor, etc.
│   ├── pom.xml             # Gestor de dependencias de Java/Maven (o build.gradle si usan Gradle)
│   └── .gitignore          # Ignora /target, .idea, archivos compilados .class
│
├── /docs                   # Documentación técnica
│   ├── Analisis_Funcional_SGI-U_v1.pdf # El PDF que acabamos de terminar
│   ├── /diagramas          # Imágenes exportadas (DER, Secuencia, Statecharts)
│   └── /mockups            # Los diseños de UI alta fidelidad (Tablet, Móvil, Desktop)
│
├── README.md               # Instrucciones EXÁCTAS de cómo levantar la BD, Backend y Frontend
└── .gitignore              # Gitignore global (opcional)
