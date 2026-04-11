# Database Schema

> Legacy bridge file.
>
> La documentación canónica del contrato actual vive en:
>
> - `DocsV2/04-backend/FIREBASE_CONTRACT.md`
> - `DocsV2/04-backend/RULES_AND_INDEXES.md`

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

Tomar `DocsV2/` como fuente de verdad actual.
