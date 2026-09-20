# Pass 3 — Data Layer

> Sources: `lib/database/database_manager.dart` (+ `database_metadata.dart`), `lib/models/` (29 files), `lib/database/reference_engine/`, `lib/database/ai/`. Verified directly during audit.

---

## 3.1 Database architecture overview

- Storage: **Hive** (local, per-device, binary boxes). No remote sync, no cloud, no export/import plumbing at data layer (file export only mentioned in docs).
- Boot: `lib/main.dart` → `DatabaseManager.instance.initialize()` → Hive.initFlutter → adapter registration → schema detection → migrations → open 19 application boxes.
- `DatabaseManager` is a **singleton** (`database_manager.dart:43-47`) with a per-box accessor via a generic `getBox<T>()` map (`:51, 86`).

## 3.2 The 19 Hive boxes

All opened sequentially in `_openApplicationBoxes()` (`database_manager.dart:451-471`), box-name constants at `:22-41`:

| # | Box name | Type | Opened at |
|---|---|---|---|
| 0 | `lorekeeper_meta` | `DatabaseMetadata` | `:128/152/157` (during detect) |
| 1 | `projects` | `Project` | `:453` |
| 2 | `chapters` | `Chapter` | `:454` |
| 3 | `sections` | `Section` | `:455` |
| 4 | `manuscript_documents` | `ManuscriptDocument` | `:456` |
| 5 | `manuscript_collections` | `ManuscriptCollection` | `:457` |
| 6 | `characters` | `Character` | `:458` |
| 7 | `links` | `Link` | `:459` |
| 8 | `history` | `HistoryEntry` | `:460` |
| 9 | `magic_systems` | `MagicSystem` | `:461` |
| 10 | `magic_nodes` | `MagicNode` | `:462` |
| 11 | `calendar_systems` | `CalendarSystem` | `:463` |
| 12 | `calendar_nodes` | `CalendarNode` | `:464` |
| 13 | `timeline_events` | `TimelineEvent` | `:465` |
| 14 | `classification_nodes` | `ClassificationNode` | `:466` |
| 15 | `map_data` | `MapData` | `:467` |
| 16 | `settings` | untyped (`Box`) | `:468` |
| 17 | `custom_traits` | untyped (`Box`) | `:469` |
| 18 | `customPanel` | `Box<String>` | `:470` |
| 19 | `customField` | `Box<String>` | `:471` |

> Note the two boxes `customPanel` / `customField` (strings, not models). Box 17 `custom_traits` is untyped — see `trait_service.dart`.

## 3.3 Schema versioning & migrations

- `currentSchemaVersion = 3` (`database_metadata.dart:10`).
- Versioned metadata box `lorekeeper_meta`, record key `'metadata'` (`database_manager.dart:131`).
- Detection (`_detectAndInitialize`, `:124-164`): three cases — (1) metadata box exists → read version + migrate; (2) no metadata but any legacy box present → treat as *legacy_v1*; (3) nothing → fresh database.
- Stepped migration loop `_runMigrations` (`:244-264`) migrates one version at a time: `v→v+1…→current`, updating `schemaVersion` + `lastMigrationAt`.
- Existing migrations:
  - **V1→V2** (`:283-293`): no-op data-wise; writes metadata record to formalize versioning.
  - **V2→V3** (`:295-435`): creates the `ManuscriptDocument` hierarchy out of legacy `Chapter`/`Section` boxes: root `manuscript_<projectKey>` per project, `part_<sectionKey>` per section, `chapter_<chapterKey>` per chapter (parenting respects `front_matter_` sections under the manuscript root, `:393-402`). Copies `richTextJson` and computes word/char counts (`:423-424`).
- Hive TypeIds registered in `_registerAdapters()` (`:203-240`) — full map below.

**Note:** the migration code (`:437-447`) duplicates the word-count logic found in services (`lib/services/manuscript_binder_service.dart`) — the same "raw JSON regex word count" heuristic appears 3× in tree (`_countWords` here + `manuscript_binder_service.dart:246-247,551-559`; editor uses Quill `toPlainText()` at `manuscript_module.dart:576-585`). Divergence documented in Pass 6.

## 3.4 Entity model map & TypeId registry

Registered TypeAdapters (`database_manager.dart:203-240`) with Hive TypeIds:

| TypeId | Entity | TypeId | Entity |
|---|---|---|---|
| 0 | Project | 26 | CalendarSystem |
| 2 | Chapter | 27 | CalendarNode |
| 3 | Section | 28 | CalendarAttribute |
| 4 | Character | 29 | TimelineEvent (hand-written adapter) |
| 5 | Link | 30 | MapData |
| 7 | MagicSystem | 31 | MapLayer |
| 8 | MagicNode | 32 | MapStamp |
| 9 | MagicAttribute | 33 | MapPath |
| 10 | CharacterIterationSafe | 34 | MapPolygon |
| 11 | HistoryEntry | 35 | OffsetData |
| 12 | CustomTrait | 36 | ClassificationNode (hand-written) |
| 13 | CharacterImage | 37 | ClassificationArticle (hand-written) |
| 20 | CustomField | 40 | ManuscriptDocument |
| 21 | CustomPanel | 41 | ManuscriptCollection |
| 22 | MagicImage | 50 | DatabaseMetadata (hand-written) |

> **Critical:** four adapters (`DatabaseMetadata`, `TimelineEvent`, `ClassificationNode`, `ClassificationArticle`) are **hand-written** in `database_metadata.dart` (lines 88–371) with explicit doc comments stating they were written "because the project's dev_dependencies have a pre-existing version conflict that prevents build_runner from resolving" (e.g. `:83-87`). This is direct evidence of the **broken codegen build** from Pass 1 — the build pipeline has been dead for a while and is worked around manually. This is the root cause of the `.g.dart`-deletion incident.

## 3.5 Entity relationships & reference model

- Project (1) → Chapters/Sections/Characters/Links/MagicSystems/CalendarSystems/TimelineEvents/ClassificationNodes/ManuscriptDocuments/Collections — all child boxes carry `projectId` (`int`).
- Legacy `chapters`/`sections` boxes: `parentProjectId`, `parentSectionKey`, `orderIndex`; section key `-1` (constant `frontMatterSectionKey`) reserved for front matter (`:309`).
- Manuscript hierarchy (Pass 6 detail): `ManuscriptDocument.parentId` string forest; legacy strings `chapter_<int>` / `part_<int>` / `front_matter_-N`.
- Link model (`lib/models/link.dart`) is a real FK between entities (characters ↔ others).
- **Reference index** (`lib/database/reference_engine/`): `ReferenceIndex` builds an in-memory bloom+bucket index of manuscript mentions; `EntityRef` (`lib/database/entity_ref.dart`) is the addressable reference type (`kind` = mention/backlink, etc.) — **95–100% test-covered** (Pass 8).

## 3.6 Data access hygiene

- **Rule "no `Hive.openBox` in widgets" HOLDS in the shell** — `Hive.box('settings')` is confined to `theme_provider.dart:51` and `settings_repository.dart`; direct `Hive.box('chapters')` appears in `chapter_diff_view_dialog.dart` (one legacy dialog) — a rule violation but contained.
- **Query pattern:** services/providers iterate `box.values.where((x) => x.projectId == id)` with in-memory filtering; no indexes (other than the reference engine). O(n) scans on every open of a project; fine at current scales, but a scaling risk.
- **Direct-Hive leakage into state:** providers read/write boxes directly (e.g. `character_list_provider.dart`, `chapter_list_provider.dart`) — data access is not mediated by repositories (Clean Architecture `data/repositories/` dir from the docs **does not exist**).

## 3.7 Coverage of the data layer

`flutter test --coverage` (2026-09-20): layer at **68.7%** (646/941 lines) — the best-covered layer, dominated by the AI + reference-engine + metadata files:

- `database/entity_ref.dart` 100%, `ai/device_ai/device_ai_discovery` 100%, `ai/ai_provider_factory` 100%, `ai/ai_metadata` 100%, `reference_engine/reference_engine.dart` 92.6%, `reference_index.dart` 81.5%, `openai_compatible_client` 94.4%, `openai_http_ai_provider` 94.1%, `database_metadata.dart` 67.7%.
- **Weak spots:** `database_manager.dart` only **37.0%** (the migration logic `V2→V3` is largely untested); `map`-related models 0%.
- `test/database/legacy_migration_test.dart` (407 lines) exists and covers migration paths *directly* against `DatabaseManager` (in-memory Hive) — but see Pass 8 caveat: it **fails to load** when `.g.dart` files are missing (the incident state).

## 3.8 Pass 3 conclusions

1. Data layer is well-structured around Hive with versioned schema + stepped migrations — genuinely better than the skeleton most apps ship.
2. **P0: codegen pipeline is broken** (hand-written adapters + `.g.dart` deletion incident). Fix before any `@HiveField` change — otherwise migrations and box adapters drift silently.
3. Word/character counting is duplicated across 3 implementations with divergent semantics (JSON-string length vs plain-text length) — consolidate.
4. Repositories layer (per docs) doesn't exist; data flows Hive → providers → widgets. Not "wrong", but it means the documented Clean Architecture has no repository seam for tests/mocking.
5. `TimelineEvent` & `ClassificationNode` adapters hand-written means any field change to those models requires manual adapter edits (no codegen safety net).