import 'package:flutter/material.dart';

/// Encapsulates module-specific view resolution for the project editor.
class ProjectEditorModuleResolution {
  final Widget secondColumn;
  final Widget moduleContent;
  final bool showSecondColumnDivider;

  const ProjectEditorModuleResolution({
    required this.secondColumn,
    required this.moduleContent,
    required this.showSecondColumnDivider,
  });
}
