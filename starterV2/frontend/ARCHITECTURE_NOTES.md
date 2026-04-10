# Frontend Architecture Notes

## Route access policy actual

### Public routes
- dashboard
- article detail

### Protected routes
- profile
- create article
- my notes
- my favorites

### Auth-only routes
- login
- register

## Shared behaviors

- Auth redirect centralizado mediante `AuthRedirectDestination`
- Drawer/navigation respeta confirmación por cambios sin guardar cuando la pantalla lo declara
- `AppSectionScaffold` es el shell visual compartido

## Feature split actual

- `features/daily_news` → dashboard público, detalle y favoritos
- `features/articles` → authoring y mis notas
- `features/user_profile` → perfil y foto de perfil
- `features/auth` → login/register/session handling
