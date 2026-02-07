# 🚀 Lore Keeper: Master Flutter Development Guidelines

## 🛠️ Core Operational Protocol

### Truth via Documentation (Context7)

**ZERO HALLUCINATION POLICY**: Before suggesting code for any third-party package (Riverpod, BLoC, Freezed, etc.), you MUST use the context7 MCP tool to fetch the latest documentation. If unsure of API changes, fetch README from pub.dev or GitHub via MCP.

### Terminal & Environment Mastery (Dart-MCP)

**SELF-CORRECTION MANDATE**: After completion of tasks, run `flutter analyze` via dart-mcp-server. If a single hint, warning, or lint error exists, fix it immediately before considering the task complete.

**AUTOMATION**: Do not wait for permission to manage dependencies. If a library is missing, run `flutter pub add [package]`.

**CODEGEN**: If using freezed or json_serializable, automatically run: `dart run build_runner build --delete-conflicting-outputs`

## 📋 Essential Commands

### Dependencies & Code Generation

```bash
flutter pub get                                 # Install dependencies
dart run build_runner build --delete-conflicting-outputs  # Generate Hive adapters + JSON serialization
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
flutter test                                    # Run all tests (test/ directory currently empty)
flutter test test/specific_test.dart            # Run single test file
flutter test --coverage                         # Run with coverage report
```

---

## 🏗️ Architectural Standards

### Clean Architecture Purity

**Strict 3-Layer Separation**:

- **Data**: Repositories, Data Sources (Local/Remote), and DTOs
- **Domain**: Entities, Business Logic, and Use Cases (Pure Dart)
- **Presentation**: Widgets, State Management (Providers/BLoCs), and UI Logic

### Layer Structure (Strict Enforcement)

```
lib/
├── data/
│   ├── repositories/     # Data repositories
│   ├── models/          # Data models with Hive integration
│   └── datasources/     # Local/Remote data sources
├── domain/
│   ├── entities/        # Business entities
│   ├── usecases/        # Business use cases
│   └── repositories/    # Repository interfaces
├── presentation/
│   ├── providers/       # State management
│   ├── screens/         # UI screens
│   ├── widgets/         # Reusable UI components  
│   └── theme/           # Theming system
└── shared/              # Shared utilities and constants
```

### State Management Philosophy

**Hooks over Statefulness**: Prefer flutter_hooks to reduce widget lifecycle boilerplate.

**Stateless by Default**: Use StatelessWidget with a state management wrapper (Provider) instead of StatefulWidget unless handling local animations or focus nodes.

### Data Layer Rules

- All models must extend `HiveObject`
- Use `@HiveType()` and `@HiveField()` annotations
- Run `dart run build_runner build` after model changes
- Repositories handle data access, never UI widgets
- Inject dependencies via constructor, never access directly in UI

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
- **Provider widgets**: Suffix with `Provider` (`ThemeProvider`)

### Type Safety Requirements

- Use proper type annotations for all public APIs
- Prefer non-nullable types with default values
- Use `late` only for Hive model fields initialized by adapters
- Avoid `dynamic` except for Hive keys (int/String)
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

### Test Structure (Currently Empty - Must Implement)

```
test/
├── unit/
│   ├── services/      # Service layer tests
│   └── providers/     # Provider tests  
├── widget/            # Widget tests
├── integration/       # Integration tests
└── test_utils/        # Test utilities
```

### Testing Requirements

- **Unit tests**: All services and providers must have 80%+ coverage
- **Widget tests**: Test all custom widgets with golden checks
- **Integration tests**: Test critical user flows
- Use `mockito` for mocking dependencies
- Test Hive operations with in-memory databases

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
- Extend `AppThemeData` for custom theme properties
- Test both light and dark themes
- Use `GoogleFonts` consistently with theme integration

---

## 🔧 Development Workflow

### Pre-Commit Checklist

1. `flutter analyze` returns clean (0 issues)
2. `flutter format .` applied to all changed files  
3. Code generation run if models changed
4. All tests pass (`flutter test`)
5. Manual test on target platforms

### Code Generation Protocol

After any changes to:

- Model fields → Run `dart run build_runner build`
- JSON serialization → Run `dart run build_runner build`  
- Hive adapters → Run `dart run build_runner build`

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
- Riverpod providers mixed with Provider
- `print()` statements (use proper logging)
- Hard-coded strings (extract to constants)

### ALWAYS Do

- Run analysis before commits
- Handle Hive operation errors
- Use dependency injection for services
- Document public APIs with `///` explaining "Why," not just "What."
- Test critical user flows

---

## 🎯 Project-Specific Context

### Domain: Creative Writing Application

- **Core Entities**: Projects, Chapters, Characters, Maps, Links
- **Key Features**: Rich text editing, relationship management, world-building
- **Storage**: Local Hive database with file export/import

### Current Technical Debt

- 13 analyzer warnings (mostly dead code - remove SVG optimization files)
- Empty test suite (implement full testing coverage)
- Mixed state management (consolidate on Provider pattern)
- Missing documentation on public APIs

### Priority Focus Areas

1. **Testing Implementation**: Start with service layer unit tests
2. **Code Quality**: Resolve analyzer warnings
3. **State Management**: Standardize on Provider pattern
4. **Documentation**: Add API docs for public methods
