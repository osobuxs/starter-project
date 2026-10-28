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
- [x] T2 — Realtime board: `watchGame(gameId)` stream (game doc + hands subcollection `snapshots()`), `GameBloc` subscribes on load and cancels on close. Route: delegated writer (data source, repo interface/impl, bloc, fakes). Commit: see `git log` (`feat(la_loba): tablero en tiempo real ...`). RED: 4/6 new tests failed (no subscription); GREEN 33/33 La Loba tests. Remote updates keep `currentHandScores`, are buffered while a round is closing / retry dialog is open, stream errors are ignored, remote finish emits `gameFinished`. Data-source `snapshots()` combination has no runnable unit test (no Firestore fake in deps).
- [ ] T3 — Instant score entry: compute next game state locally, emit it immediately, persist hand + game update (+ winner/stats) in one `WriteBatch` without blocking the UI; surface background failures without losing local state. Route: delegated writer.
- [ ] T4 — Edit last hand: each new hand stores a snapshot of the pre-hand state (`participantStatesBefore`, `dealerIdBefore`, `finishedGame`); admin can reopen the last hand with prefilled scores, re-close it (overwrites same hand doc, reverts winner/stats if needed) or cancel. Legacy hands without snapshot are not editable. Route: delegated writer.

## Acceptance criteria

- Dealer never freezes; eliminated mano → previous dealer deals again; rotation continues next round.
- Closing a hand updates the scorer's board with no spinner; writes reach Firestore in the background.
- A second device viewing the game sees new totals without reloading.
- Admin can edit the last hand; totals, eliminations, dealer and winner reflect the corrected scores.

## Checks

- `C:/Users/Osobuco/scoop/apps/fvm/current/versions/3.32.8/bin/flutter test test/features/la_loba` (from `frontend/`).
- `flutter analyze lib/features/la_loba test/features/la_loba` with the same SDK.

## Progress

T1, T2 done. Next: T3 (instant score entry).
