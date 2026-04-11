# Implementation Matrix

## Lectura recomendada

La tabla siguiente separa claramente:

- **Starter**: lo que ya existía en la base del proyecto
- **Challenge original**: lo pedido explícitamente o fuertemente sugerido
- **Implementado**: lo efectivamente resuelto
- **Overdelivery**: lo agregado más allá del mínimo original

| Tema | Starter | Challenge original | Implementado | Overdelivery |
|---|---|---|---|---|
| Arquitectura Flutter | Sí | Respetarla | Sí | Hardening y cleanup fuerte |
| Dashboard de noticias | Sí, remoto | Adaptarlo a artículos propios | Sí, ahora en Firestore | Pull-to-refresh, filtro fecha, shell unificado |
| Detalle de noticia | Sí | Mantener/ajustar | Sí | Refresh fresco, zoom imagen, metadata de autor |
| Firebase backend | Estructura base | Sí | Sí | Rules/indexes endurecidos |
| Auth email/password | No | No estrictamente requerido; agregado para ownership real | Sí | Redirects, UX endurecida |
| Google Sign-In | No | No requerido originalmente | Sí | Sí |
| Perfil usuario | No | No estrictamente requerido en el mínimo | Sí | Sync a notas del autor |
| Crear noticia | No | Sí | Sí | Drafts + publish + image upload |
| Editar noticia | No | No siempre requerido explícitamente | Sí | Sí |
| Mis notas | No | Sí | Sí | Estados y acciones rápidas |
| Baja lógica / archivado | No | Sí | Sí | Reactivación |
| Favoritos persistentes | No | No requerido originalmente | Sí | Sí |
| Storage de fotos | Parcialmente preparado | Sí | Sí | Profile + articles separados |
| Reglas Firestore/Storage | No | Sí | Sí | Ajustadas al producto real |
| APK / entrega Android | No | Sí | Parcialmente preparado | Keystore evaluador compartido |

## Qué venía realmente del starter

El starter aportaba principalmente:

- estructura Flutter existente
- feature `daily_news` como base visual
- separación en capas
- carpeta `backend/` para Firebase
- lineamientos de challenge y arquitectura

## Qué pidió realmente el challenge

El corazón del challenge era:

- permitir que un usuario suba sus propios artículos
- diseñar y documentar schema
- escribir rules
- conectar frontend a Firebase
- respetar arquitectura
- documentar la solución

En otras palabras: el núcleo no era “hacer un producto completo tipo red social”, sino **tomar el starter y convertirlo en una app donde la publicación de artículos propios sea real, mantenible y defendible técnicamente**.

## Qué se implementó finalmente

Además del circuito de artículos, la solución final incluye:

- autenticación completa
- perfil de usuario
- drafts
- publicación/archivo/reactivación
- favoritos por usuario
- sincronización de autor en notas
- navegación protegida con redirect
- shell visual consistente

## Qué cuenta como overdelivery

- Google Sign-In
- favoritos persistentes por usuario
- invalidación de favoritos en flujo de archivado
- sync de perfil a notas existentes
- hardening fuerte de navegación/auth/UX
- documentación técnica separada y canónica

## Evidencia del challenge original

Tomando como referencia el brief y la documentación original del repositorio, las piezas claramente nucleares del desafío eran:

- backend Firebase real
- schema de artículos
- rules de seguridad
- dashboard/detalle
- crear artículo
- mis notas
- baja lógica

Autenticación completa, perfil fuerte, Google Sign-In y favoritos persistentes fueron decisiones de implementación para reforzar ownership, coherencia de producto y calidad de demo, no simplemente requisitos mínimos del enunciado.
