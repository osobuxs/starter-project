# Rules Summary

## Firestore

### Articles
- lectura pública solo para `isPublished == true && isActive == true`
- el autor puede leer sus propios drafts/inactivos
- create/update solo por el autor autenticado
- delete deshabilitado

### Users
- owner read/write only

### Favorites
- owner read/write/delete only
- solo pueden favoritear artículos públicos/activos
- se valida ownership del subpath del usuario

## Storage

### Profile photos
- lectura pública
- create/update/delete solo dueño
- solo imágenes

### Article images
- lectura pública
- create/update/delete solo dueño
- solo imágenes
