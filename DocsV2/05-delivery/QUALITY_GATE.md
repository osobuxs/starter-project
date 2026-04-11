# Quality Gate

## Objetivo

Definir un gate de calidad reproducible para evaluación técnica senior de esta entrega.

## Scope

- Seguridad backend (Firestore/Storage rules)
- Lógica de dominio/presentación crítica
- Navegación y políticas de acceso

## Verification Commands

### 1) Firebase rules suite

```bash
cd backend
npm install
npm run test:rules
```

### 2) Flutter tests (unit/widget)

```bash
cd frontend
flutter test
```

## Current coverage evidence

### Backend security

- `backend/tests/firestore.rules.test.js`
- `backend/tests/storage.rules.test.js`
- Resultado esperado: `17 passing, 0 failing`

### Frontend critical logic

- Auth cubit state transitions
- Navigation redirect helpers
- Route access policy mapping
- Article mapper/validators for authoring workflow
- Repository behavior for news/favorites

## Pass criteria

1. Todas las suites en verde.
2. Ninguna regresión en reglas de ownership/visibilidad.
3. Validación de publicación mantiene requisitos obligatorios (título, contenido, imagen).
4. Política de rutas mantiene separación pública/protegida/auth-only.

## Known improvement path (next hardening)

- Integración UI E2E con Emulator para flujo completo draft → publish → dashboard.
- Pipeline CI para ejecutar ambos bloques automáticamente en PR.
