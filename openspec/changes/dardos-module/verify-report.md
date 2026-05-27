# Verify Report -- Dardos Module

- Change ID: dardos-module
- Date: 2026-05-22
- Verifier: sdd-verify (Sonnet 4.6)
- Mode: Strict TDD

## 1. Summary

Status: PASS_WITH_WARNINGS
CRITICAL: 0 | WARNING: 4 | SUGGESTION: 3

253 tests pass. flutter analyze 0 errors. No cross-writes. No CoAuthoredBy. No Dart3+.
All 97 tasks complete.

## 2. Spec Coverage (61/65 COMPLIANT, 4 PARTIAL)

R1 - 5 scenarios - ALL COMPLIANT (dardos_participant_bloc_test.dart)
R2 - 3/4 COMPLIANT; PARTIAL: Cricket doubleOut=false not tested at BLoC layer
R3 - 2 scenarios - ALL COMPLIANT (dardos_game_bloc_test.dart Part C)
R4 - 3 scenarios - ALL COMPLIANT (Part G + multi_game_bloc_test)
R5 - 4/5 COMPLIANT; PARTIAL: explicit take-over by different device not BLoC-tested
R6 - 8 scenarios - ALL COMPLIANT (score_rules_test 32 + game_bloc Part D/E)
R7 - 6/7 COMPLIANT; PARTIAL: Cricket BLoC RecordThrow path not in bloc_test
R8 - 3 scenarios - ALL COMPLIANT (Part D + auto_advance_banner_test)
R9 - 4 scenarios - ALL COMPLIANT (leg_rules_test + Part E)
R10 - 5/6 COMPLIANT; PARTIAL: cross-set undo not explicitly tested
R11-R18 - ALL COMPLIANT

## 3. Risk Register

Cross-collection writes: MITIGATED (no_cross_collection_writes_test + grep)
BottomNavBloc ambiguity: MITIGATED (routes.dart:202 MultiBlocProvider)
Dart 3+ syntax: MITIGATED (sdk <3.0.0; only classic switch statements found)
Co-Authored-By: MITIGATED (zero instances in dardos/)
Stale annotator lock v1: ACCEPTED (design 11; admin force-release in GamePlayPage)

## 4. CRITICAL Findings

None.

## 5. WARNING Findings

W1: R7 Cricket BLoC throw path not tested
  dardos_game_bloc_test.dart has no test for RecordThrowEvent in Cricket mode.
  Domain Cricket logic fully tested (28 tests) but BLoC routing not exercised.
  File: test/features/dardos/presentation/bloc/dardos_game_bloc_test.dart
  Spec: R7, R12

W2: R5 Annotator take-over by different device not BLoC-tested
  R5 Scenario 3 (explicit take-over) not covered at BLoC level.
  Datasource test covers idempotent re-acquire (same device) only.
  File: test/features/dardos/presentation/bloc/dardos_game_bloc_test.dart Part B
  Spec: R5 Scenario 3

W3: R10 Undo cross-set not explicitly tested
  R10 Scenario 4 (undo cruzando set) has no dedicated integration test.
  undo_roundtrip_test.dart covers single-leg 501 only.
  File: test/features/dardos/integration/undo_roundtrip_test.dart
  Spec: R10 Scenario 4

W4: flutter analyze warnings in dardos presentation
  - unused_field: _activeBannerType (auto_advance_banner.dart:26)
  - unused_element_parameter: gamesPlayed, gamesWon (ranking_tab.dart:182-183)

## 6. SUGGESTION Findings

S1: WillPopScope deprecated (game_play_page.dart:80). Use PopScope.
S2: super parameter style: 36 info items. Zero functional impact.
S3: DI deviation: DardosParticipantRepositoryImpl receives DardosFirestoreDataSource
    instead of FirebaseFirestore (design 13). Actually better but deviates from doc.
    File: lib/di/dardos_di.dart:26-28

## 7. Test Execution Evidence

  flutter test test/features/dardos/
  00:15 +253: All tests passed!
  Total: 253 tests | 0 failed | 0 skipped | Exit code: 0

  flutter analyze lib/features/dardos/ lib/di/dardos_di.dart
  36 issues: 0 errors | 3 warnings | 33 infos (22.7s)

## 8. Glue Checklist

Spec coverage 61/65 .......................... PASS
Design decisions reflected in code ........... PASS
97 tasks with evidence ....................... PASS
flutter test passes 253/253 .................. PASS
flutter analyze 0 errors ..................... PASS
No Co-Authored-By ............................ PASS
No Dart 3+ syntax ............................ PASS
No cross-writes to la_loba ................... PASS
Firestore dardos_participants ................ PASS (rules:210)
Firestore dardos_games ....................... PASS (rules:217)
Firestore throws subcollection ............... PASS (rules:223)
Drawer Dardos + Icons.sports_score ........... PASS (scaffold:159)
Routes 5 dardos cases ........................ PASS (routes.dart)
DI in injection_container .................... PASS (line:19)

## 9. Recommendation

ARCHIVE

0 CRITICAL. 253/253 pass. All 18 requirements implemented.
W1/W2: BLoC tests missing for Cricket mode and take-over. Domain fully tested. Tech debt v1.1.
W3: Cross-set undo integration missing. Domain services correct.
W4: Unused field and params. No functional impact.

Verdict: PASS_WITH_WARNINGS -- safe to archive.