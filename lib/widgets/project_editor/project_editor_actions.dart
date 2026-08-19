import 'package:flutter/material.dart';

/// Encapsulates module-specific actions for the project editor UI.
/// New indices: 0=Overview, 1=Manuscripts, 2=Characters, 3=World Building, 4=Lore Map
class ProjectEditorActions {
  final int moduleIndex;
  final VoidCallback onShowSelectionDialog;
  final VoidCallback onToggleHistoryPanel;
  final VoidCallback onOpenFindReplace;
  final VoidCallback onCreateChapter;
  final VoidCallback onCreateCharacter;
  final VoidCallback onOpenSettings;

  const ProjectEditorActions({
    required this.moduleIndex,
    required this.onShowSelectionDialog,
    required this.onToggleHistoryPanel,
    required this.onOpenFindReplace,
    required this.onCreateChapter,
    required this.onCreateCharacter,
    required this.onOpenSettings,
  });

  bool get supportsHistory => moduleIndex == 1 || moduleIndex == 2;

  bool get showFindReplace => moduleIndex == 1;

  String get selectionLabel =>
      moduleIndex == 1 ? 'Select Chapter' : 'Select Character';

  String get addLabel => moduleIndex == 1
      ? 'Add New Chapter'
      : moduleIndex == 2
      ? 'Add New Character'
      : 'Add';

  VoidCallback get onFloatingAction {
    if (moduleIndex == 1) return onCreateChapter;
    if (moduleIndex == 2) return onCreateCharacter;
    return () {};
  }
}
