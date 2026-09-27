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
