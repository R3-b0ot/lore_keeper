<div align="center">
  <h1>Lore Keeper</h1>
  <p><strong>A comprehensive creative writing and world-building platform built with Flutter.</strong></p>

  [![Flutter Version](https://img.shields.io/badge/Flutter-3.9.2+-blue.svg)](https://flutter.dev)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)]()
</div>

---

## 📖 Overview

**Lore Keeper** is a specialized desktop and mobile application designed for authors, world-builders, and storytellers. It consolidates rich manuscript text editing, complex character linking, and expansive world-building modules (such as Magic, Calendars, Timelines, and Species) into a single, cohesive offline-first platform.

### ✨ Primary Features
- **Manuscript Editor:** A powerful rich-text editor (powered by `flutter_quill`) with integrated grammar checking via LanguageTool.
- **World-Building Modules:** Detailed property tracking for Characters, Timelines, Magic Systems, Calendars, and more.
- **Dynamic Linking:** Interconnect your lore with intelligent relationship mapping and history state tracking.
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

Lore Keeper enforces a **strict Clean Architecture** approach, separating concerns into three pure layers: Data, Domain, and Presentation. 

### Technology Stack
- **Framework:** Flutter (Dart)
- **Local Database:** [Hive](https://pub.dev/packages/hive) (Lightweight and incredibly fast NoSQL database)
- **State Management:** `provider` (and internally migrating to modern state management practices)
- **Rich Text Editing:** `flutter_quill` and `flutter_quill_extensions`
- **NLP / Grammar:** `language_tool`

### Directory Structure
```text
lib/
├── core/
│   └── theme/           # Theming system, color palettes & accessibility constraints
├── data/
│   ├── models/          # Hive data models & DTOs
│   └── repositories/    # Hive storage adapters and persistence logic
├── domain/
│   ├── entities/        # Business entities
│   └── usecases/        # Core business operations
├── modules/             # Module definitions mapping to specific feature panes
│   ├── manuscript_module.dart
│   ├── character_module.dart
│   ├── timeline_module.dart
│   └── ...
├── providers/           # Shared state providers that bridge Domain and Presentation
├── screens/             # Top-level UI containers (e.g. ProjectEditorScreen)
├── widgets/             # Reusable UI widgets and specific screen panels
└── main.dart            # Application entry point
```

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

3. **Run Code Generation (Mandatory):**
   This project relies on `json_serializable` and `hive_generator` for local storage synchronization. You must run build runner whenever you pull updates or modify models.
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Launch the application:**
   ```bash
   flutter run -d windows # Or your preferred development target
   ```

---

## 💻 Usage

When you open Lore Keeper, you start at the **Main Screen / Project Selection**. 

1. **Create a Project:** Click the "+" button in the project list to create a new story universe.
2. **Access Modules:** The left-hand collapsible sidebar features your primary tabs—starting with the **Manuscript**. 
3. **Write & Build:** Use the Manuscript tab to draft your chapters. Switch to the **Characters** or **Magic** modules to define your lore. 
4. **Link Entities:** By establishing entities in the character list, you can dynamically link them across your texts.

### Example: Running static analysis
Always check for hints or lint warnings before committing!
```bash
flutter analyze
flutter format .
```

---

## 🧩 Core Architecture & Modules

### Modularity
The application is organized around self-contained `Modules`. The `ProjectEditorScreen` routes to specific panes (like `CalendarListPane` and `CharacterModule`) depending on the selected active module index. 

1. **ManuscriptModule:** Handles text entry, grammar debouncing (`_grammarDebounce`), and word count (`_updateWordCount`).
2. **CharacterModule:** Encapsulates the UI and state for individual persona tracking.
3. **Calendar / Timeline / Magic:** Dynamically rendered modules supporting expandable schema properties.

### State & Context Lifecycles
Lore Keeper heavily utilizes `ChangeNotifier` and Flutter's widget lifecycle hooks. Operations ensure that state mutation (`setState`) always honors widget mount boundaries, reducing defunct assertion errors during highly rapid view transitions.

---

## 🧪 Testing

The testing suite (located in `test/`) focuses primarily on unit tests for the domain and service layers, alongside widget tests with golden checks.

To execute the test suite:
```bash
flutter test
```
To run testing with coverage:
```bash
flutter test --coverage
```

*(Note: In-memory Hive databases should be used to mock storage during module testing.)*

---

## 🤝 Contributing

We welcome contributions! Please adhere to the following workflow:

1. **Branching Strategy:** Create a separate branch prefixed with `feature/`, `bugfix/`, or `refactor/`.
2. **Code Guidelines:** Follow the project's **Clean Architecture Purity** rules. Place logic in the proper layer (`data`, `domain`, or `presentation`). Always favor composition over inheritance and `StatelessWidget` over `StatefulWidget` where possible.
3. **Code Generation:** Remember to run `build_runner` if you adjust any model annotated with `@HiveType`.
4. **Pre-Commit Checks:** Ensure `flutter analyze` returns cleanly with 0 issues.
5. **PR Process:** Submit a descriptive pull request summarizing your work and verifying tests pass.

---

## 📜 License

[Insert License here - e.g., MIT License]

---
*Generated based on codebase structure and AGENTS.md rules.*
