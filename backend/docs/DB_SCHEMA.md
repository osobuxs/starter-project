# Database Schema

> Legacy bridge file.
>
> La documentación canónica del contrato actual vive en:
>
> - `starterV2/backend/CANONICAL_SCHEMA.md`
> - `starterV2/backend/RULES_SUMMARY.md`

## Current implemented model

### Firestore collections
- `users/{uid}`
- `articles/{articleId}`
- `users/{uid}/favorites/{articleId}`

### Storage paths
- `media/users/{uid}/profile.jpg`
- `articles/{authorId}/{timestamp}.{ext}`

## Important note

El proyecto evolucionó más allá del starter original. Algunos documentos legacy en la raíz y `backend/` reflejan la consigna inicial, no necesariamente la implementación final.

Tomar `starterV2/` como fuente de verdad actual.
