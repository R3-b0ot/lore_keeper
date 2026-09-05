/// Column 2 list pane for the Manuscript module.
///
/// Hosts the four Manuscript views — Binder, Corkboard, Outliner, Collections —
/// with a view-switcher header, mirroring how `ChapterListPane` / `CharacterListPane`
/// serve their respective modules in the shell's Column 2.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lore_keeper/widgets/manuscript_binder.dart';
import 'package:lore_keeper/widgets/manuscript_corkboard.dart';
import 'package:lore_keeper/widgets/manuscript_outliner.dart';
import 'package:lore_keeper/widgets/manuscript_collections.dart';

enum ManuscriptListViewMode { binder, corkboard, outliner, collections }

/// The Manuscript List Pane that lives in Column 2 of the Project Editor.
///
/// A shared [ManuscriptBinderProvider] is provided by the shell so that
/// both the list pane and the editor stay in sync.
class ManuscriptListPane extends StatefulWidget {
  final ManuscriptBinderProvider provider;
  final String selectedDocumentId;
  final ValueChanged<String> onDocumentSelected;

  const ManuscriptListPane({
    super.key,
    required this.provider,
    required this.selectedDocumentId,
    required this.onDocumentSelected,
  });

  @override
  State<ManuscriptListPane> createState() => _ManuscriptListPaneState();
}

class _ManuscriptListPaneState extends State<ManuscriptListPane> {
  ManuscriptListViewMode _mode = ManuscriptListViewMode.binder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        // ── View Switcher Header ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              _ViewToggleButton(
                icon: LucideIcons.listTree,
                tooltip: 'Binder',
                isSelected: _mode == ManuscriptListViewMode.binder,
                onTap: () =>
                    setState(() => _mode = ManuscriptListViewMode.binder),
              ),
              _ViewToggleButton(
                icon: LucideIcons.layoutGrid,
                tooltip: 'Corkboard',
                isSelected: _mode == ManuscriptListViewMode.corkboard,
                onTap: () =>
                    setState(() => _mode = ManuscriptListViewMode.corkboard),
              ),
              _ViewToggleButton(
                icon: LucideIcons.list,
                tooltip: 'Outliner',
                isSelected: _mode == ManuscriptListViewMode.outliner,
                onTap: () =>
                    setState(() => _mode = ManuscriptListViewMode.outliner),
              ),
              _ViewToggleButton(
                icon: LucideIcons.folderSearch,
                tooltip: 'Collections',
                isSelected: _mode == ManuscriptListViewMode.collections,
                onTap: () =>
                    setState(() => _mode = ManuscriptListViewMode.collections),
              ),
              const Spacer(),
              Text(
                'Manuscript',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // ── View Content ─────────────────────────────────────────────────
        Expanded(child: _buildView()),
      ],
    );
  }

  Widget _buildView() {
    final provider = widget.provider;

    if (!provider.isInitialized || provider.manuscriptRoot == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (_mode) {
      case ManuscriptListViewMode.binder:
        return ManuscriptBinder(
          provider: provider,
          selectedDocumentId: widget.selectedDocumentId,
          onDocumentSelected: widget.onDocumentSelected,
        );
      case ManuscriptListViewMode.corkboard:
        return ManuscriptCorkboard(
          provider: provider,
          containerDocumentId: widget.selectedDocumentId.isNotEmpty
              ? widget.selectedDocumentId
              : provider.manuscriptRoot!.id,
          onDocumentSelected: widget.onDocumentSelected,
        );
      case ManuscriptListViewMode.outliner:
        return ManuscriptOutliner(
          provider: provider,
          containerDocumentId: widget.selectedDocumentId.isNotEmpty
              ? widget.selectedDocumentId
              : provider.manuscriptRoot!.id,
          onDocumentSelected: widget.onDocumentSelected,
        );
      case ManuscriptListViewMode.collections:
        return ManuscriptCollections(
          provider: provider,
          onDocumentSelected: widget.onDocumentSelected,
        );
    }
  }
}

/// A compact icon-only toggle button for the view-switcher header.
class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected
                ? cs.onPrimaryContainer
                : cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
