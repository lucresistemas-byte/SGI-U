# SGI-U — Política de Ramas y Versiones (A12)

## Rama principal de trabajo

| Rama            | Propósito                                                       |
|-----------------|------------------------------------------------------------------|
| `lucre-develop` | Integración de todo el equipo. Siempre debe compilar y pasar CI. |
| `develop`       | Candidato a producción. Se nutre de PRs desde `lucre-develop`.   |
| `main`          | Producción etiquetada. Solo recibe merges de `develop` con tag.  |

## Flujo de ramas

```
feat/<tema>  ──►  lucre-develop  ──PR──►  develop  ──PR──►  main
fix/<tema>   ──►  lucre-develop                              (tag v1.x.x)
```

1. **Toda tarea nueva** nace en `feat/<nombre>` o `fix/<nombre>` partiendo de `lucre-develop`.
2. Al terminar, se abre un PR hacia `lucre-develop` (no directo a `develop`).
3. Lucio revisa el código (code review). Luciano ejecuta las pruebas (QA).
4. Una vez aprobado, Lucrecia hace merge en `lucre-develop` y push.
5. Al finalizar el sprint, Lucrecia abre el PR `lucre-develop → develop` para revisión del equipo.
6. `develop → main` solo ocurre cuando el sistema está listo para instalar en producción (Sandra).

## Etiquetado de versiones

- Formato: `vMAJOR.MINOR.PATCH` (semver)
- `v1.0.0` = primera instalación en el local de Sandra con Bloque A completo.
- Parcheos posteriores: `v1.0.1`, `v1.0.2`, etc.
- Nueva funcionalidad: `v1.1.0`.

```bash
# Crear tag en main después del merge de producción
git tag -a v1.0.0 -m "Primera instalación en producción — Bloque A completo"
git push origin v1.0.0
```

## Convenciones de nombres de rama

| Prefijo    | Cuándo usarlo                                    |
|------------|--------------------------------------------------|
| `feat/`    | Nueva funcionalidad (A2, A6, finanzas-tanda2…)  |
| `fix/`     | Corrección de bug o hallazgo de tests            |
| `hotfix/`  | Corrección urgente sobre `develop` o `main`      |
| `docs/`    | Solo documentación, sin código de producción     |

## Reglas de protección (configurar en GitHub)

- `lucre-develop`, `develop` y `main`: **no se puede hacer push directo**, se requiere PR.
- Mínimo **1 aprobación** de review para merge.
- El CI (`backend-ci.yml`) debe pasar antes de habilitar el merge.
