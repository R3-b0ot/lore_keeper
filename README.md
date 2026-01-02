# Lore Keeper

**Lore Keeper** is a comprehensive desktop application designed for writers and world-builders to create, manage, and visualize their fictional worlds. From detailed character profiles to intricate plotlines and manuscript writing, Lore Keeper provides the tools you need to bring your stories to life.

Built with Flutter, it is designed to be a cross-platform tool for Windows and Linux.

## Table of Contents

- [Implemented Features](#implemented-features)
  - [Core](#core)
  - [Manuscript Module](#manuscript-module)
  - [Character Module](#character-module)
  - [User Experience](#user-experience)
  - [Map Module](#map-module)
- [Features In Progress / Planned](#features-in-progress--planned)

---

## Implemented Features

### Core

*   **Project-Based Organization**: All your data—characters, manuscripts, etc.—is organized into distinct projects.
*   **Local First Storage**: Utilizes Hive for fast and reliable local database storage, ensuring your data is always available offline.
*   **Cross-Platform Support**: Native build configurations for both **Windows** and **Linux**.
*   **Data History**: A robust history service tracks changes to key data models like Chapters, allowing for future versioning and rollback capabilities.

### Manuscript Module

*   **Rich Text Editor**: A powerful and intuitive manuscript editor built with `flutter_quill`.
*   **Automatic Saving**: Changes to your manuscript are automatically saved after a short delay, so you never lose your work.
*   **Grammar & Spell Checking**: Integrated with `languagetool.org` to provide real-time proofing. Detected issues can be reviewed in a dedicated dialog.
*   **Custom Dictionary**: Add unrecognized words (like fantasy names) to a project-specific dictionary to ignore them during grammar checks.
*   **Structured Manuscript**: Organize your writing into **Sections** and **Chapters**.
*   **Front Matter Support**: Special handling for front matter pages, including:
    -   **Auto-Generated Index**: An index/table of contents page is automatically generated based on your sections and chapters.
    -   **About the Author Template**: A pre-populated template for the author bio page.
*   **Editor Status Bar**: A helpful bottom bar displays:
    -   Live word count.
    -   Grammar issue summary and access to the proofing dialog.
    -   Zoom controls for the editor.
    -   Real-time saving status indicator.

### Character Module

*   **Relationship Chart**: A highly interactive, visual web to map out character relationships.
    -   **Interactive Canvas**: Pan and zoom across a large canvas to explore complex relationship networks.
    -   **Node-Based Visualization**: Characters are represented as nodes, with lines indicating their relationships.
    -   **Draggable Layouts**: Drag and drop character nodes to organize your chart.
    -   **Snap-to-Grid System**: A background "web" with hook points allows for clean, organized, and aesthetically pleasing layouts.
    -   **Auto-Sort Layout**: Automatically arrange nodes into a default, organized layout based on relationship types.
    -   **Layout Persistence**: Your custom chart layouts are saved per character, so your organization is never lost.
    -   **Relationship Management**: Easily add new relationships (Parent, Child, Spouse, Rival, etc.) and delete existing ones directly from the chart.
    -   **Chart Navigation**: Click on any connected character to make them the new center of the chart, with full navigation history (back button).
*   **Character Iterations**: Support for tracking different versions or states of a character across a timeline.
*   **Character Traits**: A comprehensive, pre-defined list of over 500 categorized traits (Positive, Neutral, Negative) that can be assigned to characters.

### User Experience

*   **Keyboard-Aware Dialogs**: Custom dialogs that respond to `Enter` (confirm) and `Escape` (cancel) for faster desktop interaction.

### Map Module

*   **Grid-Based Map Editor**: A basic map editor with ocean base, grid, and objects layers for creating fantasy maps.
*   **Editing Tools**: Includes tools for select, brush, stamp, line, shape, text, and note to customize maps.
*   **Biome System**: Color-based rendering for different biomes to visualize terrain types.

---

## Features Currently in Development

These features have UI components implemented but are not yet fully functional.

*   **AI Writing Tools**: AI-powered assistance for writing improvement.
    -   **Grammar Check**: Automated grammar and style checking using AI.
    -   **Improve Language**: Suggestions to enhance language quality.
    -   **Improve Writing**: Overall writing improvement recommendations.
*   **Character Filter Functionality**: Ability to filter and search characters in the character list pane.

---

## Features In Progress / Planned

This is a list of modules and features that are either under active development or planned for future releases, based on the current codebase structure.

*   **Map Module Enhancements**:
    -   **Land Layers**: Add elevation layer for height mapping, biome layer for terrain types, terrain layer for natural features, and settlements layer for man-made elements.
    -   **Enhanced Brush Tool**: Implement biome brush functionality, add brush size and opacity controls, support different brush shapes, and add brush presets for common biomes.
    -   **Enhanced Stamp Tool**: Add stamps for towns, mountains, castles/fortresses, forests, with support for rotation and scaling.
    -   **Texture System**: Add texture loading system, implement distinct textures for man-made vs natural elements, add texture blending for smooth transitions, and support user-provided texture files.
    -   **Layer Management**: Update layer panel with new layer types, add layer blending modes, implement layer ordering and visibility, and add layer export/import.
    -   **UI Improvements**: Add tool settings panel, color picker for custom biomes, stamp library browser, and undo/redo for brush and stamp operations.
*   **World Module**: A dedicated section for world-building elements.
    -   Locations
    -   Items
    -   Events
    -   Magic Systems / Technologies
*   **Plotting Module**: Tools for outlining and managing plot points and timelines.
*   **Full Link/Relationship Management**:
    -   A dedicated UI for managing all links between different entity types (e.g., linking a Character to an Event, or an Item to a Location).
    -   Support for inverse relationships (e.g., creating a "Parent" link automatically creates a "Child" link on the other character).
*   **Enhanced History/Versioning UI**: A user interface to view and revert to previous versions of documents and character data.
*   **Data Export**: Functionality to export project data to common formats (e.g., JSON, Markdown).
*   **Theming**: Light and Dark mode support.
