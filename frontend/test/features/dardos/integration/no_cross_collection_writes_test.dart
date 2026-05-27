import 'dart:io';
import 'package:test/test.dart';

/// Integration/static-analysis test.
/// Asserts that NO file under lib/features/dardos/ references
/// the bare Firestore collection paths 'participants' or 'games'
/// without the 'dardos_' prefix.
///
/// This enforces R18: complete isolation from la_loba collections.
void main() {
  group('Dardos isolation — no cross-collection references', () {
    late List<File> dartFiles;

    setUpAll(() {
      final dir = Directory('lib/features/dardos');
      dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
    });

    test('no file references bare participants collection', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // Match collection('participants') or 'participants' without dardos_ prefix
        // We allow 'dardos_participants' but NOT bare 'participants'
        final bareParticipants = RegExp(
          r"collection\('participants'\)|'participants'(?!_)",
        );
        if (bareParticipants.hasMatch(content)) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Found bare "participants" collection reference in dardos module:\n'
            '${violations.join('\n')}',
      );
    });

    test('no file references bare games collection', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // Allow 'dardos_games' but NOT collection('games')
        final bareGames = RegExp(r"collection\('games'\)");
        if (bareGames.hasMatch(content)) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Found bare "games" collection reference in dardos module:\n'
            '${violations.join('\n')}',
      );
    });
  });
}
