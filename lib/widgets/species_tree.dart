import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/classification_node.dart';
import 'package:lore_keeper/providers/species_provider.dart';

/// Left panel - Classification Tree for Species Module.
/// Matches the Magic list pane style with tree navigation.
class SpeciesTree extends StatefulWidget {
  final SpeciesProvider speciesProvider;
  final bool isMobile;

  const SpeciesTree({
    super.key,
    required this.speciesProvider,
    required this.isMobile,
  });

  @override
  State<SpeciesTree> createState() => _SpeciesTreeState();
}

class _SpeciesTreeState extends State<SpeciesTree> {
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

  void _showCreateChoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.plus, size: 20),
            SizedBox(width: 8),
            Text('Create New'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CreateOptionTile(
              icon: LucideIcons.penTool,
              title: 'Create Manually',
              subtitle: 'Build classification path step by step',
              onTap: () {
                Navigator.of(context).pop();
                _showManualCreationDialog();
              },
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.5,
              child: _CreateOptionTile(
                icon: LucideIcons.sparkles,
                title: 'Ask AI',
                subtitle: 'Coming soon',
                onTap: null,
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.5,
              child: _CreateOptionTile(
                icon: LucideIcons.upload,
                title: 'Import',
                subtitle: 'Coming soon',
                onTap: null,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showManualCreationDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          _SpeciesClassificationDialog(speciesProvider: widget.speciesProvider),
    );
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

          final filterText = _filterController.text;
          final nodes = widget.speciesProvider.getVisibleNodes(
            filter: filterText,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
                        if (!_showFilter) _filterController.clear();
                      }),
                      tooltip: 'Search Nodes',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.circlePlus, size: 20),
                      onPressed: _showCreateChoiceDialog,
                      tooltip: 'Create Species',
                    ),
                  ],
                ),
              ),

              // Filter field
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

              // Tree content
              Expanded(
                child: nodes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.pawPrint,
                              size: 48,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No nodes found',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text('Create Species'),
                              onPressed: _showCreateChoiceDialog,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: nodes.length,
                        itemBuilder: (context, index) {
                          final entry = nodes[index];
                          final node = entry.node;
                          final isSelected =
                              widget.speciesProvider.selectedNode?.id ==
                              node.id;

                          return _SpeciesTreeTile(
                            node: node,
                            level: entry.level,
                            isSelected: isSelected,
                            isExpanded: widget.speciesProvider.isExpanded(
                              node.id,
                            ),
                            hasChildren: widget.speciesProvider.hasChildren(
                              node.id,
                            ),
                            onTap: () {
                              widget.speciesProvider.selectNode(node.id);
                            },
                            onToggle: () =>
                                widget.speciesProvider.toggleExpanded(node.id),
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
}

/// Tree tile widget matching Magic list pane style
class _SpeciesTreeTile extends StatelessWidget {
  final ClassificationNode node;
  final int level;
  final bool isSelected;
  final bool isExpanded;
  final bool hasChildren;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _SpeciesTreeTile({
    required this.node,
    required this.level,
    required this.isSelected,
    required this.isExpanded,
    required this.hasChildren,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = _getIconForNode(node);

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      color: isSelected
          ? colorScheme.onPrimaryContainer
          : colorScheme.onSurface,
    );

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
                iconData,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : Color(node.colorValue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.name,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Rank badge for species/subspecies
              if (node.isSpeciesOrSubspecies)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    node.rankEnum.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForNode(ClassificationNode node) {
    switch (node.rank) {
      case 'category':
        return node.normalizedName == 'fauna'
            ? LucideIcons.pawPrint
            : LucideIcons.leaf;
      case 'lineage':
        return LucideIcons.globe;
      case 'kingdom':
        return LucideIcons.crown;
      case 'phylum':
        return LucideIcons.dna;
      case 'classRank':
        return LucideIcons.bookOpen;
      case 'order':
        return LucideIcons.list;
      case 'family':
        return LucideIcons.usersRound;
      case 'genus':
        return LucideIcons.book;
      case 'species':
        return LucideIcons.dna;
      case 'subspecies':
        return LucideIcons.microscope;
      default:
        return LucideIcons.folder;
    }
  }
}

/// Create option tile for the creation choice dialog
class _CreateOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _CreateOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cascading classification creation dialog - shows all fields
class _SpeciesClassificationDialog extends StatefulWidget {
  final SpeciesProvider speciesProvider;

  const _SpeciesClassificationDialog({required this.speciesProvider});

  @override
  State<_SpeciesClassificationDialog> createState() =>
      _SpeciesClassificationDialogState();
}

class _SpeciesClassificationDialogState
    extends State<_SpeciesClassificationDialog> {
  // All classification ranks in order
  static const _ranks = [
    'category',
    'lineage',
    'kingdom',
    'phylum',
    'classRank',
    'order',
    'family',
    'genus',
    'species',
    'subspecies',
  ];

  // Text controllers for each field
  final Map<String, TextEditingController> _controllers = {};
  // Currently selected existing nodes
  final Map<String, ClassificationNode?> _selectedNodes = {};
  // Options for autocomplete for each field
  final Map<String, List<ClassificationNode>> _options = {};
  bool _isSubmitting = false;

  _SpeciesClassificationDialogState() {
    for (final rank in _ranks) {
      _controllers[rank] = TextEditingController();
      _selectedNodes[rank] = null;
      _options[rank] = [];
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize category options (Fauna, Flora)
    _loadOptionsForRank('category', null);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadOptionsForRank(String rank, ClassificationNode? parent) {
    if (rank == 'category') {
      _options[rank] = widget.speciesProvider.getRootNodes();
    } else if (parent != null) {
      _options[rank] = widget.speciesProvider.getChildrenOf(parent.id);
    } else {
      _options[rank] = [];
    }
  }

  String _getDisplayName(String rank) {
    return rank == 'classRank'
        ? 'Class'
        : rank[0].toUpperCase() + rank.substring(1);
  }

  String _getHintText(String rank) {
    switch (rank) {
      case 'category':
        return 'Fauna or Flora';
      case 'lineage':
        return 'e.g., Terran Life, Xylorian Life';
      case 'kingdom':
        return 'e.g., Animalia, Plantae';
      case 'phylum':
        return 'e.g., Chordata, Arthropoda';
      case 'classRank':
        return 'e.g., Mammalia, Insecta';
      case 'order':
        return 'e.g., Primates, Coleoptera';
      case 'family':
        return 'e.g., Hominidae, Formicidae';
      case 'genus':
        return 'e.g., Homo, Formica';
      case 'species':
        return 'e.g., Homo sapiens';
      case 'subspecies':
        return 'e.g., Homo sapiens cyberneticus (optional)';
      default:
        return '';
    }
  }

  bool _isRankEnabled(String rank) {
    if (rank == 'category') return true;

    final index = _ranks.indexOf(rank);
    final previousRank = _ranks[index - 1];

    final prevText = _controllers[previousRank]?.text.trim() ?? '';
    final prevSelected = _selectedNodes[previousRank];

    return prevText.isNotEmpty || prevSelected != null;
  }

  ClassificationNode? _getParentForRank(String rank) {
    final index = _ranks.indexOf(rank);
    if (index <= 0) return null;

    final previousRank = _ranks[index - 1];
    return _selectedNodes[previousRank];
  }

  void _onTextChanged(String rank, String value) {
    final parent = _getParentForRank(rank);
    _loadOptionsForRank(rank, parent);

    final normalizedInput = value.trim().toLowerCase();
    final exactMatch = _options[rank]
        ?.where((o) => o.normalizedName == normalizedInput)
        .firstOrNull;

    setState(() {
      if (exactMatch != null) {
        _selectedNodes[rank] = exactMatch;
      } else if (value.trim().isEmpty) {
        _selectedNodes[rank] = null;
      } else {
        _selectedNodes[rank] = null;
      }

      _clearLowerRanks(rank);
    });
  }

  void _clearLowerRanks(String fromRank) {
    final startIndex = _ranks.indexOf(fromRank);
    for (int i = startIndex + 1; i < _ranks.length; i++) {
      final rank = _ranks[i];
      _controllers[rank]!.clear();
      _selectedNodes[rank] = null;
      _options[rank] = [];
    }
  }

  void _onOptionSelected(String rank, ClassificationNode node) {
    setState(() {
      _controllers[rank]!.text = node.name;
      _selectedNodes[rank] = node;

      final nextRank = _getNextRank(rank);
      if (nextRank != null) {
        _loadOptionsForRank(nextRank, node);
      }

      _clearLowerRanks(rank);
    });
  }

  String? _getNextRank(String rank) {
    final index = _ranks.indexOf(rank);
    if (index < _ranks.length - 1) {
      return _ranks[index + 1];
    }
    return null;
  }

  bool get _canSubmit {
    if (_selectedNodes['category'] == null) return false;

    final speciesText = _controllers['species']?.text.trim() ?? '';
    final speciesSelected = _selectedNodes['species'];
    if (speciesText.isEmpty && speciesSelected == null) return false;

    return true;
  }

  List<({String rank, String name})> _buildPath() {
    final path = <({String rank, String name})>[];

    for (final rank in _ranks) {
      final selected = _selectedNodes[rank];
      final text = _controllers[rank]?.text.trim() ?? '';

      if (selected != null) {
        path.add((rank: rank, name: selected.name));
      } else if (text.isNotEmpty) {
        path.add((rank: rank, name: text));
      } else {
        break;
      }
    }

    return path;
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final path = _buildPath();

      if (path.isNotEmpty) {
        await widget.speciesProvider.createClassificationPath(
          path
              .map(
                (p) => (
                  rank: p.rank,
                  name: p.name,
                  iconKey: 'folder',
                  colorValue: 0xFF6366F1,
                  content: '',
                ),
              )
              .toList(),
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(LucideIcons.dna, size: 20),
          SizedBox(width: 8),
          Text('Create Species'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Helper text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Example Classification',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fauna → Terran Life → Animalia → Chordata → Mammalia → Primates → Hominidae → Homo → Homo sapiens',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // All classification fields
              ..._ranks.map((rank) => _buildRankField(rank)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSubmit && !_isSubmitting ? _submit : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildRankField(String rank) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = _isRankEnabled(rank);
    final options = _options[rank] ?? [];
    final selectedNode = _selectedNodes[rank];
    final controller = _controllers[rank]!;
    final isOptional = rank == 'subspecies';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Text(
                _getDisplayName(rank),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              if (isOptional) ...[
                const SizedBox(width: 8),
                Text(
                  '(optional)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (selectedNode != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.check,
                        size: 12,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Existing',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (controller.text.trim().isNotEmpty && isEnabled) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.plus,
                        size: 12,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'New',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.tertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Input field with autocomplete
          Autocomplete<ClassificationNode>(
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return options;
              }
              return options.where(
                (o) => o.name.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                ),
              );
            },
            displayStringForOption: (node) => node.name,
            fieldViewBuilder:
                (context, textController, focusNode, onFieldSubmitted) {
                  if (textController.text != controller.text) {
                    textController.text = controller.text;
                  }
                  textController.addListener(() {
                    if (textController.text != controller.text) {
                      controller.text = textController.text;
                      _onTextChanged(rank, textController.text);
                    }
                  });
                  return TextField(
                    controller: textController,
                    focusNode: focusNode,
                    enabled: isEnabled,
                    decoration: InputDecoration(
                      hintText: _getHintText(rank),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      _onTextChanged(rank, value);
                    },
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              final optionsList = options.toList();
              final hasTypedText = controller.text.trim().isNotEmpty;

              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 450,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: optionsList.length + (hasTypedText ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == optionsList.length) {
                          return ListTile(
                            leading: const Icon(LucideIcons.plus, size: 18),
                            title: Text('Create "${controller.text.trim()}"'),
                            dense: true,
                            onTap: () {},
                          );
                        }
                        final option = optionsList[index];
                        return ListTile(
                          leading: Icon(_getIconForNode(option), size: 18),
                          title: Text(option.name),
                          subtitle: Text(option.rankEnum.displayName),
                          dense: true,
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (node) => _onOptionSelected(rank, node),
          ),
        ],
      ),
    );
  }

  IconData _getIconForNode(ClassificationNode node) {
    switch (node.rank) {
      case 'category':
        return node.normalizedName == 'fauna'
            ? LucideIcons.pawPrint
            : LucideIcons.leaf;
      case 'lineage':
        return LucideIcons.globe;
      case 'kingdom':
        return LucideIcons.crown;
      case 'phylum':
        return LucideIcons.dna;
      case 'classRank':
        return LucideIcons.bookOpen;
      case 'order':
        return LucideIcons.list;
      case 'family':
        return LucideIcons.usersRound;
      case 'genus':
        return LucideIcons.book;
      case 'species':
        return LucideIcons.dna;
      case 'subspecies':
        return LucideIcons.microscope;
      default:
        return LucideIcons.folder;
    }
  }
}
