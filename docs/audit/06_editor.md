# Pass 6 — Manuscript, Editor & Reference Engine

> Deep-dive from direct source read + reference-system agent. Every claim file:line verified.

---

## 6.1 Quill stack

- `flutter_quill ^11.4.0`, `flutter_quill_extensions ^11.0.0`, `language_tool ^2.2.0` (pubspec.yaml:40-42). Installed/resolved 11.4.x per lockfile at audit time.
- Editor configured in `manuscript_module.dart:970-980`: `embedBuilders: [...FlutterQuillEmbeds.editorBuilders()]` (image+video only), `onLaunchUrl: _onReferenceLaunch`, `customLinkPrefixes: ['ref:']`.
- `_cleanDocument` (`manuscript_module.dart:509-518`) strips `{'insert':{'page-break':…}}` ops — **dead defensive code**: no page-break embed exists in flutter_quill 11.x (verified against package sources). Can be deleted.

## 6.2 The manuscript document model (2026 redesign, works)

`lib/models/manuscript_document.dart` (88 analyzed lines, 86.7% covered):
- `@HiveType(40)`; 25 fields: `id(0) projectId(1) title(2) documentTypeIndex(3) parentId(4) orderIndex(5) richTextJson(6) statusIndex(7) summary(8) povCharacterId(9) locationId(10) timelineEventId(11) plotline(12) characterIds(13) tagIds(14) isExpanded(15) createdAt(16) modifiedAt(17) wordCount(18) characterCount(19) purpose(20) isFavorite(21)` + 3 calendar-date fields (22–24).
- Types: `manuscript/part/chapter/scene/section/note/research/frontMatter/backMatter/custom`; statuses: idea→complete/archived.
- Stored in `'manuscript_documents'` box (`database_manager.dart:456`), opened box 4.
- **Hierarchy invariants** (`manuscript_binder_service.dart:492-527`): manuscript→{part,chapter,frontMatter,backMatter}; part→{chapter,section}; chapter→{scene}; section→{scene,note,research}; scene→{note}. Enforcement is **warn-only** (`_validateTypeHierarchy`) — invalid trees are silently allowed.
- IDs: root `manuscript_${project.key}` (`manuscript_binder_service.dart:205`; auto-created at `manuscript_binder_provider.dart:48-54`); children `'${type.label}_${Uuid().v4()}'`; legacy `chapter_<intKey>` (map bridge at `project_editor_screen.dart:372-378`); front-matter via **legacy negative keys** `front_matter_-1/-2/-3` (`manuscript_service.dart:11-15, 129-133`), rendered by custom widgets (`CoverPageForm`, `IndexPageWidget`, `AboutAuthorForm`) instead of Quill (`manuscript_module.dart:955-965`).
- Content: `richTextJson` = `{"ops":[...]}` Delta JSON; empty doc = `{"ops":[{"insert":"\n"}]}` (`manuscript_binder_service.dart:564`).

### ⚠️ Word/char count divergence (bug class)
Three different "word count" implementations live in the tree:
1. Editor, live: `toPlainText().trim().split(RegExp(r'\s+'))` (`manuscript_module.dart:576-585`) + `characterCount = toPlainText().length` (`:532-539`).
2. `ManuscriptBinderService.updateContent`: `wordCount = _countWords(richTextJson)` via regex `[^a-zA-Z0-9\s]` on **raw JSON** and `characterCount = richTextJson.length` (**JSON string length**, not text length) (`manuscript_binder_service.dart:246-247, 551-559`).
3. Migration `_countWords` (`database_manager.dart:437-447`) — same JSON approach as (2).
Result: any consumer reading between saves (Inspector totals, corkboard) sees JSON-length "character counts". Should be consolidated to one plain-text counter (Pass 9).

## 6.3 The @mention/reference system — TODAY's actual design

**Claims in older docs/plans about a regex-based system are outdated. The current system is attribute-based and works:**

- **Encoding**: `ReferenceTarget.encode()` → `ref:${type.label}:$id` stored as a standard Quill **`link` attribute**; `decode()` reverse; `isReference()` predicate (`services/reference_attribute.dart:73-89`). `ReferenceEntityType` has 10 values; `fromEntityType()` maps Calendar/Timeline/CustomTrait labels (`:39-53`).
- **Triggering**: `@` after whitespace (`reference_autocomplete_controller.dart:185-192`) → candidates ranked by `EntityNameMatcher` (exactName 1.0 > exactAlias 0.9 > prefix 0.7/0.6 > substring 0.3/0.2, max 20, `entity_name_matcher.dart:120-258`) → insert via `formatText(..., LinkAttribute(...))` (`:133-146`). Overlay: max 8 rows, keyboard nav, hover is a **no-op** (`reference_autocomplete_overlay.dart:125-127`).
- **Candidate scoping** (`manuscript_module.dart:353-381`): Characters (always) + Species leaf nodes + Timeline Events + Manuscript Documents.
- **Extraction/backlinks**: `ManuscriptReferenceService.extractAllReferences` (`manuscript_reference_service.dart:70-100`) scans Delta `attrs['link']` where `isReference`, emits `ReferenceIndexEntry(source, target, kind:'mentions')` for every manuscript doc → `ReferenceEngine` index. **Backlink flow is real** (list via `reference_integrity_service.dart`, Inspector shows "Referenced by").
- **Cleanup**: purging deleted characters removes stale index entries (`character_list_provider.dart:145-152`).

### Bugs (verified)
1. **`rebuildIndex` wholesale-clear** (`manuscript_reference_service.dart:103-109`): `_referenceEngine.clear()` then rebuilds only manuscript-source entries → any index work contributed by non-manuscript modules is wiped on the next autosave.
2. **Name-resolution gaps**: `reference_name_resolver.dart:80-84` resolves Character, Species, TimelineEvent, ManuscriptDocument; Location/Item/Org/Faction/Research/Calendar return `null` and `entityExists=false` (`:122-146`) → such mentions are "Unresolved" in the Inspector and **purged as stale even when valid**. (These are the still-unimplemented World-Building tabs.)
3. **Navigation**: `_onReferenceNavigate` (`project_editor_screen.dart:322-339`) navigates only `Character`; the rest are "not yet implemented" (`:338`).

## 6.4 History (snapshot model, no undo/redo)

- `HistoryService` (`services/history_service.dart`, 58 lines): two boxes `history` + `projects`. `addHistoryEntry` (`:14-57`) stores `jsonEncode(objectToSave.toJson())` per `(targetKey, targetType)`, prunes to `project.historyLimit` (default 10) oldest-first.
- `HistoryEntry` = `@HiveType(11)`; `data` field is an opaque JSON string.
- `HistoryPanel` (`widgets/history_panel.dart`): reads `targetType` to pick a diff viewer — `'Character'→DiffViewDialog`, `'Chapter'→ChapterDiffViewDialog`, **everything else "Diff view not supported"**.

### 🐛 Pass 6's most impactful bug: **manuscript history is invisible**
- Manuscript saves write `targetType: 'ManuscriptDocument'` with the **document id** (`manuscript_module.dart:633-638`).
- The panel filters `targetType: 'Chapter'` with the **legacy chapter key** (`project_editor_screen.dart:665-679`).
- → Manuscript revisions are stored in `history` but **never listed**. The panel's "Chapter" branch probably refers to the legacy `chapters` box too (`chapter_diff_view_dialog.dart:23-25, 90`), which the 2026 redesign is phasing out. Net: the history feature as surfaced today works only for the legacy chapters box and characters.

## 6.5 Find & Replace — attribute-destructive

`widgets/find_replace_dialog.dart`:
- `_performFind` (`:36-54`): `toPlainText()` + case-aware `indexOf`, always from start; no next/wrap; no scroll-to-selection (acknowledged `:51-52`).
- `_performReplace` (`:56-83`): requires current selection == find string; `replaceText(..., null)` **strips `ref:` link attribute (and any formatting)** on the replaced span.
- `_replaceAll` (`:85-111`): iterates a **snapshot of the original plain text** while mutating the live document → **🐛 offset drift when replacement length ≠ find length**; also attribute-lossy.

## 6.6 Grammar checker (LanguageTool) — consistent with mentions

- `_runGrammarCheck` (`manuscript_module.dart:1104-1116`): sends `toPlainText()`; ignored words from `_project.ignoredWords` (`:1117-1121`); `_acceptIssue`/`_runAutoCorrect` use `controller.replaceText(offset, length, …, null)` directly with LanguageTool plain-text offsets (`:1153-1159, 1220-1227`); autoclose sorts **descending offset** (`:1151`).
- **Offsets are consistent** because (a) mentions are characters (1:1 in `toPlainText`), and (b) embeds contribute exactly 1 object-replacement char in this quill version — so grammar offsets never misalign with text. Good.
- Opt-in consent dialog before any network call (`:1176-1203`).

## 6.7 Editor lifecycle / leaks

- `QuillController _manuscriptController` declared `project_editor_screen.dart:77`, created at `:579`, used at `:398-409` (find-replace) — **not disposed** in `dispose()` (`:417-429`). Leak per editor session (Pass 8 cross-ref).
- `ReferenceEngine` + the `AiProvider` built by `buildAiProviderFromSettings` (`project_editor_screen.dart:166-174`) are **never disposed** (engine has no dispose; the provider objects live for app lifetime).
- Autosave every 2 s snapshots whole document → history prunes to 10 fast (volume concern, not bug per se).

## 6.8 Dead/unused surface in this area

- `ManuscriptReferenceService.getReferencesInContainer` / `searchReferences` / `getReferencedEntityTypes` and `ReferenceEngine.search` are implemented but **not consumed by any widget**.
- `_cleanDocument` page-break stripping (dead).
- History "Chapter vs ManuscriptDocument" mismatch makes manuscript history dead UI.

## 6.9 Pass 6 conclusions

1. The 2026 manuscript redesign is the **best-engineered area of the app**: model + binder + reference engine with real tests (39.6–97% coverage in its files).
2. But three real bugs undermine it: (a) history `targetType` mismatch hides manuscript history; (b) word/char counts diverge between editor and persistence; (c) find-replace is attribute-destructive + offset-drifting.
3. Reference mentions of non-character entities are structurally disabled (no resolver, no navigation, no world-building tab).
4. Editor + engine + AI resources leak from the shell.