# 🚀 SGI-U: Sistema de Gestión Inteligente Unificado

Bienvenido al repositorio central de **SGI-U**. Para mantener el orden y la calidad del código durante el desarrollo del MVP, todos los integrantes (Amarilla, Chesani, Czajkowski y Mencia) debemos seguir estas directrices.

---

## 📂 Estructura del Repositorio

Utilizamos una estructura de **Monorepo** para facilitar la gestión de los componentes de la aplicación:

```text
/sgi-u
├── /client             # Frontend: Interfaz de usuario (React/Vite/etc.)
│   ├── /src
│   │   ├── /components # Componentes reutilizables
│   │   ├── /pages      # Pantallas principales (Ventas, Balance, etc.)
│   │   └── /services   # Lógica de conexión con la API
│   └── package.json
├── /server             # Backend: Lógica de negocio y API
│   ├── /src
│   │   ├── /controllers # Lógica de los Casos de Uso
│   │   ├── /models      # Modelos de datos (Sequelize/Prisma/etc.)
│   │   └── /routes      # Definición de Endpoints
│   └── package.json
├── /docs               # Documentación técnica y diagramas (DER, Casos de Uso)
├── .gitignore          # Archivos excluidos (node_modules, .env, etc.)
└── README.md           # Guía general del proyecto
