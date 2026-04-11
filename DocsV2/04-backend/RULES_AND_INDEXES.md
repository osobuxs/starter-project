# Rules and Indexes

## Firestore rules

Las rules actuales buscan equilibrar:

- lectura pública del producto final
- protección de edición por autor
- encapsulación de favoritos por usuario

### Resumen rápido

| Recurso | Lectura | Escritura |
|---|---|---|
| `articles` públicos | pública si activa/publicada | no |
| `articles` del autor | solo autor | solo autor |
| `users/{uid}` | solo dueño | solo dueño (delete deshabilitado) |
| `users/{uid}/favorites/{articleId}` | solo dueño | solo dueño |

## Storage rules

| Ruta | Lectura | Escritura |
|---|---|---|
| `media/users/{uid}/profile.jpg` | pública | solo dueño |
| `articles/{authorId}/...` | pública | solo dueño |

Observaciones:

- las reglas permiten create/update/delete del dueño en esas rutas
- las subidas están restringidas a archivos de imagen (`image/*`)

## Índices

### Implementado
- Dashboard: `articles(isActive ASC, isPublished ASC, createdAt DESC)`

### Hardening recomendado (cursor pagination)

Para sostener la paginación incremental del dashboard (sin re-descargar páginas anteriores),
el query usa orden estable por:

- `createdAt DESC`
- `__name__ ASC` (documentId) como tie-breaker

Esto permite `startAfter([createdAt, firestoreId])` y evita duplicados o saltos cuando hay
varios documentos con el mismo `createdAt`.

Si el entorno exige índice compuesto adicional para el order + filtros (`isActive`, `isPublished`),
crearlo desde el link que devuelve Firestore en el error de índice faltante.

## Nota para evaluadores

La app pasó por una evolución fuerte respecto del starter inicial. Por eso los artifacts de backend legacy se mantienen, pero la fuente de verdad actual es esta carpeta `DocsV2/` junto con los archivos efectivos de `backend/`.

## Relevant implementation files

- `backend/firestore.rules`
- `backend/storage.rules`
- `backend/firestore.indexes.json`
