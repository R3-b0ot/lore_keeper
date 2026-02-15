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
  final bool isMobile;
  final bool isFindReplaceAvailable;

  const SpecificFunctionsBar({
    super.key,
    required this.onHistoryPressed,
    required this.isHistoryVisible,
    required this.showHistoryButton,
    this.onSettingsPressed,
    this.onFindReplacePressed,
    required this.isMobile,
    required this.isFindReplaceAvailable,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.ellipsisVertical),
            onSelected: (value) {
              switch (value) {
                case 'history':
                  onHistoryPressed();
                  break;
                case 'find_replace':
                  onFindReplacePressed?.call();
                  break;
                case 'settings':
                  onSettingsPressed?.call();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (showHistoryButton)
                PopupMenuItem<String>(
                  value: 'history',
                  child: Text(
                    isHistoryVisible ? 'Hide History' : 'Show History',
                  ),
                ),
              if (onFindReplacePressed != null)
                const PopupMenuItem<String>(
                  value: 'find_replace',
                  child: Text('Find and Replace'),
                ),
              const PopupMenuItem<String>(
                value: 'bookmarks',
                child: Text('Bookmarks'),
              ),
              const PopupMenuItem<String>(
                value: 'comments',
                child: Text('Comments'),
              ),
              const PopupMenuItem<String>(
                value: 'add_block',
                child: Text('Add Block'),
              ),
              const PopupMenuItem<String>(
                value: 'download',
                child: Text('Download'),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      );
    }

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
