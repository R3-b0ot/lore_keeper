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

---

## Cycle 4 - reference index integrity

**Branch:** `manuscript-fixes`
**Scope:** MS-014, MS-015, MS-004 completion, MS-016

### Housekeeping (before any code change)

- B7 MS-007's acceptance named `ManuscriptBinderProvider.updateContent` as the
  revert path. Cycle 3b replaced that with `revertContentTo` (snapshot before
  overwrite, plus the `revertSignal` editor reload), so the requirement now
  names the undoable path and states explicitly why bare `updateContent` is the
  content-write path (MS-008) and not a revert.
- B7 gains **OQ-8**: a revert does not flush the editor's unsaved buffer first,
  so text typed but not yet autosaved can be lost without being snapshotted.
  Recommended default — warn the user and let them cancel if the buffer has
  unsaved changes. Deferred.

### Baseline (before any code change)

`flutter analyze`:

```
Analyzing lore_keeper...
No issues found! (ran in 2.4s)
```

`flutter test --concurrency=1` (last line):

```
00:48 +428: All tests passed!
```

### Traced current behaviour

**MS-014 — `ManuscriptReferenceService.rebuildIndex()` as found** (the code had
not shifted since the B5 D4 audit):

```dart
  /// Rebuild the reference index for all manuscript documents in this project.
  Future<void> rebuildIndex() async {
    final entries = extractAllReferences();
    _referenceEngine.clear();
    for (final entry in entries) {
      _referenceEngine.addEntry(entry);
    }
  }
```

`ReferenceEngine` already exposed `removeWhere(bool Function(ReferenceIndexEntry)
test)`, so no API addition was needed — the removal method was available and
simply unused.

**MS-015 — two services, one engine.** `_ManuscriptModuleState._initReferenceService()`
built a `ManuscriptReferenceService`, and `_ManuscriptEditorState._initReferenceService()`
built a second one:

```dart
  Future<void> _initReferenceService() async {          // editor
    final db = DatabaseManager.instance;
    _referenceService = ManuscriptReferenceService(
      projectId: widget.projectId,
      referenceEngine: _resolveSharedEngine(),
      documentBox: db.manuscriptDocuments,
    );
    await _referenceService!.rebuildIndex();
  }
```

Both ran `rebuildIndex()` on the same shared engine at init, so the module
session built the index twice on mount and the autosave at
`_saveContent → rebuildIndex()` had two owners.

`ManuscriptCollections` was traced as instructed and is **not** part of MS-015's
scope. It self-constructs a `ManuscriptCollectionsService` (a different class
that receives `widget.provider.referenceEngine`), not a
`ManuscriptReferenceService`, and it is not mounted in the editor column. It
holds no reference service to share, so the identity assertion in the test
covers the module, the editor, and (correctly) not the collections pane. Wiring
a service into it would mean adding a new constructor parameter to a public
widget purely for uniformity — out of scope, and deferred.

**MS-016 — `entityExists` conflated "deleted" with "unresolvable":**

```dart
  bool entityExists(EntityRef ref) {
    final targetProjectId = int.tryParse(ref.projectId) ?? -1;
    switch (ref.entityType) {
      case EntityType.character: ...
      case EntityType.species: ...
      case EntityType.timelineEvent: ...
      case EntityType.manuscriptDocument: ...
      default:
        return false;
    }
  }
```

and the purge used that single bool as a removal test:

```dart
  List<ReferenceIndexEntry> purgeStaleEntries() {
    final stale = findStaleEntries();
    engine.removeWhere(
      (e) => !entityExists(e.source) || !entityExists(e.target),
    );
    return stale;
  }
```

Confirmed: Location/Item/Organization/Faction/Research/CalendarDate/Map resolve
to `false` because no box exists to look in, and the purge read that as
"deleted". The first purge after any entity deletion destroyed every mention of
every not-yet-implemented type.

### Requirement log

#### MS-014 - rebuildIndex must not clear non-manuscript entries (4f52f37)

- **Test first (red):**

```
00:00 +0 -1: MS-014 — rebuildIndex only owns manuscript-sourced entries a non-manuscript-sourced entry survives rebuildIndex [E]
  Expected: an object with length of <1>
    Actual: []
     Which: has length of <0>
  a Character-sourced entry must survive a manuscript rebuildIndex
```

- **Implementation.** Replaced the wholesale `clear()` with a scoped removal of
  only manuscript-sourced entries, then re-added the freshly extracted set:

```dart
    _referenceEngine.removeWhere(
      (e) => e.source.entityType == EntityType.manuscriptDocument,
    );
```

- **Two extra tests, not just the required one.** "stale manuscript entries are
  still replaced" pins that the fix did not degrade into a no-op append — the
  obvious way to make the first test pass would be to stop removing anything.
  "idempotent across repeated calls" pins that a second rebuild replaces rather
  than duplicates.
- **A test-harness fault worth recording:** Hive's adapter registry is global
  and outlives `Hive.deleteFromDisk()`, so the per-test `registerAdapter` threw
  `HiveError: There is already a TypeAdapter for typeId 40`, which surfaced as
  a confusing `LateInitializationError: Local 'box' has not been initialized`
  in the tests. Guarded with `Hive.isAdapterRegistered(...)`.
- **After the change:**

```
00:00 +6: All tests passed!
No issues found! (ran in 2.2s)
00:52 +431: All tests passed!
```

#### MS-015 - one ManuscriptReferenceService per module session (601b965)

- **Test first: the first version of this test was wrong and passed
  vacuously.** It asserted on `tester.widget<ManuscriptEditor>(...).referenceService`
  — the *constructor field*. That field is whatever the module handed down, so
  the assertion could only ever confirm that the module passed an argument; a
  second service built inside the editor's State was invisible to it. Three
  successive red checks all came back green, which is what exposed the fault.
  Rewritten to read the editor's **State** via
  `tester.state(find.byKey(kManuscriptEditorKey)) as dynamic` and its
  `referenceService` getter.
- **Real red, with adoption disabled:**

```
00:02 +0 -1: runtime topology ONE ManuscriptReferenceService instance serves the module and the editor (MS-015) [E]
Expected: true
Actual: <false>
the editor must hold the module's own service instance, not a second service over the same engine (MS-015)
```

- **Implementation.** The editor's `_initReferenceService()` was deleted. The
  editor now reads `widget.referenceService` in `initState` and adopts the
  canonical instance in `didUpdateWidget` via `_adoptReferenceService()`, which
  no-ops when the service is unchanged or not yet built. `ManuscriptEditor`
  gained one nullable constructor parameter; the module passes `_referenceService`
  to both the editor and the inspector.
- **One consequence accepted deliberately:** on the very first build the
  module's service is still null (it is built asynchronously), so the editor
  holds null for that frame. An earlier draft built a binder-derived fallback
  instead, but that reintroduced a second service — the very thing MS-015
  forbids — and its `rebuildIndex()` on top. Null-for-one-frame is strictly
  better than a duplicate owner, and the autosave that needs the service cannot
  fire before it exists.
- **MS-004 completion:** the existing MS-004 engine-identity test was re-run
  unchanged and still passes, and still means the same thing — it asserts
  identity of the *engine* across the binder, the editor's binder provider, and
  the inspector's service:

```
00:00 +0: runtime topology ProjectEditorScreen shares ONE ReferenceEngine across the manuscript pipeline (MS-004)
00:02 +1: All tests passed!
```

  MS-015 is a strictly stronger assertion layered on top (service identity, not
  engine identity), and the two together pin both levels of the topology.
- **After the change:**

```
No issues found! (ran in 2.1s)
00:48 +432: All tests passed!
```

#### MS-016 - unsupported types must not be purged as stale (e2cf190)

- **The pre-existing test asserted the bug.** Cycle 0's
  `unsupported types (no data source) are treated as stale` required
  `removed, hasLength(2)` and an empty index. That is the defect, encoded as a
  contract, so the test was replaced rather than left failing. Its name and
  intent are recorded here so the change is auditable rather than silent.
- **Real red** (fix reverted, old unresolvable-based purge restored):

```
Expected: an object with length of <1>
    Actual: [
Which: has length of <3>
Expected: empty
Actual: [Instance of 'ReferenceIndexEntry']
00:00 +10 -6: Some tests failed.
```

- **Implementation.** `ReferenceNameResolver.entityIsDefinitelyGone(EntityRef)`
  added: true only for the four types with a canonical box (character, species,
  timelineEvent, manuscriptDocument) when `entityExists` says they are absent;
  false for everything else. `entityExists` itself is **unchanged** in
  signature and behaviour, so the autocomplete and Inspector callers that
  depend on the bool are untouched.
- **`ReferenceIntegrityService` gains one optional named parameter**
  (explicitly permitted for MS-016): `entityIsDefinitelyGone`. `purgeStaleEntries`
  now filters on it. Reporting paths (`findStaleEntries`, `groupByUnresolved`,
  `unresolvedCount`) deliberately stay on `entityExists`, so unresolved mentions
  are still *surfaced* to the author — they are just no longer destroyed. That
  split is the point of the requirement: surfacing an unresolvable mention is
  correct, deleting it is not.
- **A polarity bug caught by the existing suite, worth recording.** The
  constructor default was first written as `entityIsDefinitelyGone ??
  entityExists`, which inverts the meaning: the new predicate answers "was it
  deleted?" while `entityExists` answers "does it exist?". Two pre-existing
  `reference_integrity_service_test.dart` tests failed with
  `Expected: length <1>, Actual: length <2>` — the purge had started removing
  every entry whose source *resolved*. Fixed to `(ref) => !entityExists(ref)`,
  which preserves the old behaviour exactly for callers that pass no predicate.
- **Four tests added**, including the required non-regression:

```
00:00 +13: MS-016: a Location ref survives the purge (no canonical source)
00:00 +14: MS-016: every sourceless type survives, not just Location
00:00 +15: MS-016: a genuinely deleted Character is still purged
00:00 +16: MS-016: entityIsDefinitelyGone is false without a source, true after deletion
00:00 +17: All tests passed!
```

  The "every sourceless type" test covers all eight types with no canonical box,
  so the fix is not a Location special case. The "deleted Character is still
  purged" test pins that real deletions still remove both of their backlinks
  while a surviving species reference in the same index is left alone.
- **After the change:**

```
No issues found! (ran in 2.2s)
00:00 +10: All tests passed!     (reference_integrity_service_test.dart)
00:55 +435: All tests passed!
```

### Commits

| Commit | Requirement |
| --- | --- |
| `f90c34d` | housekeeping - MS-007 revert path corrected, OQ-8 added |
| `4f52f37` | MS-014 - rebuildIndex removes only manuscript-sourced entries |
| `601b965` | MS-015 - one ManuscriptReferenceService instance per module session |
| `e2cf190` | MS-016 - purge only known-deleted entities, not unresolvable types |

MS-004 required no code change; its existing test was re-verified in place.

### Tests added

| File | Tests | Covers |
| --- | --- | --- |
| `test/services/manuscript_reference_service_test.dart` | 3 | non-manuscript entry survives; stale manuscript entries still replaced; idempotent across rebuilds |
| `test/widgets/manuscript_topology_test.dart` | 1 | module and editor hold one identical service instance (MS-015) |
| `test/services/reference_name_resolver_test.dart` | 4 | Location survives; all 8 sourceless types survive; deleted Character still purged; predicate polarity |

| | Before | After |
| --- | --- | --- |
| Count | 428 | **435** (+7) |

One pre-existing test was rewritten (it asserted the MS-016 bug); no test was
deleted.

### Files changed

| File | Change |
| --- | --- |
| `lib/services/manuscript_reference_service.dart` | `rebuildIndex` scoped removal (MS-014) |
| `lib/modules/manuscript_module.dart` | editor adopts the module's service; `referenceService` param + getter; `didUpdateWidget` adoption (MS-015) |
| `lib/services/reference_name_resolver.dart` | `entityIsDefinitelyGone` added; `purgeStale` wires it; `entityExists` behaviour unchanged (MS-016) |
| `lib/services/reference_integrity_service.dart` | optional `entityIsDefinitelyGone` param; `purgeStaleEntries` uses it (MS-016) |
| `test/services/manuscript_reference_service_test.dart` | MS-014 group |
| `test/widgets/manuscript_topology_test.dart` | MS-015 identity test |
| `test/services/reference_name_resolver_test.dart` | MS-016 group; Cycle 0 stale-types test replaced |
| `docs/audit2/B7_manuscript_requirements.md` | MS-007 corrected; OQ-8 added |

No build_runner, no dependency changes, no Hive adapters, no schema change. No
existing public signature was changed or removed — `ReferenceIntegrityService`
gained one optional named parameter, which MS-016 explicitly calls for. No new
service file was added, so the MS-005 Flutter-free guard list needed no
extension.

### Verification (final)

`flutter analyze`:

```
Analyzing lore_keeper...
No issues found! (ran in 2.2s)
```

`flutter test --concurrency=1` (last line):

```
00:55 +435: All tests passed!
```

### Deferred / not done

- **MS-014 performance note (measured, not fixed).** `rebuildIndex()` still
  re-scans **every** manuscript document in the project on every call, not just
  the active one — `extractAllReferences()` filters the whole document box by
  `projectId` and re-parses each document's Delta JSON. With the 2s autosave
  from 3b-1 that is a full-project re-parse every two seconds while typing, and
  it is *also* the largest single contributor to the 3b-4 teardown window.
  **Not fixed this cycle, and it should not have been:** making it incremental
  means tracking which documents changed and invalidating only those, which is a
  real design change to the index's ownership model (a rename, move, reorder, or
  delete also changes what a document *emits*, and a re-index must still notice).
  That is its own cycle, not a side effect of fixing the `clear()`. Flagged here
  rather than silently absorbed.
- **`ManuscriptCollections` DI bypass (MS-015 out of scope).** It
  self-constructs a `ManuscriptCollectionsService`. That is a different class
  from `ManuscriptReferenceService`, it receives the shared engine, and it holds
  no reference service — so there is nothing to de-duplicate. Giving it one for
  uniformity would mean adding a constructor parameter to a public widget with
  no consumer. Left alone deliberately.
- **MS-016 reporting vs. removal is now split, and the reporting half is
  unchanged.** An unresolved Location mention still shows up in
  `unresolvedCount` / `groupByUnresolved` / the Inspector, which is correct
  behaviour but means the UI will keep flagging mentions it cannot resolve.
  Whether those should be visually distinguished from genuinely dangling refs
  is a UX decision not taken here.
- **No Location/Item/Organization box exists yet.** MS-016 stops the data loss
  but does not make those mentions resolvable. When those modules are built,
  `entityIsDefinitelyGone` must be extended to cover the new types or their
  deletions will silently stop being purged.
- **B7 OQ-8** (revert does not flush the editor's unsaved buffer) remains
  deferred, as recorded in housekeeping.
- **B5 D3** (`rebuildIndex` on every autosave) was partly addressed by MS-014 —
  it no longer destroys other producers' entries — but its frequency is
  untouched and is the performance note above.
- MS-015 (dual `ManuscriptReferenceService`) is now closed.

---

## Cycle 4b - incremental re-index on autosave

**Branch:** `manuscript-fixes`
**Scope:** closes the MS-014 deferred performance note and the frequency half of
B5 D3. Not a numbered MS requirement.

### Baseline (before any code change)

`flutter analyze`:

```
Analyzing lore_keeper...
No issues found! (ran in 2.1s)
```

`flutter test --concurrency=1` (last line):

```
00:47 +435: All tests passed!
```

### Traced call sites of rebuildIndex()

Two call sites in `lib/`, both found by grepping for `rebuildIndex`; the only
other hits are comments and the definition itself.

**Call site 1 — module session init** (`lib/modules/manuscript_module.dart:157`,
in `_ManuscriptModuleState._initReferenceService`):

```dart
    await svc.rebuildIndex();
```

What changed: **nothing yet — this is the first read of the index.** The
module just came up and the shared engine may be cold, or may have been
populated by a previous module instance. A full rebuild is the only correct
call: there is no single document to scope to. **This call site is unchanged.**

**Call site 2 — the autosave** (`lib/modules/manuscript_module.dart:827`, at the
end of `_ManuscriptEditorState._saveContent`):

```dart
    await _referenceService?.rebuildIndex();
```

What changed: **exactly one document's body, and nothing else.** Immediately
above, `_saveContent` has already called
`_binderProvider?.updateContent(_selectedDocument!.id, content)` — one document,
one field. No sibling was touched, no document was created, moved, renamed, or
deleted. This call site is the one that was over-scoped, and it is the one that
fires on the 2s debounce from 3b-1. **This call site now calls the scoped
path.**

There is no third call site. Notably, `ManuscriptBinderService`'s structural
operations (`moveDocument`, `deleteDocument`, `createDocument`) never call
`rebuildIndex()` at all — `deleteDocument` removes its own entries directly via
`ReferenceIntegrityService.removeSource`/`removeTarget`. That is the right
shape, and it means switching the autosave to a scoped rebuild could not have
weakened those paths, because they never went through it.

### Decisions

**The scope boundary is documented on the method, not just in the log.** The
brief's design constraint was that rename/move/reorder/delete change what a
document *emits*, not just its body. Rather than silently assuming they don't,
each case was traced:

- **body edit** — changes only this document's outbound entries. The scoped
  path is exactly right.
- **delete** — the document is gone, so there is nothing to re-parse.
  `deleteDocument` already owns this through `removeSource`/`removeTarget`,
  which also handles *inbound* backlinks that a scoped rebuild could not.
  Calling `rebuildIndexFor` with a deleted id is a safe no-op (the removal
  branch still runs, the re-add does not), but the binder remains the owner.
- **move / reorder** — change `parentId`/`orderIndex`. The current extractor
  (`extractReferencesFromDocument`) reads *only* `richTextJson`, so these
  genuinely do not alter the index today.
- **rename** — changes `title`, which the extractor does not index.

So the constraint is satisfied for the right reason: the index's inputs are
currently the body alone, and the method's doc comment says so explicitly —
including the caveat that if a future change makes a document emit
hierarchy-derived or title-derived entries, `rebuildIndexFor` must be
accompanied by a full rebuild on those operations. Without that note, the next
person to add a title-derived entry would get a silently stale index.

**A test asserts identity, not presence.** This was the load-bearing test
choice. `ReferenceIndexEntry` overrides `operator ==`, so a remove-and-re-add
produces an object that is *equal* to the original — a "still present" assertion
passes even when every entry was destroyed and rebuilt. The test captures the
entry instances before the scoped rebuild and asserts `identical()` afterward,
which is the only way to distinguish "untouched" from "rebuilt identically".

**One public addition, no signature changes.** `rebuildIndex()` is untouched
(MS-014's contract and its three tests depend on it). Added alongside it:
`rebuildIndexFor(String documentId)`, the `parsedDocumentCount` getter (evidence
for the requirement-4 measurement, and a cheap way for a test to assert scope),
and a private `_sourceRefFor` helper. The MS-005 Flutter-free guard needed no
extension because no new service file was created.

### Tests

**Test first (red)** — the methods did not exist:

```
test/services/manuscript_reference_service_test.dart:327:21: Error: The method 'rebuildIndexFor' isn't defined for the type 'ManuscriptReferenceService'.
test/services/manuscript_reference_service_test.dart:404:41: Error: The getter 'parsedDocumentCount' isn't defined for the type 'ManuscriptReferenceService'.
```

**And a second red, with `rebuildIndexFor` temporarily delegating to the full
rebuild** — this is the check that proves the identity assertion is real:

```
Expected: true
Actual: <false>
doc_1 entry 0 must be the SAME instance (never re-parsed)
00:00 +0 -1: Some tests failed.
```

**A test fault, recorded because it nearly produced a false pass.** The delete
test initially built its inbound backlink with a *Location*-typed target whose
id happened to be the doomed document's id. `removeTarget` matches on the whole
`EntityRef`, so the entry survived and the test failed for a reason unrelated to
the behaviour. Split into a separate `mentionDocument` helper that types the
target as `manuscriptDocument`, which is what an inbound document-to-document
backlink actually is.

**After the change:**

```
00:00 +23: All tests passed!     (reference service + binder service)
No issues found! (ran in 2.0s)
00:54 +441: All tests passed!
```

### Performance measurement (requirement 4)

A temporary bench test (created, run, then deleted — not left in the suite)
seeded realistic bodies: one prose insert plus 8 `ref:Location` links each, so
the parse cost is not trivial. A warm-up full rebuild was run first so Hive's
box caching is not charged to the measured call.

```
BENCH docs=10  entries=80   full=1230us (20 parses)  scoped=773us  (1 parse)  speedup=1.6x
BENCH docs=50  entries=400  full=1908us (100 parses) scoped=85us   (1 parse)  speedup=22.4x
BENCH docs=200 entries=1600 full=4242us (400 parses) scoped=163us  (1 parse)  speedup=26.0x
```

(The parse counts are cumulative across the two measured calls, hence 20/100/400
rather than 10/50/200; the scoped column is the per-call delta and is the number
that matters.)

**The result scales with project size, which is the point.** The 10-document
case is nearly break-even (1.6x) because fixed overhead dominates; by 200
documents the scoped path is 26x cheaper and the gap keeps widening, since the
full path is O(documents) and the scoped path is O(1). The counted assertion is
also in the permanent suite: a 20-document project must parse 20 documents on a
full rebuild and exactly 1 on a scoped one.

### Requirement 5 — 3b-4 teardown probe

**Skipped as specified, with the reasoning recorded.** The 3b-4 probes were
throwaway files, deleted after the diagnosis, and reconstructing the
ProjectEditorScreen-level scaffolding to re-run them would be significant work
for a nice-to-confirm.

The closest permanent equivalent *was* run: `manuscript_revert_test.dart` drives
a real autosave through a real `QuillController` in a real editor mount — the
same real-write-in-the-real-zone path probe A exercised — and it passes:

```
00:07 +5: 3b-3 — a pending debounce and the next autosave both keep the revert
00:15 +6: All tests passed!
```

That is consistent with, but does not prove, a narrower teardown window: the
diagnose in 3b-4 established that the hang is a zone-mixing artefact of the
fake-async harness, not a fixed cost that shrinking the work would remove. The
honest claim is that the work done per autosave is now ~26x smaller at 200
documents, which reduces the in-flight window teardown waits on — not that the
hang is fixed. It is a harness problem, and it stays a harness problem.

### Commits

| Commit | Requirement |
| --- | --- |
| `0afcb40` | scoped `rebuildIndexFor` + autosave rewired + identity/count/delete tests |

### Tests added

| File | Tests | Covers |
| --- | --- | --- |
| `test/services/manuscript_reference_service_test.dart` | 4 | other documents keep object identity; unknown id is a no-op not a wipe; scoped idempotence; parse-count reduction at 20 documents |
| `test/services/manuscript_binder_service_test.dart` | 2 | delete purges outbound *and* inbound; delete with an empty index |

| | Before | After |
| --- | --- | --- |
| Count | 435 | **441** (+6) |

No test was modified or deleted.

### Files changed

| File | Change |
| --- | --- |
| `lib/services/manuscript_reference_service.dart` | `rebuildIndexFor`, `parsedDocumentCount`, `_sourceRefFor`, parse counter |
| `lib/modules/manuscript_module.dart` | autosave calls `rebuildIndexFor(_selectedDocument!.id)` |
| `test/services/manuscript_reference_service_test.dart` | Cycle 4b group |
| `test/services/manuscript_binder_service_test.dart` | structural-change group |

`rebuildIndex()` itself is unchanged. No build_runner, no dependencies, no
adapters, no schema. No listed public API changed or lost a method.

### Verification (final)

`flutter analyze`:

```
Analyzing lore_keeper...
No issues found! (ran in 2.2s)
```

`flutter test --concurrency=1` (last line):

```
00:50 +441: All tests passed!
```

### Deferred / not done

- **The 10-document case is only ~1.6x faster.** For a very small project the
  scoped path's fixed cost is nearly the whole cost, so there is no dramatic win
  yet. Not worth special-casing.
- **`rebuildIndex()` is still O(all documents)** and is still called on module
  session init. That is correct — a cold or previously-populated engine has no
  single changed document to scope to — but a long-lived session that never
  remounts never re-indexes the whole project. If another writer mutates
  documents outside the autosave path, the full rebuild is the only thing that
  will notice, and nothing calls it on a schedule. Deferred.
- **Structural operations still do not re-index at all** (they never did).
  Correct today because move/reorder/rename are not index inputs, but that is
  an invariant held by convention in the binder rather than by anything the
  compiler or the tests would catch. If a future feature indexes a document's
  title, hierarchy, or metadata, the binder's `moveDocument`/`updateTitle` must
  gain a `rebuildIndex()` call. Recorded in `rebuildIndexFor`'s doc comment for
  that reason.
- **Requirement 5 not verified by the original probes** — see above; the
  teardown deadlock remains a fake-async harness artefact, not a product defect.
- **B5 D3 is now closed on both halves**: MS-014 stopped the collateral damage
  (no longer clearing other producers' entries), and Cycle 4b stopped the
  over-scoped work. The `rebuildIndex`-on-autosave call itself still exists, by
  design — it is the re-index, and it is now correctly scoped.
