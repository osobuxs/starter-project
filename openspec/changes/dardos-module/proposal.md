# Dardos Module

- **Status**: Draft
- **Date**: 2026-05-21
- **Owner**: Exequiel Vega
- **Change ID**: dardos-module

## Intent

Incorporar al app un nuevo módulo de feature, "dardos", que permita registrar y puntuar partidas de dardos (501, 301 y Cricket) con soporte para sets/legs, double-out opcional y anotación por tiro. Replica el patrón arquitectónico ya consolidado en `la_loba` (Clean Architecture + BLoC + Firestore + GetIt), pero con un modelo de dominio propio (mucho más rico que el de manos) y colecciones Firestore independientes. El objetivo es habilitar partidas reales con varios jugadores, anotador único por partida, historial completo de tiros (event-sourced para undo + analytics) y un dashboard/ranking análogo al de La Loba.

## Scope

### In (v1)
- Tres modos de juego: **501**, **301** y **Cricket** (estándar, sin Cut Throat).
- Configuración por partida: **sets** y **legs**, **double-out** on/off (501/301).
- Anotación **tiro por tiro** (3 dardos por turno) con bust detection.
- Persistencia event-sourced en `dardos_games/{id}/throws/{id}` (un write por tiro).
- **Soft-lock de anotador**: campo `activeAnnotator` en el game; sólo el dispositivo poseedor puede escribir; toma del lock por compare-and-swap.
- **Undo del último tiro sin restricción** — se puede deshacer el último dardo aunque cruce fronteras de turno, leg o set (replay del event log).
- Colecciones Firestore **independientes**: `dardos_participants` y `dardos_games` (NO compartidas con la_loba).
- Pantalla wrapper con bottom nav de 3 tabs: **Iniciar / Jugadores / Ranking** (con sub-tabs internos 301 / 501 / Cricket en Ranking).
- Admin gate por email idéntico al de `la_loba` (`lfexevega95@gmail.com`): sólo admin crea jugadores y cancela partidas; cualquier usuario logueado crea partidas y anota; usuarios anónimos sólo leen.
- **Cancelación de partidas**: sólo admin. Partidas canceladas NO suman al ranking (no contabilizan W/L) pero SÍ persisten sus tiros para analítica.
- **Nombre de partida** manual al crear (mismo patrón que la_loba).
- **Soft-delete** con `isActive` + `deletedAt` (jugadores y partidas).
- **Roster lock** al primer tiro de la partida: no se pueden agregar/quitar jugadores ni reordenar.
- **Rotación cíclica del starter por leg** (leg N → jugador `N mod count`).
- **Métricas de ranking persistidas por partida**: avg 3-dart, mejor turno, 180s, 140+, checkout % (501/301); MPR, cierres (Cricket). Se computan al finalizar la partida.
- **Stats por tiro persistidas con campos estructurados**: `{number, multiplier, points, ...}` (no totales pre-calculados) para habilitar análisis posterior.
- Cartel visual 2s con auto-avance en bust / leg ganado / set ganado.
- Drawer entry global "Dardos" en `AppSectionScaffold` con `Icons.sports_score`.
- Reglas Firestore extendidas (`dardos_participants`, `dardos_games`, subcolección `throws`).
- Tests unitarios obligatorios en `domain/services/` (strict TDD activo).

### Out (v1 — explícito)
- Reconocimiento de voz / dictado por voz para tiros.
- Modo **Cut Throat** de Cricket.
- **Master Out** y **Double-In**.
- Compartir `participants` con `la_loba` (jugadores son entidades separadas).
- Cache local SQLite / modo offline (sólo Firestore en línea).
- Edición concurrente real con CRDT / OT; el soft-lock es suficiente.
- Importación/exportación de partidas.
- **Dashboard de analítica avanzada por jugador** (gráficos de tendencia, heatmaps de tablero, drill-down histórico) — fuera de v1. Los datos crudos sí se persisten desde v1.

## Approach

Espejar la estructura de `la_loba` archivo por archivo, con tres diferencias estructurales:

1. **Granularidad de escritura**: en vez de `updateParticipantScores` en batch por mano, se escribe un `DardosThrowEntity` por cada tiro a la subcolección `throws`. El estado agregado del game (puntajes vivos, leg/set actuales, ganador) se mantiene en el doc del game y se recomputa en cliente desde el evento.
2. **State machine de 2 niveles**: leg → set → game. El BLoC mantiene `currentLeg`, `currentSet`, `starterOrder[]`, `legWinners[]`, `setWinners[]` y rota el starter cíclicamente.
3. **Dominio puro separado por modo**: tres servicios sin dependencias — `dardos_score_rules.dart` (501/301 countdown + bust + double-out), `dardos_cricket_rules.dart` (marcas, puntos cruzados, condición de cierre) y `dardos_leg_rules.dart` (winner de leg/set/game, rotación de starter).

Capas:
- **domain/**: entidades inmutables (`Equatable`), servicios puros (funciones, sin BLoC, sin Firestore), interfaces de repository.
- **data/**: modelos `toJson/fromFirestore`, datasource Firestore con la interfaz `DardosFirestoreDataSource`, repos que delegan al datasource.
- **presentation/**: BLoCs (`DardosGameBloc`, `DardosMultiGameBloc`, `DardosParticipantBloc`), páginas y widgets.
- **DI**: `dardos_di.dart` con `registerDardosDependencies(sl)`, invocado desde `injection_container.dart`.

Soft-lock: al iniciar la anotación, el cliente hace un update transaccional sobre `dardos_games/{id}` con condición `activeAnnotator == null || activeAnnotator == myDeviceId`. Si falla, la UI muestra "otro dispositivo está anotando" y entra en modo read-only. El lock se libera al cerrar la pantalla o al finalizar la partida.

Undo (sin restricción): el último throw se borra del subcollection; el estado agregado del game se recomputa replayando los throws restantes ordenados por (set, leg, turn, dartIndex). Esto permite deshacer aunque cruce turnos, legs o sets — el costo es un recompute completo del estado, pero la cantidad de eventos por partida es acotada (~60-300).

## Affected areas

### Crear (nuevos archivos)
```
frontend/lib/features/dardos/
  domain/
    entities/
      dardos_game.dart
      dardos_throw.dart
      dardos_leg.dart
      dardos_participant.dart
      cricket_marks_state.dart
    services/
      dardos_score_rules.dart
      dardos_cricket_rules.dart
      dardos_leg_rules.dart
    repository/
      dardos_game_repository.dart
      dardos_participant_repository.dart
  data/
    models/
      dardos_game_model.dart
      dardos_throw_model.dart
      dardos_leg_model.dart
      dardos_participant_model.dart
    data_sources/remote/
      dardos_firestore_data_source.dart
      dardos_firestore_data_source_impl.dart
    repository/
      dardos_game_repository_impl.dart
      dardos_participant_repository_impl.dart
  presentation/
    bloc/
      dardos_game_bloc.dart
      dardos_game_state.dart
      dardos_game_event.dart
      dardos_multi_game_bloc.dart
      dardos_multi_game_state.dart
      dardos_multi_game_event.dart
      dardos_participant_bloc.dart
      dardos_participant_state.dart
      dardos_participant_event.dart
      dardos_bottom_nav_bloc.dart
      dardos_bottom_nav_state.dart
      dardos_bottom_nav_event.dart
    pages/
      dardos_wrapper.dart
      iniciar_tab.dart
      jugadores_tab.dart
      ranking_tab.dart
      create_game_page.dart
      game_play_page.dart
      game_finished_page.dart
      jugador_detail_page.dart
    widgets/
      throw_input.dart
      player_dart_card.dart
      cricket_board.dart
      leg_set_indicator.dart
      annotator_lock_banner.dart
    utils/
      dardos_participant_display.dart

frontend/lib/di/dardos_di.dart

frontend/test/features/dardos/
  domain/
    services/
      dardos_score_rules_test.dart
      dardos_cricket_rules_test.dart
      dardos_leg_rules_test.dart
    entities/ (equality/copyWith tests)
  data/
    repositories/ (mocked Firestore)
  presentation/
    bloc/ (bloc_test + mockito)
```

### Editar
- `frontend/lib/core/navigation/route_names.dart` — agregar `dardos`, `dardosCreate`, `dardosPlay`, `dardosFinished`, `dardosJugadorDetail`.
- `frontend/lib/core/widgets/app_section_scaffold.dart` — `_DrawerRouteTile` con `Icons.sports_score`, label `'Dardos'`, ruta `AppRouteNames.dardos`.
- `frontend/lib/config/routes/routes.dart` — case entries para las rutas de dardos con BlocProvider wrapping equivalente al de la_loba.
- `frontend/lib/injection_container.dart` — `await registerDardosDependencies(sl)`.
- `backend/firestore.rules` — añadir bloques `dardos_participants`, `dardos_games` y subcolección `throws` (read público, write `isSignedIn()`, delete deshabilitado — mismo patrón que la_loba).
- `frontend/pubspec.yaml` — sin cambios (todas las deps ya presentes).

## Risks & mitigations

| # | Riesgo | Mitigación |
|---|--------|------------|
| 1 | **Provisión de `BottomNavBloc` ambigua en la_loba** (registrado en DI pero consumido en wrapper sin BlocProvider visible en `routes.dart`). | Verificar en apply: si la_loba lo provee internamente en el wrapper, replicar el mismo patrón en `DardosWrapper`. Si lo provee `main.dart`, agregar `DardosBottomNavBloc` allí. NO copiar a ciegas. |
| 2 | **Cricket cross-player scoring** (un punto sólo se suma si yo cerré y el oponente no). Requiere leer estado de marcas de TODOS los jugadores en cada throw. | Aislar la lógica en `dardos_cricket_rules.dart` como función pura `computePointsAfterThrow(currentMarks, allPlayersMarks, target, multiplier)`. Tests exhaustivos en TDD antes de tocar BLoC. |
| 3 | **Undo sin restricción (cruza turnos/legs/sets)** — costo de recompute en cada undo. | Modelo event-sourced: cada undo borra el último throw y recomputa el estado vivo del game desde la subcolección `throws` ordenada. Eventos por partida acotados (~300 max) → recompute es O(n) trivial. Test de integridad: el estado tras N undos + N redos debe ser idéntico al original. |
| 4 | **`activeAnnotator` race conditions** — sin transacción, dos clientes pueden creer que ganaron el lock. | Usar `FirebaseFirestore.runTransaction` para tomar/soltar el lock; condición `activeAnnotator == null || == myDeviceId`. Heartbeat opcional v2; v1 acepta el lock "pegado" si el cliente se desconecta (admin libera manualmente). |
| 5 | **Write-per-throw infla 3× el volumen de datos vs la_loba** y costo Firestore. | Aceptado: es lo que permite undo y analytics. Documentar en design el budget esperado (≈60 writes por partida 501 promedio). |
| 6 | **SDK `<3.0.0`** — sin records, sin switch expressions, sin sealed classes. | Usar clases planas + `Equatable`, if/else chains en servicios. Code review explícito para evitar sintaxis Dart 3. |
| 7 | **Cross-write accidental a colección `participants` de la_loba**. | Los repos de dardos referencian SÓLO `dardos_participants` y `dardos_games`. Test de integración que falle si algún path apunta a `participants` o `games`. |
| 8 | **State machine de 2 niveles (leg/set/game)** es nueva — no hay precedente en la_loba. | Aislar en `dardos_leg_rules.dart` con funciones puras: `isLegOver`, `isSetOver`, `isGameOver`, `nextStarter`. TDD obligatorio. |

## Non-goals

- Reconocimiento por voz / dictado de tiros.
- Modo **Cut Throat**.
- **Master Out** y **Double-In**.
- Compartir entidades `participants` con `la_loba`.
- Cache offline / SQLite local.
- Resolución de conflictos en edición concurrente más allá del soft-lock.
- Estadísticas avanzadas (3-dart average, checkout %, 180s) — habilitadas por event-sourcing pero fuera de v1.
- Importación/exportación de partidas.

## Open questions

Ninguna. Todas las decisiones de diseño fueron cerradas en la sesión grill-me previa (engram `dardos/design-decisions` #158).

## Acceptance criteria

- [ ] El módulo `dardos/` existe con la estructura Clean Architecture espejada de la_loba.
- [ ] Se puede crear una partida (admin) eligiendo modo (501/301/Cricket), participantes, sets, legs y double-out.
- [ ] Se puede jugar una partida completa anotando tiro por tiro; el bust se detecta correctamente en 501/301.
- [ ] Cricket calcula marcas, cierres y puntos cruzados según `reglas_dardos_501_cricket.md`.
- [ ] El ganador de leg, set y partida se determina automáticamente y se persiste.
- [ ] Existe soft-lock funcional: un segundo dispositivo ve la partida en read-only.
- [ ] Existe undo del último tiro **sin restricción** — funciona aunque cruce turnos, legs o sets, encadenable hasta el principio de la partida.
- [ ] Sólo el admin puede cancelar una partida; las partidas canceladas no aparecen en ranking pero conservan sus tiros.
- [ ] El roster queda lockeado al primer tiro: no se pueden agregar/quitar/reordenar jugadores después.
- [ ] La pantalla de partida finalizada muestra modo, sets/legs jugados, double-out usado, ganador, y métricas por jugador (avg, 180s, checkout % para 501/301; MPR para Cricket).
- [ ] El ranking tiene 3 sub-tabs (301/501/Cricket) con métricas por modo.
- [ ] Las reglas Firestore permiten read público y write autenticado en `dardos_participants`, `dardos_games` y `dardos_games/{id}/throws`.
- [ ] El drawer global muestra entry "Dardos" con `Icons.sports_score`.
- [ ] Los servicios de dominio (`dardos_score_rules`, `dardos_cricket_rules`, `dardos_leg_rules`) tienen cobertura de tests unitarios > 90% (TDD strict).
- [ ] Las colecciones de dardos NO escriben jamás en `participants` ni `games` de la_loba.
