import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Consolidates editor-specific actions so the main screen stays focused
/// on layout and state orchestration.
class SpecificFunctionsBar extends StatelessWidget {
  final VoidCallback onHistoryPressed;
  final bool isHistoryVisible;
  final bool showHistoryButton;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onFindReplacePressed;

  const SpecificFunctionsBar({
    super.key,
    required this.onHistoryPressed,
    required this.isHistoryVisible,
    required this.showHistoryButton,
    this.onSettingsPressed,
    this.onFindReplacePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (showHistoryButton)
          IconButton(
            icon: Icon(
              isHistoryVisible ? LucideIcons.history : LucideIcons.history,
            ),
            onPressed: onHistoryPressed,
            tooltip: isHistoryVisible ? 'Hide History' : 'Show History',
          ),
        if (onFindReplacePressed != null)
          IconButton(
            icon: const Icon(LucideIcons.replace),
            onPressed: onFindReplacePressed,
            tooltip: 'Find and Replace',
          ),
        IconButton(
          icon: const Icon(LucideIcons.bookmark),
          onPressed: null,
          tooltip: 'Bookmarks',
        ),
        IconButton(
          icon: const Icon(LucideIcons.messageSquare),
          onPressed: null,
          tooltip: 'Comments',
        ),
        IconButton(
          icon: const Icon(LucideIcons.squarePlus),
          onPressed: null,
          tooltip: 'Add Block',
        ),
        IconButton(
          icon: const Icon(LucideIcons.download),
          onPressed: null,
          tooltip: 'Download',
        ),
        IconButton(
          icon: const Icon(LucideIcons.settings),
          onPressed: onSettingsPressed,
          tooltip: 'Settings',
        ),
        const Spacer(),
        const SizedBox(height: 16),
      ],
    );
  }
}
