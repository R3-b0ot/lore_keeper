/// Overlay widget for the @mention autocomplete dropdown.
///
/// Displays candidate results with keyboard navigation indicators,
/// mouse/tap selection, and candidate highlighting.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/services/reference_engine.dart';
import 'package:lore_keeper/widgets/reference_autocomplete_controller.dart';

/// A positioned dropdown overlay showing autocomplete candidates.
///
/// Reads state from [controller] and calls [controller.selectCandidate]
/// on tap/Enter. Highlights [controller.selectedIndex] for keyboard
/// navigation feedback.
class ReferenceAutocompleteOverlay extends StatefulWidget {
  /// The controller providing candidates and selection state.
  final ReferenceAutocompleteController controller;

  /// Creates the autocomplete overlay.
  const ReferenceAutocompleteOverlay({
    super.key,
    required this.controller,
  });

  @override
  State<ReferenceAutocompleteOverlay> createState() =>
      _ReferenceAutocompleteOverlayState();
}

class _ReferenceAutocompleteOverlayState
    extends State<ReferenceAutocompleteOverlay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final candidates = controller.candidates;

    if (!controller.isActive || candidates.isEmpty) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final headerHeight = 32.0;
    final maxVisible = candidates.length.clamp(1, 8);
    final itemHeight = 40.0;
    final maxHeight = headerHeight + (maxVisible * itemHeight);

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        minWidth: 220,
        maxWidth: 320,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.atSign, size: 12, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    controller.query.isEmpty
                        ? 'Characters'
                        : '"${controller.query}"',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${candidates.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),

          // Candidates list
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: candidates.length,
              itemExtent: itemHeight,
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                final isSelected = index == controller.selectedIndex;

                return _CandidateTile(
                  candidate: candidate,
                  isSelected: isSelected,
                  onTap: () => controller.selectCandidate(index),
                  onHover: () {
                    // Optionally update selection on hover.
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A single candidate row in the autocomplete dropdown.
class _CandidateTile extends StatelessWidget {
  final ReferenceCandidate candidate;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  const _CandidateTile({
    required this.candidate,
    required this.isSelected,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final matchedIsDifferent =
        candidate.matchedName.toLowerCase() != candidate.displayName.toLowerCase();

    return MouseRegion(
      onEnter: (_) => onHover(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: isSelected
              ? cs.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          child: Row(
            children: [
              // Avatar circle
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.user,
                  size: 14,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 10),

              // Name and matched alias
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (matchedIsDifferent)
                      Text(
                        'aka ${candidate.matchedName}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Match type indicator
              Icon(
                _matchTypeIcon(candidate.matchType),
                size: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _matchTypeIcon(MatchType type) {
    switch (type) {
      case MatchType.exactName:
      case MatchType.exactAlias:
        return LucideIcons.circleCheck;
      case MatchType.prefixName:
      case MatchType.prefixAlias:
        return LucideIcons.arrowRight;
      case MatchType.substringName:
      case MatchType.substringAlias:
        return LucideIcons.search;
    }
  }
}
