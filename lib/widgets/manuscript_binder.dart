// lib/widgets/manuscript_binder.dart

import 'package:flutter/material.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _ReorderableChildren extends StatelessWidget {
  final ManuscriptBinderProvider provider;
  final List<ManuscriptDocument> children;
  final String? selectedDocumentId;
  final ValueChanged<String> onDocumentSelected;
  final ValueChanged<String>? onDocumentRenamed;
  final ValueChanged<String>? onDocumentMoved;
  final int depth;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;

  const _ReorderableChildren({
    required this.provider,
    required this.children,
    required this.selectedDocumentId,
    required this.onDocumentSelected,
    this.onDocumentRenamed,
    this.onDocumentMoved,
    required this.depth,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final child = children[index];
        return _BinderNode(
          key: ValueKey(child.id),
          provider: provider,
          document: child,
          selectedDocumentId: selectedDocumentId,
          onDocumentSelected: onDocumentSelected,
          onDocumentRenamed: onDocumentRenamed,
          onDocumentMoved: onDocumentMoved,
          depth: depth,
        );
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 4,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: child,
        );
      },
    );
  }
}

class ManuscriptBinder extends StatelessWidget {
  final ManuscriptBinderProvider provider;
  final String? selectedDocumentId;
  final ValueChanged<String> onDocumentSelected;
  final ValueChanged<String>? onDocumentRenamed;
  final ValueChanged<String>? onDocumentMoved;

  const ManuscriptBinder({
    super.key,
    required this.provider,
    required this.selectedDocumentId,
    required this.onDocumentSelected,
    this.onDocumentRenamed,
    this.onDocumentMoved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgMain : AppColors.bgMainLight;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          _buildToolbar(context),
          const Divider(height: 1),
          Expanded(
            child: _buildTreeView(context),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Binder',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _ToolbarButton(
            icon: LucideIcons.plus,
            tooltip: 'Add Document',
            onPressed: () => _showAddDocumentDialog(context, null),
          ),
          _ToolbarButton(
            icon: LucideIcons.folderPlus,
            tooltip: 'Add Folder (Part)',
            onPressed: () => _showAddDocumentDialog(context, ManuscriptDocumentType.part),
          ),
          _ToolbarButton(
            icon: LucideIcons.fileText,
            tooltip: 'Add Chapter',
            onPressed: () => _showAddDocumentDialog(context, ManuscriptDocumentType.chapter),
          ),
          _ToolbarButton(
            icon: LucideIcons.maximize,
            tooltip: 'Expand All',
            onPressed: _expandAll,
          ),
          _ToolbarButton(
            icon: LucideIcons.minimize,
            tooltip: 'Collapse All',
            onPressed: _collapseAll,
          ),
        ],
      ),
    );
  }

  void _expandAll() {
    for (final doc in provider.allDocuments) {
      if (doc.isContainer) {
        provider.updateMetadata(doc.id, isExpanded: true);
      }
    }
  }

  void _collapseAll() {
    for (final doc in provider.allDocuments) {
      if (doc.isContainer) {
        provider.updateMetadata(doc.id, isExpanded: false);
      }
    }
  }

  Widget _buildTreeView(BuildContext context) {
    final root = provider.manuscriptRoot;
    if (root == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        _BinderNode(
          provider: provider,
          document: root,
          selectedDocumentId: selectedDocumentId,
          onDocumentSelected: onDocumentSelected,
          onDocumentRenamed: onDocumentRenamed,
          onDocumentMoved: onDocumentMoved,
          depth: 0,
        ),
      ],
    );
  }

  void _showAddDocumentDialog(BuildContext context, ManuscriptDocumentType? presetType) {
    final titleController = TextEditingController();
    ManuscriptDocumentType selectedType = presetType ?? ManuscriptDocumentType.chapter;
    String? parentId = selectedDocumentId ?? provider.manuscriptRoot?.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(presetType != null ? 'New ${presetType.label}' : 'New Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (presetType == null) ...[
                DropdownButtonFormField<ManuscriptDocumentType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ManuscriptDocumentType.values
                      .where((t) => t != ManuscriptDocumentType.manuscript)
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter document title',
                ),
                autofocus: true,
                onSubmitted: (_) => _createDocument(context, parentId, selectedType, titleController.text),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _createDocument(context, parentId, selectedType, titleController.text),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _createDocument(BuildContext context, String? parentId, ManuscriptDocumentType type, String title) {
    if (title.trim().isEmpty) return;
    if (parentId == null) return;

    Navigator.pop(context);

    provider.createChild(
      parentId: parentId,
      title: title.trim(),
      type: type,
    ).then((doc) {
      onDocumentSelected(doc.id);
      onDocumentRenamed?.call(doc.id);
    });
  }
}

class _BinderNode extends StatelessWidget {
  final ManuscriptBinderProvider provider;
  final ManuscriptDocument document;
  final String? selectedDocumentId;
  final ValueChanged<String> onDocumentSelected;
  final ValueChanged<String>? onDocumentRenamed;
  final ValueChanged<String>? onDocumentMoved;
  final int depth;

  const _BinderNode({
    super.key,
    required this.provider,
    required this.document,
    required this.selectedDocumentId,
    required this.onDocumentSelected,
    this.onDocumentRenamed,
    this.onDocumentMoved,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedDocumentId == document.id;
    final isExpanded = document.isExpanded;
    final hasChildren = document.isContainer;
    final children = hasChildren
        ? provider.getChildren(document.id)
        : <ManuscriptDocument>[];

    if (!hasChildren || !isExpanded) {
      return _DocumentRow(
        document: document,
        isSelected: isSelected,
        isExpanded: isExpanded,
        hasChildren: hasChildren,
        depth: depth,
        onTap: () => onDocumentSelected(document.id),
        onExpandToggle: () => provider.setExpanded(document.id, !isExpanded),
        onContextMenu: (details) => _showContextMenu(context, details),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DocumentRow(
          document: document,
          isSelected: isSelected,
          isExpanded: isExpanded,
          hasChildren: hasChildren,
          depth: depth,
          onTap: () => onDocumentSelected(document.id),
          onExpandToggle: () => provider.setExpanded(document.id, !isExpanded),
          onContextMenu: (details) => _showContextMenu(context, details),
        ),
        Padding(
          padding: EdgeInsets.only(left: 16.0 + depth * 12.0),
          child: _ReorderableChildren(
            provider: provider,
            children: children,
            selectedDocumentId: selectedDocumentId,
            onDocumentSelected: onDocumentSelected,
            onDocumentRenamed: onDocumentRenamed,
            onDocumentMoved: onDocumentMoved,
            depth: depth + 1,
            onReorder: (oldIndex, newIndex) async {
              final child = children[oldIndex];
              await provider.reorderDocument(child.id, newIndex);
            },
          ),
        ),
      ],
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<dynamic>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: <PopupMenuEntry<dynamic>>[
        const PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              Icon(LucideIcons.edit, size: 16),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(LucideIcons.copy, size: 16),
              SizedBox(width: 8),
              Text('Duplicate'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'add_child',
          child: Row(
            children: [
              Icon(LucideIcons.plus, size: 16),
              SizedBox(width: 8),
              Text('Add Child'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'add_sibling',
          child: Row(
            children: [
              Icon(LucideIcons.plusSquare, size: 16),
              SizedBox(width: 8),
              Text('Add Sibling'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null && context.mounted) {
        _handleContextAction(context, value);
      }
    });
  }

  void _handleContextAction(BuildContext context, String action) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context);
        break;
      case 'duplicate':
        _duplicateDocument();
        break;
      case 'add_child':
        _showAddChildDialog(context);
        break;
      case 'add_sibling':
        _showAddSiblingDialog(context);
        break;
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: document.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Title'),
          autofocus: true,
          onSubmitted: (_) => _rename(context, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _rename(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _rename(BuildContext context, String newTitle) {
    Navigator.pop(context);
    if (newTitle.trim().isEmpty || newTitle.trim() == document.title) return;
    provider.updateTitle(document.id, newTitle.trim());
    onDocumentRenamed?.call(document.id);
  }

  void _duplicateDocument() async {
    final parentId = document.parentId ?? provider.manuscriptRoot?.id;
    if (parentId == null) return;

    final children = provider.getChildren(parentId);
    final index = children.indexWhere((c) => c.id == document.id) + 1;

    final copy = await provider.createChild(
      parentId: parentId,
      title: '${document.title} (Copy)',
      type: document.documentType,
      orderIndex: index,
      richTextJson: document.richTextJson,
      status: document.status,
      summary: document.summary,
      povCharacterId: document.povCharacterId,
      locationId: document.locationId,
      timelineEventId: document.timelineEventId,
      plotline: document.plotline,
      characterIds: document.characterIds,
      tagIds: document.tagIds,
    );

    onDocumentSelected(copy.id);
  }

  void _showAddChildDialog(BuildContext context) {
    final binder = _findBinder(context);
    if (binder != null) {
      binder._showAddDocumentDialog(context, _getDefaultChildType());
    }
  }

  void _showAddSiblingDialog(BuildContext context) {
    final parentId = document.parentId ?? provider.manuscriptRoot?.id;
    if (parentId == null) return;

    final binder = _findBinder(context);
    if (binder != null) {
      binder._showAddDocumentDialog(context, null);
    }
  }

  ManuscriptBinder? _findBinder(BuildContext context) {
    return context.findAncestorWidgetOfExactType<ManuscriptBinder>();
  }

  ManuscriptDocumentType _getDefaultChildType() {
    return switch (document.documentType) {
      ManuscriptDocumentType.manuscript => ManuscriptDocumentType.part,
      ManuscriptDocumentType.part => ManuscriptDocumentType.chapter,
      ManuscriptDocumentType.chapter => ManuscriptDocumentType.scene,
      ManuscriptDocumentType.section => ManuscriptDocumentType.scene,
      _ => ManuscriptDocumentType.note,
    };
  }

  void _confirmDelete(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasChildren = provider.getChildren(document.id).isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          hasChildren
              ? 'This document has ${provider.getChildren(document.id).length} child(ren). Delete them as well?'
              : 'Delete "${document.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (hasChildren)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteDocument(deleteChildren: false);
              },
              child: const Text('Promote Children'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDocument(deleteChildren: hasChildren);
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: Text(hasChildren ? 'Delete All' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteDocument({required bool deleteChildren}) async {
    await provider.deleteDocument(document.id, deleteChildren: deleteChildren);
    final root = provider.manuscriptRoot;
    if (root != null) {
      onDocumentSelected(root.id);
    }
  }
}

class _DocumentRow extends StatelessWidget {
  final ManuscriptDocument document;
  final bool isSelected;
  final bool isExpanded;
  final bool hasChildren;
  final int depth;
  final VoidCallback onTap;
  final VoidCallback onExpandToggle;
  final void Function(Offset) onContextMenu;

  const _DocumentRow({
    required this.document,
    required this.isSelected,
    required this.isExpanded,
    required this.hasChildren,
    required this.depth,
    required this.onTap,
    required this.onExpandToggle,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      onSecondaryTapDown: (details) => onContextMenu(details.globalPosition),
      onLongPress: () => onContextMenu(Offset.zero),
      child: Container(
        color: isSelected ? cs.primaryContainer : Colors.transparent,
        child: Padding(
          padding: EdgeInsets.only(
            left: 8.0 + depth * 12.0,
            right: 8.0,
            top: 2.0,
            bottom: 2.0,
          ),
          child: Row(
            children: [
              if (hasChildren)
                IconButton(
                  icon: Icon(
                    isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: onExpandToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                )
              else
                const SizedBox(width: 24),
              Icon(
                _getIconForType(document.documentType),
                size: 16,
                color: _getColorForType(document.documentType, cs),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  document.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontStyle: document.status == ManuscriptDocumentStatus.archived
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (document.wordCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${_formatCount(document.wordCount)}w',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              _StatusBadge(status: document.status),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(ManuscriptDocumentType type) {
    return switch (type) {
      ManuscriptDocumentType.manuscript => LucideIcons.bookOpen,
      ManuscriptDocumentType.part => LucideIcons.folderKanban,
      ManuscriptDocumentType.chapter => LucideIcons.book,
      ManuscriptDocumentType.scene => LucideIcons.fileText,
      ManuscriptDocumentType.section => LucideIcons.folder,
      ManuscriptDocumentType.note => LucideIcons.stickyNote,
      ManuscriptDocumentType.research => LucideIcons.search,
      ManuscriptDocumentType.frontMatter => LucideIcons.fileInput,
      ManuscriptDocumentType.backMatter => LucideIcons.fileOutput,
      ManuscriptDocumentType.custom => LucideIcons.file,
    };
  }

  Color _getColorForType(ManuscriptDocumentType type, ColorScheme cs) {
    return switch (type) {
      ManuscriptDocumentType.manuscript => cs.primary,
      ManuscriptDocumentType.part => cs.tertiary,
      ManuscriptDocumentType.chapter => cs.secondary,
      ManuscriptDocumentType.scene => cs.primary,
      ManuscriptDocumentType.section => cs.tertiary,
      ManuscriptDocumentType.note => Colors.amber,
      ManuscriptDocumentType.research => Colors.blue,
      ManuscriptDocumentType.frontMatter => Colors.purple,
      ManuscriptDocumentType.backMatter => Colors.purple,
      ManuscriptDocumentType.custom => cs.outline,
    };
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

class _StatusBadge extends StatelessWidget {
  final ManuscriptDocumentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final (label, color) = switch (status) {
      ManuscriptDocumentStatus.idea => ('Idea', cs.outline),
      ManuscriptDocumentStatus.outline => ('Outline', Colors.blue),
      ManuscriptDocumentStatus.draft => ('Draft', Colors.orange),
      ManuscriptDocumentStatus.revised => ('Revised', Colors.green),
      ManuscriptDocumentStatus.complete => ('Complete', cs.primary),
      ManuscriptDocumentStatus.archived => ('Archived', cs.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      color: cs.onSurfaceVariant,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}