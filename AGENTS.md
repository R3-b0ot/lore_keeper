# 🚀 Lore Keeper: Master Flutter Development Guidelines

## 🛠️ Core Operational Protocol

### Truth via Documentation (Context7)

**ZERO HALLUCINATION POLICY**: Before suggesting code for any third-party package (Riverpod, BLoC, Freezed, etc.), you MUST use the context7 MCP tool to fetch the latest documentation. If unsure of API changes, fetch README from pub.dev or GitHub via MCP.

### Terminal & Environment Mastery (Dart-MCP)

**SELF-CORRECTION MANDATE**: After completion of tasks, run `flutter analyze` via dart-mcp-server. If a single hint, warning, or lint error exists, fix it immediately before considering the task complete.

**AUTOMATION**: Do not wait for permission to manage dependencies. If a library is missing, run `flutter pub add [package]`.

### ⚠️ Code Generation Warning

**NEVER run `dart run build_runner`.** Hive adapters (`.g.dart` files) are **committed** to the repository and must remain committed. Running build_runner deletes them and writes no output, breaking the build and the tests. If a model annotated with `@HiveType`/`@HiveField` is changed, update the corresponding `.g.dart` adapter **by hand** to match, or restore any accidentally-deleted files with `git restore .`.

## 📋 Essential Commands

### Dependencies

```bash
flutter pub get                                 # Install dependencies (only command needed)
```

### Development & Analysis

```bash
flutter analyze                                 # Static analysis (MUST return 0 issues)
flutter format .                                # Format all Dart files
flutter run                                     # Run the application
```

### Build Commands

```bash
flutter build apk                              # Android build
flutter build ios                              # iOS build
flutter build web                              # Web build
flutter build windows                          # Windows desktop
flutter build macos                            # macOS build
```

### Testing

```bash
flutter test                                    # Run all tests (377 tests, 25 files)
flutter test test/specific_test.dart            # Run single test file
flutter test --coverage                         # Run with coverage report
```

---

## 🏗️ Architectural Standards

### Layered Architecture (as actually implemented)

The project uses a practical layered structure, **not** a strict Clean Architecture with `data/domain/presentation` folders. Data flows through clearly separated layers:

```
lib/
├── models/             # Hive entities (Project, Chapter, ManuscriptDocument, Character, ...) + .g.dart adapters
├── database/           # Hive box management, migrations, schema metadata, reference engine, AI providers
├── services/           # Business logic (manuscript binder, references, history, collections)
├── providers/          # ChangeNotifier state providers (Provider package)
├── modules/            # Feature modules: manuscript, character, magic, calendar, timeline, species
├── widgets/            # Reusable + module-specific UI (project_editor/, project_book/, manuscript*, ...)
├── screens/            # Top-level UI containers (dashboard, ProjectEditorScreen, trait editor)
├── settings/           # Settings app, panes, and widgets
├── core/theme/         # Theming: ThemeBootstrap, ThemeRegistry, theme packs, tokens
├── theme/              # Legacy AppTheme color/theme builder (live color source via MinimalThemePack)
└── utils/              # Helpers, icon maps, debug logging
```

Data flow: **models → database → services → providers → modules/widgets → screens**.

### Layer Rules

- **Data access** lives in `database/` (boxes, migrations, adapters) and `services/` (business logic). Widgets must not open Hive boxes directly.
- **State** lives in `providers/` as `ChangeNotifier` subclasses, injected via constructor dependencies.
- **Models** are Hive entities annotated with `@HiveType()` / `@HiveField()`; their `.g.dart` adapters are committed (see the build_runner warning above).
- **UI** lives in `widgets/` (reusable + module-specific) and `screens/` (top-level containers).
- Do **not** introduce new `data/`, `domain/`, or `presentation/` directories.

### State Management Philosophy

**Stateless by Default**: Use StatelessWidget with a Provider (ChangeNotifierProvider) instead of StatefulWidget unless handling local animations or focus nodes.

**Provider over Riverpod for now**: The app runs on the `provider` package. `main.dart` wraps the widget tree in `riverpod.ProviderScope` (kept for an upcoming rewrite) but **no Riverpod providers exist in the codebase** — do not add Riverpod providers.

---

## ⚡ Performance & Rendering

### Build Method Sanctity

The build() method is for UI declaration ONLY. No heavy logic, no list filtering, and no object instantiation.

### Const Obsession

Use const constructors everywhere possible to reduce garbage collection pressure.

### Repaint Boundaries

Use RepaintBoundary for complex animations or static parts of a heavy UI to isolate the paint engine.

### Sliver Supremacy

Use CustomScrollView and Slivers for all lists to ensure maximum scroll performance and efficiency.

---

## 📝 Code Style Standards

### Dart 3.x Features

Use Records for multiple returns, Patterns/Destructuring for JSON, and Extension Types for domain-specific wrappers.

### Import Organization

```dart
// Flutter/Dart core imports
import 'package:flutter/material.dart';
import 'dart:async';

// Package imports
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

// Local imports
import '../models/chapter.dart';
import '../services/manuscript_service.dart';
```

### Naming Conventions

- **Classes**: `PascalCase` (`ChapterListProvider`, `ManuscriptService`)
- **Files**: `snake_case.dart` (`chapter_list_provider.dart`)
- **Variables**: `camelCase` (`_chapterBox`, `_isReordering`)
- **Constants**: `SCREAMING_SNAKE_CASE` (`frontMatterSectionKey`)
- **Private members**: Prefix with `_` (`_loadData()`, `_chapters`)
- **Provider widgets**: Suffix with `Provider` or `Notifier` (`ThemeProvider`, `ThemeNotifier`)

### Type Safety Requirements

- Use proper type annotations for all public APIs
- Prefer non-nullable types with default values
- Use `late` only for Hive model fields initialized by adapters
- Avoid `dynamic` except for Hive keys (int/String) and legacy adapter maps
- Always provide `///` documentation for public methods explaining "Why," not just "What."

### Error Handling Patterns

```dart
// Hive operations
try {
  final chapter = await _chapterBox.get(id);
  return chapter;
} catch (e) {
  // Log error and return fallback
  return null;
}

// Service operations
if (!_chapterBox.isOpen()) {
  throw StateError('Chapter box not initialized');
}
```

---

## 🧪 Testing Standards

### Test Structure

```
test/
├── database/           # Migration, metadata, reference engine, AI providers
├── services/           # Manuscript binder, collections, references, name matcher
├── utils/              # Calendar chronology, debug logger
└── widgets/            # Manuscript topology, project book, reference autocomplete
```

### Testing Requirements

- All new services and providers should have unit tests (target 80%+ for new code)
- Use in-memory Hive databases to mock storage during tests
- Do not delete the committed `.g.dart` files (tests depend on them)
- Run `flutter test` before every commit — the suite must stay green

---

## 🎨 UI Development Standards

### Widget Composition

- Prefer composition over inheritance
- Use `StatelessWidget` with providers when possible
- Use `StatefulWidget` only for local state (animations, controllers)
- Implement proper `dispose()` methods for resources

### Performance Rules

- Use `const` constructors everywhere possible
- Implement `RepaintBoundary` for complex animations
- Use `ListView.builder` for long lists
- Avoid heavy logic in `build()` methods

### Theme Integration

- Always use theme colors via `Theme.of(context)`
- Theme system: `ThemeBootstrap.initialize()` → `ThemeRegistry` → theme packs → legacy `AppTheme` (live color source)
- Test both light and dark themes
- The `core/theme/` controller path was removed as dead code; do not reintroduce it

---

## 🔧 Development Workflow

### Pre-Commit Checklist

1. `flutter analyze` returns clean (0 issues)
2. `flutter format .` applied to all changed files
3. All tests pass (`flutter test`)
4. Manual test on target platforms

### Dependency Management

- Add dependencies via `flutter pub add package_name`
- Check for Flutter version compatibility
- Prefer latest stable versions
- Review changelog for breaking changes

---

## ⚠️ Critical Rules

### NEVER in Production Code

- Direct `Hive.openBox()` calls in widgets
- Business logic in UI layer
- Riverpod providers (the app uses `provider`; the ProviderScope wrapper is reserved for migration)
- `print()` statements (use `debug_logger.dart`)
- Hard-coded strings (extract to constants)
- Running `dart run build_runner` (deletes committed `.g.dart` files)

### ALWAYS Do

- Run analysis before commits
- Handle Hive operation errors
- Use dependency injection for services
- Document public APIs with `///` explaining "Why," not just "What."
- Test critical user flows

---

## 🎯 Project-Specific Context

### Domain: Creative Writing Application

- **Core Entities**: Projects, ManuscriptDocuments, Chapters, Characters, ClassificationNodes (Species), Systems (Magic/Calendar), TimelineEvents, Links
- **Key Features**: Rich text editing, @mention reference engine + backlinks, relationship management, world-building
- **Storage**: Local Hive database (offline-first)

### Current Technical Debt

- Test coverage ~16% overall; state providers and screens are the least-covered layers
- Mixed state management (consolidate on Provider pattern — Riverpod scope reserved for rewrite)
- Missing documentation on public APIs
- Build_runner is disabled (deletes committed adapters); adapters must be hand-maintained

### Priority Focus Areas

1. **Code Quality**: Keep `flutter analyze` clean and `flutter test` green
2. **State Management**: Standardize on Provider pattern
3. **Documentation**: Add API docs for public methods
4. **Testing**: Extend coverage beyond the manuscript/reference pipeline