# Frontend Architecture

## Organización por features

La solución final quedó dividida principalmente así:

- `features/auth` → login, registro, sesión
- `features/user_profile` → perfil y foto de perfil
- `features/articles` → crear/editar noticia y mis notas
- `features/daily_news` → dashboard público, detalle y favoritos

## Política de rutas actual

### Rutas públicas
- dashboard
- detalle de noticia

### Rutas protegidas
- mi perfil
- crear noticia
- mis notas
- mis favoritos

### Rutas auth-only
- login
- register

## Principios aplicados

- `domain` no depende de Flutter/Firebase
- `data` concentra acceso real a Firebase/Storage
- `presentation` maneja UI y estados
- navegación protegida centralizada cerca del router
- shell visual compartido con `AppSectionScaffold`

## Comportamientos importantes

### Redirect post-auth
Cuando una sección requiere autenticación y el usuario intenta abrirla desde la UI, la app:

1. muestra un dialog breve
2. envía a login/register
3. después del éxito vuelve al destino solicitado

### Acceso directo a rutas protegidas o auth-only
Además del flujo iniciado por la UI, el router aplica política sistémica:

- si una ruta protegida se abre sin auth, puede redirigir automáticamente a login
- si una ruta auth-only se abre con sesión activa, redirige fuera de login/register

### Cambios sin guardar
Pantallas que editan datos sensibles (perfil / crear-editar nota) exponen confirmación al salir, incluso navegando por drawer.

### Loading y feedback
Se consolidaron componentes compartidos para:

- loading states
- mensajes vacíos
- retry/error states
- snackbars de feedback

## Decisión importante

Aunque favorites vive físicamente dentro de `features/daily_news`, la fuente de verdad actual es Firebase, no almacenamiento local. Esa decisión se mantuvo por continuidad con la base original, pero el comportamiento ya no es el del starter inicial.

## Relevant implementation files

- `frontend/lib/config/routes/routes.dart`
- `frontend/lib/core/navigation/auth_redirect.dart`
- `frontend/lib/core/navigation/route_access_policy.dart`
- `frontend/lib/core/widgets/app_section_scaffold.dart`
