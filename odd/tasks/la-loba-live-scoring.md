# La Loba — live scoring, instant score entry, edit last hand

## Objective

Make La Loba score keeping fluid and trustworthy for every viewer at the table.

## Problem

- Dealer rotation froze on the same dealer after the mano was eliminated.
- Closing a hand awaits 2–4 sequential Firestore writes plus a full reload before the UI updates; slow networks block the scorer behind a spinner.
- A mistyped hand cannot be corrected.
- Other devices watching the board only see changes after a manual reload (`getGame` uses one-shot `.get()`).

## Why

Several people follow the same board at the table; the scorer must not wait on the network and mistakes must be fixable.

## Scope

- `frontend/lib/features/la_loba/**` (data source, models, repository, bloc, page).
- `frontend/test/features/la_loba/**`.
- No backend rules change required (hands are overwritten by id; deletes stay denied).

## Constraints

- Keep clean architecture layering (domain repository interface → data impl).
- Firestore latency compensation + its built-in write queue provide the "retry until success" behavior; no custom retry queue.
- Last-write-wins between concurrent scorers is accepted (admin-only scoring).
- Flutter SDK pinned to 3.32.8 for this lockfile (system Flutter 3.47 cannot resolve `bloc_test ^10` + `floor_generator ^1.5`).

## Delivery strategy

`ask-on-risk`. Forecast ≈ 600–800 authored lines → will ask for chain strategy before PRs.

## Tasks

- [x] T1 — Fix dealer rotation freeze after the mano is eliminated. Route: inline (1 source file + 1 test). Commit `56d2e60`. RED observed (`p1` vs expected `p3`), GREEN 27/27 La Loba tests. Review assess: medium, `under_budget`.
- [x] T2 — Realtime board: `watchGame(gameId)` stream (game doc + hands subcollection `snapshots()`), `GameBloc` subscribes on load and cancels on close. Route: delegated writer (data source, repo interface/impl, bloc, fakes). Commit `f54ad2e`. RED: 4/6 new tests failed (no subscription); GREEN 33/33 La Loba tests. Remote updates keep `currentHandScores`, are buffered while a round is closing / retry dialog is open, stream errors are ignored, remote finish emits `gameFinished`. Data-source `snapshots()` combination has no runnable unit test (no Firestore fake in deps).
- [x] T3 — Instant score entry: compute next game state locally, emit it immediately, persist hand + game update (+ winner/stats) in one `WriteBatch` without blocking the UI; surface background failures without losing local state. Route: delegated writer. Commit `9dfb061`. RED: 13 failing (4 new + 9 updated rules tests expecting a single `commitHand` and no loading flash); GREEN 37/37. New `HandCommit` entity + `commitHand` (hand set + game update + winner/status + stats increments in one batch); post-write `getGame` reload removed; failures emit `error` keeping the local board. Data-source batch has no runnable unit test.
- [x] T4 — Edit last hand: each new hand stores a snapshot of the pre-hand state (`participantStatesBefore`, `dealerIdBefore`, `finishedGame`, `winnerId`); admin can reopen the last hand with prefilled scores, re-close it (overwrites same hand doc, reverts winner/stats if needed) or cancel. Legacy hands without snapshot are not editable. Route: delegated writer. Commit: see `git log` (`feat(la_loba): permite editar la ultima mano ...`). RED: 8 new tests failed (+1 for participants added after the snapshot); GREEN 46/46. Edit mode buffers remote updates and applies them on cancel; edited commit uses net stats deltas (`FieldValue.increment`) and rewrites status/winner. UI: admin-only `Editar última mano` app-bar action (also on finished games via `Ver partida`), edit banner with `Cancelar`, edit wording in the confirm dialog, `Agregar` disabled while editing. No widget tests for the page.
- [x] T5 — User follow-up: finished games are correctable only within 10 minutes of the finishing hand's original timestamp (edits never extend the window); visible pencil `Corregir última mano` button. Route: inline (state, bloc clock injection, page label, tests). RED: compile failure (no `now` clock / `editableLastHandAt`); GREEN 48/48; analyze 28 pre-existing issues, none new.

### Hardening round (user request 2026-10-28: "resolvé todo" + rejoin value display)

- [x] T6 — Firestore rules: La Loba writes (`participants`, `games`, `hands`) only for the admin (same email as `participant_bloc.dart:127`); keep reads public. Verify no non-admin client path writes these collections. Rules are NOT deployed by the agent. Route: delegated writer. Commit: `fix(la_loba): restringe escrituras de La Loba al admin en las reglas`. New `isLaLobaAdmin()` (`request.auth.token.email`, no `email_verified` requirement). rg check: every client write (create/update participant, create game, commit hand, add participant to game, status updates) is reachable only from admin-gated UI/bloc paths; `MultiGameBloc` pause/resume/finish events are never dispatched by the UI. No runnable rules test (no emulator harness). Rules must be deployed manually (`firebase deploy --only firestore:rules`).
- [x] T7 — Stats writes in the hand batch must not fail the whole commit when a participant doc is missing (`set` + merge with increments). Route: delegated writer. Commit: `fix(la_loba): evita que falte un participante haga fallar el cierre de mano`. Added dev dependency `fake_cloud_firestore: 4.1.0+1` (exact pin; only new transitive packages, no existing version changed; 4.0.0 does not compile against `cloud_firestore 6.2.0`, 4.1.1+ requires `cloud_firestore ^6.4.0`). RED: new data-source test failed with not-found from `batch.update`; GREEN 49/49 La Loba tests.
- [x] T8 — Persist the rejoin (reentry) score per hand in the hand doc; show it as `(N)` under the orange rejoin total in the board. Legacy hands: compute it in a domain service by replay. Route: delegated writer; merged with T10 in one commit (`feat(la_loba): muestra el puntaje de reingreso por mano en el tablero`) because both live in the same service. `HandEntity.rejoinScores` (null = legacy, `{}` = no rejoins) persisted via `HandModel`/`HandCommit`; rejoin base rule moved to `computeRejoinBaseScore` in `game_round_rules.dart`. Board renders small orange `(N)` under every rejoin cell. RED: bloc tests failed to compile (`rejoinScores` undefined); GREEN 61/61 incl. Firestore round-trip test.
- [x] T9 — Mid-game join no longer writes the entry total into the previous hand's `scores`; store `joinedAtHand` / `joinScore` in participant state. Keep legacy data readable. Route: delegated writer. Commit: `fix(la_loba): guarda el ingreso a mitad de partida en el estado del participante`. `addParticipantToGame` is now a single game update (no previous-hand read/rewrite). `buildBoardHistory` starts a joiner's replay total at `joinScore` and exposes `joinScoresByHand` so the board still shows the entry score in the row before the join (legacy games keep it inside that hand's scores). RED: data-source test (previous hand got `p3: 70`) + service test compile failure; GREEN 64/64.
- [x] T10 — Move legacy elimination/rejoin inference out of `game_play_page.dart` into a pure domain service with tests. New pure `buildBoardHistory(game)` in `domain/services/board_history.dart` (9 unit tests): replays hands with rejoin resets, uses persisted `rejoinScores` or infers legacy rejoins (kept playing / `rejoinedAtHand` / active after last hand) and elimination hands (explicit `eliminatedAtHand` first). Behavior change vs. the old page inference: a legacy player who rejoined and later went out is now marked at the real elimination hand, and every legacy rejoin is colored (not only the last). RED: compile failure without the service; GREEN 9/9.
- [x] T11 — Fix La Loba analyze issues (`use_build_context_synchronously`, `use_super_parameters`, null-aware warnings). Route: delegated writer. Commit: `refactor(la_loba): corrige los avisos del analizador`. 28 → 0 issues: `context.mounted` for dialogs that receive a `BuildContext`, early `return` after the retry dialog in the listener (no other status can match a retryRequired state), super parameters, dead null checks on non-nullable `GameEntity` fields, promotable `final` participant lookup. No behavior change; 64/64 tests green.
- [x] T12 — Remove dead repository/data-source methods; parallelize `getGameHistory` hand reads. Route: delegated writer. Commit: `refactor(la_loba): elimina metodos sin uso y agiliza la carga del historial`. rg confirmed `createHand`, `updateParticipantScores`, `updateGameWinner`, `updateParticipantStatsOnGameFinished` were only referenced by La Loba interface/impl/fakes (Dardos has its own same-named methods, untouched); removed from repository, data source and the 4 test fakes. `getGameHistory` already used `Future.wait` but re-read every game doc via `getGame`; now `_gamesWithHands` reuses the query docs and loads hands in parallel (also for the `queryGamesBy*` methods). No RED: characterization test for history order + hands passed before and after; 65/65, analyze 0.
- [ ] T13 — Widget tests for the game play page key flows; data-source tests with `fake_cloud_firestore` only if it resolves under the pinned SDK without touching other deps.
- [ ] T14 — Pin Flutter 3.32.8 with `.fvmrc` and document why (Floor vs bloc_test analyzer conflict; real fix = migrate Floor, out of La Loba scope).

## Acceptance criteria

- Dealer never freezes; eliminated mano → previous dealer deals again; rotation continues next round.
- Closing a hand updates the scorer's board with no spinner; writes reach Firestore in the background.
- A second device viewing the game sees new totals without reloading.
- Admin can edit the last hand; totals, eliminations, dealer and winner reflect the corrected scores.

## Checks

- `C:/Users/Osobuco/scoop/apps/fvm/current/versions/3.32.8/bin/flutter test test/features/la_loba` (from `frontend/`).
- `flutter analyze lib/features/la_loba test/features/la_loba` with the same SDK.

## Progress

T1–T4 done. Next: native review assessment, then delivery decision (ask for chain strategy: forecast exceeded ~400 lines).
