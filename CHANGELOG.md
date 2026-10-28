# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the app version in `frontend/pubspec.yaml` follows [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH+BUILD`).

## Release process

1. Bump `version:` in `frontend/pubspec.yaml` (increase `+BUILD` on every release).
2. Add a section to this file.
3. Commit, then tag `vMAJOR.MINOR.PATCH` on `main` and push the tag.
4. Build the APK with `frontend/build_apk.bat` (Flutter pinned in `frontend/.fvmrc`).

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
