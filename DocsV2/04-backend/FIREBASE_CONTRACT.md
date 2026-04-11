# Firebase Contract

## Colecciones reales

### `users/{uid}`
Perfil editable del usuario autenticado.

Campos principales:
- `name`
- `email`
- `age`
- `photoUrl`
- `createdAt`
- `updatedAt`

### `articles/{articleId}`
Noticias creadas por usuarios.

Campos principales:
- `authorId`
- `authorName`
- `authorEmail`
- `authorPhotoUrl`
- `title`
- `subtitle`
- `description`
- `category`
- `content`
- `urlToImage` / `thumbnailUrl`
- `isPublished`
- `isActive`
- `createdAt`
- `updatedAt`
- `publishedAt`
- `favoritesVersion`

### `users/{uid}/favorites/{articleId}`
Favoritos persistentes por usuario.

Importante: el documento de favorito guarda un **snapshot denormalizado** del artículo para poder renderizar favoritos sin depender únicamente de leer `articles/{articleId}`.

Campos típicos del snapshot:

- `articleId`
- `favoritedAt`
- `favoritesVersion`
- `firestoreId`
- `title`
- `description`
- `category`
- `content`
- `author`
- `authorId`
- `authorPhotoUrl`
- `urlToImage`
- `createdAt`
- `updatedAt`
- `publishedAt`
- `isPublished`
- `isActive`

## Storage

### Foto de perfil
- `media/users/{uid}/profile.jpg`

### Imagen de noticia
- `articles/{authorId}/{timestamp}.{ext}`

> Nota: el material original sugería una convención más cercana a `media/articles/...`, pero la implementación final usa rutas particionadas por autor para simplificar ownership y reglas de Storage.

## Reglas funcionales principales

### Artículos
- lectura pública solo si `isPublished == true && isActive == true`
- el autor puede leer sus propios drafts o archivados
- solo el autor puede crear/actualizar
- delete físico deshabilitado

### Users
- lectura/escritura solo del dueño

### Favorites
- solo el dueño puede leer/escribir/borrar sus favoritos
- solo se permite favoritear artículos públicos/activos

## Índice actual necesario

Dashboard público:

- `articles(isActive ASC, isPublished ASC, createdAt DESC)`

## Decisiones importantes de diseño

### Denormalización del autor
Las notas guardan snapshot de autor (`authorName`, `authorPhotoUrl`, `authorEmail`) para permitir que dashboard y detalle sigan siendo públicos sin depender de leer perfiles privados.

### Sync perfil → artículos
Cuando el usuario actualiza perfil, la app sincroniza esos campos en todas sus notas existentes.

### Favoritos
Los favoritos viven en subcolección por usuario y almacenan snapshot denormalizado. Eso evita depender exclusivamente de lecturas directas a `articles/{id}` al listar favoritos.

### `favoritesVersion`
Cada artículo mantiene un `favoritesVersion` para invalidar referencias stale cuando cambia su visibilidad (por ejemplo, al archivarse). Es una decisión de diseño pensada para reducir dependencia del estado viejo guardado en snapshots de favoritos.

## Relevant implementation files

- `backend/firestore.rules`
- `backend/storage.rules`
- `backend/firestore.indexes.json`
- `frontend/lib/features/articles/data/data_sources/article_authoring_firestore_data_source.dart`
- `frontend/lib/features/daily_news/data/data_sources/remote/favorite_firestore_data_source.dart`
- `frontend/lib/features/user_profile/data/data_sources/user_profile_firestore_data_source.dart`
