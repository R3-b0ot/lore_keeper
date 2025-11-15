// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// THIS WIDGET IS DEPRECATED and its functionality has been merged into
/// `SettingsDialog`. It is kept temporarily to prevent breaking changes.
/// Please update all usages to `SettingsDialog(project: null, ...)` and
/// then delete this file.
class GlobalSettingsDialog extends StatefulWidget {
  const GlobalSettingsDialog({super.key});

  @override
  State<GlobalSettingsDialog> createState() => _GlobalSettingsDialogState();
}

class _GlobalSettingsDialogState extends State<GlobalSettingsDialog> {
  @override
  Widget build(BuildContext context) {
    // Return an empty container or a placeholder.
    // This should be replaced with the new SettingsDialog.
    return const SizedBox.shrink();
  }
}
