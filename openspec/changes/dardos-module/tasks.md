# Tasks — Dardos Module

- **Change ID**: dardos-module
- **Date**: 2026-05-21
- **Owner**: Exequiel Vega
- **TDD Mode**: STRICT — tests before every implementation unit

---

## Legend

- `(TDD: red→green→refactor)` — write failing test first, make it pass, clean up
- `(parallel)` — can run alongside other tasks in same phase
- `(sequential)` — must follow the preceding task

Requirements map: R1=Participants, R2=Create game, R3=Roster lock, R4=Cancel, R5=Soft-lock, R6=Throw 501/301, R7=Cricket, R8=Auto-advance, R9=Leg/set/game winner, R10=Undo, R11=Live view, R12=Cricket multi-player, R13=Metrics, R14=Ranking, R15=Navigation, R16=Firestore rules, R17=Domain tests, R18=Isolation

---

## Phase 1 — Foundations

> No logic, no tests. Skeleton only. All tasks parallel.

- [x] **T1.1**: Create folder skeleton `frontend/lib/features/dardos/domain/{entities,services,repository}/`
  - Empty `.gitkeep` files; establishes Clean Architecture layers. (R15, R18)

- [x] **T1.2**: Create folder skeleton `frontend/lib/features/dardos/data/{models,data_sources/remote,repository}/`
  - (parallel) (R15)

- [x] **T1.3**: Create folder skeleton `frontend/lib/features/dardos/presentation/{bloc,pages,widgets,utils}/`
  - (parallel) (R15)

- [x] **T1.4**: Create test folder tree `frontend/test/features/dardos/{domain/services,domain/entities,data/repositories,data/data_sources,presentation/bloc,integration}/`
  - (parallel) (R17)

- [x] **T1.5**: Create `frontend/lib/di/dardos_di.dart` with empty `Future<void> registerDardosDependencies(GetIt sl) async {}` function
  - (parallel) (R15)

- [x] **T1.6**: Add route constants to `frontend/lib/core/navigation/route_names.dart`: `dardos`, `dardosCreate`, `dardosPlay`, `dardosFinished`, `dardosJugadorDetail`
  - (parallel) (R15)

- [x] **T1.7**: Add drawer entry stub to `frontend/lib/core/widgets/app_section_scaffold.dart`: `_DrawerRouteTile(icon: Icons.sports_score, label: 'Dardos', routeName: AppRouteNames.dardos)`
  - (parallel) (R15)

---

## Phase 2 — Domain entities (TDD)

> One entity at a time. Each: write test (red) → implement (green) → refactor.

- [x] **T2.1**: Write `dardos_participant_entity_test.dart` — equality via Equatable, `copyWith` changes every field, null fields allowed for email/uid/deletedAt
  - (TDD: red→green→refactor) (R1, R17)

- [x] **T2.2**: Implement `DardosParticipantEntity` in `domain/entities/dardos_participant.dart` — all fields from design §3, `Equatable`, `copyWith`
  - (sequential after T2.1) (R1)

- [x] **T2.3**: Write `dardos_throw_entity_test.dart` — equality, `copyWith`, `cricketTarget`/`cricketMarksDelta` nullable, `dartIndex` 0..2 range semantics
  - (TDD: red→green→refactor) (R6, R7, R17)

- [x] **T2.4**: Implement `DardosThrowEntity` in `domain/entities/dardos_throw.dart`
  - (sequential after T2.3) (R6, R7)

- [x] **T2.5**: Write `cricket_marks_state_test.dart` — `CricketMarksState.empty(playerIds)` returns zero marks for all targets, equality, `copyWith`
  - (TDD: red→green→refactor) (R7, R12, R17)

- [x] **T2.6**: Implement `CricketMarksState` in `domain/entities/cricket_marks_state.dart` — value object with `marksByPlayer: Map<String, Map<String, int>>` and `pointsByPlayer: Map<String, int>`
  - (sequential after T2.5) (R7, R12)

- [x] **T2.7**: Write `dardos_game_entity_test.dart` — equality, `copyWith`, `legWinners` is `List<List<String?>>`, `throws` field, `winnerId` nullable
  - (TDD: red→green→refactor) (R2, R9, R17)

- [x] **T2.8**: Implement `DardosGameEntity` in `domain/entities/dardos_game.dart` — all fields from design §3, no Firebase imports
  - (sequential after T2.7) (R2, R9)

---

## Phase 3 — Domain services (STRICT TDD — highest priority for coverage)

> One function at a time per service. No shortcuts. Each sub-task is one public function: write test file entry → run (red) → add implementation → run (green).

### `dardos_score_rules.dart` (R6, R17)

- [x] **T3.1**: Write test group `isBust` in `dardos_score_rules_test.dart` — covers ALL bust scenarios:
  - remainingAfter < 0 (overshoot)
  - remainingAfter == 1 with doubleOut=true
  - remainingAfter == 0 with doubleOut=true and multiplier != 2 (single lands on zero)
  - remainingAfter == 0 with doubleOut=true and number==50 multiplier==2 (bull inner = valid checkout, NOT bust)
  - remainingAfter == 0 with doubleOut=false (any dart = valid, not bust)
  - (TDD: red→green→refactor) (R6, R17)

- [x] **T3.2**: Implement `isBust({required int remainingBefore, required int dartPoints, required int dartMultiplier, required bool doubleOut})` in `dardos_score_rules.dart`
  - (sequential after T3.1) (R6)

- [x] **T3.3**: Write test group `isValidCheckout` — mirrors bust logic: valid double, valid bull inner, invalid without doubleOut=false rule, invalid if remainingBefore != dartPoints
  - (TDD: red→green→refactor) (R6, R17)

- [x] **T3.4**: Implement `isValidCheckout({required int remainingBefore, required int dartPoints, required int dartMultiplier, required bool doubleOut})`
  - (sequential after T3.3) (R6)

- [x] **T3.5**: Write test group `nextScoreAfterThrow` — normal subtraction, score floors at bust detection boundary (caller's responsibility), no negative results expected from this function alone
  - (TDD: red→green→refactor) (R6, R17)

- [x] **T3.6**: Implement `nextScoreAfterThrow({required int remainingBefore, required int dartPoints})`
  - (sequential after T3.5) (R6)

- [x] **T3.7**: Write test group `turnTotal` and `isTurnComplete` — 3 darts completes turn, bust on dart 1 completes turn, bust on dart 2 completes turn (no dart 3), non-bust 2-dart turn is NOT complete
  - (TDD: red→green→refactor) (R8, R17)

- [x] **T3.8**: Implement `turnTotal(List<DardosThrowEntity> dartsInTurn)` and `isTurnComplete(List<DardosThrowEntity> dartsInTurn)`
  - (sequential after T3.7) (R8)

- [x] **T3.9**: Write test group `computeRemainingScore` — 501 normal sequence, 301 normal, bust darts excluded from subtraction, multi-player only counts target player's darts
  - (TDD: red→green→refactor) (R6, R17)

- [x] **T3.10**: Implement `computeRemainingScore({required int startScore, required List<DardosThrowEntity> throwsInLeg, required String playerId})`
  - (sequential after T3.9) (R6)

### `dardos_cricket_rules.dart` (R7, R12, R17)

- [x] **T3.11**: Write test group `computeMarksAfterThrow` — single on 15 adds 1 mark, double on 19 adds 2, triple on 20 adds 3, bull exterior adds 1 mark on "bull", bull interior adds 2 marks on "bull", hit on 14 adds 0 marks (invalid target), marks cap at value (>=3 means closed, no negative surplus stored here)
  - (TDD: red→green→refactor) (R7, R17)

- [x] **T3.12**: Implement `computeMarksAfterThrow({required CricketMarksState currentState, required String playerId, required String target, required int multiplier})` — returns new `CricketMarksState`
  - (sequential after T3.11) (R7)

- [x] **T3.13**: Write test group `isTargetClosedByAll` — all 2 players closed = true, one of 2 not closed = false, 3 players all closed = true, 3 players one not closed = false
  - (TDD: red→green→refactor) (R12, R17)

- [x] **T3.14**: Implement `isTargetClosedByAll(Map<String, int> playerMarksOnTarget)`
  - (sequential after T3.13) (R12)

- [x] **T3.15**: Write test group `computePointsFromOverflow` — own marks < 3 → no points (not yet closed), own marks == 3 → 0 surplus points, own marks == 4, opponent not closed → basePoints * 1, own marks == 5, opponent not closed → basePoints * 2, own marks > 3, ALL opponents closed → 0 points (number dead), 3-player scenario: 1 opponent closed, 1 not → points generated, bull target uses 25 as basePoints
  - (TDD: red→green→refactor) (R7, R12, R17)

- [x] **T3.16**: Implement `computePointsFromOverflow({required Map<String, int> playerMarksOnTarget, required String playerId, required String target, required int multiplierApplied, required int basePoints})`
  - (sequential after T3.15) (R7, R12)

- [x] **T3.17**: Write test group `isCricketWinner` — player closed all 7 targets AND pts >= all opponents → true, player closed all but has fewer pts than one opponent → false, player has more pts but one target not closed → false, 3-player all-closed pts comparison
  - (TDD: red→green→refactor) (R7, R12, R17)

- [x] **T3.18**: Implement `isCricketWinner({required CricketMarksState state, required String playerId, required List<String> playerIds})`
  - (sequential after T3.17) (R7, R12)

### `dardos_leg_rules.dart` (R9, R17)

- [x] **T3.19**: Write test group `nextStarter` — `[A,B,C]` globalLeg=0→A, leg=1→B, leg=2→C, leg=3→A (wraps), leg=4→B, single-player list always returns same player
  - (TDD: red→green→refactor) (R9, R17)

- [x] **T3.20**: Implement `nextStarter({required List<String> starterOrder, required int globalLegIndex})`
  - (sequential after T3.19) (R9)

- [x] **T3.21**: Write test group `isLegOver` / `legWinner` — 501 mode: player reaches 0 with valid checkout → leg over, bust dart leaves score > 0 → not over; Cricket mode: player closed all + pts >= others → leg over
  - (TDD: red→green→refactor) (R9, R17)

- [x] **T3.22**: Implement `isLegOver(...)` and `legWinner(...)` — delegates to `dardos_score_rules` for 501/301, to `dardos_cricket_rules` for cricket
  - (sequential after T3.21) (R9)

- [x] **T3.23**: Write test group `isSetOver` / `setWinner` — legs=3: 2 wins for A → set over for A, 1-1 after 2 legs → not over, 2-0 → set over, setWinner returns correct playerId
  - (TDD: red→green→refactor) (R9, R17)

- [x] **T3.24**: Implement `isSetOver({required int legsPerSet, required List<String?> legWinnersInSet})` and `setWinner(List<String?> legWinnersInSet)`
  - (sequential after T3.23) (R9)

- [x] **T3.25**: Write test group `isGameOver` / `gameWinner` — sets=3: 2 wins for A → game over, 1-1 after 2 sets → not over, sets=1: 1 win → game over
  - (TDD: red→green→refactor) (R9, R17)

- [x] **T3.26**: Implement `isGameOver({required int setsPerGame, required List<String?> setWinners})` and `gameWinner(List<String?> setWinners)`
  - (sequential after T3.25) (R9)

---

## Phase 4 — Data layer

> Models first (TDD), then datasource interface, then impl with mocked Firestore, then repository impls.

- [x] **T4.1**: Write `dardos_participant_model_test.dart` — `fromFirestore` parses all fields, `toJson` round-trips, null fields (email, uid, deletedAt) handled correctly
  - (TDD: red→green→refactor) (R1)

- [x] **T4.2**: Implement `DardosParticipantModel` in `data/models/dardos_participant_model.dart` — `toJson`, `fromFirestore(Map, String id)`, `toEntity()`, `fromEntity()`
  - (sequential after T4.1) (R1)

- [x] **T4.3**: Write `dardos_throw_model_test.dart` — `fromFirestore` parses cricket fields (nullable), `toJson` includes all structured fields, `dartIndex` preserved
  - (TDD: red→green→refactor) (R6, R7)

- [x] **T4.4**: Implement `DardosThrowModel` in `data/models/dardos_throw_model.dart`
  - (sequential after T4.3) (R6, R7)

- [x] **T4.5**: Write `dardos_game_model_test.dart` — `fromFirestore` parses nested `legWinners: List<List<String?>>`, `computedMetrics` nullable, `throws` list from snapshot
  - (TDD: red→green→refactor) (R2, R9, R13)

- [x] **T4.6**: Implement `DardosGameModel` in `data/models/dardos_game_model.dart` — handles the nested `legWinners` serialization carefully
  - (sequential after T4.5) (R2, R9)

- [x] **T4.7**: Create `DardosFirestoreDataSource` abstract class in `data/data_sources/remote/dardos_firestore_data_source.dart` — all method signatures from design §6 without implementation
  - (parallel with T4.1-T4.6) (R2, R4, R5, R6, R10)

- [x] **T4.8**: Write `dardos_firestore_data_source_impl_test.dart` — mock `FirebaseFirestore` via mockito; test `acquireAnnotator` transaction returns true when `activeAnnotator == null`, returns false when occupied by another device, sets to own deviceId on success; test `releaseAnnotator` only clears if owned; test `deleteLastThrow` selects last by composite index; test `appendThrow` writes to subcollection
  - (TDD: red→green→refactor) (R5, R10)

- [x] **T4.9**: Implement `DardosFirestoreDataSourceImpl` in `data/data_sources/remote/dardos_firestore_data_source_impl.dart` — full implementation per design §6; references ONLY `dardos_participants` and `dardos_games` paths
  - (sequential after T4.7, T4.8) (R2, R4, R5, R6, R10, R18)

- [x] **T4.10**: Create repository interfaces `DardosGameRepository` and `DardosParticipantRepository` in `domain/repository/`
  - (parallel with T4.7) (R1, R2)

- [x] **T4.11**: Write `dardos_game_repository_impl_test.dart` — mock datasource; happy path for `createGame`, `appendThrow`, `deleteLastThrow`, `finishGame`, `cancelGame`; test `DataState` error wrapping on exception
  - (TDD: red→green→refactor) (R2, R4, R6, R10)

- [x] **T4.12**: Implement `DardosGameRepositoryImpl` in `data/repository/dardos_game_repository_impl.dart`
  - (sequential after T4.10, T4.11) (R2, R4, R6, R10)

- [x] **T4.13**: Write `dardos_participant_repository_impl_test.dart` — mock datasource; `createParticipant`, `fetchAllParticipants`, `deleteParticipant` (soft-delete sets `isActive=false`); error wrapping
  - (TDD: red→green→refactor) (R1)

- [x] **T4.14**: Implement `DardosParticipantRepositoryImpl` in `data/repository/dardos_participant_repository_impl.dart`
  - (sequential after T4.13) (R1)

---

## Phase 5 — BLoCs (bloc_test)

> Each BLoC: write all event/state tests first (failing), then implement the BLoC to make them pass.

### `DardosBottomNavBloc` (trivial)

- [x] **T5.1**: Write `dardos_bottom_nav_bloc_test.dart` — `ChangeTabEvent(0/1/2)` emits correct `DardosBottomNavState`; initial state is tab 0
  - (TDD: red→green→refactor) (R15)

- [x] **T5.2**: Implement `DardosBottomNavBloc` with `DardosBottomNavEvent` and `DardosBottomNavState` in `presentation/bloc/`
  - (sequential after T5.1) (R15)

### `DardosParticipantBloc`

- [x] **T5.3**: Write `dardos_participant_bloc_test.dart` — covers:
  - `FetchAllParticipantsEvent` → emits loading then success with list
  - `CreateParticipantEvent` by admin → calls repo, emits success
  - `CreateParticipantEvent` by non-admin → emits error, repo NOT called
  - `DeleteParticipantEvent` by admin → repo called with soft-delete
  - `DeleteParticipantEvent` by non-admin → emits error, repo NOT called
  - `CheckAdminStatusEvent` with admin email → `isAdmin = true`
  - (TDD: red→green→refactor) (R1)

- [x] **T5.4**: Implement `DardosParticipantBloc` with full admin gate (email check `lfexevega95@gmail.com`)
  - (sequential after T5.3) (R1)

### `DardosMultiGameBloc`

- [x] **T5.5**: Write `dardos_multi_game_bloc_test.dart` — `LoadGamesEvent` emits loading then games list; cancelled games excluded from ranking query; `LoadGamesByModeEvent` filters by mode; `RefreshGamesEvent` re-fetches
  - (TDD: red→green→refactor) (R4, R14)

- [x] **T5.6**: Implement `DardosMultiGameBloc` with events and states
  - (sequential after T5.5) (R4, R14)

### `DardosGameBloc` (most complex)

- [x] **T5.7**: Write `dardos_game_bloc_test.dart` — Part A: creation and loading
  - `CreateDardosGameEvent` with valid inputs → repo called, navigates
  - `CreateDardosGameEvent` with <2 participants → error, no repo call (R2)
  - `CreateDardosGameEvent` with empty name → error, no repo call (R2)
  - `LoadDardosGameEvent` → emits loading then loaded state (R11)
  - (TDD: red→green→refactor) (R2)

- [x] **T5.8**: Write `dardos_game_bloc_test.dart` — Part B: annotator lock
  - `AcquireAnnotatorEvent` → repo transaction called, `annotatorOwned=true` on success
  - `RecordThrowEvent` without lock → emits `annotatorLocked` error, repo NOT called
  - `ReleaseAnnotatorEvent` when owned → clears lock (R5)
  - (TDD: red→green→refactor) (R5)

- [x] **T5.9**: Write `dardos_game_bloc_test.dart` — Part C: roster lock
  - First `RecordThrowEvent` on game with `rosterLocked=false` → sets `rosterLocked=true` before appending throw
  - Subsequent `RecordThrowEvent` → `rosterLocked` stays true (R3)
  - (TDD: red→green→refactor) (R3)

- [x] **T5.10**: Write `dardos_game_bloc_test.dart` — Part D: 501/301 throw recording
  - Normal throw → `appendThrow` called, live score updated, dart advances
  - 3rd dart completes turn → auto-advance to next player, `bannerType=none` then auto-advance
  - Bust on dart 2 → throw persisted with `isBust=true`, turn ends immediately (R6, R8)
  - (TDD: red→green→refactor) (R6, R8)

- [x] **T5.11**: Write `dardos_game_bloc_test.dart` — Part E: leg/set/game resolution
  - Valid checkout → `legWinners` updated, `bannerType=legWon` emitted, starter rotates (R9)
  - Leg win completes set → `setWinners` updated, `bannerType=setWon` (R9)
  - Final set win → `finishGame` called, `updateParticipantStats` called, `bannerType=gameWon`, `activeAnnotator` released, status=`gameFinished` (R9, R13)
  - (TDD: red→green→refactor) (R9, R13)

- [x] **T5.12**: Write `dardos_game_bloc_test.dart` — Part F: undo
  - `UndoLastThrowEvent` with throws present → `deleteLastThrow` called, `getThrows` called, state recomputed via replay, `bannerType=none` (R10)
  - `UndoLastThrowEvent` with 0 throws → ignored, no repo calls (R10)
  - Undo crosses leg boundary → `legWinners` recalculated correctly (R10)
  - (TDD: red→green→refactor) (R10)

- [x] **T5.13**: Write `dardos_game_bloc_test.dart` — Part G: cancellation
  - `CancelGameEvent` by admin → repo `cancelGame` called (R4)
  - `CancelGameEvent` by non-admin → error, no repo call (R4)
  - (TDD: red→green→refactor) (R4)

- [x] **T5.14**: Implement `DardosGameBloc` with all events and states, integrating domain services for bust/cricket/leg resolution; implement `_recomputeGameState` per design §10
  - (sequential after T5.7–T5.13) (R2, R3, R4, R5, R6, R7, R8, R9, R10, R13)

---

## Phase 6 — Presentation pages & widgets

> Widget tests where meaningful. Pages are smoke tests (renders without throw).

- [x] **T6.1**: Implement `DardosWrapper` in `presentation/pages/dardos_wrapper.dart` — `IndexedStack` with 3 tabs driven by `DardosBottomNavBloc`, `BottomNavigationBar` with Iniciar/Jugadores/Ranking labels
  - (R15)

- [x] **T6.2**: Implement `IniciarTab` in `presentation/pages/iniciar_tab.dart` — list of active games from `DardosMultiGameBloc`, "Crear partida" FAB (visible to all authenticated), tap game tile → navigate to `dardosPlay`
  - (R2, R11)

- [x] **T6.3**: Implement `JugadoresTab` in `presentation/pages/jugadores_tab.dart` — list from `DardosParticipantBloc`, admin-only "+" FAB, soft-deleted participants hidden, tap → `dardosJugadorDetail`
  - (R1)

- [x] **T6.4**: Implement `RankingTab` in `presentation/pages/ranking_tab.dart` — `DefaultTabController` with sub-tabs 301/501/Cricket, each sub-tab queries `DardosMultiGameBloc` filtered by mode and status=finished, sorted per R14 rules
  - (R14)

- [x] **T6.5**: Implement `CreateGamePage` in `presentation/pages/create_game_page.dart` — name field, mode toggle (501/301/cricket), doubleOut toggle (disabled when cricket), sets/legs steppers (>=1), multi-select participant list, submit dispatches `CreateDardosGameEvent`, doubleOut forced false for cricket
  - (R2)

- [x] **T6.6**: Implement `ThrowInputGrid` widget in `presentation/widgets/throw_input_grid.dart` — 6×4 grid numbers 1-20 + bull button, tap opens `MultiplierModal`, "Miss" button, emits `RecordThrowEvent`; disabled/hidden when `!annotatorOwned`
  - (R6)

- [x] **T6.7**: Implement `MultiplierModal` widget — BottomSheet with 1x/2x/3x buttons; 3x disabled for bull; dismisses on selection
  - (R6)

- [x] **T6.8**: Implement `CricketBoard` widget in `presentation/widgets/cricket_board.dart` — table N players × 7 targets (15-20+bull); marks shown as tally marks (|, X); closed target highlighted; points shown per player; tapping a target+multiplier emits `RecordThrowEvent` with cricketTarget; disabled when `!annotatorOwned`
  - (R7, R12)

- [x] **T6.9**: Implement `PlayerDartCard` widget — name, live score (501/301) or points+marks (Cricket), "su turno" indicator, last 3 darts of current turn
  - (R6, R7, R11)

- [x] **T6.10**: Implement `LegSetIndicator` widget — `Set X/Y · Leg N/M` banner; updates from game state
  - (R9, R15)

- [x] **T6.11**: Implement `AnnotatorLockBanner` widget — orange banner "X está anotando. Tocá para tomar el control"; button dispatches `AcquireAnnotatorEvent`; hidden when `annotatorOwned`; for anonymous users button is absent
  - (R5, R11)

- [x] **T6.12**: Implement `AutoAdvanceBanner` widget — full-screen overlay, 2s Timer auto-dismiss → dispatches `AcknowledgeBannerEvent`; renders different text per `bannerType` (BUST / Leg ganado / Set para X / ¡Partida ganada!)
  - (R8, R9)

- [x] **T6.13**: Implement `GamePlayPage` in `presentation/pages/game_play_page.dart` — assembles all widgets; on load dispatches `LoadDardosGameEvent` + `AcquireAnnotatorEvent`; on WillPopScope/dispose dispatches `ReleaseAnnotatorEvent`; shows `ThrowInputGrid` (501/301) OR `CricketBoard`; shows undo button; `BlocListener` handles `gameFinished` → navigate to `dardosFinished`; shows `AutoAdvanceBanner` overlay when `bannerType != none`
  - (R5, R6, R7, R8, R9, R10, R11)

- [x] **T6.14**: Implement `GameFinishedPage` in `presentation/pages/game_finished_page.dart` — mode, sets/legs played, doubleOut, winner name, metrics per player (`avg3Dart`, `bestTurn`, `count180s`, `count140plus`, `checkoutPct` for 501/301; `mpr`, `closes` for Cricket)
  - (R13)

- [x] **T6.15**: Implement `JugadorDetailPage` in `presentation/pages/jugador_detail_page.dart` — participant name, stats per mode from `statsByMode` map, games played/won
  - (R1, R14)

---

## Phase 7 — Integration & glue

- [x] **T7.1**: Wire DI in `frontend/lib/injection_container.dart` — add `await registerDardosDependencies(sl);` after la_loba registration
  - (R15)

- [x] **T7.2**: Add all 5 dardos route cases to `frontend/lib/config/routes/routes.dart` — per design §14, each with correct `BlocProvider` wrapping; `dardos` case wraps `DardosWrapper` with `BlocProvider<DardosBottomNavBloc>`
  - (R15)

- [x] **T7.3**: Populate `dardos_di.dart` with all registrations per design §13 — datasource, repos, BLoCs as `registerLazySingleton`/`registerFactory`
  - (sequential after T4.9, T4.12, T4.14, T5.2, T5.4, T5.6, T5.14) (R15)

- [x] **T7.4**: Update `backend/firestore.rules` — add `dardos_participants`, `dardos_games`, and `throws` subcollection rules per design §12; `throws` allows `delete: if isSignedIn()` (intentional deviation from la_loba for undo support)
  - (R16)

- [x] **T7.5**: Write `integration/no_cross_collection_writes_test.dart` — static analysis / string search test that asserts no file under `lib/features/dardos/` references the strings `'participants'` or `collection('games')` without the `dardos_` prefix (fails the test if found)
  - (TDD: red→green→refactor) (R18)

- [x] **T7.6**: Write `integration/undo_roundtrip_test.dart` — simulate a full 501 game with N throws via domain services, undo all N throws one by one, verify state returns to initial; redo N throws, verify same final state as before undos
  - (TDD: red→green→refactor) (R10)

---

## Phase 8 — Polish

- [x] **T8.1**: Verify `AutoAdvanceBanner` auto-dismiss is exactly 2000ms via `fakeAsync` widget test — no manual timer leak
  - (R8, R9)

- [x] **T8.2**: Add empty state widget to `IniciarTab` — "No hay partidas activas. ¡Crea una!" shown when games list is empty
  - (R2)

- [x] **T8.3**: Add empty state to `JugadoresTab` — "No hay jugadores registrados." shown when participants list is empty
  - (R1)

- [x] **T8.4**: Add empty state to `RankingTab` sub-tabs — "Sin datos para este modo todavía." per sub-tab when no finished games exist for that mode
  - (R14)

- [x] **T8.5**: Add `CircularProgressIndicator` loading states to `IniciarTab`, `JugadoresTab`, and `RankingTab` — shown on `status == loading`
  - (R11)

- [x] **T8.6**: Add admin-only "Forzar liberación de anotador" button in `GamePlayPage` — visible only when `participantBloc.state.isAdmin`; dispatches `ReleaseAnnotatorEvent` unconditionally (design §11 edge case)
  - (R5)

- [x] **T8.7**: Final isolation check — manual review of all files under `frontend/lib/features/dardos/` confirming zero references to `/participants` or `/games` Firestore paths (complement to T7.5 automated check)
  - (R18)

---

## Task summary

| Phase | Tasks | Notes |
|-------|-------|-------|
| 1 — Foundations | T1.1–T1.7 (7) | All parallel, no logic |
| 2 — Domain entities | T2.1–T2.8 (8) | TDD pairs, sequential per entity |
| 3 — Domain services | T3.1–T3.26 (26) | TDD strict, grouped by service |
| 4 — Data layer | T4.1–T4.14 (14) | Models → datasource → repos |
| 5 — BLoCs | T5.1–T5.14 (14) | bloc_test, GameBloc split 7 test tasks + 1 impl |
| 6 — Presentation | T6.1–T6.15 (15) | Pages + widgets |
| 7 — Integration | T7.1–T7.6 (6) | Glue + integration tests |
| 8 — Polish | T8.1–T8.7 (7) | Banners, empty states, loading |
| **Total** | **97 tasks** | |

### Dependency chain (critical path)

```
T1.x (foundations)
  → T2.x (entities)
    → T3.x (services — can start in parallel with T2.x after T1.x)
      → T4.x (data layer — needs entities)
        → T5.x (BLoCs — needs repos + services)
          → T6.x (presentation — needs BLoCs)
            → T7.x (glue — needs all)
              → T8.x (polish)
```

Phase 3 and Phase 2 can interleave: service tests can be written while entity implementations are in progress, since service tests only depend on `DardosThrowEntity` (T2.4) and `CricketMarksState` (T2.6).
