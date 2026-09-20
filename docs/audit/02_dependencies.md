# Pass 2 — Dependencies & Platform Surface

> Source: `pubspec.yaml`, `dart pub outdated`, README. Date: 2026-09-20.

---

## 2.1 Direct dependencies (`pubspec.yaml`, as analyzed)

```yaml
environment:
  sdk: ^3.x (Dart 3.x / Flutter 3.9.2+)

dependencies:
  flutter
  flutter_localizations            # presumably; l10n setup
  provider                         # live state layer (primary)
  flutter_riverpod                 # ONLY main.dart wraps tree in ProviderScope (1 import site)
  hive                            # storage
  hive_flutter
  path_provider
  uuid
  intl
  flutter_quill ^11.4.0            # rich text editor
  flutter_quill_extensions ^11.0.0 # image/video embeds
  language_tool ^2.2.0            # LanguageTool grammar API
  file_picker
  image_picker / native_image_cropper
  flutter_svg
  lucide_icons_flutter
  xml
  json_annotation
  cupertino_icons                  # UNUSED in lib/ (0 import sites)

dev_dependencies:
  flutter_test
  flutter_lints
  build_runner
  json_serializable
  mockito
```

Exact versions measured via `dart pub outdated` below.

## 2.2 `dart pub outdated` (resolved, versions as of audit)

| Package | Resolved | Latest | Kind of stale |
|---|---|---|---|
| flutter_riverpod | 3.0.3 | 3.4.3 | patch-level, minor gap |
| provider | (locked) | — | mature |
| flutter_quill | 11.4.x (resolved per lock; pubspec allows ^11.5.x?) | 11.6.0 | minor |
| flutter_quill_extensions | 11.0.x | 11.6.x | minor |
| file_picker | 8.x | **13.x** | **major gap (8 → 13)** |
| language_tool | 2.2.0 | — | — |
| json_annotation | 4.9.0 | 4.12.0 | patch |
| flutter_svg | 2.2.x | 2.3.x | patch |
| lucide_icons_flutter | 3.1.15 | 3.1.20 | patch |
| native_image_cropper | 0.7.0 | 0.8.0 | minor |
| uuid | 4.5.2 | 4.6.0 | patch |
| xml | 6.6.1 | **7.x** | c#major |
| build_runner (dev) | 2.15.1 | 2.15.1+ | current |
| json_serializable (dev) | 6.11.4 | current | current |
| mockito (dev) | 5.6.4 | current | current |

**Noteworthy:**

1. **`cupertino_icons` is declared but not imported anywhere in `lib/`** — removable.
2. **`flutter_riverpod` has 1 usage in the whole codebase** (`main.dart:4,58`, `ProviderScope` wrapper around `MultiProvider`). The app is otherwise 100% `provider`. This is the "Mixed state management" debt item, currently *harmless* (no Riverpod providers in code) but confusing.
3. **`file_picker` major version gap (8 → 13)** — scheduled upgrade work; `flutter_quill` also trades against `file_picker` (Quill's image picker).
4. No CI config observed at repo root.

## 2.3 Platform surface

Platform folders present: `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`. Flutter desktop is the primary target (per README feature set — keyboard-oriented editor, desktop-first project editor layouts, drag-and-drop corkboard).

Per-`README`/`AGENTS`, build commands for all six targets exist; only `flutter test` and `flutter run` were exercised in this audit.

## 2.4 `analysis_options.yaml`

Extends `flutter_lints`. Analyzer is clean (`flutter analyze` → "No issues found"). Rule set is default flutter_lints — **no strict custom rules** (e.g. no `avoid_dynamic_calls` / `public_member_api_docs`), so the AGENTS.md "documentation" standard is not machine-enforced.

## 2.5 Deps findings for Pass 9

- Remove `cupertino_icons` (unused).
- Decide Riverpod-vs-Provider once: either delete the `flutter_riverpod` import + `ProviderScope` in `main.dart`, or migrate fully (docs say "consolidate on Provider").
- Schedule: `file_picker 8→13`, `xml 6→7`, `flutter_quill_extensions 11.x → 11.6.x` as deliberate, tested upgrades.