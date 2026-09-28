# CYCLE_LOG — Manuscript Rebuild

Per-file journal for the staged Manuscript rebuild (spec `docs/LORE_KEEPER_MANUSCRIPT_MASTER_SPEC.md`,
requirements `docs/audit2/B7_manuscript_requirements.md`).

Legend: `+` green, `-` red/broken, `~` partial/known-issue, `!` decision/blocker.

---

## Cycle 1 — Manuscript Topology Guards (MS-001 … MS-005)

Branch: `manuscript-fixes`. Scope: prove the four canonical columns render exactly once
through the real shell and that the manuscript pipeline shares one binder + one reference engine.

### Commits

| Commit | Requirement | Summary |
| --- | --- | --- |
| `b029633` | MS-002 | Added canonical stable key `project-editor-column-1` for Column 1 (`ModuleSidebar` root). |
| `afe8b8f` | MS-001 | Runtime audit: pump the REAL `ProjectEditorScreen` and assert the four canonical columns render exactly once, Binder only in Column 2, and a seeded chapter opens. |
| `f23ccf1` | MS-003 | Identity test: Columns 2/3/4 observe ONE `ManuscriptBinderProvider` instance. |
| `90fbbeb` | MS-004 | Exposed `ManuscriptReferenceService.referenceEngine` + identity test: binder engine == inspector reference-service engine == shell engine. |
| current | MS-005 | Grep guard: the six manuscript logic services stay Flutter-free; this log. |

### Tests added (`test/widgets/manuscript_topology_test.dart`)

- `ProjectEditorScreen shell renders exactly one of each canonical column (MS-001)`
- `ProjectEditorScreen threads ONE ManuscriptBinderProvider to Columns 2/3/4 (MS-003)`
- `ProjectEditorScreen shares ONE ReferenceEngine across the manuscript pipeline (MS-004)`
- `manuscript logic services stay Flutter-free (MS-005)`

### Key findings / decisions

- **Pumping `ProjectEditorScreen` under plain FakeAsync hangs the framework**
  post-test epilogue. The shell builds its own Hive-backed providers in
  `initState`; their bootstrap completes on the real-async event loop and, when
  stranded in the FakeAsync zone, leaves the post-test `flushMicrotasks` in an
  endless churn (no `testDone` event, `--timeout` cannot interrupt). The
  supported remedy, discovered by bisect (overview vs manuscript vs
  runAsync-bootstrap probes): run the whole shell mount + bootstrap inside
  `tester.runAsync` (real event loop), render with one normal `pump`, then
  optionally unmount. Helper `_pumpProjectEditorShell` encodes this.
- **`_normalizeModuleIndex` legacy remap quirk**: `initialModuleIndex: 0` is a
  legacy deep-link index and maps to Manuscripts (1). New-range indices are
  0=Overview … 4=Lore Map. Tests reach the manuscript module via the legacy 0.
- **Hive writes must not be awaited directly inside a `testWidgets` FakeAsync
  zone** (they are real-async I/O); seed in `setUp` (real async context) or in
  `tester.runAsync`.
- **MS-003 structurally satisfied** (spec §5.2): the shell already threads one
  `ManuscriptBinderProvider` to Column 2 (`ManuscriptListPane.provider`) and to
  the module, which passes the same instance into Column 3 (`ManuscriptEditor.binderProvider`)
  and Column 4 (`ManuscriptInspector.binderProvider`). Guarded by identity test.
- **MS-004 structurally satisfied** (§11.3): every reference producer (module &
  editor `ManuscriptReferenceService`, binder, collections) builds on the one
  shell `ReferenceEngine`. The module and editor each *construct* a
  `ManuscriptReferenceService`, which is acceptable structurally but is the
  **MS-015 (Cycle 4) technical debt**: unify to a single service instance.
  Deferred by explicit decision, noted here.
- **`ManuscriptCollections`** self-creates a `ManuscriptReferenceService` with
  the same engine; that DI-bypass is a maintenance concern only, not a second
  engine — no fix required this cycle.
- **MS-005 already clean**: the six logic services carry zero
  `package:flutter/` imports; the grep-guard test pins it.
- Pre-existing analyzer infos (9, `use_null_aware_elements` in
  `database/ai/device_ai/*`, `services/entity_reference_entries.dart`,
  `settings/widgets/settings_widgets.dart`) are untouched; all changed files are
  analyzer-clean and the Dart analyzer reports no warnings/errors.

### Health

| Check | Baseline | Cycle 1 end |
| --- | --- | --- |
| `flutter analyze` | 0 errors / 0 warnings (9 pre-existing infos) | unchanged |
| `flutter test` | 377 | **381** (corrected from 380; the MS-005 commit's suite run reported 381) |
| Tooling rules | no build_runner, no dep adds, no public-API changes to off-limits types | honored (`ManuscriptReferenceService.referenceEngine` is explicitly allowed) |

---

## Cycle 2 — Unified Word/Character Counting (MS-009, MS-010, MS-026)

Branch: `manuscript-fixes`. Scope: one canonical word count, one canonical
character count, and a live character count in the editor status bar.

### Decision: the structural trailing `"\n"` is EXCLUDED

**Chosen: exclude.** `ManuscriptTextStats.countableText` strips exactly one
trailing `'\n'` before every measurement.

Reasoning: a Quill Delta stores one `'\n'` per line as its block terminator, so
`Document.toPlainText()` (`flutter_quill-11.5.1/lib/src/document/document.dart:548`,
root children joined; each line's `toPlainText()` carries its own terminator)
returns `lineText + "\n"` for every line. For a single-paragraph document that
is exactly one trailing `'\n'` the author never typed. Counting it would
over-report every document in the app by one character and would make the
editor disagree with the stored value. The newline is an artifact of the Delta
container format, not authored content, so it is excluded. Only the single
trailing terminator is removed; interior newlines and any further trailing
newlines (empty trailing paragraphs) are preserved and counted.

`test/utils/manuscript_text_stats_test.dart` encodes the decision with the
explicit numbers 11 (excluded) vs 12 (included).

### Exact current behavior of the three implementations (measured before changing)

Captured with a throwaway probe (since deleted) that ran each algorithm on the
same fixtures. `editorCols` is `_controller.document.toPlainText()`;
`binderCols/migCols` is the raw `richTextJson` string.

| Fixture (stored `richTextJson`) | editorCols | editor words | editor chars | binder/mig words | binder/mig chars |
| --- | --- | --- | --- | --- | --- |
| `{"ops":[{"insert":"\n"}]}` (empty doc) | `\n` | 0 | 1 | 3 | 25 |
| `{"ops":[{"insert":"Hello world\n"}]}` | `Hello world\n` | 2 | 12 | 5 | 36 |
| `{"ops":[{"insert":"A  B\n"}]}` | `A  B\n` | 2 | 5 | 5 | 29 |
| `{"ops":[{"insert":"Eryll\n","attributes":{"link":"ref:Character:42"}}]}` | `Eryll\n` | 1 | 6 | 9 | 71 |
| `{"ops":[{"insert":{"image":"data:image/png;base64,QUJD"}},{"insert":"\n"}]}` | `\uFFFC\n` | 1 | 2 | 10 | 75 |

Findings:
- **Editor** words were correct (2) but counted the trailing newline in the
  *character* count (12 instead of 11; an empty document reported 1).
- **Binder and migration** "word counts" were not word counts at all: both
  regex-stripped the *raw JSON* (`[^a-zA-Z0-9\s]` → `' '`) and split that, so
  every document was inflated by the JSON envelope tokens (`ops`, `insert`)
  and by attribute keys — the mention fixture counted 9 words for one word of
  prose, and an image embed counted 10 (its base64 payload became a token).
- **Character counts** in the binder and migration were `richTextJson.length`
  (the length of the JSON envelope: 25 for an empty document, 36 for
  "Hello world", 75 for a one-image document).
- A `ref:` mention is an inline text run with a link attribute
  (`reference_autocomplete_controller.dart:142-146`), not an embed, so its
  visible name legitimately counts as prose.
- An image/embed op contributes exactly one `U+FFFC`
  (`EmbedBuilder.toPlainText` → `Embed.kObjectReplacementCharacter`), which
  the shared Delta-JSON adapter reproduces.

After this cycle all three producers agree: `hello` = 2 words / 11 characters,
empty document = 0 / 0, `A  B\n` = 2 / 4, mention = 1 / 5, image = 1 / 1.

### Commits

| Commit | Requirement | Summary |
| --- | --- | --- |
| `0b378cb` | MS-009 | `ManuscriptTextStats.wordCount` / `wordCountOfJson` / `plainTextOfDeltaJson`; the editor live count, `ManuscriptBinderService._countWords` and the migration's `_countWords` all route through it; both dead implementations deleted. |
| `9025e82` | MS-010 | `ManuscriptTextStats.characterCount` / `characterCountOfJson`; the editor's `toPlainText().length`, the binder's `richTextJson.length` and the migration's `chapter.richTextJson?.length` all replaced. |
| `032b250` | MS-026 | Live "Chars: N" beside "Words: N" in the editor status bar (normal + focus mode), derived from one `toPlainText()` snapshot. |

### Tests added

`test/utils/manuscript_text_stats_test.dart` (new file):
- `'"Hello world\n" counts 2 words via plain text'
- `the fixture counts 2 words through the Delta-JSON adapter`
- `empty or whitespace-only strings count 0 words`
- `multiple consecutive spaces still yield 2 words`
- `a ref-linked mention counts its visible name as a word`
- `an image/embed op contributes one replacement character (1 unit)`
- `a bare ops array (legacy V2 shape) is counted the same way`
- `malformed JSON yields 0 words, never a crash`
- `'"Hello world\n" counts exactly 11 characters'` (MS-010 decision encoded)
- `an empty document counts 0 characters`
- `interior newlines are preserved, only one trailing \n is dropped`
- `an embed op contributes exactly one character`

`test/services/manuscript_binder_service_test.dart` (group `word count is canonical (MS-009)`):
- `updateContent stores wordCount == 2 for "Hello world\n"`
- `updateContent stores 0 words for an empty document`
- `createDocument with content counts the same words`
- `createDocument with no content counts 0 words`

`test/widgets/manuscript_topology_test.dart`:
- `Editor status bar shows a live "Chars: N" beside "Words: N" (MS-026)` —
  asserts `Chars: 11` and `Words: 2` for the seeded `Hello world\n` document.

### Files changed (and deleted code)

- `lib/utils/manuscript_text_stats.dart` (**new**) — the single source of truth,
  pure Dart (`dart:convert` only, no `package:flutter/` import).
- `lib/modules/manuscript_module.dart` — `_updateWordCount` → `_updateCounts`
  (adds `_characterCount`), `_updateDocumentWordCount` routed through the
  utility, "Chars: N" in both status bars, `_loadEmptyContent` resets both.
  Old inline `toPlainText().trim().split(RegExp(r'\s+'))` and
  `toPlainText().length` removed.
- `lib/services/manuscript_binder_service.dart` — `createDocument` and
  `updateContent` routed through the utility; **`_countWords` deleted** (the
  regex-over-JSON implementation).
- `lib/database/database_manager.dart` — V2→V3 migration routed through the
  utility; **`_countWords` deleted**.
- `lib/utils/manuscript_text_stats.dart`, `test/utils/manuscript_text_stats_test.dart` (**new**),
  plus the two test files extended.

No `dart run build_runner`, no dependency changes, no public API on
`EntityRef` / `ReferenceEngine` / `ReferenceIndex` / `EntityNameMatcher` /
`ManuscriptBinderService` / `ReferenceIntegrityService` was altered — only the
bodies of existing public methods changed.

### Health — raw output

`flutter analyze` before Cycle 2:

```
   info - Use the null-aware marker '?' rather than a null check via an 'if'. Try using '?' - lib\database\ai\device_ai\device_ai_discovery.dart:82:9 - use_null_aware_elements
   info - Use the null-aware marker '?' rather than a null check via an 'if'. Try using '?' - lib\database\ai\device_ai\openai_compatible_client.dart:122:9 - use_null_aware_elements
   info - Use the null-aware marker '?' rather than a null check via an 'if'. Try using '?' - lib\database\ai\device_ai\openai_compatible_client.dart:123:9 - use_null_aware_elements
   info - Use the null-aware marker '?' rather than a null check via an 'if'. Try using '?' - lib\database\ai\device_ai\openai_compatible_client.dart:124:9 - use_null_aware_elements
   info - Use the null-aware marker '?' rather than a null check via an 'if'. Try using '?' - lib\database\ai\device_ai\openai_compatible_client.dart:176:7 - use_null_aware_elements
   info - Use the null-aware marker '?' rather than a null check via an 'if'. Try using '?' - lib\database\ai\device_ai\openai_compatible_client.dart:177:7 - use_null_aware_elements
   info - Use the null-aware marker '?' rather than a null check via an 'if'. Try using '?' - lib\database\ai\device_ai\openai_compatible_client.dart:178:7 - use_null_aware_elements
   info - Use the null-aware marker '?' rather than a null check via an 'if'. Try using '?' - lib\services\entity_reference_entries.dart:20:34 - use_null_aware_elements
   info - Use the null-aware marker '?' rather than a null check via an 'if'. Try using '?' - lib\settings\widgets\settings_widgets.dart:156:15 - use_null_aware_elements

9 issues found. (ran in 2.0s)
```

`flutter analyze` after each Cycle 2 requirement (identical to the baseline —
`0b378cb`, `9025e82` and `032b250` each re-ran it) — last line:

```
9 issues found. (ran in 3.3s)
```

Final `flutter analyze` at cycle close, raw output:

```
The system cannot find the file specified.
Analyzing lore_keeper...
No issues found! (ran in 5.3s)
```

Both states are clean: **0 errors, 0 warnings, and no issue in any file this
cycle touched.** The final run is *better* than the baseline, and the
difference is not caused by this cycle's code — it is a lint-resolution
change in the toolchain:

- The 9 baseline infos were all `use_null_aware_elements` in files this cycle
  never opens (`device_ai_discovery.dart`, `openai_compatible_client.dart`,
  `entity_reference_entries.dart`, `settings_widgets.dart`); every one of those
  files is byte-identical to its pre-cycle state.
- `pubspec.lock` is unchanged and pins `flutter_lints 6.0.0`, whose
  `lib/flutter.yaml` does **not** enable `use_null_aware_elements`. Under the
  current resolution the rule is therefore not applied at all, so the 9 infos
  legitimately disappear.
- Verified directly: `dart analyze lib/settings/widgets/settings_widgets.dart`
  → `No issues found!` (its `if (trailing != null) trailing!,` on line 156 is
  still present), and a scratch file reproducing that exact collection-element
  pattern produced no `use_null_aware_elements` diagnostic either, while
  `avoid_print` / `unnecessary_non_null_assertion` /
  `unnecessary_nullable_for_final_variable_declarations` still fired — so lints
  are active, only this stale rule set no longer applies. The scratch probe
  files were deleted.
- No source change was made to reach this state; nothing in this cycle
  introduced or suppressed a diagnostic.

`flutter test` before Cycle 2 (baseline) — last line:

```
00:25 +381: All tests passed!
```

`flutter test` after Cycle 2 — last line:

```
00:27 +398: All tests passed!
```

381 → 398 (+17: 12 in `manuscript_text_stats_test.dart`, 4 in the binder
service test, 1 in the topology test). Intermediate: 393 after MS-009, 397
after MS-010, 398 after MS-026.

Cycle 2 health summary:

| Check | Cycle 2 baseline | Cycle 2 end |
| --- | --- | --- |
| `flutter analyze` | 0 errors / 0 warnings (9 pre-existing infos) | **0 errors / 0 warnings / 0 infos** — the stale rule set is gone; no diagnostic added or suppressed by this cycle |
| `flutter test` | 381 | **398** |
| Tooling rules | no build_runner, no dep adds, no protected public-API changes, no SDK-artifact drift | honored (`docs/audit2/CYCLE_LOG.md` and one test-name typo fix are the only files in the closing commit) |

### Deferred / not done

- **No bulk recompute of stored `wordCount`/`characterCount`** for existing
  documents, per the cycle brief: the counts self-correct on the next save of
  each document (every `updateContent` now recomputes both fields). A migration
  would need to walk every `ManuscriptDocument`, decode each Delta and rewrite
  the box — nontrivial, and the stored numbers only feed display aggregates.
- Documents never re-opened keep their old (inflated) counts until saved, so
  project-level totals may be mixed old/new until then.
- MS-015 (dual `ManuscriptReferenceService`) remains deferred to Cycle 4.

---

## Cycle 3 - manuscript history, diff/revert, and autosave integrity

**Branch:** `manuscript-fixes`
**Scope:** MS-006, MS-007, MS-008, MS-020 (plus OQ-3, the debounce value
MS-008 depends on)
**Test count:** 398 -> **409** (+11)

### Baseline (before any change)

`flutter analyze`:

```
Analyzing lore_keeper...
No issues found! (ran in 2.4s)
```

`flutter test` (last line):

```
00:25 +398: All tests passed!
```

(The harmless `The system cannot find the file specified.` line that precedes
Flutter output on this machine appeared on every command in this cycle.)

### Topology trace - what the manuscript revision path did before Cycle 3

Quoted from the working tree at the start of the cycle.

**(a) Where manuscript snapshots are written** -
`lib/modules/manuscript_module.dart`, `_saveContent`:

```dart
await _historyService.addHistoryEntry(
  targetKey: _selectedDocument!.id,
  targetType: 'ManuscriptDocument',
  objectToSave: _selectedDocument!,
  projectId: widget.projectId,
);
```

So the writer's pair is `(document id, 'ManuscriptDocument')`.

**(b) What the shell asked for** - `lib/screens/project_editor_screen.dart`
(module index 1, the Manuscripts pane) built a *legacy Chapter* key and type:

```dart
final targetKey = _selectedChapterKey.startsWith('front_matter_')
    ? _selectedChapterKey
    : int.tryParse(_selectedChapterKey);
```

with `targetType: 'Chapter'` handed to `HistoryPanel`.

**Consequence (the MS-006 defect):** the two pairs never matched, so the
history panel for an open manuscript document was *always* empty - the writer
used the canonical document id, the reader used a legacy key. No application
code anywhere writes `targetType: 'Chapter'`; the only `Chapter` history
entries are the ones the old `ChapterDiffViewDialog` path consumed.

**(c) Unsupported diff types** - `HistoryPanel` filtered entries by exact
`targetKey` + `targetType` equality, and its diff dispatcher had no
`ManuscriptDocument` case, so it fell through to:

```dart
SnackBar(content: Text('Diff view not supported for this type.'))
```

**(d) The legacy diff/revert dialog read and wrote Hive directly** -
`lib/widgets/chapter_diff_view_dialog.dart`:

```dart
final chapterBox = Hive.box<Chapter>('chapters');
...
currentChapter = chapterBox.get(historyEntry.targetKey);
...
final historicalChapter = chapterFromJson(jsonDecode(historyEntry.data));
...
await chapterBox.put(historyEntry.targetKey, historicalChapter);
```

That is the `Hive.box<Chapter>` dependency the manuscript path had to avoid:
the manuscript binder stores canonical documents in `manuscriptDocuments`,
and a Chapter-keyed read/write would have silently written the wrong entity.

### Requirement log

#### MS-006 - history panel queries ManuscriptDocument revisions (f0c9686)

- **Test first (red):** a shell test opened the real `ProjectEditorScreen` on
  the Manuscripts module, opened the history panel and asserted a version
  snapshot appeared. Red reason:

```
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Version snapshot": []>
```

  Three companion tests for the `HistoryPanel` contract passed before the fix,
  which isolated the defect to the shell's query pair rather than the panel.
- **Implementation:** one ternary in
  `project_editor_screen.dart` - module index 1 now passes
  `_selectedManuscriptDocumentId` with `targetType: 'ManuscriptDocument'`,
  matching what `_saveContent` writes. The Characters pane (index 2) is
  untouched.
- **Green:** analyze clean, `00:28 +402: All tests passed!`
- **Tests added:** 4

#### MS-007 - ManuscriptDocument diff and revert (705e95b)

- **Test first (red):** the panel test failed to compile -
  `Error: No named parameter with the name 'binderProvider'.` - which is the
  defect: `HistoryPanel` had no way to reach a manuscript document. A second
  red, `Found 0 widgets with text containing - Hello world: []`, was a *fault in
  the test*, not the product: it assumed DiffMatchPatch emits whole-phrase
  segments, and it also had the diff direction backwards (`dmp.diff(current,
  historical)` renders the live text as the removal). The test was corrected to
  pin the dialog's inputs directly and assert on the diff markers, which is
  stable regardless of segmentation.
- **Implementation:**
  - New `lib/widgets/manuscript_diff_view_dialog.dart`: a data-in /
    callback-out `ManuscriptDocumentDiffViewDialog`. It receives the entry,
    the current title and both `richTextJson` payloads through its
    constructor, renders the DiffMatchPatch diff of the two documents' *plain
    text* (`ManuscriptTextStats.plainTextOfDeltaJson`, so the author sees
    prose changes rather than Delta-JSON punctuation), and calls
    `onRevert(historicalRichTextJson)`.
  - `HistoryPanel` gained an optional `binderProvider` and a
    `'ManuscriptDocument'` branch: it resolves the current document through
    the binder, decodes the snapshot's `richTextJson` field, and reverts via
    `ManuscriptBinderProvider.updateContent`.
  - The legacy `'Chapter'` and `'Character'` branches are unchanged, and
    `ChapterDiffViewDialog` was deliberately left untouched - it remains the
    path for pre-manuscript Chapter snapshots only.
- **Green:** analyze clean, `00:29 +404: All tests passed!`
- **Tests added:** 2. The revert test seeds a *decoy* `chapters['chapter_1']`
  and proves it is neither read nor written, and that the project save is
  unaffected.

#### MS-020 - no Hive.box<Chapter> in the manuscript diff/revert path (4bb80aa)

- **Implementation:** test-only - three static contract tests following the
  existing MS-005 pattern. They assert the dialog and panel code contains no
  `Hive.box<Chapter>`, no `chapterFromJson` and no `models/chapter.dart`
  import; that the dialog imports no `package:hive` and takes every input via
  its constructor; and that the panel still routes `'Chapter'` and
  `'ManuscriptDocument` separately.
- **Note on the guard's design:** the assertions strip comments first
  (`_codeOfFile`). The dialog's doc comment legitimately *names*
  `Hive.box<Chapter>` to explain that it never opens it, and a guard that
  matched documentation would prove nothing while being impossible to write
  around.
- **Green:** analyze clean, `00:32 +407: All tests passed!`
- **Tests added:** 3

#### MS-008 + OQ-3 - autosave does not snapshot unchanged content (575e8be)

- **Test first (red):** two independent failures against the unfixed module:

```
Expected: contains 'String? _lastSavedContent'
Actual: ' \n'
the module must remember the content it last saved

Expected: a value greater than or equal to <5>
Actual: <2>
OQ-3: the autosave debounce must be 5s or longer
```

- **Implementation** (`lib/modules/manuscript_module.dart`):
  - New `String? _lastSavedContent` holds the exact payload last persisted.
  - `_saveContent` encodes the Delta through a new `_currentContentJson`
    helper and returns early when the result is identical to that baseline -
    **before** `addHistoryEntry` and before `_isSaving` is set, so a no-op
    save writes nothing and does not flash the saving indicator.
  - The baseline is seeded in `_loadContent` / `_loadEmptyContent` (so the
    first save after opening a document is never mistaken for a no-op) and
    refreshed only after a real write.
  - `_autosaveDelay`: 2s -> 5s (OQ-3). No existing test depends on the old
    value; the manuscript topology test's 50 ms step and 10 s deadline are
    unaffected.
- **Behavioural verification** (a throwaway probe, run before the commit and
  then deleted) drove the *real* editor in the shell and counted
  `ManuscriptDocument` history entries:

```
before the fix:  first=1  second=2   <- identical re-save wrote a duplicate
after the fix:   first=1  second=1   <- duplicate suppressed, real save kept
```

  The shipped test asserts the guard structurally rather than behaviourally;
  see *Deferred* below for why.
- **Green:** analyze clean, `00:30 +409: All tests passed!`
- **Tests added:** 2

### Verification

| Check | Cycle 3 baseline | Cycle 3 end |
| --- | --- | --- |
| `flutter analyze` | 0 errors / 0 warnings / 0 infos | **0 / 0 / 0** |
| `flutter test` | 398 | **409** |
| `flutter build windows --debug` | not run | **succeeded** - `Built build\windows\x64\runner\Debug\lore_keeper.exe` (25.1s) |
| Tooling rules | - | honored: no build_runner, no dependency changes, no protected public-API changes, no SDK-artifact drift (tree clean at the closing commit) |

Raw final output:

```
Analyzing lore_keeper...
No issues found! (ran in 2.0s)
```

```
00:30 +409: All tests passed!
```

```
Building Windows application...                                    25.1s
- Built build\windows\x64\runner\Debug\lore_keeper.exe
```

Test count progression: 398 -> 402 (MS-006) -> 404 (MS-007) -> 407 (MS-020) ->
409 (MS-008).

### Commits

| Commit | Requirement |
| --- | --- |
| `f0c9686` | MS-006 - history panel queries ManuscriptDocument revisions |
| `705e95b` | MS-007 - ManuscriptDocument diff and revert |
| `4bb80aa` | MS-020 - Hive-free manuscript diff/revert path guard |
| `575e8be` | MS-008 + OQ-3 - unchanged autosave writes no snapshot; debounce 2s -> 5s |

### Deferred / not done

- **The MS-008 behaviour is not covered by a shipped widget test.** Driving a
  real autosave from a widget test leaves `ProjectEditorScreen`'s provider
  graph holding open Hive writes, and tearing that tree down afterwards
  deadlocks the test runner (reproduced twice: the run reached the assertion,
  reported the result, then hung until the runner was killed). The structural
  guard plus the recorded probe evidence covers the contract today, but a
  proper fix needs `ProjectEditorScreen`'s disposal to be teardown-safe under
  `FakeAsync` - a lifecycle issue beyond MS-008's scope and worth its own
  cycle.
- `ChapterDiffViewDialog` still opens `Hive.box<Chapter>` and writes
  directly. That is unchanged on purpose (it serves pre-manuscript Chapter
  snapshots); MS-020 only guarantees the *manuscript* path never reaches it.
  Removing the legacy path is a migration decision, not a Cycle 3 change.
- No backfill of the new guard: documents that already have duplicate history
  entries from identical saves keep them. The panel is append-only and the
  duplicates are indistinguishable from real repeats, so no automatic dedupe was
  attempted.
- MS-015 (dual `ManuscriptReferenceService`) remains deferred to Cycle 4, as
  recorded at the end of Cycle 2.

---

## Cycle 3b - autosave pacing, snapshot policy, and revert correctness

**Branch:** `manuscript-fixes`
**Scope:** the four Cycle 3 follow-ups
**Test count:** 409 -> **428** (+19)

### Baseline (before any change)

`flutter analyze`:

```
Analyzing lore_keeper...
No issues found! (ran in 2.1s)
```

`flutter test --concurrency=1` (last line):

```
00:32 +409: All tests passed!
```

Branch and tree were clean at `5c3c326`.

### Item 3b-1 - restore the 2s autosave debounce (S-34)

**Decision.** Cycle 3 read OQ-3 and raised the debounce from 2s to 5s. Spec
11.3 says: *"The current target is approximately two seconds unless profiling or
UX requirements justify another value."* No profiling or UX evidence was ever
produced, so the spec's own value governs. The OQ-3 concern (a fired timer
carries unchanged content) is a real problem, but slowing the content save is
the wrong instrument for it: it is a *snapshot pacing* question, and it
contradicts the spec. It is also self-defeating, because spec 11.3 separately
requires that autosave "must not rebuild unrelated project/module state on every
keystroke" - an obligation that is now visible at 2s and is tracked against B5
D3 instead of being masked by a longer timer.

**Test first (red):**

```
Expected: <2>
Actual: <5>
S-34: the autosave debounce target is 2 seconds
00:00 +0 -1: Some tests failed.
```

**After the change:**

```
00:00 +1: All tests passed!
No issues found! (ran in 2.2s)
00:41 +409: All tests passed!
```

### Item 3b-2 - HistorySnapshotPolicy (decouple snapshots from autosave)

**Decision.** Content autosave and history snapshots are different concerns.
Content must reach storage on the 2s debounce; a snapshot is a *revision
record*. Cycle 3 welded them together inside `_saveContent`, so every autosave
wrote a `HistoryEntry` and the panel filled with near-identical revisions.

New pure-Dart service `lib/services/history_snapshot_policy.dart` - no Flutter
imports, no Hive, and deliberately no clock, so the interval boundaries are
testable without waiting on real time. The caller supplies the elapsed
duration. Rules, in priority order:

1. Never snapshot identical content, on any trigger. This also covers the
   seeded-on-load case.
2. Autosave snapshots at most once per
   `HistorySnapshotPolicy.autosaveSnapshotInterval` (60s, a named constant).
3. Close/switch always records a pending change, so leaving a document cannot
   lose an edit to an open pacing window.

The decision is returned as a record
(`({bool shouldSnapshot, HistorySnapshotSkip? skipReason})`) so a skip can
report *why* - identical content versus inside the window - which is what makes
the behaviour assertable rather than merely boolean.

**The one non-obvious consequence.** The snapshot baseline
(`_lastSnapshottedContent`) is a *separate field* from the MS-008 content-write
baseline (`_lastSavedContent`), and this is load-bearing. Content is written on
every autosave while snapshots are paced, so a shared baseline would make the
close/switch trigger believe an edit had already been snapshotted - the content
was just written - and silently drop exactly the edit rule 3 exists to protect.
Both baselines are seeded on load.

**Test first (red)** - the class did not exist:

```
test/services/history_snapshot_policy_test.dart:15:8: Error: Error when reading
'lib/services/history_snapshot_policy.dart': The system cannot find the file specified
test/services/history_snapshot_policy_test.dart:23:22: Error: Method not found: 'HistorySnapshotPolicy'.
test/services/history_snapshot_policy_test.dart:28:18: Error: Undefined name: 'HistorySnapshotTrigger'.
```

**After the change** (policy + history suites):

```
00:04 +24: All tests passed!
```

**A guard caught the new file for a real reason.** The MS-005 static guard
rejects any `package:flutter/` string in a service-layer file, and the new
policy's own doc comment named that import path while describing what it did
*not* import:

```
Expected: not contains 'package:flutter/'
  Actual: '/// Decides *when* a `ManuscriptDocument` history snapshot is written.\n'
```

The guard was correct and the comment was wrong, so the comment was reworded
("no Flutter UI imports"). The new file was added to the MS-005 guard list so
the constraint is enforced going forward.

**Full suite:**

```
00:30 +422: All tests passed!
```

### Item 3b-3 - a revert must be undoable and visible

**Diagnosis of the two defects.** The revert was lossy in two independent ways,
and only the first was visible from the code:

1. *Undoability.* `HistoryPanel` called
   `binderProvider.updateContent(...)`, which overwrote the live document
   without recording what it replaced. Undoing a change destroyed it.
2. *Visibility, and the silent variant.* The editor holds its own
   `QuillController` and its own "unchanged" baselines. A revert mutates the
   document in place, so **no widget property the editor observes actually
   changes** - the editor cannot detect it. It keeps displaying the pre-revert
   prose *and* believes nothing changed, so the next autosave early-returns and
   ignores the revert entirely. The work is lost when the author types the fix
   they are typing precisely because the revert appears not to have worked.
   Separately, a debounce armed before the revert carries the pre-revert buffer
   and writes it back, so it must be cancelled rather than left to fire.

**Decisions.**

- The snapshot-before-overwrite lives in
  `ManuscriptBinderProvider.revertContentTo`, not in the panel. The panel is UI;
  the provider is the canonical manuscript state owner MS-007 established, and
  it already has the document and `_projectId` for `HistoryService`, so no new
  parameter had to be threaded into the panel. `revertContentTo` delegates to
  `updateContent`, so the MS-007 contract ("the revert goes through the binder
  provider, never the legacy `chapters` box") still holds and its spy-based
  test still observes the payload it always did.
- A revert to the content already loaded is a no-op, rather than recording a
  duplicate snapshot - the same "never snapshot identical content" rule the
  policy applies on the autosave path.
- The pre-revert snapshot deliberately **bypasses** `HistorySnapshotPolicy`:
  this is a user-initiated revision, not a paced autosave beat, and forcing it
  through the 60s window would drop the revert's own history.
- The editor cannot observe an in-place document mutation, so the shell bumps a
  monotonic `revertSignal` (threaded screen -> `ManuscriptModule` ->
  `ManuscriptEditor`) and the editor answers in `didUpdateWidget` with
  `_applyExternalRevert`: re-read the canonical document *through the
  provider* (the editor's own reference is exactly what cannot be trusted
  here), cancel the armed timers, decode, and re-base both baselines.
- The delta decode is extracted into `_applyDocumentContent` and the baselines
  into `_resyncBaselines`, so a document loaded normally and one reloaded after
  a revert share one path. A second copy of the decode is how a revert ends up
  rendering differently from the same content opened fresh.

**Test first (red):**

```
test/widgets/manuscript_revert_test.dart:219:11: Error: No named parameter with the name 'revertSignal'.
test/widgets/manuscript_revert_test.dart:151:28: Error: The method 'revertContentTo' isn't defined for the type 'ManuscriptBinderProvider'.
```

**Two faults in the test itself, not the product**, both worth recording:

- The chapter document was seeded *after* the binder provider was constructed.
  The provider caches its document list at construction, so the editor's
  chapter-key resolution could not see it and the buffer came up empty. Fixed by
  seeding before constructing the provider.
- The autosave debounce is a `Timer` created while the test is inside
  `tester.runAsync`, so it lives in the **real** zone. `tester.pump(3s)`
  advances only the fake clock and therefore never saves anything; the first
  version asserted a save that could not possibly have happened. Waiting for a
  save means waiting in *real* time, then pumping to flush continuations.

A third fault was caught by Quill's own assertion rather than by an expect: a
fixture whose last insert lacked a trailing newline
(`(doc.last.data as String).endsWith('\n')`) threw *inside* `runAsync`, where
the framework reports it as "the exception was caught asynchronously" and the
test's own failure still surfaces - so a broken fixture can masquerade as a
product failure.

**After the change:**

```
00:15 +6: All tests passed!     (manuscript_revert_test.dart)
00:15 +35: All tests passed!    (history + revert + topology)
No issues found! (ran in 2.0s)
00:46 +428: All tests passed!
```

**Both halves confirmed red with the fix disabled**, so the tests are not
vacuous. Disabling the `didUpdateWidget` hook:

```
00:10 +4 -2: Some tests failed.
  3b-3 ... a pending debounce and the next autosave both keep the revert
  3b-3 ... the editor displays the reverted content
```

Disabling the pre-revert snapshot:

```
Expected: non-empty
Actual: []
the revert must be undoable
```

**Test harness.** Per the instruction to drive the smallest real
`ManuscriptEditor`/`QuillController` harness if the shell deadlocks, the revert
tests mount `ManuscriptModule` (real editor, real `QuillController`, real
in-memory Hive) rather than `ProjectEditorScreen`. A probe test,
`the editor autosaves an edit after the 2s debounce`, asserts the harness's
autosave genuinely reaches storage, so "the autosave did not overwrite the
revert" cannot pass by never saving anything.

One existing assertion was updated rather than worked around: MS-007's
`historyEntries.values.single` became "the snapshot that was reverted to is
untouched, and the replaced content is now recorded". Two entries are the
intended new behaviour.

### Item 3b-4 - teardown deadlock: diagnosis only (no fix)

**Conclusion: this is a test-harness artefact of zone mixing, not an application
defect.** There is no lock, no leaked Hive handle, and no provider holding a
write open. Two probes, differing in exactly one line, isolate it.

**Probe A - shell + chapter open + real autosave + unmount, all real-zone:**

```
PROBE: mounted
PROBE: QuillEditor found=2
PROBE: body text="Hello world"
PROBE: after autosave stored=[{"insert":"Autosaved prose\n"}]
PROBE: unmounting
PROBE: unmounted
00:05 +1: All tests passed!
```

The write completes, the unmount completes, `DatabaseManager.instance.close()`
and `Hive.close()` in `tearDown` complete. No hang.

**Probe B - identical, except the controller change is *not* wrapped in
`tester.runAsync`:**

```
PROBE B: mounted
PROBE B: edit applied, advancing fake clock 3s
PROBE B: after fake pump stored=[{"insert":"Autosaved in fake zone\n"}]
```

The test **body completed and the write landed** - and the process then never
exited. `flutter test --timeout 45s` did not fire, and the shell command was
terminated by its own 600s limit. No `All tests passed` line was ever printed.
The hang is therefore in post-test teardown, after the body, and no stack can
be captured because the runner is unresponsive.

**Mechanism.** `_saveContent` does substantial asynchronous work *after* the
content write: the history snapshot (box add plus pruning) and then
`rebuildIndex()`. Those continuations live in whatever zone armed the autosave
timer. When that zone is the FakeAsync test zone, the chain is still in flight
when the test body ends: each remaining step needs the real event loop to
service Hive I/O, while the framework's teardown is draining the fake-async
zone and waiting for it to quiesce. The runner ends up waiting for quiescence
that requires the very loop it is not letting run. Probe A avoids it purely
because the 3-second real delay lets the chain drain before the body ends.

This explains the Cycle 3 observation exactly: that probe drove a real autosave
from the fake zone, reached its assertion, reported the result, and then hung
until the runner was killed.

**Two latent contributors, reported but deliberately not changed** (out of
3b-4's diagnose-only scope):

- `_saveContent` calls `rebuildIndex()` on every autosave (B5 D3 warns this
  calls `engine.clear()` and can drop non-manuscript entries). Besides being
  wrong at 2s, it lengthens the in-flight window that the teardown waits on,
  so it is a contributing factor to the hang's timing as well as a live
  correctness issue.
- `ChapterListProvider`'s constructor mutates Hive (creating front matter and a
  `Chapter`) as a side effect of construction. It did not cause this hang - the
  shell mounts fine in probe A - but it is the same class of hazard: work
  spawned from a constructor has no owner to await or cancel it, and any
  teardown-safety work should start there.

**Practical guidance that follows from the diagnosis:** every harness that
performs a real write must create it inside `tester.runAsync` and unmount under
the fake clock. That is what the existing topology, history, and new revert
harnesses already do, and it is why 3b-3 needed no shell-level test at all.

### Commits

| Commit | Requirement |
| --- | --- |
| `7c40acb` | 3b-1 - restore the 2s autosave debounce (S-34) |
| `26235d1` | 3b-2 - HistorySnapshotPolicy; editor delegates the snapshot decision |
| `6966c79` | 3b-3 - revert is undoable and the open editor follows it |

### Tests added

| File | Tests | Covers |
| --- | --- | --- |
| `test/services/history_snapshot_policy_test.dart` | 12 | identical content (3 triggers), 60s interval elapsed / not / boundary / no prior snapshot, close-trigger override, seeded-on-load |
| `test/widgets/manuscript_revert_test.dart` | 6 | pre-revert snapshot, historical write, no-op revert, editor display, pending debounce + next autosave, harness autosave probe |

Plus 1 delegation guard added to
`test/widgets/manuscript_history_test.dart` (3b-2), 1 file added to the MS-005
Flutter-free guard, and MS-007's revert assertion restated for the two-entry
history.

Test count progression: 409 -> 409 (3b-1) -> 422 (3b-2) -> **428** (3b-3).

### Files changed

| File | Change |
| --- | --- |
| `lib/services/history_snapshot_policy.dart` | new - pure-Dart snapshot pacing |
| `lib/modules/manuscript_module.dart` | 2s debounce, policy delegation, split baselines, `_applyDocumentContent`, `_resyncBaselines`, `_applyExternalRevert`, `revertSignal` |
| `lib/providers/manuscript_binder_provider.dart` | `revertContentTo` (snapshot then overwrite) |
| `lib/widgets/history_panel.dart` | revert routes through `revertContentTo` |
| `lib/screens/project_editor_screen.dart` | `_manuscriptRevertSignal`, `_handleManuscriptRevert` |
| `lib/widgets/manuscript_topology_test.dart` | MS-005 guard list |
| `test/services/history_snapshot_policy_test.dart` | new |
| `test/widgets/manuscript_revert_test.dart` | new |
| `test/widgets/manuscript_history_test.dart` | MS-008 re-scoped to the content write + delegation guard; MS-007 history assertion |

No Hive adapters, no schema, no dependencies, and no changes to the public APIs
of `EntityRef`, `ReferenceEngine`, `ReferenceIndex`, `EntityNameMatcher`,
`ManuscriptBinderService`, or `ReferenceIntegrityService`.

### Verification (final)

`flutter analyze`:

```
Analyzing lore_keeper...
No issues found! (ran in 2.2s)
```

`flutter test --concurrency=1` (last line):

```
00:49 +428: All tests passed!
```

### Deferred / not done

- **B5 D3: `rebuildIndex()` on every autosave.** Now unmissable at a 2s
  debounce, and a contributing factor to the 3b-4 teardown window. Out of
  3b scope; needs its own cycle.
- **3b-4 diagnosed, not fixed.** The teardown deadlock is a zone-mixing
  artefact of the test harness rather than a product defect, so there is
  nothing to fix in `lib/` on its account. Making the app's provider
  construction side-effect-free (see `ChapterListProvider`) and trimming the
  post-write work in `_saveContent` would both narrow the window and are worth
  doing for their own reasons.
- **Unsaved editor buffer at revert time.** The pre-revert snapshot captures the
  *stored* document, which is what "snapshot the current content before a revert
  writes historical content" asks for. A revert while the author has uncommitted
  text in the buffer does not snapshot that buffer. Flushing the editor first
  would need the editor to participate in the revert transaction; not done.
- **No backfill.** Documents that already carry duplicate history entries from
  identical saves keep them, as recorded at the end of Cycle 3.
- **B7 MS-020 wording vs. reality.** Resolved after Cycle 3b; see
  *Post-Cycle 3b correction* below.
- MS-015 (dual `ManuscriptReferenceService`) remains deferred to Cycle 4.

### Post-Cycle 3b correction

- B7's MS-020 acceptance was corrected to name the artifact Cycle 3 actually
  built, because the original text named the legacy `chapter_diff_view_dialog.dart`
  and would have sent the next implementer to guard the one file that was
  deliberately left alone, while leaving the real `ManuscriptDocumentDiffViewDialog`
  path unguarded by name.
