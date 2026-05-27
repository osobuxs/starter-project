# Design — Dardos Module

- **Change ID**: dardos-module
- **Date**: 2026-05-21
- **Owner**: Exequiel Vega
- **Related**: `openspec/changes/dardos-module/proposal.md`, engram `sdd/dardos-module/explore` (#159), `sdd/dardos-module/proposal` (#160), `reglas_dardos_501_cricket.md`

> Documento técnico: arquitectura, modelo de datos, BLoCs, undo event-sourced, soft-lock transaccional y plan de tests para el módulo `dardos/`. Refleja archivo por archivo el patrón de `la_loba`, con tres diferencias estructurales (write-per-throw, state machine leg→set→game, dominio dividido en 3 servicios puros).

---

## 1. Architecture overview

```
+--------------------------------------------------------------------------+
|                              presentation/                                |
|  pages: dardos_wrapper, iniciar_tab, jugadores_tab, ranking_tab,          |
|         create_game_page, game_play_page, game_finished_page,             |
|         jugador_detail_page                                               |
|  widgets: throw_input, player_dart_card, cricket_board,                   |
|           multiplier_modal, leg_set_indicator, annotator_lock_banner      |
|  bloc: DardosGameBloc, DardosMultiGameBloc, DardosParticipantBloc,        |
|        DardosBottomNavBloc                                                |
|                                  |                                        |
|                                  v                                        |
+--------------------------------------------------------------------------+
|                                domain/                                    |
|  entities: DardosGameEntity, DardosThrowEntity, DardosLegEntity,          |
|            DardosParticipantEntity, CricketMarksState                     |
|  services (pure):                                                         |
|    - dardos_score_rules.dart    (501/301 countdown, bust, double-out)     |
|    - dardos_cricket_rules.dart  (marks, cross points, close condition)    |
|    - dardos_leg_rules.dart      (leg/set/game winners, starter rotation)  |
|  repository (abstract):                                                   |
|    - DardosGameRepository                                                 |
|    - DardosParticipantRepository                                          |
|                                  ^                                        |
|                                  | (interfaces, no Firebase imports)      |
+--------------------------------------------------------------------------+
|                                 data/                                     |
|  models: DardosGameModel, DardosThrowModel, DardosLegModel,               |
|          DardosParticipantModel  (toJson / fromFirestore)                 |
|  data_sources/remote:                                                     |
|    - DardosFirestoreDataSource (interface)                                |
|    - DardosFirestoreDataSourceImpl (FirebaseFirestore, transactions)      |
|  repository:                                                              |
|    - DardosGameRepositoryImpl                                             |
|    - DardosParticipantRepositoryImpl                                      |
+--------------------------------------------------------------------------+
                                   |
                                   v
                          Firestore (cloud_firestore 6.2.0)
```

Reglas de dependencia (todas verificadas en tests de import):
- `domain/` no importa `package:cloud_firestore` ni `package:flutter_bloc`.
- `data/` importa `domain/` y `package:cloud_firestore`. No importa `presentation/`.
- `presentation/` importa `domain/` (entidades + repos como interfaces, vía sl) y `package:flutter_bloc`. No importa `package:cloud_firestore` directamente.
- DI: `dardos_di.dart` resuelve interfaces a impls — único punto de contacto.

---

## 2. Firestore data model

Tres colecciones, **completamente independientes** de `participants` / `games` de la_loba.

### 2.1 `/dardos_participants/{participantId}`

```json
{
  "id": "auto",
  "name": "Exe",
  "email": "lfexevega95@gmail.com",
  "uid": "firebase-uid-or-null",
  "isActive": true,
  "deletedAt": null,
  "createdAt": 1716000000000,
  "totalGamesPlayed": 12,
  "totalGamesWon": 4,
  "statsByMode": {
    "501":     { "played": 5, "won": 2, "avg3Dart": 42.3, "best180s": 3, "checkoutPct": 0.18 },
    "301":     { "played": 4, "won": 1, "avg3Dart": 38.0, "best180s": 0, "checkoutPct": 0.10 },
    "cricket": { "played": 3, "won": 1, "mpr": 1.7, "closes": 22 }
  }
}
```

- `email` opcional (puede ser null para invitados).
- `uid` opcional: si el jugador está vinculado a una cuenta Firebase.
- `isActive` + `deletedAt`: soft-delete (mismo patrón que la_loba).
- `statsByMode` se actualiza al finalizar cada partida en transacción/batch sobre `updateParticipantStatsOnGameFinished`.

### 2.2 `/dardos_games/{gameId}`

```json
{
  "id": "auto",
  "name": "Final torneo viernes",
  "mode": "501",                       // "501" | "301" | "cricket"
  "doubleOut": true,                   // ignored when mode == cricket
  "sets": 1,                           // 1..7
  "legs": 3,                           // 1..9
  "status": "playing",                 // "playing" | "finished" | "cancelled"
  "createdAt": 1716000000000,
  "createdBy": "uid-of-creator",
  "playerIds": ["p1","p2","p3"],
  "starterOrder": ["p1","p2","p3"],    // locked al primer throw
  "rosterLocked": false,               // true tras el primer throw
  "currentSet": 0,                     // index 0-based
  "currentLeg": 0,                     // dentro del set actual
  "currentTurnPlayerId": "p1",
  "currentTurnIndex": 0,               // turno global dentro del leg
  "currentDartIndex": 0,               // 0,1,2 dentro del turno
  "legWinners":  [["p1","p2"], []],    // [setIndex][legIndex] -> playerId
  "setWinners":  ["p1", null],
  "winnerId": null,
  "activeAnnotator": null,             // deviceId | null  (soft-lock)
  "activeAnnotatorAt": null,           // ts ms para staleness opcional v2
  "isActive": true,
  "deletedAt": null,
  "cancelledAt": null,
  "cancelledBy": null,
  "computedMetrics": null              // se llena al finish
}
```

`computedMetrics` (al `finish`, calculado client-side replayando throws):
```json
{
  "perPlayer": {
    "p1": { "avg3Dart": 45.1, "highestTurn": 140, "count180": 1, "count140plus": 3, "checkouts": 2, "checkoutAttempts": 6, "checkoutPct": 0.33 },
    "p2": { "avg3Dart": 38.7, "highestTurn": 96,  "count180": 0, "count140plus": 1, "checkouts": 1, "checkoutAttempts": 5, "checkoutPct": 0.20 }
  },
  "perPlayerCricket": {
    "p1": { "mpr": 2.1, "closes": 7 }
  }
}
```

### 2.3 `/dardos_games/{gameId}/throws/{throwId}`

Un documento por **dardo individual**, no por turno. Permite undo dardo-a-dardo y analytics granular.

```json
{
  "id": "auto",
  "playerId": "p1",
  "setIndex": 0,
  "legIndex": 0,
  "turnIndex": 4,                      // turno global dentro del leg
  "dartIndex": 1,                      // 0,1,2 dentro del turno
  "number": 20,                        // 1..20 | 25 (bull)
  "multiplier": 3,                     // 1|2|3 (3 sólo para 1..20; bull: 1 o 2)
  "points": 60,                        // number * multiplier (o 0 si missed)
  "isMiss": false,
  "isBust": false,                     // marcado en 501/301 si este dardo busta el turno
  "remainingAfter": 441,               // 501/301: score restante DESPUÉS de aplicar; cricket: null
  "cricketTarget": null,               // cricket: 15..20 | "bull" | null si miss
  "cricketMarksDelta": null,           // cricket: marcas que sumó (0,1,2,3)
  "cricketPointsScored": 0,            // cricket: puntos cruzados generados por este dardo
  "timestamp": 1716000123456,
  "createdBy": "uid"
}
```

Ordenado por `(setIndex, legIndex, turnIndex, dartIndex)` ascendente — esa es la clave de orden total para el replay del undo.

---

## 3. Domain entities

Todas inmutables, `Equatable`, con `copyWith`. Sin imports de Firebase, sin lógica I/O. Dart `<3.0.0` → sin sealed/records/switch expressions.

### `DardosParticipantEntity`
```
id: String
name: String
email: String?
uid: String?
isActive: bool
deletedAt: int?
createdAt: int
totalGamesPlayed: int
totalGamesWon: int
statsByMode: Map<String, Map<String, dynamic>>
```

### `DardosGameEntity`
```
id: String
name: String
mode: String                 // '501' | '301' | 'cricket'
doubleOut: bool
sets: int
legs: int
status: String               // 'playing' | 'finished' | 'cancelled'
createdAt: int
createdBy: String
playerIds: List<String>
starterOrder: List<String>
rosterLocked: bool
currentSet: int
currentLeg: int
currentTurnPlayerId: String
currentTurnIndex: int
currentDartIndex: int
legWinners: List<List<String?>>    // [setIndex][legIndex]
setWinners: List<String?>
winnerId: String?
activeAnnotator: String?
activeAnnotatorAt: int?
isActive: bool
deletedAt: int?
cancelledAt: int?
cancelledBy: String?
computedMetrics: Map<String, dynamic>?
throws: List<DardosThrowEntity>    // hidratado on-demand al loadGame
```

### `DardosThrowEntity`
```
id: String
playerId: String
setIndex: int
legIndex: int
turnIndex: int
dartIndex: int               // 0..2
number: int                  // 1..20 | 25
multiplier: int              // 1..3
points: int
isMiss: bool
isBust: bool
remainingAfter: int?         // 501/301
cricketTarget: String?       // '15'..'20' | 'bull' | null
cricketMarksDelta: int?
cricketPointsScored: int
timestamp: int
createdBy: String
```

### `DardosLegEntity` (proyección runtime, no persistida directamente — se computa)
```
setIndex: int
legIndex: int
starterId: String
turns: List<DardosTurnView>  // agrupación lógica
winnerId: String?
```

### `CricketMarksState` (value object usado por `dardos_cricket_rules`)
```
marksByPlayer: Map<String, Map<String, int>>
  // ej: { 'p1': {'15':3, '16':2, '17':0, '18':0, '19':0, '20':3, 'bull':1} }
pointsByPlayer: Map<String, int>
```

---

## 4. Domain services (firmas, sin implementación)

### `domain/services/dardos_score_rules.dart` (501/301)
```dart
int computeRemainingScore({
  required int startScore,           // 501 o 301
  required List<DardosThrowEntity> throwsInLeg,
  required String playerId,
});

bool isBust({
  required int remainingBefore,
  required int dartPoints,
  required int dartMultiplier,
  required bool doubleOut,
});
// bust si remainingAfter < 0
// bust si remainingAfter == 0 && doubleOut && multiplier != 2 (excepto bull doble = 50)
// bust si remainingAfter == 1 && doubleOut

bool isValidCheckout({
  required int remainingBefore,
  required int dartPoints,
  required int dartMultiplier,
  required bool doubleOut,
});

int nextScoreAfterThrow({
  required int remainingBefore,
  required int dartPoints,
});

// Helpers para detección de turno cerrado y avance
int turnTotal(List<DardosThrowEntity> dartsInTurn);
bool isTurnComplete(List<DardosThrowEntity> dartsInTurn);  // dartIndex==2 o bust
```

### `domain/services/dardos_cricket_rules.dart`
```dart
CricketMarksState computeMarksAfterThrow({
  required CricketMarksState currentState,
  required String playerId,
  required String target,             // '15'..'20' | 'bull'
  required int multiplier,            // 1..3 (bull: 1 o 2)
});

int computePointsFromOverflow({
  required Map<String, int> playerMarksOnTarget,    // por jugador, antes del tiro
  required String playerId,
  required String target,
  required int multiplierApplied,
  required int basePoints,            // 15..20 o 25 (bull)
});
// puntos sólo si jugador cerró (>=3) Y existe oponente con marks < 3 en ese target

bool isTargetClosedByAll(Map<String,int> playerMarksOnTarget);

bool isCricketWinner({
  required CricketMarksState state,
  required String playerId,
  required List<String> playerIds,
});
// gana si: todos sus targets (15-20+bull) están en >=3 marks AND points >= max(otros)
```

### `domain/services/dardos_leg_rules.dart`
```dart
bool isLegOver({
  required String mode,
  required int legStartScore,           // 501/301
  required List<DardosThrowEntity> legThrows,
  required List<String> playerIds,
});

String? legWinner({
  required String mode,
  required int legStartScore,
  required List<DardosThrowEntity> legThrows,
  required List<String> playerIds,
  required bool doubleOut,
});

bool isSetOver({
  required int legsPerSet,
  required List<String?> legWinnersInSet,
});

String? setWinner(List<String?> legWinnersInSet);

bool isGameOver({
  required int setsPerGame,
  required List<String?> setWinners,
});

String? gameWinner(List<String?> setWinners);

String nextStarter({
  required List<String> starterOrder,
  required int globalLegIndex,          // setIndex * legs + legIndex
});
// return starterOrder[globalLegIndex % starterOrder.length]
```

---

## 5. Repository interfaces

### `DardosGameRepository`
```dart
Future<DataState<DardosGameEntity>> createGame({
  required String name,
  required String mode,
  required bool doubleOut,
  required int sets,
  required int legs,
  required List<String> playerIds,
  required String createdBy,
});

Future<DataState<DardosGameEntity>> getGame(String gameId);
Future<DataState<List<DardosGameEntity>>> getGameHistory();
Future<DataState<List<DardosGameEntity>>> queryGamesByStatus(String status);
Future<DataState<List<DardosGameEntity>>> queryGamesByMode(String mode);

Future<DataState<DardosThrowEntity>> appendThrow({
  required String gameId,
  required DardosThrowEntity throw_,
});

Future<DataState<void>> deleteLastThrow(String gameId);
Future<DataState<List<DardosThrowEntity>>> getThrows(String gameId);

Future<DataState<void>> updateGameProgress({
  required String gameId,
  required int currentSet,
  required int currentLeg,
  required String currentTurnPlayerId,
  required int currentTurnIndex,
  required int currentDartIndex,
  required List<List<String?>> legWinners,
  required List<String?> setWinners,
  required bool rosterLocked,
});

Future<DataState<void>> finishGame({
  required String gameId,
  required String winnerId,
  required Map<String, dynamic> computedMetrics,
});

Future<DataState<void>> cancelGame({
  required String gameId,
  required String cancelledBy,
});

// Soft-lock (ver §11)
Future<DataState<bool>> acquireAnnotator({
  required String gameId,
  required String deviceId,
});
Future<DataState<void>> releaseAnnotator({
  required String gameId,
  required String deviceId,
});

Future<DataState<void>> updateParticipantStatsOnGameFinished({
  required List<String> playerIds,
  required String winnerId,
  required String mode,
  required Map<String, dynamic> metricsPerPlayer,
});
```

### `DardosParticipantRepository`
Mismas firmas que `ParticipantRepository` de la_loba pero apuntando a `dardos_participants`:
```dart
Future<DataState<DardosParticipantEntity>> createParticipant(DardosParticipantEntity p);
Future<DataState<void>> updateParticipant(DardosParticipantEntity p);
Future<DataState<void>> deleteParticipant(String id);   // soft-delete
Future<DataState<List<DardosParticipantEntity>>> fetchAllParticipants();
Future<DataState<DardosParticipantEntity>> fetchParticipantById(String id);
```

---

## 6. Firestore data source

### `DardosFirestoreDataSource` (interface)
Métodos espejo de `DardosGameRepository` pero crudos (sin `DataState`, sin envolver). Patrón idéntico a `LaLobaFirestoreDataSource`.

### `DardosFirestoreDataSourceImpl` (FirebaseFirestore inyectado)
Outline clave:

```dart
class DardosFirestoreDataSourceImpl implements DardosFirestoreDataSource {
  final FirebaseFirestore _firestore;
  DardosFirestoreDataSourceImpl(this._firestore);

  CollectionReference get _games => _firestore.collection('dardos_games');
  CollectionReference get _participants =>
      _firestore.collection('dardos_participants');

  Future<DardosGameEntity> createGame({...}) async {
    final ref = _games.doc();
    final game = DardosGameEntity(... starterOrder: List.from(playerIds), ...);
    await ref.set(DardosGameModel.fromEntity(game).toJson());
    return game.copyWith(id: ref.id);
  }

  Future<DardosGameEntity> getGame(String id) async {
    final snap = await _games.doc(id).get();
    if (!snap.exists) throw Exception('Game not found');
    final throwsSnap = await _games.doc(id).collection('throws')
        .orderBy('setIndex').orderBy('legIndex')
        .orderBy('turnIndex').orderBy('dartIndex')
        .get();
    final throws_ = throwsSnap.docs
        .map((d) => DardosThrowModel.fromFirestore(d.data(), d.id).toEntity())
        .toList();
    return DardosGameModel.fromFirestore(snap.data()!, snap.id, throws_)
        .toEntity();
  }

  Future<DardosThrowEntity> appendThrow({...}) async {
    final ref = _games.doc(gameId).collection('throws').doc();
    await ref.set(DardosThrowModel.fromEntity(throw_).toJson());
    return throw_.copyWith(id: ref.id);
  }

  Future<void> deleteLastThrow(String gameId) async {
    final q = await _games.doc(gameId).collection('throws')
        .orderBy('setIndex', descending: true)
        .orderBy('legIndex', descending: true)
        .orderBy('turnIndex', descending: true)
        .orderBy('dartIndex', descending: true)
        .limit(1).get();
    if (q.docs.isEmpty) return;
    await q.docs.first.reference.delete();
  }

  // Soft-lock: compare-and-swap transaccional
  Future<bool> acquireAnnotator({required String gameId,
                                  required String deviceId}) async {
    return _firestore.runTransaction<bool>((tx) async {
      final ref = _games.doc(gameId);
      final snap = await tx.get(ref);
      final current = snap.data()?['activeAnnotator'] as String?;
      if (current == null || current == deviceId) {
        tx.update(ref, {
          'activeAnnotator': deviceId,
          'activeAnnotatorAt': DateTime.now().millisecondsSinceEpoch,
        });
        return true;
      }
      return false;
    });
  }

  Future<void> releaseAnnotator({required String gameId,
                                  required String deviceId}) async {
    await _firestore.runTransaction((tx) async {
      final ref = _games.doc(gameId);
      final snap = await tx.get(ref);
      if (snap.data()?['activeAnnotator'] == deviceId) {
        tx.update(ref, {
          'activeAnnotator': null,
          'activeAnnotatorAt': null,
        });
      }
    });
  }
}
```

---

## 7. BLoCs

### `DardosGameBloc` (state machine de la partida activa)

**Events**:
- `CreateDardosGameEvent({name, mode, doubleOut, sets, legs, playerIds})`
- `LoadDardosGameEvent({gameId})`
- `AcquireAnnotatorEvent({gameId, deviceId})`
- `ReleaseAnnotatorEvent({gameId, deviceId})`
- `RecordThrowEvent({number, multiplier, isMiss})` — agrega 1 dardo
- `UndoLastThrowEvent()` — deshace dardo anterior (event-sourced replay)
- `CancelGameEvent({gameId, cancelledBy})` — admin only (validado en repo/UI)
- `AcknowledgeBannerEvent()` — cierra el cartel 2s manualmente

**State** (`DardosGameState`, Equatable):
```
status: enum {
  initial, loading, gameCreated, loaded, throwRecorded,
  bustDetected, legWon, setWon, gameFinished,
  annotatorLocked, error,
}
game: DardosGameEntity?
throws: List<DardosThrowEntity>
liveScores: Map<String,int>             // computado en cada recompute
cricketState: CricketMarksState?        // null si mode != cricket
annotatorOwned: bool                    // true si nuestro deviceId tiene el lock
bannerType: enum { none, bust, legWon, setWon, gameWon }
bannerPayload: String?                  // ej: "Pedro ganó el leg"
error: String?
```

Flujo `RecordThrowEvent`:
1. Si `!annotatorOwned` → emit `annotatorLocked`, return.
2. Si `!game.rosterLocked` y es el primer throw → set `rosterLocked = true` antes de escribir.
3. Construir `DardosThrowEntity` con `setIndex/legIndex/turnIndex/dartIndex` actuales.
4. Aplicar reglas en domain services para detectar bust / leg / set / game.
5. `appendThrow` al repo.
6. Si bust → marcar throw con `isBust=true`, avanzar turno, banner 2s.
7. Si `isLegOver` → escribir `legWinners`, rotar starter (`nextStarter`), banner.
8. Si `isSetOver` → escribir `setWinners`, banner.
9. Si `isGameOver` → calcular `computedMetrics`, `finishGame`, `updateParticipantStatsOnGameFinished`.

Flujo `UndoLastThrowEvent`:
1. `deleteLastThrow(gameId)` en repo.
2. `getThrows(gameId)` ordenado.
3. **Recompute total** del state (ver §10).
4. Emit nuevo state con `liveScores`/`cricketState` recomputados, `bannerType=none`.

### `DardosMultiGameBloc` (dashboard de partidas)

Events: `LoadGamesEvent`, `LoadGamesByModeEvent({mode})`, `RefreshGamesEvent`.
State: `{status, games: List<DardosGameEntity>, error}`.

Patrón idéntico a `MultiGameBloc` de la_loba.

### `DardosParticipantBloc`

Events espejo de la_loba: `CreateParticipantEvent`, `UpdateParticipantEvent`, `DeleteParticipantEvent`, `FetchAllParticipantsEvent`, `CheckAdminStatusEvent`.
State: `{status, participants, isAdmin, error}`.
Admin gate idéntico: `_auth.currentUser?.email == 'lfexevega95@gmail.com'`.

### `DardosBottomNavBloc`

Events: `ChangeTabEvent(int index)`.
State: `{currentTabIndex: int}`.
3 tabs: 0=Iniciar, 1=Jugadores, 2=Ranking.

---

## 8. Pages — flujo

```
Drawer (AppSectionScaffold)
   |
   +-- "Dardos" tile (Icons.sports_score) -> AppRouteNames.dardos
        |
        v
  +------------------+
  |  DardosWrapper   |  (provee DardosBottomNavBloc via BlocProvider)
  |  IndexedStack:   |
  |   - IniciarTab   |  (DardosMultiGameBloc)
  |   - JugadoresTab |  (DardosParticipantBloc)
  |   - RankingTab   |  (DardosMultiGameBloc, sub-tabs 301/501/Cricket)
  +------------------+
        |
        +-- IniciarTab "Crear partida" (admin) -> AppRouteNames.dardosCreate
        |        |
        |        v
        |   CreateGamePage  (BlocProvider<DardosGameBloc>)
        |    - selectMode (501/301/Cricket)
        |    - doubleOut toggle (disabled si Cricket)
        |    - sets, legs steppers
        |    - participant multi-select
        |    - name input
        |    -> on create -> Navigator.pushReplacementNamed(dardosPlay, args: gameId)
        |
        +-- IniciarTab tile partida activa -> AppRouteNames.dardosPlay(gameId)
                 |
                 v
            GamePlayPage  (BlocProvider<DardosGameBloc>..add LoadGame + AcquireAnnotator)
             - AnnotatorLockBanner si !annotatorOwned (read-only)
             - LegSetIndicator (set X/Y, leg N/M)
             - ThrowInputGrid (501/301: grid 1-20+bull, modal multiplicador)
             - CricketBoard (Cricket: por jugador, targets 15-20+bull)
             - Undo button (sin restricción)
             - on gameFinished -> Navigator.pushReplacementNamed(dardosFinished)
                 |
                 v
            GameFinishedPage
             - modo, sets/legs jugados, double-out, ganador
             - métricas por jugador (avg, 180s, checkout% / MPR Cricket)

JugadoresTab tile -> AppRouteNames.dardosJugadorDetail(participantId)
   -> JugadorDetailPage (stats persistidas por modo)
```

---

## 9. Widgets

- **`ThrowInputGrid`** — grid 5x5: números 1-20 + bull (25). Tap → abre `MultiplierModal` con (1x/2x/3x; 3x disabled para bull). Botón "Miss" para dardo fuera. Emite `RecordThrowEvent`.
- **`MultiplierModal`** — BottomSheet con 3 botones grandes. Cierra al elegir.
- **`CricketBoard`** — tabla N jugadores × 7 targets (15..20, bull). Por celda: marcas (rayas/cruz) + indicador "cerrado por todos". Resaltar puntos acumulados.
- **`PlayerDartCard`** — tarjeta por jugador: nombre, puntaje vivo (501/301) o puntos+marcas (Cricket), indicador "su turno", últimos 3 dardos del turno actual.
- **`LegSetIndicator`** — banner superior: `Set 1/3 · Leg 2/5`.
- **`AnnotatorLockBanner`** — banner naranja: "Otro dispositivo está anotando" + botón "Tomar control" (dispara `AcquireAnnotatorEvent` con re-check transaccional).
- **`AutoAdvanceBanner`** — overlay 2s: "BUST", "Pedro ganó el leg", "Set para Ana", "¡Partida ganada!". Auto-dismiss via Timer + `AcknowledgeBannerEvent`.

---

## 10. Undo design — event-sourced replay

Premisa: el estado vivo (`liveScores`, `cricketState`, `currentSet`, `currentLeg`, `currentTurnPlayerId`, `currentTurnIndex`, `currentDartIndex`, `legWinners`, `setWinners`) es **derivable** de la lista ordenada de throws. Por lo tanto el undo es:

1. Borrar el último throw de la subcolección.
2. Releer todos los throws ordenados.
3. Recomputar el estado desde cero.

Pseudocódigo del recompute (en `DardosGameBloc._recomputeGameState`):

```dart
DardosGameState recomputeFromThrows({
  required DardosGameEntity baseGame,
  required List<DardosThrowEntity> throws_,
}) {
  // Throws vienen pre-ordenados por (setIndex, legIndex, turnIndex, dartIndex)
  final mode = baseGame.mode;
  final legStartScore = mode == '501' ? 501 : mode == '301' ? 301 : 0;

  // Estado vivo
  var currentSet = 0;
  var currentLeg = 0;
  var currentTurnIndex = 0;
  var currentDartIndex = 0;
  var currentTurnPlayerId = baseGame.starterOrder[0];
  final legWinners = List<List<String?>>.generate(
      baseGame.sets, (_) => List<String?>.filled(baseGame.legs, null));
  final setWinners = List<String?>.filled(baseGame.sets, null);
  final liveScores = <String,int>{
    for (final p in baseGame.playerIds) p: legStartScore,
  };
  var cricket = CricketMarksState.empty(baseGame.playerIds);

  for (final t in throws_) {
    if (mode == 'cricket') {
      // delegar a dardos_cricket_rules
      cricket = computeMarksAfterThrow(
        currentState: cricket,
        playerId: t.playerId,
        target: t.cricketTarget!,
        multiplier: t.multiplier,
      );
    } else {
      // 501/301
      if (!t.isBust) {
        liveScores[t.playerId] = liveScores[t.playerId]! - t.points;
      }
      // si isBust el liveScore del turno se restaura al inicio del turno —
      // ese estado ya quedó capturado porque solo restamos puntos de
      // dardos NO-bust del turno.
    }

    // Avance de cursor (turno/leg/set)
    if (t.dartIndex == 2 || t.isBust) {
      // turno cerrado
      currentTurnIndex += 1;
      currentDartIndex = 0;
      currentTurnPlayerId = _nextPlayerInRotation(
        baseGame.starterOrder, baseGame.playerIds, currentTurnIndex,
        baseGame.currentSet * baseGame.legs + currentLeg);
    } else {
      currentDartIndex = t.dartIndex + 1;
    }

    if (isLegOver(...)) {
      legWinners[currentSet][currentLeg] = legWinner(...);
      currentLeg += 1;
      currentTurnIndex = 0;
      currentDartIndex = 0;
      // reset scores
      for (final p in baseGame.playerIds) liveScores[p] = legStartScore;
      cricket = CricketMarksState.empty(baseGame.playerIds);
      currentTurnPlayerId = nextStarter(
        starterOrder: baseGame.starterOrder,
        globalLegIndex: currentSet * baseGame.legs + currentLeg,
      );
      if (isSetOver(legsPerSet: baseGame.legs,
                    legWinnersInSet: legWinners[currentSet])) {
        setWinners[currentSet] = setWinner(legWinners[currentSet]);
        currentSet += 1;
        currentLeg = 0;
      }
    }
  }

  final winner = gameWinner(setWinners);
  return DardosGameState(
    game: baseGame.copyWith(
      currentSet: currentSet,
      currentLeg: currentLeg,
      currentTurnPlayerId: currentTurnPlayerId,
      currentTurnIndex: currentTurnIndex,
      currentDartIndex: currentDartIndex,
      legWinners: legWinners,
      setWinners: setWinners,
      winnerId: winner,
    ),
    throws: throws_,
    liveScores: liveScores,
    cricketState: cricket,
    status: winner != null
        ? DardosGameStatus.gameFinished
        : DardosGameStatus.loaded,
  );
}
```

Coste: O(n) con n ≤ ~300 throws/partida → trivial. Después del recompute, el BLoC también dispara `updateGameProgress` para persistir el cursor en el doc del game (mantiene consistencia si otro device lo abre).

**Test de integridad** (obligatorio): para una partida completa simulada, `N undos + N RecordThrow idénticos` debe producir el mismo state final.

---

## 11. Soft-lock design

Campo `activeAnnotator: String?` en `dardos_games/{id}`. Cada cliente tiene un `deviceId` único (generado via `uuid` o `flutter_secure_storage` y cacheado en SharedPreferences).

Transacción de adquisición (ver §6 impl):
```
runTransaction:
  read activeAnnotator
  if (null || == myDeviceId):
    set activeAnnotator = myDeviceId
    set activeAnnotatorAt = now()
    return true
  else:
    return false
```

UX:
- Al entrar a `GamePlayPage` → `AcquireAnnotatorEvent`. Si `true` → modo write.
- Si `false` → modo read-only, muestra `AnnotatorLockBanner` con botón "Tomar control" que repite la transacción.
- Al salir de la página (dispose) → `ReleaseAnnotatorEvent` (si `annotatorOwned`).
- Si la partida finaliza → release automático.

Edge case: cliente A toma lock, crashea sin release → lock queda "pegado". v1 acepta esto; admin libera manualmente (botón "Forzar liberación" en `GamePlayPage` visible sólo si `participantBloc.state.isAdmin`). Heartbeat / TTL en `activeAnnotatorAt` queda para v2.

---

## 12. Firestore security rules

Agregar al final del bloque `match /databases/{database}/documents` en `backend/firestore.rules`, después del bloque de `/games/{gameId}`:

```
// Dardos
match /dardos_participants/{participantId} {
  allow read: if true;
  allow create, update: if isSignedIn();
  allow delete: if false;
}

match /dardos_games/{gameId} {
  allow read: if true;
  allow create, update: if isSignedIn();
  allow delete: if false;

  match /throws/{throwId} {
    allow read: if true;
    allow create, update, delete: if isSignedIn();
    // throws.delete permitido (a diferencia de games.delete) porque el
    // undo borra documentos. Diseño event-sourced lo requiere.
  }
}
```

NOTA crítica: a diferencia de la_loba (donde TODAS las deletes son false), la subcolección `throws` permite `delete: if isSignedIn()` porque el undo lo necesita. `dardos_games` y `dardos_participants` siguen el patrón soft-delete sin delete real.

---

## 13. DI registration — `frontend/lib/di/dardos_di.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
// imports de feature/dardos/...

Future<void> registerDardosDependencies(GetIt sl) async {
  // Data sources
  sl.registerLazySingleton<DardosFirestoreDataSource>(
    () => DardosFirestoreDataSourceImpl(sl<FirebaseFirestore>()),
  );

  // Repositories
  sl.registerLazySingleton<DardosGameRepository>(
    () => DardosGameRepositoryImpl(sl<DardosFirestoreDataSource>()),
  );
  sl.registerLazySingleton<DardosParticipantRepository>(
    () => DardosParticipantRepositoryImpl(sl<FirebaseFirestore>()),
  );

  // BLoCs
  sl.registerFactory(() => DardosGameBloc(repository: sl()));
  sl.registerFactory(() => DardosMultiGameBloc(sl<DardosGameRepository>()));
  sl.registerFactory(() => DardosParticipantBloc(
        sl<DardosParticipantRepository>(),
        sl<FirebaseAuth>(),
      ));
  sl.registerFactory(() => DardosBottomNavBloc());
}
```

Invocación en `injection_container.dart`:
```dart
await registerLaLobaDependencies(sl);
await registerDardosDependencies(sl);  // <-- añadir
```

---

## 14. Navigation integration

### `route_names.dart` — diff
```dart
class AppRouteNames {
  // ...existing...
  static const laLobaParticipantDetail = '/LaLoba/ParticipantDetail';

  // Dardos
  static const dardos = '/Dardos';
  static const dardosCreate = '/Dardos/Create';
  static const dardosPlay = '/Dardos/Play';
  static const dardosFinished = '/Dardos/Finished';
  static const dardosJugadorDetail = '/Dardos/JugadorDetail';
}
```

### `app_section_scaffold.dart`
Agregar tras el `_DrawerRouteTile` de La Loba:
```dart
const _DrawerRouteTile(
  icon: Icons.sports_score,
  label: 'Dardos',
  routeName: AppRouteNames.dardos,
),
```

### `routes.dart` — agregar cases (patrón espejo de la_loba)
```dart
case AppRouteNames.dardos:
  return _materialRoute(settings, policy: policy,
      child: BlocProvider<DardosBottomNavBloc>(
        create: (_) => sl<DardosBottomNavBloc>(),
        child: const DardosWrapper(),
      ));

case AppRouteNames.dardosCreate:
  return _materialRoute(settings, policy: policy,
      child: BlocProvider<DardosGameBloc>(
        create: (_) => sl<DardosGameBloc>(),
        child: const DardosCreateGamePage(),
      ));

case AppRouteNames.dardosPlay:
  final gameId = _extractGameId(settings.arguments);
  if (gameId == null) { /* error route */ }
  return _materialRoute(settings, policy: policy,
      child: BlocProvider<DardosGameBloc>(
        create: (_) => sl<DardosGameBloc>()..add(LoadDardosGameEvent(gameId)),
        child: DardosGamePlayPage(gameId: gameId),
      ));

case AppRouteNames.dardosFinished:
  /* idem con DardosGameFinishedPage */

case AppRouteNames.dardosJugadorDetail:
  /* idem con JugadorDetailPage(participantId) */
```

**RESOLUCIÓN del riesgo #1 (BottomNavBloc ambigua de la_loba)**: en dardos NO replicamos la ambigüedad. `DardosBottomNavBloc` se provee explícitamente como `BlocProvider` al envolver `DardosWrapper` en `routes.dart` (ver `case AppRouteNames.dardos` arriba). Esto deja la dependencia visible y testeable, sin depender de un MultiBlocProvider global mal documentado.

### `injection_container.dart`
Ver §13.

### `backend/firestore.rules`
Ver §12.

---

## 15. Test plan summary

Layout (TDD strict activo — domain primero):

```
frontend/test/features/dardos/
  domain/
    services/
      dardos_score_rules_test.dart       <- §4.1 (501/301 + bust + double-out)
      dardos_cricket_rules_test.dart     <- §4.2 (marks, cross points, close)
      dardos_leg_rules_test.dart         <- §4.3 (legWinner, setWinner, rotation)
    entities/
      dardos_game_entity_test.dart       <- equality, copyWith
      dardos_throw_entity_test.dart      <- equality, copyWith
      dardos_participant_entity_test.dart
      cricket_marks_state_test.dart
  data/
    repositories/
      dardos_game_repository_impl_test.dart        <- mockito FakeFirestore
      dardos_participant_repository_impl_test.dart
    data_sources/
      dardos_firestore_data_source_impl_test.dart  <- transacción soft-lock
  presentation/
    bloc/
      dardos_game_bloc_test.dart         <- bloc_test: record, bust, undo, finish
      dardos_multi_game_bloc_test.dart
      dardos_participant_bloc_test.dart  <- admin gate
      dardos_bottom_nav_bloc_test.dart
  integration/
    undo_roundtrip_test.dart             <- N undo + N replay -> mismo state
    no_cross_collection_writes_test.dart <- verifica que NUNCA escribe en
                                             /participants ni /games
```

Cobertura objetivo:
- `domain/services/*` > 90%
- `domain/entities/*` 100% (equality/copyWith)
- `data/repositories/*` > 80% (paths felices + 2 errores por método)
- `presentation/bloc/*` flujos clave (record throw, bust, undo, leg/set/game finished, cancel admin-only)

Orden TDD obligatorio (primer batch de tasks):
1. `dardos_score_rules_test.dart` → impl `dardos_score_rules.dart`
2. `dardos_cricket_rules_test.dart` → impl `dardos_cricket_rules.dart`
3. `dardos_leg_rules_test.dart` → impl `dardos_leg_rules.dart`
4. Entity tests → impls
5. Models (toJson/fromFirestore) tests → impls
6. Repository impl tests (mocked) → impls
7. BLoC tests (bloc_test + mockito) → impls
8. Páginas / widgets (smoke + widget tests donde valga la pena)

Mapping spec → tests (resumen — el doc `tasks.md` lo expandirá):
- "Bust si remainingAfter < 0 / == 1 / == 0 sin double" → `dardos_score_rules_test.dart`
- "Cricket: punto sólo si cerré y oponente no" → `dardos_cricket_rules_test.dart`
- "Rotación cíclica del starter por leg" → `dardos_leg_rules_test.dart::nextStarter`
- "Undo encadenable cruza fronteras" → `undo_roundtrip_test.dart`
- "Soft-lock compare-and-swap" → `dardos_firestore_data_source_impl_test.dart`
- "Roster lock al primer throw" → `dardos_game_bloc_test.dart`
- "Cancelación admin-only excluye de ranking" → `dardos_game_bloc_test.dart` + `dardos_multi_game_bloc_test.dart`
- "No cross-write a colecciones de la_loba" → `no_cross_collection_writes_test.dart`
