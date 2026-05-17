import 'package:flutter/widgets.dart';

/// Describes a project editor module without relying on dynamic maps.
class ProjectEditorModuleItem {
  /// User-facing module label shown in navigation.
  final String label;

  /// Icon displayed beside the module label.
  final IconData icon;

  const ProjectEditorModuleItem({required this.label, required this.icon});
}
