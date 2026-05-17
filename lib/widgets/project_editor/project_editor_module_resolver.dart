import 'package:flutter/material.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_module_item.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_module_resolution.dart';

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

  bool get supportsHistory => moduleIndex == 0 || moduleIndex == 1;
  bool get supportsSecondColumn =>
      moduleIndex == 0 ||
      moduleIndex == 1 ||
      moduleIndex == 2 ||
      moduleIndex == 4 ||
      moduleIndex == 6;

  ProjectEditorModuleResolution resolve() {
    return ProjectEditorModuleResolution(
      secondColumn: buildSecondColumn(),
      moduleContent: buildModuleContent(),
      showSecondColumnDivider: supportsSecondColumn,
    );
  }
}
