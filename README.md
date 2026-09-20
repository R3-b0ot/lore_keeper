<div align="center">
  <h1>Lore Keeper</h1>
  <p><strong>A comprehensive creative writing and world-building platform built with Flutter.</strong></p>

  [![Flutter Version](https://img.shields.io/badge/Flutter-3.9.2+-blue.svg)](https://flutter.dev)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
</div>

---

## 📖 Overview

**Lore Keeper** is a specialized desktop and mobile application designed for authors, world-builders, and storytellers. It consolidates rich manuscript text editing, complex character linking, and expansive world-building modules (such as Magic, Calendars, Timelines, and Species) into a single, cohesive offline-first platform.

### ✨ Primary Features
- **Manuscript Editor:** A powerful rich-text editor (powered by `flutter_quill`) with integrated grammar checking via LanguageTool, in-line entity @mentions, and backlink tracking.
- **World-Building Modules:** Detailed property tracking for Characters, Timelines, Magic Systems, Calendars, and Species. Locations, Languages, Items, Cultures, and other domains are reserved placeholder tabs.
- **Dynamic Linking:** Interconnect your lore with intelligent relationship mapping and a manuscript reference engine.
- **Offline First:** Fast and secure local storage handled by Hive databases.

---

## 📑 Table of Contents

- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Getting Started](#-getting-started)
- [Usage](#-usage)
- [Core Architecture & Modules](#-core-architecture--modules)
- [Testing](#-testing)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🏗️ Architecture & Tech Stack

Lore Keeper uses a pragmatic layered architecture. Data flows through clearly separated layers, and generated/persistent code is kept separate from UI concerns.

### Technology Stack
- **Framework:** Flutter (Dart)
- **Local Database:** [Hive](https://pub.dev/packages/hive) (Lightweight and incredibly fast NoSQL database)
- **State Management:** `provider` (`ChangeNotifier` providers; a `ProviderScope` wrapper from `flutter_riverpod` is present for future migration)
- **Rich Text Editing:** `flutter_quill` and `flutter_quill_extensions`
- **NLP / Grammar:** `language_tool`

### Directory Structure
```text
lib/
├── models/             # Hive entities (e.g. Project, Chapter, ManuscriptDocument,
│                       #   Character, MagicSystem, CalendarSystem) + generated .g.dart adapters
├── database/           # Hive box management, migrations, schema metadata,
│                       #   reference engine, AI provider backends
├── services/           # Business logic (manuscript binder, references, history, collection)
├── providers/          # ChangeNotifier state providers (Provider package)
├── modules/            # Feature modules: manuscript, character, magic, calendar, timeline, species
├── widgets/            # Reusable + module-specific UI (project_editor/, project_book/,
│                       #   dashboard/, manuscript*, magic*, calendar*, species*)
├── screens/            # Top-level UI containers (dashboard, ProjectEditorScreen, trait editor)
├── settings/           # Settings app, panes, and widgets
├── core/theme/         # Theming system: ThemeBootstrap, ThemeRegistry, theme packs, tokens
├── theme/              # Legacy AppTheme color/theme builder (live color source via MinimalThemePack)
├── utils/              # Helpers, icon maps, debug logging
└── main.dart           # Application entry point
```

> Data flow: **models → database → services → providers → modules/widgets → screens**.

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK:** Version 3.9.2 or higher
- **Dart SDK:** Included with Flutter
- **Platform Toolchains:** Depending on your target (e.g., Visual Studio for Windows, Xcode for macOS/iOS, Android Studio for Android)

### Installation
1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/lore_keeper.git
   cd lore_keeper
   ```

2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

3. **Launch the application:**
   ```bash
   flutter run -d windows # Or your preferred development target
   ```

> ⚠️ **Do not run `dart run build_runner`.** Hive adapters (`.g.dart` files) are **committed** to the repository. Running build_runner deletes them and writes no output; restore with `git restore .` if this ever happens.

---

## 💻 Usage

When you open Lore Keeper, you start at the **Main Screen / Project Selection**.

1. **Create a Project:** Click the "+" button in the project list to create a new story universe.
2. **Access Modules:** The left-hand collapsible sidebar features your primary tabs—starting with an **Overview**, then **Manuscript**, **Characters**, **World Building**, and **Lore Map**.
3. **Write & Build:** Use the Manuscript tab to draft your chapters. Switch to the **Characters**, **Magic**, **Timelines**, **Calendars**, or **Species** tabs to define your lore.
4. **Link Entities:** Type `@` in the editor to mention characters, species, timeline events, or manuscript documents — mentions are tracked as backlinks in the reference engine.
5. **Grammar Check:** The editor calls LanguageTool for grammar suggestions (opt-in per app settings).

### Example: Running static analysis
Always check for hints or lint warnings before committing!
```bash
flutter analyze
flutter format .
```

---

## 🧩 Core Architecture & Modules

### Modularity
The application is organized around self-contained `Modules`. The `ProjectEditorScreen` routes to specific panes depending on the selected active module index. World Building consolidates its lore domains (Magic, Timelines, Calendars, Species) as internal tabs.

1. **ManuscriptModule:** Handles text entry, grammar debouncing (`_grammarDebounce`), word count, and the @mention reference toolbar.
2. **CharacterModule:** Encapsulates the UI and state for individual persona tracking, plus a trait/relationship editor.
3. **Calendar / Timeline / Magic / Species:** Dynamically rendered modules supporting expandable schema properties.
4. **Lore Map:** Currently a stub (`lore_map_stub.dart`); the real map editor module is not yet wired in.

### State & Context Lifecycles
Lore Keeper heavily utilizes `ChangeNotifier` and Flutter's widget lifecycle hooks. Operations ensure that state mutation (`setState`) always honors widget mount boundaries, reducing defunct assertion errors during highly rapid view transitions.

---

## 🧪 Testing

The test suite is located in `test/`, organized by layer (`test/database/`, `test/services/`, `test/utils/`, `test/widgets/`), with a focus on the manuscript pipeline, database migrations, and the reference engine.

To execute the test suite:
```bash
flutter test
```
To run testing with coverage:
```bash
flutter test --coverage
```

*(Note: In-memory Hive databases are used to mock storage during module testing.)*

---

## 🤝 Contributing

We welcome contributions! Please adhere to the following workflow:

1. **Branching Strategy:** Create a separate branch prefixed with `feature/`, `bugfix/`, or `refactor/`.
2. **Code Guidelines:** Follow the project's layered-architecture rules. Keep data access in `database`/`services`, state in `providers`, and UI in `widgets`/`screens`. Always favor composition over inheritance and `StatelessWidget` over `StatefulWidget` where possible.
3. **Pre-Commit Checks:** Ensure `flutter analyze` returns cleanly with 0 issues.
4. **PR Process:** Submit a descriptive pull request summarizing your work and verifying tests pass.

---

## 📜 License

[Insert License here - e.g., MIT License]