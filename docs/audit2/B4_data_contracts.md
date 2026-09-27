# B4 — Data Contracts

> All field types and defaults verified by direct source reads. "Legacy-only" means the field is on a legacy model no longer written by the new pipeline.

---

## 1. ManuscriptDocument (`lib/models/manuscript_document.dart`, typeId 40)

| HiveField | Name | Type | Default | Who reads | Who writes | Legacy-only |
|---|---|---|---|---|---|---|
| 0 | `id` | `String` (late) | — | everywhere | `ManuscriptBinderService.createDocument` (UUID-based) | NO |
| 1 | `projectId` | `int` (late) | — | all service queries | `ManuscriptBinderService` on create; V2→V3 migration | NO |
| 2 | `title` | `String` (late) | — | Binder, Outliner, Inspector, search | `ManuscriptBinderService.updateTitle`, `ManuscriptEditor._saveTitle` | NO |
| 3 | `documentTypeIndex` | `int` | `chapter.index` | Binder (icon/color), Outliner, Collections filter, hierarchy validation | `ManuscriptBinderService.createDocument` | NO |
| 4 | `parentId` | `String?` | `null` | Binder tree, getChildren, ancestor chain | `ManuscriptBinderService.createDocument`, `moveDocument` | NO |
| 5 | `orderIndex` | `int` | `0` | Binder sort, Outliner row order | `ManuscriptBinderService.reorderDocument`, `_shiftSiblings` | NO |
| 6 | `richTextJson` | `String?` | `null` | `ManuscriptEditor._loadContent`, `ManuscriptReferenceService` | `ManuscriptEditor._saveContent` → `ManuscriptBinderProvider.updateContent` → `ManuscriptBinderService.updateContent` | NO |
| 7 | `statusIndex` | `int` | `draft.index` | Binder (italic for archived), Corkboard, Outliner, Collections filter | `ManuscriptBinderProvider.updateStatus` | NO |
| 8 | `summary` | `String?` | `null` | Corkboard card, Inspector, Collections search | `ManuscriptBinderProvider.updateMetadata` | NO |
| 9 | `povCharacterId` | `String?` | `null` | Inspector (resolved via `ReferenceNameResolver`), Corkboard, Outliner | `ManuscriptBinderProvider.updateMetadata` | NO |
| 10 | `locationId` | `String?` | `null` | Inspector (raw — no resolver), Outliner | `ManuscriptBinderProvider.updateMetadata` | NO |
| 11 | `timelineEventId` | `String?` | `null` | Inspector (resolved), Outliner, `updateTimelineEvent` | `ManuscriptBinderProvider.updateTimelineEvent` | NO |
| 12 | `plotline` | `String?` | `null` | Corkboard, Outliner, search query | `ManuscriptBinderProvider.updateMetadata` | NO |
| 13 | `characterIds` | `List<String>` | `[]` | Inspector (resolved list) | `ManuscriptBinderProvider.updateMetadata` | NO |
| 14 | `tagIds` | `List<String>` | `[]` | Not consumed in any current widget | `ManuscriptBinderProvider.updateMetadata` | NO |
| 15 | `isExpanded` | `bool` | `true` | Binder expand/collapse | `ManuscriptBinderProvider.setExpanded` | NO |
| 16 | `createdAt` | `DateTime?` | `null` | Inspector | `ManuscriptBinderService.createDocument` | NO |
| 17 | `modifiedAt` | `DateTime?` | `null` | Inspector | Every update method sets `DateTime.now()` | NO |
| 18 | `wordCount` | `int` | `0` | Binder row, Outliner, Inspector, `getBranchWordCount` | `ManuscriptBinderService.updateContent` (JSON-regex), `ManuscriptEditor._updateDocumentWordCount` (plain-text) — **DIVERGES** | NO |
| 19 | `characterCount` | `int` | `0` | Inspector | `ManuscriptBinderService.updateContent` (`richTextJson.length` — **JSON length, not text length**), `ManuscriptEditor._updateDocumentWordCount` (`toPlainText().length`) — **DIVERGES** | NO |
| 20 | `purpose` | `String?` | `null` | Inspector | `ManuscriptBinderProvider.updatePurpose` | NO |
| 21 | `isFavorite` | `bool` | `false` | Collections `CollectionType.favorites` filter | `ManuscriptBinderProvider.toggleFavorite` → `ManuscriptBinderService.setFavorite` | NO |
| 22 | `calendarDateSystemKey` | `int` | `0` (unassigned) | Inspector (raw value) | `ManuscriptBinderProvider.updateCalendarDate` | NO |
| 23 | `calendarDateYear` | `int` | `0` (unassigned) | Inspector (raw value) | `ManuscriptBinderProvider.updateCalendarDate` | NO |
| 24 | `calendarDateDayOfYear` | `int` | `0` (unassigned) | Inspector (raw value) | `ManuscriptBinderProvider.updateCalendarDate` | NO |

**Computed accessors (not HiveFields):**
- `documentType` → `ManuscriptDocumentType.values[documentTypeIndex]`
- `status` → `ManuscriptDocumentStatus.values[statusIndex]`
- `isContainer` → manuscript / part / chapter / section
- `isLeaf` → scene / note / research
- `hasCalendarDate` → `calendarDateYear > 0`

---

## 2. ManuscriptCollection (`lib/models/manuscript_collection.dart`, typeId 41)

| HiveField | Name | Type | Default | Who reads | Who writes |
|---|---|---|---|---|---|
| 0 | `id` | `String` | — | `ManuscriptCollectionsService` queries | `ManuscriptCollectionsService.createCollection` (UUID) |
| 1 | `projectId` | `int` | — | All collection queries | On create |
| 2 | `name` | `String` | — | Collections widget | `ManuscriptCollectionsService.renameCollection` |
| 3 | `documentTypeIndex` | `int?` | `null` | `documentsForCollection` type filter | On create |
| 4 | `statusIndex` | `int?` | `null` | `documentsForCollection` status filter | On create |
| 5 | `createdAt` | `DateTime` | — | Sort order (newest first) | On create |

---

## 3. Project (manuscript-relevant fields, `lib/models/project.dart`, typeId 0)

| HiveField | Name | Type | Manuscript relevance |
|---|---|---|---|
| 0 | `title` | `String` | Manuscript root `title` defaults to this |
| 3 | `bookTitle` | `String?` | Manuscript root `title` prefers this if set |
| 4 | `lastEditedChapterKey` | `dynamic` | Legacy chapter key; written by `ManuscriptEditor._saveContent` and `ChapterListProvider`; used by `ProjectEditorScreen` as initial chapter selection |
| 7 | `ignoredWords` | `List<String>?` | Grammar check ignored words list |
| 8 | `lastModified` | `DateTime?` | Updated by every `ManuscriptBinderService` write operation |
| 9 | `historyLimit` | `int?` | Default 10; controls history pruning in `HistoryService` |

---

## 4. Chapter (legacy, `lib/models/chapter.dart`, typeId 2)

| HiveField | Name | Type | Notes |
|---|---|---|---|
| 0 | `title` | `String` | Read by `GlobalSearchDelegate`, `IndexPageWidget`, `OverviewModule` |
| 1 | `parentSectionKey` | `int` | Foreign key to Section. `-1` = front-matter section |
| 2 | `parentProjectId` | `int` | Project FK |
| 3 | `orderIndex` | `int` | Sort order |
| 4 | `richTextJson` | `String?` | Rich text (legacy); read by `ChapterDiffViewDialog` |

**Legacy-only.** Written by `ManuscriptService`/`ChapterListProvider`. V2→V3 migration copies content to `ManuscriptDocument`. The old `chapters` box remains open; `GlobalSearchDelegate` and `ChapterDiffViewDialog` read it directly.

---

## 5. Section (legacy, `lib/models/section.dart`, typeId 3)

| HiveField | Name | Type | Notes |
|---|---|---|---|
| 0 | `title` | `String` | Becomes Part title in V2→V3 migration |
| 1 | `orderIndex` | `int` | Part ordering in migration |
| 2 | `parentProjectId` | `int` | Project FK |
| 3 | `isExpanded` | `bool` | UI state |
| 4 | `parentSectionKey` | `int?` | Unused in practice |

**Legacy-only.** Only consumed by `ManuscriptService` and the V2→V3 migration.

---

## 6. HistoryEntry (`lib/models/history_entry.dart`, typeId 11)

| HiveField | Name | Type | Notes |
|---|---|---|---|
| 0 | `targetType` | `String` | `'Character'`, `'Chapter'`, **`'ManuscriptDocument'`** (new, but HistoryPanel only handles first two) |
| 1 | `targetKey` | `dynamic` | Int Hive key for Character/Chapter; String doc id for ManuscriptDocument |
| 2 | `timestamp` | `DateTime` | Snapshot time |
| 3 | `data` | `String` | `jsonEncode(objectToSave.toJson())` |
| 4 | `changeDescription` | `String?` | Optional; never set in current code |

---

## 7. ID Formats

| Format | Example | Produced by | Parsed/consumed by |
|---|---|---|---|
| `manuscript_<projectKey>` | `manuscript_42` | `ManuscriptBinderService.createManuscriptRoot` | `_selectDocumentForChapterKey` (implicit — root lookup by type) |
| `part_<sectionKey>` | `part_7` | V2→V3 migration | Provider/service queries by parentId |
| `chapter_<chapterKey>` | `chapter_3` | V2→V3 migration | `_chapterKeyFromDocumentId` in shell, `_selectDocumentForChapterKey` |
| `<type.label.lowercase_nospace>_<uuid>` | `scene_a1b2c3...` | `ManuscriptBinderService.createDocument` | Service `getDocument(id)` (Hive `box.get(id)`) |
| `front_matter_<int>` | `front_matter_-1` | `ManuscriptService.createFrontMatterChapter` | `_selectDocumentForChapterKey`, editor front-matter routing |
| Int Hive auto-key | `3` | `_chapterBox.add(chapter)` | `GlobalSearchDelegate`, `ChapterDiffViewDialog`, `HistoryPanel` (Chapter branch) |
| UUID string | any UUID | `ManuscriptCollectionsService.createCollection` | Collection box `get(id)` |

**Functions that parse/produce IDs:**
- `ManuscriptBinderService.createManuscriptRoot`: produces `manuscript_${project.key}`
- `ManuscriptBinderService.createDocument`: produces `${type.label.toLowerCase().replaceAll(' ','_')}_${Uuid().v4()}`
- `ProjectEditorScreen._chapterKeyFromDocumentId`: strips `chapter_` prefix → int string
- `ManuscriptEditorState._selectDocumentForChapterKey`: maps legacy chapter key → doc id by scanning binder
- `ManuscriptService.createFrontMatterChapter`: produces `front_matter_$hiveKey` string key

---

## 8. Rich Text Storage

- Format: Quill Delta JSON — `{"ops":[{"insert":"text\n"}, {"insert":"ref text","attributes":{"link":"ref:Character:42"}}]}`
- Empty document sentinel: `'{"ops":[{"insert":"\\n"}]}'` (defined as `ManuscriptModule.emptyRichTextJson` in `manuscript_binder_service.dart`)
- Stored in `ManuscriptDocument.richTextJson` (HiveField 6)
- Loaded: `Document.fromJson(ops)` in `ManuscriptEditor._loadContent`
- Saved: `jsonEncode(_controller.document.toDelta().toJson())` in `ManuscriptEditor._saveContent`

**Mention encoding:** `ref:TypeLabel:id` stored as a Quill `link` attribute value.  
Example: `{"insert":"Aiden","attributes":{"link":"ref:Character:42"}}`  
Decoded by: `ReferenceTarget.decode(linkValue)` in `ManuscriptReferenceService.extractReferencesFromDocument`  
Produced by: `ReferenceAutocompleteController._insertReference` → `_quillController.replaceText(atIndex, replaceLength, replacement, null)` then `_quillController.formatText(atIndex, replacement.length, LinkAttribute(target.encode()))`  

**`replaceText(..., null)` strips all attributes on the replaced span** — the null `TextSelection` argument clears formatting including `ref:` links. This is the root cause of the Find & Replace attribute-destructive bug (B5 D3).

---

## 9. Public API: ReferenceEngine

File: `lib/database/reference_engine/reference_engine.dart`

| Method | Signature | Contract |
|---|---|---|
| constructor | `ReferenceEngine({AiProvider?})` | Creates engine with optional AI; defaults to `NullAiProvider` |
| `addEntry` | `void addEntry(ReferenceIndexEntry)` | Appends entry to in-memory `_index` |
| `clear` | `void clear()` | Removes ALL entries. **Used by `ManuscriptReferenceService.rebuildIndex()` — clears non-manuscript entries.** |
| `removeWhere` | `void removeWhere(bool Function(entry))` | Removes matching entries |
| `rebuildIndex` | `Future<void> rebuildIndex({required extractReferences})` | Full rebuild: clears, then iterates `EntityType.all` calling extractor per type |
| `referencesFrom` | `List<ReferenceIndexEntry> referencesFrom(EntityRef)` | Outbound refs from source |
| `backlinksTo` | `List<ReferenceIndexEntry> backlinksTo(EntityRef)` | Inbound refs to target |
| `insideContainer` | `List<ReferenceIndexEntry> insideContainer(EntityRef)` | Entries scoped to container |
| `search` | `List<ReferenceIndexEntry> search(String)` | Token search on source/target id, kind, entityType |
| `referencedEntityTypes` | `Set<String> referencedEntityTypes(EntityRef)` | All entity types touching this ref |
| `aiSuggestRelated` | `Future<List<AiSuggestion>?> aiSuggestRelated(EntityRef)` | Delegates to AI provider; null if no AI |
| `aiEmbed` | `Future<List<double>?> aiEmbed(String)` | Text embedding; null if no AI |
| `index` | `List<ReferenceIndexEntry>` (getter) | Read-only snapshot of index |
| `length` | `int` (getter) | Entry count |
| `hasAi` | `bool` (getter) | Whether AI provider is ready |

**A rewrite must preserve:** `addEntry`, `clear`, `removeWhere`, `referencesFrom`, `backlinksTo`, `insideContainer`, `search`, `referencedEntityTypes` — all consumed by services/tests. `rebuildIndex` (full-rebuild overload) is defined but NOT called anywhere in production code; production uses `ManuscriptReferenceService.rebuildIndex()` instead.

---

## 10. Public API: ReferenceIndex / ReferenceIndexEntry

File: `lib/database/reference_engine/reference_index.dart`

| Member | Type | Contract |
|---|---|---|
| `source` | `EntityRef` | The entity containing the reference |
| `target` | `EntityRef` | The entity being referenced |
| `kind` | `String` | Relationship type — only `'mentions'` used in practice |
| `containerEntity` | `EntityRef?` | Optional scoping container |
| `computedAt` | `DateTime` | Index timestamp |
| Equality | `==` | By source + target + kind + containerEntity (not `computedAt`) |

---

## 11. Public API: EntityRef

File: `lib/database/entity_ref.dart`

| Member | Contract |
|---|---|
| `id` | Stable string identity (Hive key as string or UUID/own-id) |
| `entityType` | One of `EntityType.*` constants |
| `projectId` | Stringified project Hive key |
| `fromKey(key, entityType, projectId)` | Factory: `id = key.toString()` |
| `asKey` | Returns `int.tryParse(id) ?? id` |
| `==` / `hashCode` | By id + entityType + projectId |
| `toJson()` / `fromJson()` | Standard serialization |

---

## 12. Public API: EntityNameMatcher

File: `lib/services/entity_name_matcher.dart`

| Member | Contract |
|---|---|
| `EntityReferenceEntry(key, name, aliases, entityType)` | Data class; `aliases` defaults to `[]` |
| `ReferenceCandidate(entry, displayName, matchedName, matchType, confidence)` | Result from `resolve` |
| `EntityNameMatcher({maxResults = 20})` | Pure Dart; no Flutter/Hive dependencies |
| `resolve(String query, List<EntityReferenceEntry> entries)` | Returns ≤ `maxResults` candidates sorted by confidence desc; empty list for empty query |
| Confidence scores | exactName 1.0, exactAlias 0.9, prefixName 0.7, prefixAlias 0.6, substringName 0.3, substringAlias 0.2 |

**A rewrite must preserve all confidence values** — `reference_autocomplete_test.dart` (1,119 lines) asserts on them directly.

---

## 13. Public API: ManuscriptReferenceService

File: `lib/services/manuscript_reference_service.dart`

| Method | Signature | Contract |
|---|---|---|
| constructor | `ManuscriptReferenceService({projectId, referenceEngine, documentBox})` | Wires to shared engine and doc box |
| `extractReferencesFromDocument` | `List<(EntityRef, String)> extractReferencesFromDocument(doc)` | Parses `doc.richTextJson` Delta ops for `ref:` links; returns `(target, 'mentions')` pairs |
| `extractAllReferences` | `List<ReferenceIndexEntry> extractAllReferences()` | All project docs scanned; returns index entries |
| `rebuildIndex` | `Future<void> rebuildIndex()` | **Calls `engine.clear()` then repopulates.** Clears ALL engine entries including non-manuscript contributions. |
| `getBacklinksTo` | `List<ReferenceIndexEntry> getBacklinksTo(EntityRef)` | Delegates to engine |
| `getReferencesFrom` | `List<ReferenceIndexEntry> getReferencesFrom(doc)` | Delegates to engine |
| `getReferencesInContainer` | `List<ReferenceIndexEntry> getReferencesInContainer(String)` | Implemented; **not consumed by any widget** |
| `searchReferences` | `List<ReferenceIndexEntry> searchReferences(String)` | Implemented; **not consumed by any widget** |
| `getReferencedEntityTypes` | `Set<String> getReferencedEntityTypes(doc)` | Implemented; **not consumed by any widget** |
| `mapReferenceTypeToEntityType` | `String mapReferenceTypeToEntityType(ReferenceEntityType)` | Maps inline ref type → EntityType constant |

---

## 14. Public API: ReferenceIntegrityService

File: `lib/services/reference_integrity_service.dart`

| Method | Contract |
|---|---|
| `planDeletion(EntityRef)` | Returns `DeletionPlan(outbound, inbound)` without mutating index |
| `execute(EntityRef, DeletionStrategy)` | Applies strategy; returns affected entries |
| `removeSource(EntityRef)` | Removes all entries where source matches; returns removed |
| `removeTarget(EntityRef)` | Removes all entries where target matches; returns removed |
| `findStaleEntries()` | Returns entries where source or target fails `entityExists` |
| `purgeStaleEntries()` | Removes stale entries; returns them |
| `purgeAll()` | Calls `engine.clear()` |
| `groupByUnresolved()` | Groups stale entries by the unresolved ref |
| `unresolvedCount` / `hasUnresolvedReferences` | Count / bool of stale entries |

---

## 15. Public API: ReferenceNameResolver

File: `lib/services/reference_name_resolver.dart`

| Method | Contract |
|---|---|
| constructor | Requires boxes: characters, classificationNodes, timelineEvents, manuscriptDocuments |
| `ReferenceNameResolver.fromDatabase(int projectId)` | Factory using live `DatabaseManager.instance` boxes |
| `resolve(EntityRef)` | Delegates to `resolveById` |
| `resolveById(String entityId, String entityType)` | Returns human name or `null`; handles Character, Species, TimelineEvent, ManuscriptDocument; returns `null` for all other types |
| `entityExists(EntityRef)` | `bool`; project-scoped; same 4 types; `false` for others |
| `purgeStale(ReferenceEngine)` | Calls `ReferenceIntegrityService.purgeStaleEntries()` via the resolver's `entityExists` |
| `purgeStaleFromDatabase(ReferenceEngine)` | Static; builds resolver with projectId -1 (safe — each ref carries its own projectId) |

**Rewrite must preserve:** `resolveById` return contract (null = unknown/unsupported), `entityExists` semantics (false for unimplemented types — tests assert this), project-ID scoping, `fromDatabase` factory pattern.

---

## 16. Every Place That Reads or Writes richTextJson / ref: Mentions

| Operation | Location | Evidence |
|---|---|---|
| **Write richTextJson** | `ManuscriptEditor._saveContent` | `jsonEncode(_controller.document.toDelta().toJson())` → `ManuscriptBinderProvider.updateContent` |
| **Read richTextJson** | `ManuscriptEditor._loadContent` | `Document.fromJson(ops)` |
| **Read richTextJson** | `ManuscriptReferenceService.extractReferencesFromDocument` | Scans Delta ops for `ref:` link attrs |
| **Read richTextJson** | `ManuscriptBinderProvider.searchDocuments` | Plain `contains` on raw JSON string |
| **Write ref: attribute** | `ReferenceAutocompleteController._insertReference` | `_quillController.formatText(atIndex, len, LinkAttribute(target.encode()))` |
| **Strip ref: attribute** | `FindReplaceDialog._performReplace` / `_replaceAll` | `replaceText(..., null)` strips all attributes |
| **Count words from richTextJson** | `ManuscriptBinderService._countWords` | JSON-regex — **not plain-text count** |
| **Count words from richTextJson** | `DatabaseManager._countWords` (V2→V3 migration) | Same JSON-regex |
| **Count words live** | `ManuscriptEditor._updateWordCount` | `toPlainText().trim().split(RegExp(r'\s+'))` — plain-text |
