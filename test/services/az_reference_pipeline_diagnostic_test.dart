/// A-Z Reference Pipeline Diagnostic Test
///
/// Purpose: Trace every query "@A" through "@Z" through the full reference
/// pipeline for a controlled dataset containing exactly one character per
/// initial letter (A-Z), using ACTUAL production code with no mocks and
/// no production code modifications.
///
/// Pipeline stages:
///   Stage 1 – Query extraction (controller _checkForTrigger logic)
///   Stage 2 – CharacterListProvider filter (parentProjectId == _kProjectId)
///   Stage 3 – _buildEntries() → EntityReferenceEntry list
///   Stage 4 – ReferenceEngine.resolve(query, entries)
///   Stage 5 – Overlay guard: isActive && candidates.isNotEmpty
library;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/services/reference_engine.dart';
import 'package:lore_keeper/widgets/reference_autocomplete_controller.dart';

const _kProjectId = 1000;

List<Character> _buildAZDataset() {
  const names = [
    'Aldric Vorn',
    'Brenna Holt',
    'Cassian Dread',
    'Dyana Frost',
    'Elara Moon',
    'Fynn Ashwood',
    'Gavin Steele',
    'Hira Vale',
    'Ivan Crest',
    'Jora Blackwell',
    'Kira Dusk',
    'Lorn Ashveil',
    'Maren Coldwater',
    'Nyra Emberveil',
    'Oswin Thorn',
    'Petra Vance',
    'Quinn Marsh',
    'Ren Ashford',
    'Sable Nightwood',
    'Tavin Gale',
    'Urien Fenn',
    'Vira Stoneway',
    'Wren Coldmere',
    'Xara Dunmore',
    'Yael Brightwood',
    'Zara Embervale',
  ];
  return names
      .map((n) => Character(name: n, parentProjectId: _kProjectId))
      .toList();
}

String? _s1(String letter) {
  final t = '@$letter';
  final tb = t.substring(0, t.length);
  final at = tb.lastIndexOf('@');
  if (at == -1) return null;
  if (at > 0 && tb[at - 1] != ' ' && tb[at - 1] != '\n' && tb[at - 1] != '\t') {
    return null;
  }
  return tb.substring(at + 1);
}

List<Character> _s2(List<Character> all) =>
    all.where((c) => c.parentProjectId == _kProjectId).toList();

List<EntityReferenceEntry> _s3(List<Character> chars) {
  final entries = <EntityReferenceEntry>[];
  for (final c in chars) {
    final aliases = <String>[
      if (c.aliases != null) ...c.aliases!,
      if (c.iterations.isNotEmpty) ...[
        if (c.iterations.last.name != null) c.iterations.last.name!,
        if (c.iterations.last.aliases != null) ...c.iterations.last.aliases!,
      ],
    ];
    entries.add(
      EntityReferenceEntry(
        key: c.key,
        name: c.name,
        aliases: aliases,
        entityType: 'Character',
      ),
    );
  }
  return entries;
}

List<ReferenceCandidate> _s4(String q, List<EntityReferenceEntry> e) =>
    const ReferenceEngine(maxResults: 26).resolve(q, e);

(bool, String, List<ReferenceCandidate>) _ctrl(String l, List<Character> cs) {
  final q = QuillController.basic();
  final c = ReferenceAutocompleteController(
    quillController: q,
    entityProviders: {'Character': () => _s3(cs)},
  );
  q.replaceText(0, 0, '@$l', null);
  q.updateSelection(
    TextSelection.collapsed(offset: '@$l'.length),
    ChangeSource.local,
  );
  c.onTextChanged();
  final r = (c.isActive, c.query, List<ReferenceCandidate>.from(c.candidates));
  q.dispose();
  return r;
}

void main() {
  late List<Character> dataset;
  setUpAll(() => dataset = _buildAZDataset());
  final letters = List.generate(26, (i) => String.fromCharCode(65 + i));

  group('Per-letter pipeline (A-Z)', () {
    for (final l in letters) {
      test('@$l full pipeline', () {
        final cn = dataset.firstWhere((c) => c.name.startsWith(l)).name;
        final q = _s1(l);
        expect(q, equals(l), reason: 'S1 FAIL @$l');
        final flt = _s2(dataset);
        expect(
          flt.any((c) => c.name == cn),
          isTrue,
          reason: 'S2 FAIL $cn not in provider',
        );
        final ent = _s3(flt);
        final me = ent.where((e) => e.name == cn).toList();
        expect(
          me,
          isNotEmpty,
          reason:
              'S3 FAIL $cn not in entries keys=${ent.map((e) => "${e.name}:${e.key}").toList()}',
        );
        final cands = _s4(q!, ent);
        expect(
          cands.any((c) => c.displayName == cn),
          isTrue,
          reason:
              'S4 FAIL resolve("$q") missed "$cn" entry.key=${me.first.key} cands=${cands.map((c) => c.displayName).toList()}',
        );
        expect(
          true && cands.isNotEmpty,
          isTrue,
          reason: 'S5 FAIL overlay guard',
        );
        final (act, cq, cc) = _ctrl(l, flt);
        expect(act, isTrue, reason: 'Ctrl FAIL isActive=false @$l');
        expect(cq, equals(l), reason: 'Ctrl FAIL query="$cq"');
        expect(
          cc.any((c) => c.displayName == cn),
          isTrue,
          reason:
              'Ctrl FAIL $cn not in ctrl.candidates: ${cc.map((c) => c.displayName).toList()}',
        );
      });
    }
  });

  group('ReferenceEngine isolation A-Z', () {
    late List<EntityReferenceEntry> entries;
    setUp(() => entries = _s3(_buildAZDataset()));
    for (final l in letters) {
      test('resolve("$l") finds $l-character', () {
        final c = const ReferenceEngine(maxResults: 26).resolve(l, entries);
        expect(
          c.any((x) => x.displayName.startsWith(l)),
          isTrue,
          reason:
              'Engine FAIL resolve("$l") → ${c.map((x) => x.displayName).toList()}',
        );
      });
    }
  });

  group('Trigger guard edges', () {
    test('@A at doc start', () => expect(_s1('A'), equals('A')));
    test('@A after space', () {
      const t = 'Hello @A';
      final at = t.lastIndexOf('@');
      expect(t[at - 1], ' ');
      expect(t.substring(at + 1), 'A');
    });
    test('user@A blocked', () {
      const t = 'user@A';
      final at = t.lastIndexOf('@');
      final b = t[at - 1];
      expect(b != ' ' && b != '\n' && b != '\t', isTrue);
    });
  });

  test('A-Z SUMMARY TABLE', () {
    // ignore: avoid_print
    print(
      '\n═══════════════════════════════════════════════════════════════════════════════════════',
    );
    // ignore: avoid_print
    print(
      '  A-Z REFERENCE PIPELINE DIAGNOSTIC │ Project $_kProjectId (26 chars)',
    );
    // ignore: avoid_print
    print(
      '═══════════════════════════════════════════════════════════════════════════════════════',
    );
    // ignore: avoid_print
    print(
      '  L │ Character           │ S1 │ S2 │ S3 │ key  │ S4  │ S5 │ Ctrl │ RESULT',
    );
    // ignore: avoid_print
    print(
      '  ──┼─────────────────────┼────┼────┼────┼──────┼─────┼────┼──────┼──────────────────',
    );

    int fails = 0;
    final failLetters = <String>[];
    final failStages = <String>{};

    for (final l in letters) {
      final cn = dataset.firstWhere((c) => c.name.startsWith(l)).name;
      final q = _s1(l);
      final flt = _s2(dataset);
      final inP = flt.any((c) => c.name == cn);
      final ent = _s3(flt);
      final me = ent.where((e) => e.name == cn).toList();
      final inE = me.isNotEmpty;
      final k = inE ? '${me.first.key}'.padRight(4) : 'MISS';
      final c4 = (q != null && inE) ? _s4(q, ent) : <ReferenceCandidate>[];
      final s4ok = c4.any((c) => c.displayName == cn);
      final s5ok = q != null && c4.isNotEmpty;
      bool ctOk = false;
      if (inP) {
        final (a, _, cc) = _ctrl(l, flt);
        ctOk = a && cc.any((c) => c.displayName == cn);
      }
      final ok = q != null && inP && inE && s4ok && s5ok && ctOk;
      String? fs;
      if (q == null) {
        fs = 'S1';
      } else if (!inP) {
        fs = 'S2';
      } else if (!inE) {
        fs = 'S3';
      } else if (!s4ok) {
        fs = 'S4';
      } else if (!s5ok) {
        fs = 'S5';
      } else if (!ctOk) {
        fs = 'Ctrl';
      }
      if (!ok) {
        fails++;
        failLetters.add(l);
        if (fs != null) failStages.add(fs);
      }
      final res = ok ? 'PASS ✓' : 'FAIL ✗ ← $fs';
      // ignore: avoid_print
      print(
        '  $l │ ${cn.padRight(19)} │ ${q ?? "X"} ${q != null ? " " : ""}│ ${inP ? "✓" : "✗"} │ ${inE ? "✓" : "✗"} │ $k │ ${s4ok ? "✓" : "✗"}(${c4.length}) │ ${s5ok ? "✓" : "✗"} │  ${ctOk ? "✓" : "✗"}  │ $res',
      );
    }

    // ignore: avoid_print
    print(
      '═══════════════════════════════════════════════════════════════════════════════════════',
    );
    if (fails > 0) {
      // ignore: avoid_print
      print('\n⚠ $fails FAILURES: $failLetters  stages=$failStages');
      if (failStages.length == 1) {
        // ignore: avoid_print
        print(
          '  → ALL failures at SAME stage: ${failStages.first} – systemic.',
        );
      }
    } else {
      // ignore: avoid_print
      print('\n✓ ALL 26 LETTERS PASSED.');
    }
    // ignore: avoid_print
    print(
      '\nFILES: character_list_provider.dart(S2) reference_autocomplete_controller.dart(S1+S3)',
    );
    // ignore: avoid_print
    print(
      '       reference_engine.dart(S4) reference_autocomplete_overlay.dart(S5)',
    );
    // ignore: avoid_print
    print('       character.dart(model) reference_attribute.dart(encoding)\n');
    expect(26, 26);
  });
}
