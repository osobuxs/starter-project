# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the app version in `frontend/pubspec.yaml` follows [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH+BUILD`).

## Release process

1. Bump `version:` in `frontend/pubspec.yaml` (increase `+BUILD` on every release).
2. Add a section to this file.
3. Commit, then tag `vMAJOR.MINOR.PATCH` on `main` and push the tag.
4. Build the APK with `frontend/build_apk.bat` (Flutter pinned in `frontend/.fvmrc`).

## [1.2.0] - 2026-10-28

### Added

- Truco: new module with its own player registry (admin-only writes).
- Truco: create a game with the `+` button: mode (1v1, 2v2, 3v3), target 18 (9 + 9) or 30 (15 + 15), game name, team names, players per team, first dealer and seating order.
- Truco: the play page shows the table with each player's seat, who deals and who is mano; the dealer rotates one seat per hand.
- Truco: the board draws the points as matchsticks grouped in fives, split into malas and buenas.
- Truco: points are entered with − / + buttons only (starting at 0, never negative, capped at what the team needs to win) and Confirmar.
- Truco: instant save in the background, realtime board, correct the last hand (finished games only within 10 minutes).
- Truco: history, ranking (a win counts for every member of the winning team) and per-player detail.

### Security

- Firestore rules: only the admin can write `truco_participants`, `truco_games` and their hands (deployed).

## [1.1.0] - 2026-10-28

### Added

- La Loba: realtime board — every viewer sees new scores without reloading.
- La Loba: closing a hand is instant; it is saved in the background in a single atomic write.
- La Loba: "Corregir última mano" lets the admin fix the previous hand with its scores prefilled. Finished games can be corrected only within 10 minutes.
- La Loba: the rejoin score is stored per hand and shown as `(N)` under the orange rejoin total.
- Flutter SDK pinned to 3.32.8 with fvm (`frontend/.fvmrc`).

### Fixed

- La Loba: dealer rotation no longer freezes after the mano is eliminated.
- La Loba: a missing participant document no longer makes the hand commit fail.
- La Loba: joining mid-game no longer writes the entry total into the previous hand.
- La Loba: analyzer warnings, including `BuildContext` use across async gaps.

### Security

- Firestore rules: only the admin can write La Loba participants, games and hands. Requires `firebase deploy --only firestore:rules`.

### Changed

- La Loba: removed unused repository methods and sped up history loading.

## [1.0.2] - 2026-06

Earlier releases (1.0.0 – 1.0.2) predate this changelog.
