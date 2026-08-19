import 'package:flutter/material.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_module_item.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_module_resolution.dart';

// New indices: 0=Overview, 1=Manuscripts, 2=Characters, 3=World Building, 4=Lore Map
/// Resolves module-specific UI widgets for the project editor screen.
class ProjectEditorModuleResolver {
  final List<ProjectEditorModuleItem> moduleItems;
  final int moduleIndex;
  final Widget Function() buildSecondColumn;
  final Widget Function() buildModuleContent;

  const ProjectEditorModuleResolver({
    required this.moduleItems,
    required this.moduleIndex,
    required this.buildSecondColumn,
    required this.buildModuleContent,
  });

  String get currentModuleName => moduleItems[moduleIndex].label;

  bool get supportsHistory => moduleIndex == 1 || moduleIndex == 2;

  bool get supportsSecondColumn =>
      moduleIndex == 1 || // Manuscripts
      moduleIndex == 2 || // Characters
      moduleIndex == 3;   // World Building

  ProjectEditorModuleResolution resolve() {
    return ProjectEditorModuleResolution(
      secondColumn: buildSecondColumn(),
      moduleContent: buildModuleContent(),
      showSecondColumnDivider: supportsSecondColumn,
    );
  }
}
