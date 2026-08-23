import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/classification_node.dart';
import 'package:lore_keeper/providers/species_provider.dart';

class SpeciesListPane extends StatefulWidget {
  final SpeciesProvider speciesProvider;
  final bool isMobile;

  const SpeciesListPane({
    super.key,
    required this.speciesProvider,
    required this.isMobile,
  });

  @override
  State<SpeciesListPane> createState() => _SpeciesListPaneState();
}

class _SpeciesListPaneState extends State<SpeciesListPane> {
  late TextEditingController _filterController;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _showCreateCategoryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        await widget.speciesProvider.createRootCategory(result);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: colorScheme.surface,
      child: ListenableBuilder(
        listenable: widget.speciesProvider,
        builder: (context, child) {
          if (!widget.speciesProvider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final nodes = widget.speciesProvider.getVisibleNodes(
            filter: _filterController.text,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Text(
                      'SPECIES',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _showFilter ? LucideIcons.searchX : LucideIcons.search,
                        size: 20,
                      ),
                      onPressed: () => setState(() {
                        _showFilter = !_showFilter;
                        if (!_showFilter) {
                          _filterController.clear();
                        }
                      }),
                      tooltip: 'Search Species',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.circlePlus, size: 20),
                      onPressed: _showCreateCategoryDialog,
                      tooltip: 'Create Category',
                    ),
                  ],
                ),
              ),
              if (_showFilter)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _filterController,
                    autofocus: true,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Filter by name...',
                      prefixIcon: const Icon(LucideIcons.listFilter, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      fillColor: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            )
                          : colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: nodes.isEmpty
                    ? Center(
                        child: Text(
                          'No species found',
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: nodes.length,
                        itemBuilder: (context, index) {
                          final entry = nodes[index];
                          final node = entry.node;
                          final isSelected =
                              widget.speciesProvider.selectedNode?.id == node.id;
                          final canDelete = node.parentId != null &&
                              !(node.rank == 'category' && node.parentId == null);

                          return _SpeciesTreeTile(
                            node: node,
                            level: entry.level,
                            isSelected: isSelected,
                            canDelete: canDelete,
                            hasChildren:
                                widget.speciesProvider.hasChildren(node.id),
                            isExpanded:
                                widget.speciesProvider.isExpanded(node.id),
                            onTap: () {
                              widget.speciesProvider.selectNode(node.id);
                            },
                            onToggle: () =>
                                widget.speciesProvider.toggleExpanded(node.id),
                            onDelete: canDelete
                                ? () => _confirmDeleteNode(node.id)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteNode(String nodeId) async {
    final node = widget.speciesProvider.getNodeById(nodeId);
    if (node == null) return;

    final hasChildren = widget.speciesProvider.hasChildren(nodeId);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Delete Node'),
          content: Text(
            hasChildren
                ? 'This will remove "${node.name}" and all its descendants.'
                : 'Remove "${node.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      try {
        await widget.speciesProvider.deleteNode(nodeId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }
}

class _SpeciesTreeTile extends StatelessWidget {
  final ClassificationNode node;
  final int level;
  final bool isSelected;
  final bool canDelete;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const _SpeciesTreeTile({
    required this.node,
    required this.level,
    required this.isSelected,
    required this.canDelete,
    required this.hasChildren,
    required this.isExpanded,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(width: 8 + (level * 12)),
              if (hasChildren)
                IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    isExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 18,
                  ),
                  tooltip: isExpanded ? 'Collapse' : 'Expand',
                )
              else
                const SizedBox(width: 40),
              Icon(
                _getIcon(node.iconKey),
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  tooltip: 'Delete Node',
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String iconKey) {
    switch (iconKey) {
      case 'pawPrint':
        return LucideIcons.pawPrint;
      case 'leaf':
        return LucideIcons.leaf;
      case 'folder':
        return LucideIcons.folder;
      case 'tree':
        return LucideIcons.treePine;
      case 'dna':
        return LucideIcons.dna;
      case 'microscope':
        return LucideIcons.microscope;
      case 'bug':
        return LucideIcons.bug;
      case 'fish':
        return LucideIcons.fish;
      case 'bird':
        return LucideIcons.bird;
      case 'flower':
        return LucideIcons.flower2;
      case 'treePine':
        return LucideIcons.treePine;
      case 'seedling':
        return LucideIcons.sprout;
      default:
        return LucideIcons.folder;
    }
  }
}