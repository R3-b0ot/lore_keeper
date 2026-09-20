# Pass 8 — Tests & Quality

> Evidence: `flutter analyze` (clean), `flutter test` (377 pass), `flutter test --coverage` (15.7%), test-file inventory, lint config, code-quality greps.

---

## 8.1 Analyzer & lint

- `flutter analyze` → **"No issues found! (ran in 2.5s)"**. The "13 analyzer warnings (dead code — remove SVG optimization files)" debt in AGENTS.md is **stale** — those files are gone.
- `analysis_options.yaml` extends **`flutter_lints`** (default set). No project-specific rule tightening (no `public_member_api_docs`, no `avoid_dynamic_calls`) → the AGENTS.md coding standards (docs on public APIs, type-safety comments) are **not enforced by the toolchain**. Enforcement burden falls 100% on review.

## 8.2 Test inventory (25 files / 6,220 lines)

| Area | Files | Notes |
|---|---|---|
| `test/database/` | ai_provider 118, device_ai_discovery 87, live_generate 49, llama_cpp 149, openai_compatible_client 176, openai_http 281, species_ai_service 274, database_manager 218, database_metadata 88, entity_ref 109, legacy_migration 407, reference_engine 315 | **12 files** — deepest coverage area |
| `test/services/` | az_reference_pipeline_diagnostic 296, corkboard_reorder 177, entity_name_matcher 404, manuscript_binder_service 170, manuscript_collections_service 162, manuscript_reference_service 93, reference_integrity_service 233, reference_name_resolver 342 | **8 files** |
| `test/utils/` | calendar_chronology 185, debug_logger 80 | 2 files |
| `test/widgets/` | manuscript_topology 428, project_book 260, reference_autocomplete 1119 | **only 3 widget files** |

`flutter test` → **+377 passing, 0 failing.**

**Only 2 files touch providers** (manuscript_topology_test.dart:26-28, corkboard_reorder_test.dart:18 — both via `ManuscriptBinderProvider`). **No module is directly tested** — only `manuscript_module` indirectly through manuscript_topology.

## 8.3 Coverage (overall **15.7%** — 2,963 / 18,828 lines) by layer

| Layer | Coverage | Covered/Found |
|---|---|---|
| database | 68.7% | 646/941 |
| services | 53.7% | 419/780 |
| models | 27.9% | 379/1359 |
| utils | 27.9% | 76/272 |
| widgets | 13.9% | 1087/7798 |
| modules | 9.0% | 254/2822 |
| providers | 5.4% | 86/1590 |
| settings | 1.3% | 16/1253 |
| theme | 0.0% | 0/8 |
| core | 0.0% | 0/82 |
| **screens** | **0.0%** | **0/1923** |
| **TOTAL** | **15.7%** | 2963/18828 |

Key coverage facts:
- **Every screen is at 0%** — including `project_editor_screen.dart` (372/0), `trait_editor_screen.dart` (0/831), `relation_chart_screen.dart` (0/695).
- **All world-building surface ~0%**: `calendar_tree_provider` 0/481, `magic_tree_provider` 0/436, `species_provider` 0/233, `timeline_module` 0/315, `magic_main_panel` 0.5%, `calendar_picker` 0/444, `species_tree` 0/730.
- **Character module 0.2%** (3/1,765) — the largest, least-tested file.
- **Strong spots**: reference engine (92.6%), entity_ref (100%), ai providers (94-100%), `reference_autocomplete_controller` (97.2%)/overlay (93.4%), manuscript binder service (55.9%), bind/multi-pane widgets (36-59%), `project_book` (88.5%), `database_manager` (37.0%).

=> **Clear pattern: the *new* manuscript/editor/reference/AI pipeline is well covered; the *older* character/world-building/screens layers are effectively untested.** Tests are bias-confirmed to the 2025-2026 re-design.

## 8.4 Coverage-mode caveat

`flutter test --coverage` on this machine failed for **11 test files that fail to LOAD** in the pre-build state (they depend on generated `.g.dart` imports): `legacy_migration_test`, `az_reference_pipeline_diagnostic_test`, `corkboard_reorder_test`, `manuscript_binder_service_test`, and others; `reference_autocomplete_test` failed with "Error when reading 'lib/models/character.g.dart'". This occurred **after** the build_runner deletion incident (Pass 1.7); after `git restore`, the full suite (incl. all 11 files + 377 tests) passes and the coverage above was produced cleanly. **Regression risk:** the codegen breakage silently widens — run coverage only with `.g.dart` present, and fix the build_runner issue to remove the fragility.

## 8.5 Lifecycle & resource defects found (quality)

| Defect | Location | Severity |
|---|---|---|
| `QuillController _manuscriptController` **never disposed** | `project_editor_screen.dart:77,579` (created; not in `dispose()` at 417-429) | High (leak per editor open) |
| `ReferenceEngine` + `AiProvider` never disposed | `project_editor_screen.dart:166-174` | Med |
| 21 `debugPrint(` calls in lib (ch/list providers 10+5, services 3, modules 3) | grepped across lib/ | Low (bypasses `debug_logger.dart`) |
| 2 search delegates (GlobalSearchDelegate vs DashboardSearchDelegate) | `dashboard_topbar.dart:7` vs `dashboard_hero.dart:6` | Low |
| `ActionCard` import is `onTap: () {}` (no-op) | dashboard widget | Low |
| Duplicate date-formatting in 3 files | services/widgets | Low |
| `_CandidateTile.onHover` no-op | `reference_autocomplete_overlay.dart:125-127` | Low |
| HistoryEvent `targetType` mismatch (Pass 6.4) | manuscript_module vs history_panel | Med (feature broken) |
| `_replaceAll` offset drift + attribute-strip (Pass 6.5) | find_replace_dialog.dart:56-111 | Med |
| cron/`.g.dart` delete risk (Pass 1.7) | pubspec/build_runner | **High (build hygiene)** |

## 8.6 Diagnostics notes (Pass 1 runtime)

`flutter` in this pwsh env emits a benign leading `The system cannot find the file specified` (environment artifact; every command still succeeds). Logging util `debug_logger.dart` exists and is 94.7% covered — but 21 raw `debugPrint` calls bypass it.

## 8.7 Pass 8 conclusions

1. **Quality bar is set by the manuscript pipeline only** — that's the tested 15.7%. The other ~84% is greenfield for tests.
2. Priority test targets: shell (`project_editor_screen` incl. module-index normalization), `relation_chart_screen`/`trait_editor_screen`, `calendar_tree_provider`/`magic_tree_provider` (the 2 god providers), `character_module`, settings panes (1.3%).
3. Fix the 3 resource leaks (QuillController High; engine/AI Med) and the build pipeline (High) before anything else in Pass 9.
4. Enforce AGENTS.md standards with lint rules or accept they're advisory.