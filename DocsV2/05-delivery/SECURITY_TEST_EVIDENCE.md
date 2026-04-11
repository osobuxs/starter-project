# Security Test Evidence

## Goal

Proveer evidencia reproducible de que las reglas de Firestore y Storage aplican correctamente ownership, visibilidad y restricciones de tipo de archivo.

## Setup

- Ubicación: `backend/`
- Runner: `firebase emulators:exec`
- Framework: `@firebase/rules-unit-testing` + `node:test`
- Proyecto de pruebas: `demo-symmetry-news` (no productivo)

## Command

```bash
cd backend
npm install
npm run test:rules
```

## Result (latest run)

- Test files:
  - `backend/tests/firestore.rules.test.js`
  - `backend/tests/storage.rules.test.js`
- Total tests: **17**
- Passed: **17**
- Failed: **0**

## Covered security scenarios

### Firestore

1. Lectura pública permitida solo para artículos `isPublished=true && isActive=true`.
2. Lectura pública denegada para drafts.
3. Autor puede crear su propio artículo.
4. Usuario autenticado no puede crear artículo con `authorId` ajeno.
5. Autor puede actualizar su artículo.
6. No autor no puede actualizar artículo ajeno.
7. Dueño puede leer/actualizar su perfil.
8. No dueño no puede leer/actualizar perfil ajeno.
9. Dueño puede crear favorito si target está activo/publicado.
10. Dueño no puede favoritear draft.
11. Solo dueño puede borrar su favorito.

### Storage

1. Dueño puede subir imagen de perfil a su path.
2. No dueño no puede subir imagen al path de otro usuario.
3. Dueño no puede subir archivos no imagen (`text/plain`).
4. Autor puede subir imagen a su path de artículos.
5. No autor no puede subir imagen al path de otro autor.
6. Dueño puede borrar su imagen de perfil.

## Notes

- El runner muestra advertencia de Java < 21 en `firebase-tools` futuro; no afecta el resultado actual de la suite.
