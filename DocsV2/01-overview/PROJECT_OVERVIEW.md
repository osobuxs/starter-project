# Project Overview

## Resumen ejecutivo

El proyecto comenzó como un **starter de aplicación de noticias** con una arquitectura basada en `data / domain / presentation`, BLoC/Cubit y una carpeta `backend/` preparada para Firebase.

La entrega final evolucionó ese starter hacia una **mini plataforma de noticias con Firebase real**, donde los usuarios pueden:

- autenticarse (email/password y Google)
- editar su perfil
- crear noticias propias
- guardar borradores
- publicar noticias
- archivar/reactivar noticias
- ver sus notas
- guardar favoritos persistentes
- navegar un dashboard público con noticias publicadas

## Objetivo de esta documentación

Esta documentación busca dejar claro:

1. qué venía del starter original
2. qué pedía el challenge original
3. qué se implementó realmente
4. qué se agregó como mejora u overdelivery

## Estado funcional actual

### Público
- dashboard
- detalle de noticia

### Protegido por autenticación
- perfil
- crear noticia
- mis notas
- mis favoritos
- guardar/quitar favoritos

## Tecnologías principales

- Flutter
- Firebase Authentication
- Cloud Firestore
- Cloud Storage
- BLoC / Cubit
- Clean Architecture adaptada al starter
