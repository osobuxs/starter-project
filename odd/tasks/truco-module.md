# Truco — new scoring module

## Objective

Add a Truco score keeper module that mirrors La Loba/Dardos conventions (admin-only writes, own player registry, create game, live board) with a matchstick-style board.

## Problem

The app has La Loba and Dardos scorers but no Truco. Paper "anotadores" use groups of five sticks (a square closed by a diagonal); players want that look, digitally, with exact per-hand numbers.

## Scope

- New feature folder `frontend/lib/features/truco/**` (domain, data, presentation) + tests in `frontend/test/features/truco/**`.
- Wiring: DI module, routes, and the dashboard/module entry next to La Loba/Dardos.
- Firestore rules for the new collections are the LAST task (user request).

## Product decisions (from user, 2026-10-28)

- Modes: 1v1, 2v2, 3v3. Two teams; each team has a team name and its members are chosen from registered Truco players.
- Start screen shows seating: players alternate team A / team B around the table.
- Target: 18 points (9 malas + 9 buenas) or 30 points (15 + 15). Board separates malas and buenas.
- Per hand, enter exact numbers per team (add or subtract, like La Loba), press confirm; the board then shows the totals as matchsticks.
- Matchsticks must look like real matches (wooden stick + red head), grouped in fives like paper anotadores; original look.
- Admin rule identical to La Loba (same admin email). Player registry separate from La Loba, like Dardos (`truco_participants`).
- Same UX qualities as La Loba: instant local update with background save, realtime board for viewers, correct last hand.

## Constraints

- Clean architecture: domain entities + pure rules, repository interface, Firestore impl.
- Flutter pinned to 3.32.8 (`frontend/.fvmrc`); run with `C:/Users/Osobuco/scoop/apps/fvm/current/versions/3.32.8/bin/flutter`.
- Code/comments English; UI copy Spanish.

## Delivery strategy

`ask-on-risk`. Forecast ≈ 2.5–3.5k authored lines (new module).

## Tasks

- [x] T1 — Domain: entities (TrucoGame, TrucoTeam, TrucoHand, TrucoParticipant) + pure rules (apply hand with clamping 0..target, malas/buenas split, winner, matchstick grouping into fives) with unit tests.
- [x] T2 — Data: Firestore data source/models/repository (`truco_participants`, `truco_games`, `truco_games/{id}/hands`), `watchGame` realtime, single-batch hand commit, edit last hand; `fake_cloud_firestore` tests.
- [x] T3 — Players: admin-only register/edit players (bloc + page), mirroring La Loba.
- [x] T4 — Create game: mode, target 18/30, team names, pick players per team, seating preview.
- [x] T5 — Game board: per-team numeric entry (+/−), confirm, matchstick painter with malas/buenas divider, winner, correct last hand, realtime.
- [x] T6 — Wiring: DI, routes, module entry, game history list.
- [x] T6b — History, ranking and player detail (user request): stats on finish in the hand batch (net deltas on correction), finished games history, ranking (win counts for every member of the winning team), player detail page, bottom nav like La Loba/Dardos.
- [x] T6b — History, ranking and player detail (user scope addition 2026-10-28): per-player stats persisted in the hand-commit batch with net deltas on correction; Historial tab (finished games, read-only), Ranking tab mirroring La Loba/Dardos (a win counts for every member of the winning team), player detail page; bottom nav wrapper.
- [ ] T7 — Firestore rules for Truco collections (admin-only writes, public reads). Not deployed by the agent.

## Decisions

- Both teams reaching the target in the same hand: the higher raw (unclamped) total wins; an exact tie blocks the hand with an error so the admin corrects the entry.
- Create defaults to 2 vs 2 at 30 points; picking a player for the other team moves them; reordering uses up/down arrows within a team.
- Confirm closes the hand immediately (no confirmation dialog) because the board updates locally and the last hand can be corrected; a 0–0 hand is rejected. Per-hand entry is bounded to -99..99.
- Ranking uses the persisted per-player totals (like La Loba/Dardos); the player detail totals are computed from that player's finished games, and finished games open on the same board page in read-only mode.
- Malas/buenas are drawn from the clamped total: malas = min(total, half), buenas = the rest, each regrouped in fives from zero (so a half of 9 closes with a group of four).

## Acceptance criteria

- An admin registers players, creates a 1v1/2v2/3v3 game at 18 or 30, sees the seating, records hands, and the board shows matchsticks per team split into malas/buenas until a team wins.
- Viewers see the board update live; non-admins cannot write.

## Checks

- `flutter test test/features/truco` and full `flutter test`.
- `flutter analyze lib/features/truco test/features/truco` → no issues.

## Progress

- T1 (route: delegated writer, single bounded writer for the module). RED: `flutter test test/features/truco` failed to compile (missing `trucoSeatingOrder`, entities). GREEN: 20 tests passed; analyze: No issues found.
- T2 (delegated writer). RED: data source test failed to compile (no `TrucoFirestoreDataSourceImpl`). GREEN: 32 truco tests passed (fake_cloud_firestore: create, read, finish stats, edit revert/swap with net deltas, watchGame, participants); analyze: No issues found.
- T3 (delegated writer). RED: participant bloc test failed to compile (no bloc). GREEN: 42 truco tests passed (admin check, create/trim/empty-name, rename, delete, failures; players tab widget tests for viewer vs admin add flow); analyze: No issues found. Admin check duplicated like Dardos (`_adminEmail` constant).
- T4 (delegated writer). RED: validator and create-game cubit tests failed to compile. GREEN: 58 truco tests passed (validator rules, toggle/move between teams, trim on mode change, reorder, seating, submit valid/invalid/failure; create page widget tests for seating preview + start); analyze: No issues found.
- T5 (delegated writer). RED: game bloc test failed to compile (no `TrucoGameBloc`). GREEN: 76 truco tests passed (optimistic confirm + single commit, empty hand, finish, tie error, failed commit keeps board, remote updates/finish, edit/cancel with buffered remote, 10-minute window, legacy hands; play page widget tests: board names/members/totals/stick groups, read-only viewer, confirm flow, pencil correction); analyze: No issues found. `dart format` applied to the whole module (also reformatted T1–T4 files). Golden test skipped (optional).
- T6 (delegated writer). RED: multi-game bloc test failed to compile. GREEN: 79 truco tests passed (playing/finished split; Iniciar tab lists games and opens board/create). Wired `lib/di/truco_di.dart`, routes `/Truco`, `/Truco/Create`, `/Truco/Play` (route names in `features/truco/presentation/truco_route_names.dart`, since `core/navigation/route_names.dart` is outside the edit surface), dashboard chip. PENDING outside the edit surface: `frontend/lib/injection_container.dart` must call `await registerTrucoDependencies(sl);` (the surface listed `lib/di/injection_container.dart`, which does not exist); optional drawer entry in `frontend/lib/core/widgets/app_section_scaffold.dart`.
- T6b (delegated writer). Stats (`totalGamesPlayed`/`totalGamesWon` with net deltas on correction) were already persisted in the T2 hand-commit batch and tested there. RED: `truco_stats_test.dart` failed to compile (no `truco_stats.dart`). GREEN: 86 truco tests passed (ranking order wins → win rate → name, zero-games rate; per-player history newest first with partners/opponents/results and finished-only totals; widget tests for Historial, Ranking and player detail). Wrapper now has Iniciar / Jugadores / Historial / Ranking; route `/Truco/PlayerDetail`.

Branch `feat/truco` created from `main` (v1.1.0). Next: T1–T6 via one delegated writer, then T7.
