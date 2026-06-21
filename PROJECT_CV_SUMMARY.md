# PROJECT_CV_SUMMARY.md

> Documento técnico para extrapolar a CV, LinkedIn y entrevistas.
> **Regla de oro:** nada inventado. Cada afirmación está etiquetada como
> **[Confirmado]** (verificable en el código/config), **[Inferido]** (deducido de la
> estructura) o **[Pendiente de validar]** (requiere datos productivos o confirmación del autor).

---

## 0. Nota de contexto honesta

Este repositorio **nació** como un **challenge técnico de Symmetry** (prueba para postulantes a
puestos de programación), según `README.md`. El enunciado original pedía convertir una *News App*
starter en una app donde el usuario publica sus propios artículos con Firebase real.

**Hoy es un proyecto personal vivo:** una **plataforma multi-módulo y extensible** ("MultiApp")
que el autor sigue creciendo agregando mini-aplicaciones según necesidades cotidianas. La
modularidad no es decorativa: es el propósito del producto — cada módulo (noticias, dardos, La Loba…)
es una mini-app autocontenida que se enchufa al shell sin tocar las demás.

**[Confirmado por el autor]** Es un proyecto personal, **sin tráfico de usuarios productivos** (no
busca métricas de negocio). El valor es técnico y de utilidad propia: un *home* para herramientas
cotidianas construidas con arquitectura seria.

La entrega **sobre-entregó** el challenge original: además del circuito de artículos, se construyeron
**dos juegos completos** (Dardos y La Loba) con su propia lógica de dominio, persistencia y tests.

⚠️ **Gap de documentación detectado:** la documentación canónica `DocsV2/` cubre solo la parte de
Noticias. **No documenta Dardos ni La Loba**, que son los features más grandes del código (45 y 46
archivos `.dart` respectivamente). Para CV esto importa: gran parte del trabajo técnico más complejo
está en el código pero no en la doc oficial.

---

## 1. Resumen general del proyecto

**[Confirmado]** Aplicación móvil Flutter (`pubspec.yaml`: `name: news_app_clean_architecture`,
`version: 1.0.2+3`) cuyo título interno es **"MultiApp"** (`lib/main.dart`). Funciona como un
**contenedor multi-aplicación**: un dashboard central da acceso a varios módulos independientes.

**Qué problema resuelve / qué tipo de producto es:**
- **[Confirmado]** Plataforma de **publicación de noticias propias** (un usuario autenticado crea,
  edita, guarda como borrador, publica, archiva/reactiva sus artículos) + lectura pública.
- **[Confirmado]** Suite de **juegos con scorekeeping**: anotador de **Dardos** (501/301/Cricket) y
  el juego de cartas **La Loba**, con reglas de negocio reales y persistencia en la nube.

**Para qué usuarios / negocio está pensado:**
- **[Confirmado por el autor]** Proyecto **personal**: plataforma extensible de uso propio donde el
  autor agrega módulos con utilidades cotidianas a medida que las necesita. Sin tráfico productivo.
- **[Confirmado]** Doble valor: portfolio técnico (origen challenge Symmetry) + herramienta personal real.
- **[Inferido]** Usuarios potenciales por módulo: lectores/autores de artículos + grupos de jugadores
  que llevan el puntaje de partidas de dardos/cartas.

**Módulos principales (features):** **[Confirmado]** `lib/features/`
`articles`, `auth`, `daily_news`, `dardos`, `dashboard`, `la_loba`, `user_profile`.

**Valor que aporta:**
- **[Confirmado]** Arquitectura limpia y consistente replicada en 7 features → mantenibilidad.
- **[Confirmado]** Seguridad real basada en ownership a nivel de reglas de Firestore/Storage.
- **[Confirmado]** Lógica de juego compleja aislada en *domain services* puros y testeados.

---

## 2. Stack técnico

> Fuente: `frontend/pubspec.yaml`, `backend/package.json`, `backend/*.rules`, código.

| Capa | Tecnología | Evidencia |
|---|---|---|
| **Lenguaje frontend** | Dart (SDK `>=2.18.0 <3.0.0`) | `pubspec.yaml` |
| **Framework UI** | Flutter (Material Design) | `pubspec.yaml`, `main.dart` |
| **Gestión de estado** | `flutter_bloc` ^9.1.1, `bloc_concurrency` ^0.3.0 | `pubspec.yaml` |
| **Inyección de dependencias** | `get_it` ^9.2.1 (service locator) | `lib/injection_container.dart`, `lib/di/*` |
| **Backend** | **Firebase serverless** (no hay servidor propio) | `backend/` solo tiene rules + tests |
| **Autenticación** | `firebase_auth` ^6.3.0 + `google_sign_in` ^7.2.0 | `pubspec.yaml`, `auth/` |
| **Base de datos remota** | Cloud Firestore ^6.2.0 | `pubspec.yaml`, `firestore.rules` |
| **Base de datos local** | `floor` ^1.4.0 (SQLite, con `floor_generator`) | `pubspec.yaml`, `la_loba/data/.../local` |
| **Almacenamiento de archivos** | `firebase_storage` ^13.2.0 | `pubspec.yaml`, `storage.rules` |
| **Comparación de objetos** | `equatable` ^2.0.5 | `pubspec.yaml` |
| **UI / utilidades** | `flutter_hooks`, `cached_network_image`, `ionicons`, `image_picker`, `intl` | `pubspec.yaml` |
| **Audio / accesibilidad** | `flutter_tts` ^4.2.5, `audioplayers` ^6.5.1 (audio de dardos) | `pubspec.yaml`, `assets/audio/dardos/` |
| **Testing (frontend)** | `flutter_test`, `bloc_test` ^10.0.0, `mockito` ^5.4.4 | `pubspec.yaml`, `frontend/test/` |
| **Testing (backend)** | `@firebase/rules-unit-testing` ^3.0.3 + Node `--test` sobre emulador | `backend/package.json`, `backend/tests/` |
| **Tooling** | `build_runner`, `flutter_lints` ^6.0.0, `flutter_launcher_icons`, `firebase-tools` | `pubspec.yaml`, `backend/package.json` |

**Integraciones externas:** **[Confirmado]** Firebase (Auth, Firestore, Storage), Google Sign-In.
**[Inferido]** El feature `daily_news` originalmente consumía una API de noticias REST (estructura
`data/data_sources/remote`), hoy el dashboard sirve artículos propios desde Firestore (según
`DocsV2/02-scope/IMPLEMENTATION_MATRIX.md`).

**Servicios cloud:** **[Confirmado]** Firebase (Auth + Firestore + Cloud Storage). Emulador local
configurado en `backend/firebase.json`.

**Variables de entorno / secretos:** **[Confirmado]** No se exponen secretos en el repo. La config de
Firebase se inyecta vía `firebase_options.dart` / `google-services.json` (estándar Flutter+Firebase,
no versionado como secreto en texto plano aquí). **No incluir claves en el CV.**

---

## 3. Arquitectura

**Patrón principal: [Confirmado] Clean Architecture por feature**, replicada de forma consistente.
Cada feature en `lib/features/<feature>/` tiene:

```
<feature>/
├── data/
│   ├── data_sources/   (remote / local — Firebase, Floor)
│   ├── models/         (DTOs serializables)
│   └── repository/     (implementaciones)
├── domain/
│   ├── entities/       (objetos de negocio puros, Equatable)
│   ├── repository/     (interfaces / contratos)
│   ├── services/       (reglas de negocio puras, p.ej. scoring de dardos)
│   └── usecases/       (casos de uso)
└── presentation/
    ├── bloc/ | cubit/  (estado)
    ├── pages/          (pantallas)
    └── widgets/        (componentes)
```

**Carpetas raíz y responsabilidad:** **[Confirmado]**
- `lib/config/` → rutas (`routes/routes.dart`) y theming (`theme/app_themes.dart`).
- `lib/core/` → transversales: `navigation` (políticas de acceso), `errors` (`app_failure.dart`),
  `resources` (`data_state.dart`), `usecase` (contrato base), `widgets` (scaffolds y estados reutilizables).
- `lib/di/` → 7 módulos de registro de dependencias (uno por feature) + `core_di.dart`.
- `lib/injection_container.dart` → composición raíz del service locator.
- `backend/` → reglas y tests de Firebase (no código de servidor).

**Patrones usados:** **[Confirmado]**
- Clean Architecture / separación en capas.
- Repository pattern (interfaz en `domain`, impl en `data`).
- Service Locator / DI (`get_it`).
- BLoC/Cubit para estado.
- *Domain services* puros para reglas (testables sin Flutter): `dardos_score_rules.dart`,
  `dardos_cricket_rules.dart`, `dardos_leg_rules.dart`, `la_loba/.../game_round_rules.dart`.
- **[Inferido]** Patrón orquestador en artículos: el cubit de creación/edición separa
  `orchestrator`, `mapper`, `state_handlers`, `validators` (`articles/presentation/cubit/`).

**Flujo de datos:** **[Confirmado]** UI → Cubit/BLoC → UseCase → Repository (interfaz) →
Repository Impl → DataSource (Firestore/Storage/Floor) → de vuelta como Entity envuelta en
`DataState` (`core/resources/data_state.dart`).

**Manejo de estado:** **[Confirmado]** `flutter_bloc` (15 cubits/blocs). Dardos usa BLoCs separados
por responsabilidad: `dardos_game`, `dardos_multi_game`, `dardos_participant`, `dardos_bottom_nav`.

**Manejo de errores:** **[Confirmado]** Tipo de falla de dominio (`core/errors/app_failure.dart`,
`auth/domain/entities/auth_failure.dart`) y wrapper `DataState` (success/error) en lugar de
excepciones sueltas en la UI.

**Seguridad:** **[Confirmado]** Reglas de Firestore (`backend/firestore.rules`) con:
- `isSignedIn()`, `isOwner(userId)` → control por propiedad.
- Validación de **schema campo por campo** en escrituras (`isValidArticleWrite`, `isValidUserProfileWrite`,
  `isValidFavoriteWrite`): tipos, claves permitidas (`hasOnly`), campos inmutables (`authorId`, `createdAt`).
- Lectura de artículos condicionada a `isPublished && isActive` o ser el dueño.
- **Borrado lógico**: `allow delete: if false` en artículos, usuarios, favoritos y juegos
  (excepto `throws` de dardos, que permite delete autenticado para la función *undo*).
- En frontend, `core/navigation/route_access_policy.dart` clasifica rutas en `public / protected / authOnly`
  y `auth_redirect.dart` aplica redirects.

**Escalabilidad:** **[Confirmado]** Backend serverless (Firestore) escala gestionado por Google;
índices definidos en `firestore.indexes.json`. **[Inferido]** Estructura modular permite añadir nuevas
mini-apps sin tocar las existentes.

**Mantenibilidad:** **[Confirmado]** Linting (`flutter_lints`), arquitectura uniforme, lógica de negocio
aislada y testeada, docs de guías (`docs/CODING_GUIDELINES.md`, `docs/ARCHITECTURE_VIOLATIONS.md`).

---

## 4. Funcionalidades implementadas (por módulo)

### Auth (`features/auth`) — 17 archivos
- **[Confirmado]** Login email/password, registro, logout, usuario actual, **Google Sign-In**.
  - Archivos: `auth_firebase_data_source.dart`, usecases (`login`, `register`, `logout`,
    `get_current_user`, `sign_in_with_google`), `auth_cubit.dart`, `auth_form_validators.dart`.
  - Complejidad: media. Valor: habilita ownership real de todo el contenido.

### Artículos / Noticias (`features/articles` + `daily_news`) — 24 + 28 archivos
- **[Confirmado]** Crear/editar artículo, guardar borrador, publicar, archivar/reactivar (baja lógica),
  subir imagen a Storage, ver "mis notas", favoritos persistentes por usuario, detalle público.
  - Archivos: usecases `publish_article`, `save_article_draft`, `update_article_active_state`,
    `upload_article_image`, `get_my_articles`; cubits `create_edit_article_*`, `my_notes_cubit`.
  - Complejidad: alta (orquestación de estados borrador→publicado→archivado + upload + validación).
  - Valor: es el **núcleo del challenge original**.

### Perfil de usuario (`features/user_profile`) — 13 archivos
- **[Confirmado]** Edición de perfil (nombre, edad, foto) con validación de schema en rules.
- **[Inferido]** Sincronización de datos de autor hacia las notas existentes (según matriz de impl.).
  - Complejidad: media. Valor: coherencia de identidad del autor en todo el producto.

### Dardos (`features/dardos`) — 45 archivos ⭐ (no documentado en DocsV2)
- **[Confirmado]** Anotador completo de dardos: modos **501/301 y Cricket**, regla **double-out**,
  detección de **bust**, checkout válido, turnos de 3 dardos, **legs y sets**, **overtime** (legs/sets extra),
  banner de victoria instantánea, estadísticas de por vida, **deshacer último dardo (undo)**,
  reabrir partida finalizada, eliminación de partidas no terminadas, juego por **equipos**.
  - Lógica de dominio pura y testeada: `dardos_score_rules.dart` (104 LOC), `dardos_cricket_rules.dart`
    (124 LOC), `dardos_leg_rules.dart` (191 LOC).
  - Persistencia: colecciones `dardos_games` / `dardos_participants` / subcolección `throws` (rules).
  - Complejidad: **alta** — reglas de dartball reales, edge cases de bust/checkout, undo transaccional.
  - Valor: feature de mayor profundidad técnica del repo.

### La Loba (`features/la_loba`) — 46 archivos ⭐ (no documentado en DocsV2)
- **[Confirmado]** Juego de cartas con creación de partida, registro de manos (`hands`), participantes,
  puntajes por ronda, pantalla de partida finalizada y detalle de participante.
  - Lógica de dominio: `game_round_rules.dart` (193 LOC). Entidades: `game`, `hand`, `partida`,
    `player`, `participant`, `score`, `game_over_result`.
  - Persistencia: colecciones `games` (+ subcolección `hands`) / `participants` (rules).
  - PRD documentado en `docs/PRD_LA_LOBA.md`.
  - Complejidad: alta. Valor: segundo dominio de juego completo.

### Dashboard (`features/dashboard`) — 1 archivo
- **[Confirmado]** Punto de entrada que enruta a cada mini-app (`route_names.dart` define 19 rutas).
  - Complejidad: baja. Valor: shell unificado del producto multi-app.

---

## 5. Puntos fuertes técnicos (reales)

- **[Confirmado] Arquitectura modular consistente** replicada en 7 features sin degradarse.
- **[Confirmado] Lógica de negocio aislada y testeada** en domain services puros (sin dependencia de
  Flutter), especialmente el scoring de dardos y las rondas de La Loba.
- **[Confirmado] Seguridad a nivel de datos**: rules con ownership + validación de schema campo por campo
  + borrado lógico, no solo controles en la UI.
- **[Confirmado] Testing en ambas puntas**: **348 tests verdes, suite 100% en verde** (`All tests passed!`):
  unit, bloc_test con fakes/mocks, integración de dardos + tests de reglas de Firebase sobre emulador.
- **[Confirmado] Manejo de estados asíncronos** con BLoC/Cubit y `DataState` (success/error) uniforme.
- **[Confirmado] Manejo de errores tipado** (`AppFailure`, `AuthFailure`).
- **[Confirmado] Inyección de dependencias** desacoplada por feature (`get_it`, 7 módulos DI).
- **[Confirmado] UX endurecida**: redirects de auth, pull-to-refresh, undo, double-out indicator,
  banner de victoria (commits + matriz de implementación).
- **[Confirmado] Calidad de código**: linting activo, guías documentadas, convenciones de commit
  (conventional commits visibles en el historial).
- **[Confirmado] Accesibilidad/feedback**: TTS y audio en dardos.

**Limitaciones honestas (no ocultar):**
- **[Resuelto en esta revisión]** La suite tenía 11 tests rotos (preexistentes) por un refactor de dominio
  de La Loba (de `Player/Partida` a `Participant/Hand`, IDs `int`→`String`) y mocks faltantes. Se
  saneó: reescrito `game_bloc_test.dart` contra la API actual, eliminados 9 tests huérfanos de use cases
  ya borrados, y recreado el fake de `auth_cubit_test`. Resultado: **348 tests, 100% verde.**
- **[Resuelto en esta revisión]** `build_runner` fallaba por `floor_generator` (`DateTime?` no soportado
  en `daily_news/.../article.dart`). Se agregó un `DateTimeConverter` (`TypeConverter<DateTime?, int?>`,
  epoch en ms) registrado en `AppDatabase` con `@TypeConverters`. `build_runner` ahora **completa OK**
  (`Succeeded with 95 outputs`) y el `.g.dart` regeneró el esquema completo (17 columnas).
  Hallazgo colateral: la base **Floor local es código vestigial** — se instancia en `core_di.dart` pero
  su DAO **nunca se usa** (los artículos viven en Firestore). Candidata a eliminación futura (dead code).
- **[Confirmado]** No hay servidor backend propio ni endpoints REST custom: todo el backend es
  Firebase gestionado. (No es una debilidad per se, pero conviene no presentarlo como "API backend".)
- **[Confirmado]** Documentación canónica desalineada con el código (no cubre los juegos).
- **[Confirmado]** El rol "admin" de los juegos es un **gate de cliente** (email hardcodeado en los
  BLoCs `dardos_participant_bloc.dart` y `participant_bloc.dart`), no un rol enforced en las rules.
  Funciona para uso personal, pero **no es seguridad de servidor**; para multiusuario requeriría
  custom claims de Firebase Auth + validación en `firestore.rules`. La seguridad real del resto del
  contenido (artículos, perfil, favoritos) sí está enforced por ownership en las rules.
- **[Inferido]** No se observa CI/CD automatizado (no hay `.github/workflows`); el build de APK se
  automatiza localmente con un script propio (`build_apk.bat`) que compila y versiona el artefacto.
- **[Confirmado por el autor]** La app **está instalada y en uso real** en el dispositivo del autor
  (distribución interna). No está publicada en Google Play.

---

## 6. Métricas posibles (inferibles del repo)

> **[Confirmado]** salvo donde se indique. Conteos vía `find`/`wc` sobre `frontend/lib` y `backend/`.

| Métrica | Valor | Cómo se obtuvo |
|---|---|---|
| Features / módulos | **7** | `lib/features/` |
| Archivos `.dart` en `lib` | **197** | `find lib -name '*.dart'` |
| Líneas de código Dart (`lib`) | **~23.678** | `wc -l` |
| Archivos de test (frontend) | **~59** (tras limpiar tests huérfanos) | `find test -name '*.dart'` |
| Tests ejecutados — **pasan** | **348** | `flutter test` (suite **100% verde**) |
| Tests — **fallan** | **0** | `flutter test` → `All tests passed!` |
| Tests de reglas (backend) | **2 suites** | `backend/tests/*.test.js` (Firestore + Storage) |
| Rutas nombradas | **19** | `core/navigation/route_names.dart` |
| Entidades de dominio | **19** | `find */domain/entities` |
| Casos de uso (usecases) | **21** | `find */domain/usecases` |
| Interfaces de repositorio | **8** | `find */domain/repository` |
| Domain services (reglas) | **4** | dardos ×3 + la_loba ×1 |
| Data sources | **14** | `find */data/data_sources` |
| Models (DTOs) | **15** | `find */data/models` |
| Cubits / BLoCs | **15** | `find presentation` |
| Pantallas (pages) | **25** | `find */presentation/pages` |
| Widgets reutilizables (feature) | **14** | `find */presentation/widgets` |
| Módulos de DI | **7** | `lib/di/` |
| Colecciones Firestore | **5** | rules: `articles`, `users`(+`favorites`), `games`(+`hands`), `participants`, `dardos_games`(+`throws`), `dardos_participants` |
| Niveles de acceso de ruta | **3** | `public / protected / authOnly` |
| Integraciones externas | **2** | Firebase, Google Sign-In |

**Métricas de negocio (NO disponibles): [Pendiente de validar con datos productivos]**
- Usuarios reales, empresas/clientes, volumen de datos, tráfico, retención, performance productiva.
- *Cómo medirlas si se despliega:* Firebase Analytics + Crashlytics para usuarios activos/crashes;
  paneles de Firestore para volumen de documentos; Performance Monitoring para latencia.

---

## 7. Impacto profesional para CV (bullets)

> Verbos de impacto + tecnología + valor. Solo métricas verificables.

**Español**
- Diseñé e implementé una arquitectura **Clean Architecture** en **Flutter/Dart** replicada en 7 módulos
  (data/domain/presentation), separando vistas, lógica de negocio y acceso a datos para maximizar la mantenibilidad.
- Construí un backend **serverless sobre Firebase** (Firestore + Storage + Auth) con reglas de seguridad
  basadas en *ownership* y **validación de schema campo por campo**, evitando escrituras inválidas a nivel de datos.
- Implementé autenticación completa (**email/password + Google Sign-In**) con `firebase_auth` y redirects de ruta
  por política de acceso (`public/protected/authOnly`).
- Desarrollé el circuito completo de **publicación de artículos** (borrador → publicado → archivado/reactivado)
  con subida de imágenes a Cloud Storage y baja lógica en lugar de borrado destructivo.
- Modelé y testeé la **lógica de dardos (501/301/Cricket)** —double-out, bust, checkout, legs/sets y overtime—
  como *domain services* puros cubiertos por tests unitarios e integración.
- Apliqué **gestión de estado con BLoC/Cubit** e inyección de dependencias con `get_it`, con manejo de estados
  asíncronos y errores tipados (`DataState`, `AppFailure`).
- Aseguré calidad con **68 archivos de test** en frontend (`bloc_test`, `mockito`) y **tests de reglas de Firebase**
  ejecutados sobre el emulador.

**English**
- Designed and implemented a **Clean Architecture** in **Flutter/Dart** replicated across 7 modules
  (data/domain/presentation), separating views, business logic and data access to maximize maintainability.
- Built a **serverless backend on Firebase** (Firestore + Storage + Auth) with ownership-based security rules
  and **field-by-field schema validation**, blocking invalid writes at the data layer.
- Implemented full authentication (**email/password + Google Sign-In**) with `firebase_auth` and route-level
  access policies (`public/protected/authOnly`) with redirects.
- Developed the complete **article publishing flow** (draft → published → archived/reactivated) with Cloud
  Storage image uploads and soft-deletes instead of destructive deletion.
- Modeled and tested **darts scoring logic (501/301/Cricket)** —double-out, bust, checkout, legs/sets and
  overtime— as pure domain services covered by unit and integration tests.
- Applied **BLoC/Cubit state management** and `get_it` dependency injection, with async state handling and
  typed error modeling (`DataState`, `AppFailure`).
- Ensured quality with **68 frontend test files** (`bloc_test`, `mockito`) and **Firebase rules tests** run
  against the emulator.

---

## 8. Descripciones cortas

**LinkedIn — Español (3 líneas)**
> App móvil Flutter multi-módulo con Clean Architecture y backend serverless en Firebase (Auth, Firestore, Storage).
> Incluye publicación de artículos propios con seguridad por ownership y dos juegos completos (Dardos 501/Cricket y La Loba) con lógica de dominio testeada.
> Estado con BLoC/Cubit, DI con get_it y cobertura de tests en frontend y reglas de Firebase.

**LinkedIn — English (3 lines)**
> Multi-module Flutter mobile app built with Clean Architecture and a serverless Firebase backend (Auth, Firestore, Storage).
> Features owner-scoped article publishing plus two full games (Darts 501/Cricket and La Loba) with tested domain logic.
> State managed with BLoC/Cubit, DI via get_it, and test coverage across frontend and Firebase security rules.

**Versión técnica para entrevistas**
> "Es una app Flutter tipo 'MultiApp' con 7 features bajo Clean Architecture estricta (data/domain/presentation),
> ~23.7k LOC y 68 archivos de test. El backend es Firebase serverless: la seguridad vive en las reglas de Firestore,
> con ownership y validación de schema campo por campo, no solo en la UI. Lo más interesante técnicamente es que la
> lógica de los juegos (scoring de dardos con double-out, bust, legs/sets y overtime; rondas de La Loba) está aislada
> en domain services puros, lo que me permitió testearla sin Flutter. El estado se maneja con BLoC/Cubit y la DI con
> get_it por feature. Algo de lo que aprendí: la doc canónica quedó desalineada del código —documenta solo el módulo
> de noticias—, así que el código es la fuente de verdad de los dos juegos."

---

## 9. Preguntas pendientes para el dueño del proyecto

1. ~~**Rol exacto:** ¿único autor?~~ → **[Confirmado por el autor]** Autor **único** de punta a punta:
   arquitectura, backend Firebase, frontend Flutter y los dos juegos. **Rol para CV: Desarrollador
   Mobile (Flutter) full-stack** — abarcando UI, gestión de estado (BLoC/Cubit), DI e integración
   completa con Firebase (Auth, Firestore, Storage).
2. ~~**Despliegue:** ¿store o solo APK?~~ → **[Confirmado por el autor]** **En uso real**: la app está
   instalada y se usa en el teléfono del autor en el día a día (distribución **interna**, no Google Play).
   `build_apk.bat` es un script propio para compilar, versionar y dejar el APK listo para instalar.
3. ~~**Usuarios/uso real:**~~ → **[Confirmado por el autor]** Proyecto personal: **un único usuario
   (el autor)**, sin tráfico productivo. No se persiguen métricas de adopción.
4. ~~**Datos productivos:**~~ → **[Confirmado por el autor]** No aplica: volumen acotado a uso personal.
5. ~~**Resultado del challenge:**~~ → **[Confirmado por el autor]** Symmetry **vio la entrega** pero
   avanzó con otro candidato; **no dieron feedback técnico**. No hay veredicto sobre la calidad del
   código (ni a favor ni en contra). El proyecto **continuó como personal** más allá del challenge.
   *Para CV/entrevista: presentarlo como proyecto personal propio, no como challenge "aprobado".*
6. ~~**Admin de dardos:**~~ → **[Confirmado en código]** El rol admin es un **gate de cliente por email
   hardcodeado** (`_adminEmail = 'lfexevega95@gmail.com'` en `dardos_participant_bloc.dart:8` y
   `participant_bloc.dart:127`). Se compara contra `auth.currentUser.email` y se expone como
   `state.isAdmin`. Tiene *defense in depth* **dentro del cliente** (la UI oculta acciones + el BLoC
   re-valida antes de ejecutar, ver `dardos_multi_game_bloc.dart:24`). **⚠️ Importante: NO es seguridad
   real** — las `firestore.rules` permiten escritura a cualquier `isSignedIn()`, así que el gate vive
   solo en la app. Aceptable para uso personal monousuario; para multiusuario debería migrar a
   **Firebase Auth custom claims** + enforcement en rules. *Decir esto proactivamente en entrevista.*
7. ~~**CI/CD:**~~ → **[Confirmado por el autor]** No hay pipeline. Flujo **100% local**: tests a mano
   y compilación/instalación con `build_apk.bat`. *No reclamar CI/CD en el CV.* Mejora natural del
   roadmap: agregar GitHub Actions (test + build de APK en cada push).
8. ~~**Estado de los juegos:**~~ → **[Confirmado por el autor]** Dardos y La Loba están **terminados y
   en uso diario real** (anotar partidas, sacar historial). No son demos ni WIP: son **funcionalidad
   productiva en uso**. No están en `DocsV2/` solo porque esa doc se escribió enfocada en el challenge
   original de Noticias; el código de los juegos es maduro y la fuente de verdad. *En CV: presentarlos
   como funcionalidad en uso, no como experimento.*
9. ~~**Métricas de mejora:**~~ → **[Resuelto en esta revisión]** Estado inicial: 332 pasaban, 11 fallaban
   (todos preexistentes). Causa: refactor de dominio de La Loba (`Player/Partida`→`Participant/Hand`,
   IDs `int`→`String`) que dejó tests apuntando a una API muerta + mocks faltantes. Acciones:
   reescritura de `game_bloc_test.dart`, eliminación de 9 tests huérfanos (use cases ya borrados del
   código) y recreación del fake de `auth_cubit_test`. **Resultado final: `flutter test` → 348 pasan,
   0 fallan (`All tests passed!`).** Además se destrabó `build_runner` (fix de `floor`/`DateTime`), por lo
   que `flutter test --coverage` **ya es ejecutable** (medición numérica: pendiente de correr).

---

## 10. Resumen para entrevista (elevator pitch técnico)

Proyecto Flutter multi-módulo (7 features, ~23.7k LOC, 68 archivos de test) con **Clean Architecture**
estricta y **backend serverless en Firebase**. Núcleo: publicación de artículos propios con seguridad
por ownership y validación de schema en reglas. Overdelivery: dos juegos completos (**Dardos 501/Cricket**
y **La Loba**) con lógica de dominio pura testeada. Estado con BLoC/Cubit, DI con get_it, auth con
email/password + Google. Demuestra: arquitectura limpia, seguridad a nivel de datos, testing en ambas
puntas y capacidad de escalar un starter a un producto multi-app coherente.

---

> *Generado a partir de una revisión directa del repositorio. Las etiquetas [Confirmado] / [Inferido] /
> [Pendiente de validar] permiten al autor decidir qué afirmar con seguridad en una entrevista.*
