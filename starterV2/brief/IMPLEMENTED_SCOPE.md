# Implemented Scope

## Producto actual

La app evolucionó desde el starter de noticias remotas hacia una app de noticias con backend Firebase propio.

### Público
- Dashboard público
- Detalle público de nota

### Protegido por autenticación
- Mi perfil
- Crear nota
- Mis notas
- Mis favoritos
- Guardar/quitar favoritos

## Features implementadas

### Auth
- Login email/password
- Registro email/password
- Google Sign-In
- Logout con confirmación
- Redirect post-login al destino solicitado

### Perfil
- Nombre
- Edad
- Foto de perfil en Firebase Storage
- Preview fullscreen de foto
- Guardado solo con cambios reales

### Notes / Articles
- Crear nota
- Editar nota
- Guardar borrador
- Publicar nota
- Archivar/reactivar
- Mis notas con estados y acciones
- Dashboard Firestore con paginación
- Filtro por fecha

### Favoritos
- Persistidos en Firestore por usuario
- Mis favoritos
- Toggle desde detalle
- Invalidación de favoritos stale al archivar/desactivar

## Reglas funcionales importantes

- Un borrador requiere al menos título para guardarse.
- Publicar requiere título, contenido e imagen.
- Una nota publicada no vuelve a borrador.
- Una nota archivada no aparece en dashboard.
- Dashboard solo muestra notas publicadas y activas.
