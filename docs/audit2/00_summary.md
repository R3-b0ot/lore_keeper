# Audit Summary — Lore Keeper Cleanup + Manuscript Rebuild

> Branch `cleanup` (HEAD `a7ed2f3`, merged to `main`). Audit date: 2026-09-21.  
> Full evidence in `docs/audit2/A1_cleanup_verification.md` through `B7_manuscript_requirements.md`.

---

## Part A — Cleanup Verdict: PASS WITH MINOR NOTES

All seven cleanup categories are substantively correct. Specific findings:

| Claim | Verdict | Notes |
|---|---|---|
| Root junk files deleted | ✅ VERIFIED | All 9 files gone from tracked tree |
| Map v1 module, provider, models, box, adapters removed | ✅ VERIFIED | TypeIds 30–35 not reused; `EntityType.mapData/mapLayer` constants intentionally kept in reference engine |
| Dead theme code removed; live chain intact | ✅ VERIFIED | `ThemeBootstrap.initialize → ThemeRegistry → MinimalThemePack/Dracula → AppTheme` confirmed |
| QuillController lifecycle fixed | ✅ VERIFIED | Shell nulls reference; `ManuscriptEditor.dispose()` owns and disposes both controllers |
| `debugPrint` → `LkLog` | ✅ VERIFIED | 0 `debugPrint` calls in `lib/` |
| `cupertino_icons` removed | ✅ VERIFIED | 0 import sites in `lib/` or `test/` |
| Dashboard search unified | ✅ VERIFIED | `DashboardSearchDelegate` deleted; `GlobalSearchDelegate` is sole survivor |
| `_cleanDocument` removed | ✅ VERIFIED | `Document.fromJson(ops)` called directly; page-break ops cannot be created in Quill 11.x |
| CI workflow added | ✅ VERIFIED | `.github/workflows/ci.yaml` valid YAML; runs analyze + test on every push and PR |
| README/AGENTS.md accuracy | ⚠️ PARTIAL | Magic/Calendar/Timeline/Species described as "modules" in both docs; they live in `providers/` + `widgets/`, not `lib/modules/` |
| `flutter analyze` 0 issues | NOT VERIFIED | Flutter SDK not on PATH in audit environment; accepted from report |
| `flutter test` 377 pass | NOT VERIFIED | Same reason; accepted from report |

**Items needing fixes before this branch is used as a clean base:**
- README.md and AGENTS.md module taxonomy (low effort, low risk)

---

## Part B — Confirmed Defects (12 total, all against current HEAD)

| ID | Summary | Severity |
|---|---|---|
| D1 | Manuscript history invisible — `HistoryPanel` filters `targetType:'Chapter'`; autosave writes `'ManuscriptDocument'` | High |
| D2 | Three divergent word/character counters — service uses JSON-regex/JSON-length; editor uses plain-text | Medium |
| D3 | Find & Replace strips `ref:` link attributes; Replace All drifts offsets when replacement length ≠ find length | Medium |
| D4 | `rebuildIndex()` calls `engine.clear()` — destroys non-manuscript engine entries on every autosave | Medium |
| D5 | Non-character entity mentions (`Location`, `Item`, etc.) purged as stale — `entityExists` returns `false` for all unimplemented types | Medium |
| D6 | Hierarchy validation warn-only — invalid parent/child combinations silently accepted | Low |
| D7 | History snapshot on every autosave (every ~2s); no content-change guard | Low |
| D8a | `ManuscriptReferenceService` instantiated twice per module session — double `rebuildIndex()` during init | Medium |
| D8b | `IndexPageWidget` reads legacy `ChapterListProvider` — new ManuscriptDocument chapters do not appear on front-matter Index page | High |
| D8c | Delete document: no confirmation dialog for non-empty documents; silent child promotion | Medium |
| D8d | `ChapterDiffViewDialog` opens `Hive.box<Chapter>` directly in widget; revert writes to legacy box only | Medium |
| D8e | `tagIds` field persisted but never rendered in any view | Low |

---

## Top Ten Manuscript Requirements

Drawn from B7. The first eight each have a failing test that can be written today.

| # | ID | Priority | Description |
|---|---|---|---|
| 1 | MS-006 | MUST | HistoryPanel must show ManuscriptDocument revisions (fix D1 targeting) |
| 2 | MS-007 | MUST | Revert must use `ManuscriptBinderProvider.updateContent`, not legacy Chapter box |
| 3 | MS-009 | MUST | Single plain-text word count — replace JSON-regex in `ManuscriptBinderService._countWords` |
| 4 | MS-010 | MUST | Single plain-text character count — replace `richTextJson.length` with `toPlainText().length` |
| 5 | MS-011 | MUST | Replace preserves `ref:` link attributes (no `replaceText(..., null)`) |
| 6 | MS-012 | MUST | Replace All uses descending-offset iteration to prevent coordinate drift |
| 7 | MS-014 | MUST | `rebuildIndex` removes only manuscript-source entries, not all engine entries |
| 8 | MS-015 | MUST | Single `ManuscriptReferenceService` instance per module session |
| 9 | MS-001 | MUST | Runtime widget tree contains exactly 1 of each of the 4 canonical column widgets (verified by topology test with all 4 keys) |
| 10 | MS-019 | MUST | `IndexPageWidget` reads `ManuscriptBinderProvider`, not legacy `ChapterListProvider` |

---

## Open Questions (developer decision required)

| # | Question | Recommended default |
|---|---|---|
| OQ-1 | Keep legacy `chapters` box open while `GlobalSearchDelegate` and `OverviewModule` still use it? | Yes — replace their reads only when those modules are rebuilt |
| OQ-2 | Tri-state `entityExists` for unimplemented types (MS-016), or a separate `entityIsDefinitelyGone` predicate? | Add `entityIsDefinitelyGone(EntityRef)` alongside existing bool API |
| OQ-3 | Raise autosave debounce to reduce history spam (D7)? | Raise to 5 s + add content-change guard before increasing history limit |
| OQ-4 | Where to expose tag editing for `tagIds`? | Inspector inline chips; defer full tag management screen |
| OQ-5 | Calendar date display: formatted chronology or raw integers in Inspector? | Raw placeholder until Calendar module exposes a formatting API |
| OQ-6 | Remove `EntityType.mapData/mapLayer` from `EntityType.all`? | Keep until Map module is rebuilt — removal breaks `entity_ref_test.dart` |
| OQ-7 | Spec baseline says "300 tests"; current repo has 377. Update spec? | Yes — operative baseline is 377; update `docs/LORE_KEEPER_MANUSCRIPT_MASTER_SPEC.md §32.1` |

---

*Audit complete. No files modified outside `docs/audit2/`. Do not commit.*
