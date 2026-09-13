import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:lore_keeper/database/ai/ai_provider.dart';
import 'package:lore_keeper/database/ai/ai_provider_factory.dart';
import 'package:lore_keeper/database/ai/species_ai/ai_species_service.dart';
import 'package:lore_keeper/models/classification_node.dart';
import 'package:lore_keeper/providers/species_provider.dart';
import 'package:lore_keeper/settings/global_settings_controller.dart';

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
            _CreateOptionTile(
              icon: LucideIcons.sparkles,
              title: 'AI-Assisted Species',
              subtitle: 'Describe a creature — AI builds the taxonomy',
              onTap: () {
                Navigator.of(context).pop();
                _showAiAssistedCreateFlow();
              },
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

  /// The full AI-assisted species flow (steps 1-5):
  ///
  /// 1. Prompt the user for a common name + description.
  /// 2. Generate a detailed scientific breakdown through the configured AI
  ///    provider (built from global settings, independent of the app's shared
  ///    Reference Engine instance).
  /// 3. Review + edit the proposal, with live Existing/New badges per node.
  /// 4. Save — existing classification nodes are merged, missing ones created.
  Future<void> _showAiAssistedCreateFlow() async {
    final settings = context.read<GlobalSettingsController>();
    final provider = buildAiProviderFromSettings(
      enabled: settings.aiEnabled,
      provider: settings.aiProvider,
      endpoint: settings.aiEndpoint,
      model: settings.aiModel,
    );
    final service = AiSpeciesService();

    final generated = await showDialog<AiGeneratedSpecies>(
      context: context,
      builder: (context) =>
          _AiSpeciesPromptDialog(service: service, provider: provider),
    );
    await provider.unload();
    if (generated == null || !mounted) return;

    final saved = await showDialog<ClassificationNode>(
      context: context,
      builder: (context) => _AiSpeciesReviewDialog(
        initial: generated,
        speciesProvider: widget.speciesProvider,
      ),
    );

    if (saved != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Species "${saved.name}" added')));
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

/// Step 1+2 of the AI-assisted flow: collect a common name + description,
/// then generate the draft through the AI provider.
class _AiSpeciesPromptDialog extends StatefulWidget {
  final AiSpeciesService service;
  final AiProvider provider;

  const _AiSpeciesPromptDialog({required this.service, required this.provider});

  @override
  State<_AiSpeciesPromptDialog> createState() => _AiSpeciesPromptDialogState();
}

class _AiSpeciesPromptDialogState extends State<_AiSpeciesPromptDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canGenerate =>
      _nameController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty &&
      !_busy;

  Future<void> _generate() async {
    if (!_canGenerate) return;
    setState(() => _busy = true);
    try {
      final result = await widget.service.generate(
        provider: widget.provider,
        commonName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI is not available right now. Enable an AI provider in '
              'Settings, or create the species manually.',
            ),
          ),
        );
        return;
      }
      Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Generation failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(LucideIcons.sparkles, size: 20),
          SizedBox(width: 8),
          Text('AI-Assisted Species'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Describe a creature. The AI builds the full scientific '
                  'breakdown — existing classification nodes are reused, new '
                  'ones are created when you save.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                autofocus: true,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Common name',
                  hintText: 'e.g. Moonfire Lynx',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                enabled: !_busy,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText:
                      'e.g. A six-legged feline native to the volcanic '
                      'badlands of Kharos, whose fur glows faintly.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canGenerate ? _generate : null,
          child: _busy
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Generating…'),
                  ],
                )
              : const Text('Generate'),
        ),
      ],
    );
  }
}

/// Steps 3-5 of the AI-assisted flow: review and edit the generated draft,
/// with per-node Existing/New badges, then save (merge existing / create new).
class _AiSpeciesReviewDialog extends StatefulWidget {
  final AiGeneratedSpecies initial;
  final SpeciesProvider speciesProvider;

  const _AiSpeciesReviewDialog({
    required this.initial,
    required this.speciesProvider,
  });

  @override
  State<_AiSpeciesReviewDialog> createState() => _AiSpeciesReviewDialogState();
}

class _AiSpeciesReviewDialogState extends State<_AiSpeciesReviewDialog> {
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

  late final Map<String, TextEditingController> _rankControllers;
  final _scientificNameController = TextEditingController();
  final _originController = TextEditingController();
  final _lifespanController = TextEditingController();
  final _heightController = TextEditingController();
  final _reproductionController = TextEditingController();
  final _dietController = TextEditingController();
  final _sentienceController = TextEditingController();
  final _populationController = TextEditingController();
  final _physiologyController = TextEditingController();
  final _contentController = TextEditingController();
  late String _status;
  bool _saving = false;

  _AiSpeciesReviewDialogState() {
    _rankControllers = {
      for (final rank in _ranks) rank: TextEditingController(),
    };
    for (final step in widget.initial.path) {
      final c = _rankControllers[step.rank];
      if (c != null) c.text = step.name;
    }
  }

  @override
  void dispose() {
    for (final c in _rankControllers.values) {
      c.dispose();
    }
    _scientificNameController.dispose();
    _originController.dispose();
    _lifespanController.dispose();
    _heightController.dispose();
    _reproductionController.dispose();
    _dietController.dispose();
    _sentienceController.dispose();
    _populationController.dispose();
    _physiologyController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _scientificNameController.text = initial.scientificName ?? '';
    _originController.text = initial.origin ?? '';
    _lifespanController.text = initial.averageLifespan;
    _heightController.text = initial.averageHeight;
    _reproductionController.text = initial.reproduction;
    _dietController.text = initial.diet;
    _sentienceController.text = initial.sentience;
    _populationController.text = initial.population ?? '';
    _physiologyController.text = initial.physiology;
    _contentController.text = initial.content;
    _status = initial.status;
  }

  bool get _canSubmit {
    final speciesText = _rankControllers['species']?.text.trim() ?? '';
    final subspeciesText = _rankControllers['subspecies']?.text.trim() ?? '';
    final categoryText = _rankControllers['category']?.text.trim() ?? '';
    return (speciesText.isNotEmpty || subspeciesText.isNotEmpty) &&
        categoryText.isNotEmpty &&
        !_saving;
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);
    try {
      final path = <GeneratedClassificationStep>[];
      for (final rank in _ranks) {
        final text = _rankControllers[rank]!.text.trim();
        if (text.isEmpty) continue;
        path.add(GeneratedClassificationStep(rank: rank, name: text));
      }
      final generated = AiGeneratedSpecies(
        path: path,
        scientificName: _nullableText(_scientificNameController.text),
        status: _status,
        origin: _nullableText(_originController.text),
        averageLifespan: _lifespanController.text.trim(),
        averageHeight: _heightController.text.trim(),
        reproduction: _reproductionController.text.trim(),
        diet: _dietController.text.trim(),
        sentience: _sentienceController.text.trim(),
        population: _nullableText(_populationController.text),
        physiology: _physiologyController.text.trim(),
        content: _contentController.text.trim(),
      );
      final node = await widget.speciesProvider.createAiGeneratedSpecies(
        generated,
      );
      if (mounted) Navigator.of(context).pop(node);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _rankDisplayName(String rank) {
    return rank == 'classRank'
        ? 'Class'
        : rank[0].toUpperCase() + rank.substring(1);
  }

  String _rankHint(String rank) {
    switch (rank) {
      case 'category':
        return 'Fauna or Flora';
      case 'lineage':
        return 'e.g. Terran Life, Xylorian Life';
      case 'kingdom':
        return 'e.g. Animalia, Plantae';
      case 'phylum':
        return 'e.g. Chordata, Arthropoda';
      case 'classRank':
        return 'e.g. Mammalia, Insecta';
      case 'order':
        return 'e.g. Primates, Coleoptera';
      case 'family':
        return 'e.g. Hominidae, Formicidae';
      case 'genus':
        return 'e.g. Homo, Formica';
      case 'species':
        return 'e.g. Homo sapiens';
      case 'subspecies':
        return 'e.g. Homo sapiens cyberneticus (optional)';
      default:
        return '';
    }
  }

  /// Live resolution of each step exactly as `createClassificationPath` will
  /// see it on save: a node matches only under the resolved parent, so a New
  /// ancestor makes every deeper descendant New as well.
  ClassificationNode? _resolveNode(String rank, ClassificationNode? parent) {
    final text = _rankControllers[rank]!.text.trim();
    if (text.isEmpty) return null;
    final normalized = ClassificationNode.normalizeName(text);
    if (rank == 'category') {
      return widget.speciesProvider.findRootCategory(normalized);
    }
    if (parent == null) return null;
    return widget.speciesProvider.tryFindExistingChild(
      parent.id,
      rank,
      normalized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(LucideIcons.sparkles, size: 20),
          SizedBox(width: 8),
          Text('Review AI Draft'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Review and edit the AI draft. Existing nodes are merged '
                  '(reused), missing nodes are created on save.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Classification',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ..._buildClassificationRows(),
              const SizedBox(height: 16),
              Text(
                'Scientific Details',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _detailField(
                _scientificNameController,
                'Scientific name',
                'e.g. Panthera lynx or a fictional binomial',
              ),
              const SizedBox(height: 10),
              _detailField(_originController, 'Origin', 'Homeworld or region'),
              const SizedBox(height: 10),
              Text(
                'Status',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Extant', child: Text('Extant')),
                  DropdownMenuItem(value: 'Extinct', child: Text('Extinct')),
                  DropdownMenuItem(
                    value: 'Endangered',
                    child: Text('Endangered'),
                  ),
                  DropdownMenuItem(value: 'Mythical', child: Text('Mythical')),
                  DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _status = value);
                      },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _detailField(
                      _lifespanController,
                      'Avg. lifespan',
                      'e.g. 40-60 years',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _detailField(
                      _heightController,
                      'Avg. height',
                      'e.g. 180-220 cm',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _detailField(
                      _reproductionController,
                      'Reproduction',
                      'e.g. Sexual',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _detailField(
                      _dietController,
                      'Diet',
                      'e.g. Omnivorous',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _detailField(
                      _sentienceController,
                      'Sentience',
                      'e.g. Sapient',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _detailField(
                      _populationController,
                      'Population',
                      'e.g. ~14 Billion',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _detailField(
                _physiologyController,
                'Physiology',
                '2-4 sentence physiology',
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              _detailField(
                _contentController,
                'Article',
                'Encyclopedia entry (shown in the wiki page)',
                maxLines: 6,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _canSubmit ? _save : null,
          icon: const Icon(LucideIcons.check, size: 18),
          label: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  List<Widget> _buildClassificationRows() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rows = <Widget>[];
    ClassificationNode? parent;
    const optionalRank = 'subspecies';

    for (final rank in _ranks) {
      final controller = _rankControllers[rank]!;
      final node = _resolveNode(rank, parent);
      parent = node;
      final text = controller.text.trim();
      final isOptional = rank == optionalRank;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _rankDisplayName(rank),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
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
                  if (text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    if (node != null)
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
                      )
                    else
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
              TextField(
                controller: controller,
                enabled: !_saving,
                decoration: InputDecoration(
                  hintText: _rankHint(rank),
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  Widget _detailField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
