# Evaluator Guide

## Qué conviene revisar primero

1. Dashboard público
2. Auth (email + Google)
3. Perfil
4. Crear noticia
5. Mis notas
6. Mis favoritos

## Protocolo sugerido de evaluación

### 1. Navegación pública
**Prerequisito:** ninguna sesión iniciada.

**Pasos:**
- abrir dashboard
- abrir detalle de una nota

**Resultado esperado:**
- dashboard visible sin login
- detalle visible sin login

**Clasificación:** challenge core

### 2. Autenticación
**Prerequisito:** estar deslogueado.

**Pasos:**
- registrar usuario
- login con email
- login con Google
- logout

**Resultado esperado:**
- errores visibles si algo falla
- login correcto
- redirect correcto
- logout vuelve a dashboard

**Clasificación:** overdelivery / soporte de ownership

### 3. Perfil
**Pasos:**
- editar nombre
- editar edad
- cambiar foto
- guardar

**Resultado esperado:**
- perfil persistido
- foto en Storage
- datos del autor sincronizados en notas existentes

**Clasificación:** overdelivery

### 4. Authoring
**Pasos:**
- crear borrador
- completar y publicar
- verificar nota en dashboard

**Resultado esperado:**
- el borrador aparece en Mis notas y no en dashboard
- la nota publicada aparece en dashboard

**Clasificación:** challenge core

### 5. Mis notas
**Pasos:**
- editar
- archivar
- reactivar

**Resultado esperado:**
- al archivar desaparece del dashboard
- al reactivar vuelve a mostrarse

**Clasificación:** challenge core

### 6. Favoritos
**Pasos:**
- guardar favorito desde detalle
- ver la nota en Mis favoritos
- quitar favorito

**Resultado esperado:**
- favorito persistido por usuario
- listado visible en Mis favoritos
- al quitarlo desaparece

**Clasificación:** overdelivery

## Qué fue implementado más allá del mínimo

- Google Sign-In
- perfil editable con foto
- drafts/publicación/archivo/reactivación
- favoritos persistentes por usuario
- redirect post-login a la sección solicitada
- endurecimiento de UX y navegación

## Qué debe tener en cuenta el evaluador

El proyecto no es solo una adaptación superficial del starter. Se convirtió en una app con backend Firebase real y contrato propio, manteniendo la intención de arquitectura original.

## Relevant implementation files

- `frontend/lib/config/routes/routes.dart`
- `frontend/lib/features/articles/`
- `frontend/lib/features/daily_news/`
- `frontend/lib/features/user_profile/`
- `backend/firestore.rules`
- `backend/storage.rules`
