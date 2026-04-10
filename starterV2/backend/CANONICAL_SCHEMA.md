# Canonical Firebase Contract

## Firestore

### `users/{uid}`

| Field | Type | Required |
|---|---|---|
| `name` | string | yes |
| `email` | string | yes |
| `age` | int/null | no |
| `photoUrl` | string/null | no |
| `createdAt` | timestamp | yes |
| `updatedAt` | timestamp | yes |

### `articles/{articleId}`

| Field | Type | Required |
|---|---|---|
| `authorId` | string | yes |
| `authorName` | string | yes |
| `authorEmail` | string | yes |
| `authorPhotoUrl` | string/null | no |
| `title` | string | yes |
| `subtitle` | string/null | no |
| `description` | string/null | no |
| `category` | string | yes |
| `content` | string | yes |
| `urlToImage` | string/null | no |
| `thumbnailUrl` | string/null | no |
| `isPublished` | bool | yes |
| `isActive` | bool | yes |
| `createdAt` | timestamp | yes |
| `updatedAt` | timestamp | yes |
| `publishedAt` | timestamp/null | no |
| `favoritesVersion` | int | yes |

### `users/{uid}/favorites/{articleId}`

Documento denormalizado usado para renderizar favoritos sin depender únicamente de lecturas directas de `articles/{articleId}`.

| Field | Type | Required |
|---|---|---|
| `articleId` | string | yes |
| `favoritedAt` | timestamp | yes |
| `favoritesVersion` | int | yes |
| `firestoreId` | string | yes |
| `title` | string | yes |
| `content` | string | yes |
| `isPublished` | bool | yes |
| `isActive` | bool | yes |
| `createdAt` | timestamp | yes |
| `authorId` | string/null | no |
| `author` | string/null | no |
| `authorPhotoUrl` | string/null | no |
| `description` | string/null | no |
| `category` | string/null | no |
| `url` | string/null | no |
| `urlToImage` | string/null | no |
| `publishedAt` | string/null | no |
| `updatedAt` | timestamp/null | no |

## Storage

### Profile photos
- `media/users/{uid}/profile.jpg`

### Article images
- `articles/{authorId}/{timestamp}.{ext}`

## Indexes

### Dashboard index
- `articles(isActive ASC, isPublished ASC, createdAt DESC)`
