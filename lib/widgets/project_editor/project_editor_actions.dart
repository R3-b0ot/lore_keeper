import 'package:flutter/material.dart';

/// Encapsulates module-specific actions for the project editor UI.
class ProjectEditorActions {
  final int moduleIndex;
  final bool isHistoryVisible;
  final VoidCallback onShowSelectionDialog;
  final VoidCallback onToggleHistoryPanel;
  final VoidCallback onOpenFindReplace;
  final VoidCallback onCreateChapter;
  final VoidCallback onCreateCharacter;
  final VoidCallback onOpenSettings;

  const ProjectEditorActions({
    required this.moduleIndex,
    required this.isHistoryVisible,
    required this.onShowSelectionDialog,
    required this.onToggleHistoryPanel,
    required this.onOpenFindReplace,
    required this.onCreateChapter,
    required this.onCreateCharacter,
    required this.onOpenSettings,
  });

  bool get supportsHistory => moduleIndex == 0 || moduleIndex == 1;

  bool get showFindReplace => moduleIndex == 0;

  String get selectionLabel =>
      moduleIndex == 0 ? 'Select Chapter' : 'Select Character';

  String get addLabel => moduleIndex == 0
      ? 'Add New Chapter'
      : moduleIndex == 1
      ? 'Add New Character'
      : 'Add';

  VoidCallback get onFloatingAction {
    if (moduleIndex == 0) return onCreateChapter;
    if (moduleIndex == 1) return onCreateCharacter;
    return () {};
  }
}
