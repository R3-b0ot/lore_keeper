/// MS-021 — the manuscript UI must not acquire a legacy Chapter/Section
/// dependency (Cycle 6).
///
/// The 2026 redesign moved the manuscript onto `ManuscriptDocument`. Every
/// cycle so far has had to be told, individually, not to reach back into the
/// legacy `chapters` / `sections` boxes. This is that instruction written down
/// once, as a static guard, so a future cycle cannot quietly reintroduce a
/// legacy read and ship a page that is right for pre-cutover data and silently
/// empty for everything written after it.
///
/// Scope is the manuscript UI surface actually touched across Cycles 1-6.
/// A file is in scope if it lives in `lib/modules/`, is named
/// `manuscript_*.dart` under `lib/widgets/`, or is one of the dialogs the
/// manuscript feature owns outright.
///
/// The one permanent exemption is `chapter_diff_view_dialog.dart`: it is the
/// deliberately-kept legacy diff path (Cycles 3, 3b and 4 each declined to
/// touch it), so it still reads `Hive.box<Chapter>` by design. It is listed
/// explicitly rather than omitted, so the carve-out is visible in the code
/// instead of being an accident of the glob.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files under `lib/widgets/` that belong to the manuscript surface without
/// matching the `manuscript_` prefix.
const _namedWidgetFiles = <String>[
  'lib/widgets/find_replace_dialog.dart',
  'lib/widgets/index_page_widget.dart',
];

/// The permanent legacy carve-out, with the reason it is permanent.
const _exemptions = <String, String>{
  'lib/widgets/chapter_diff_view_dialog.dart':
      'the deliberately-kept legacy Chapter diff path (Cycles 3/3b/4)',
};

/// Every file in scope, de-duplicated and sorted for stable failure output.
List<String> _manuscriptUiFiles() {
  final files = <String>{};

  for (final entity in Directory('lib/modules').listSync()) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity.path.replaceAll('\\', '/'));
    }
  }

  for (final entity in Directory('lib/widgets').listSync()) {
    if (entity is! File) continue;
    final name = entity.path.split(RegExp(r'[/\\]')).last;
    if (name.endsWith('.dart') && name.startsWith('manuscript_')) {
      files.add(entity.path.replaceAll('\\', '/'));
    }
  }

  files.addAll(_namedWidgetFiles);
  files.removeAll(_exemptions.keys);

  return files.toList()..sort();
}

/// Reads a source file with its comments removed.
///
/// A static guard has to look at *code*: a doc comment may legitimately name
/// `Hive.box<Chapter>` to explain that the file never opens it, and a guard that
/// matched that text would prove nothing while making the file impossible to
/// document. This follows the MS-020 guard's precedent.
String _codeOfFile(String path) {
  final source = File(path).readAsStringSync();
  return source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ' ')
      .replaceAll(RegExp(r'//[^\n]*'), ' ');
}

/// The forbidden patterns. Matched as regular expressions so the `.*` spans
/// the import path and any qualifier on the box lookup.
const _forbidden = <String, String>{
  r'import.*chapter\.dart': 'must not import the legacy Chapter model',
  r'import.*section\.dart': 'must not import the legacy Section model',
  r'Hive\.box<Chapter>': 'must not open the legacy chapters box',
  r'Hive\.box<Section>': 'must not open the legacy sections box',
};

void main() {
  group('MS-021 — no legacy Chapter/Section dependency in the manuscript UI', () {
    test('the guard actually covers files', () {
      // A guard that scans an empty set passes forever. Pin the surface.
      final files = _manuscriptUiFiles();
      expect(files, isNotEmpty, reason: 'the scan set must not be empty');
      expect(
        files,
        contains('lib/modules/manuscript_module.dart'),
        reason: 'the manuscript module is the primary surface under test',
      );
      expect(
        files,
        contains('lib/widgets/manuscript_binder.dart'),
        reason: 'the binder widget is part of the manuscript surface',
      );
      expect(
        files,
        contains('lib/widgets/find_replace_dialog.dart'),
        reason: 'the find/replace dialog is a Cycle 5 surface',
      );
      expect(
        files,
        contains('lib/widgets/index_page_widget.dart'),
        reason: 'the Index page is a Cycle 6 surface (MS-019)',
      );
      expect(
        files,
        contains('lib/modules/character_module.dart'),
        reason: 'every lib/modules file is in scope, not just manuscript ones',
      );
    });

    test('no in-scope file depends on the legacy Chapter/Section model or boxes', () {
      final violations = <String>[];

      for (final file in _manuscriptUiFiles()) {
        final code = _codeOfFile(file);
        _forbidden.forEach((pattern, reason) {
          if (RegExp(pattern).hasMatch(code)) {
            violations.add('$file: $reason (matched /$pattern/)');
          }
        });
      }

      expect(
        violations,
        isEmpty,
        reason:
            'MS-021: the manuscript UI must read ManuscriptDocument data only. '
            'Legacy-exempt files belong in $_exemptions',
      );
    });

    test('the exemption is load-bearing, not decorative', () {
      // If the exempted file ever stops reading the legacy box, the exemption
      // is dead weight and should be removed rather than left to rot. This also
      // proves the patterns above can actually match real code.
      final exempt = _exemptions.keys.first;
      final code = _codeOfFile(exempt);

      expect(
        RegExp(r'Hive\.box<Chapter>').hasMatch(code),
        isTrue,
        reason:
            '$exempt is exempt on the basis that it reads the legacy chapters '
            'box; if that changed, drop it from the exemption list',
      );
    });

    test('a comment naming Hive.box<Chapter> does not trip the guard', () {
      // The MS-020 precedent, pinned: the guard must inspect code, not prose.
      // Only real comments are used here - the guard strips comments, and a
      // forbidden pattern inside a *string literal* is indistinguishable from
      // code, so it is not a case this guard claims to handle.
      const probe = '''
/// Deliberately never opens Hive.box<Chapter> or Hive.box<Section>.
/// It also never writes `import '../../models/chapter.dart';`.
import 'package:lore_keeper/models/manuscript_document.dart';

class Probe {
  // Legacy import 'package:lore_keeper/models/chapter.dart' is banned here.
  void read() {}
}
''';
      final stripped = probe
          .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ' ')
          .replaceAll(RegExp(r'//[^\n]*'), ' ');

      for (final pattern in _forbidden.keys) {
        expect(
          RegExp(pattern).hasMatch(stripped),
          isFalse,
          reason: 'comment text must not satisfy /$pattern/',
        );
      }
    });
  });
}
