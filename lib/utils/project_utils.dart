import 'package:flutter/material.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/screens/project_editor_screen.dart';

/// Utility function to handle navigation and open the Project Editor Screen.
///
/// This function encapsulates the required navigation logic, ensuring consistency
/// and proper handling of the Project model.
///
/// Args:
///   context: The BuildContext used for navigation.
///   project: The Project object to open the editor for.
/// Returns:
///   A Future that completes when the editor screen navigation is complete.
/// Opens the project editor screen for the given project.
///
/// Returns the result passed back from the editor screen, or null if cancellation occurred.
Future<dynamic> openProject(BuildContext context, Project project) async {
  final result = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ProjectEditorScreen(project: project),
    ),
  );
  return result;
}
