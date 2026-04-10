# 🚀 SGI-U: Sistema de Gestión Inteligente Unificado

Bienvenido al repositorio central de **SGI-U**. Para mantener el orden y la calidad del código durante el desarrollo del MVP, todos los integrantes (Amarilla, Chesani, Czajkowski y Mencia) debemos seguir estas directrices.

---

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
