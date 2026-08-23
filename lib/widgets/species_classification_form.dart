import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/classification_node.dart';
import 'package:lore_keeper/providers/species_provider.dart';

class SpeciesClassificationForm extends StatefulWidget {
  final SpeciesProvider speciesProvider;
  final VoidCallback onCancel;
  final VoidCallback onComplete;
  final bool isRootCreation;

  const SpeciesClassificationForm({
    super.key,
    required this.speciesProvider,
    required this.onCancel,
    required this.onComplete,
    this.isRootCreation = false,
  });

  @override
  State<SpeciesClassificationForm> createState() =>
      _SpeciesClassificationFormState();
}

class _SpeciesClassificationFormState extends State<SpeciesClassificationForm> {
  final List<String> _ranks = const [
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

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, String?> _selectedExistingIds = {};
  final Map<String, bool> _isProposingNew = {};

  @override
  void initState() {
    super.initState();
    for (final rank in _ranks) {
      _controllers[rank] = TextEditingController();
      _focusNodes[rank] = FocusNode();
      _selectedExistingIds[rank] = null;
      _isProposingNew[rank] = false;
    }

    // If creating root category, start at category rank
    if (widget.isRootCreation) {
      _selectedExistingIds['category'] = null;
      _isProposingNew['category'] = true;
    }
  }

  @override
  void dispose() {
    for (final rank in _ranks) {
      _controllers[rank]?.dispose();
      _focusNodes[rank]?.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String rank, String value) {
    final normalized = ClassificationNode.normalize(value);
    final existing = _findExisting(rank, normalized);

    setState(() {
      if (existing != null) {
        _selectedExistingIds[rank] = existing.id;
        _isProposingNew[rank] = false;
      } else if (value.isNotEmpty) {
        _selectedExistingIds[rank] = null;
        _isProposingNew[rank] = true;
      } else {
        _selectedExistingIds[rank] = null;
        _isProposingNew[rank] = false;
      }
    });
  }

  ClassificationNode? _findExisting(String rank, String normalizedName) {
    if (rank == 'category') {
      // For category, search among root nodes via public provider API
      return widget.speciesProvider.findRootCategory(normalizedName);
    }

    // For other ranks, need parent
    final parentRankIndex = _ranks.indexOf(rank) - 1;
    if (parentRankIndex < 0) return null;

    final parentRank = _ranks[parentRankIndex];
    final parentId = _selectedExistingIds[parentRank];
    if (parentId == null) return null;

    return widget.speciesProvider.tryFindExistingChild(
      parentId,
      rank,
      normalizedName,
    );
  }

  void _onSelectExisting(String rank, ClassificationNode node) {
    setState(() {
      _controllers[rank]!.text = node.name;
      _selectedExistingIds[rank] = node.id;
      _isProposingNew[rank] = false;

      // Clear all lower ranks
      _clearLowerRanks(rank);
    });
  }

  void _clearLowerRanks(String currentRank) {
    final currentIndex = _ranks.indexOf(currentRank);
    for (int i = currentIndex + 1; i < _ranks.length; i++) {
      final rank = _ranks[i];
      _controllers[rank]!.clear();
      _selectedExistingIds[rank] = null;
      _isProposingNew[rank] = false;
    }
  }

  bool _isRankActive(String rank) {
    if (rank == 'category') return true;
    final parentIndex = _ranks.indexOf(rank) - 1;
    if (parentIndex < 0) return false;
    final parentRank = _ranks[parentIndex];
    return _selectedExistingIds[parentRank] != null &&
        _controllers[rank]!.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    // Build the path
    final path =
        <
          ({
            String rank,
            String name,
            String? iconKey,
            int? colorValue,
            String content,
          })
        >[];

    for (final rank in _ranks) {
      final name = _controllers[rank]!.text.trim();
      if (name.isEmpty) break;

      // Determine icon and color based on rank
      final (iconKey, colorValue) = _getRankStyle(rank);

      path.add((
        rank: rank,
        name: name,
        iconKey: iconKey,
        colorValue: colorValue,
        content: '',
      ));

      // If this is a species or subspecies, we can stop here
      if (rank == 'species' || rank == 'subspecies') {
        // Could continue but usually stop at species
      }
    }

    if (path.isEmpty) return;

    try {
      await widget.speciesProvider.createClassificationPath(path);
      widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  (String, int) _getRankStyle(String rank) {
    switch (rank) {
      case 'category':
        return ('folder', 0xFF6366F1);
      case 'lineage':
        return ('treePine', 0xFF8B5CF6);
      case 'kingdom':
        return ('crown', 0xFFF59E0B);
      case 'phylum':
        return ('dna', 0xFF06B6D4);
      case 'classRank':
        return ('bookOpen', 0xFF10B981);
      case 'order':
        return ('list', 0xFFF43F5E);
      case 'family':
        return ('usersRound', 0xFFFB923C);
      case 'genus':
        return ('book', 0xFF6366F1);
      case 'species':
        return ('dna', 0xFF8B5CF6);
      case 'subspecies':
        return ('microscope', 0xFF06B6D4);
      default:
        return ('folder', 0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.dna, size: 24),
          const SizedBox(width: 8),
          Text(
            widget.isRootCreation
                ? 'Create Root Category'
                : 'Create New Species',
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 500,
          maxWidth: 600,
          maxHeight: 600,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Build the classification path. Existing nodes will be reused; missing nodes will be created.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ..._ranks.map((rank) => _buildRankField(rank)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
        FilledButton(
          onPressed: _canSubmit() ? _submit : null,
          child: const Text('Create Classification'),
        ),
      ],
    );
  }

  bool _canSubmit() {
    return _controllers['category']!.text.trim().isNotEmpty;
  }

  Widget _buildRankField(String rank) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = _isRankActive(rank);
    final isProposing = _isProposingNew[rank] ?? false;
    final existingId = _selectedExistingIds[rank];

    if (!isActive) {
      return const SizedBox.shrink();
    }

    final rankDisplayName = rank == 'classRank' ? 'Class' : _capitalize(rank);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  rankDisplayName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isActive
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (existingId != null)
                Chip(
                  label: Text(
                    'Reusing: ${widget.speciesProvider.getNodeById(existingId)!.name}',
                    style: theme.textTheme.labelSmall,
                  ),
                  backgroundColor: colorScheme.primaryContainer,
                  side: BorderSide.none,
                  onDeleted: () => setState(() {
                    _controllers[rank]!.clear();
                    _selectedExistingIds[rank] = null;
                    _isProposingNew[rank] = false;
                    _clearLowerRanks(rank);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _controllers[rank],
            focusNode: _focusNodes[rank],
            enabled: isActive,
            decoration: InputDecoration(
              hintText: isProposing
                  ? 'Type to create new $rankDisplayName...'
                  : 'Search or type $rankDisplayName...',
              prefixIcon: isProposing
                  ? Icon(LucideIcons.plus, color: colorScheme.primary)
                  : Icon(
                      LucideIcons.search,
                      color: colorScheme.onSurfaceVariant,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: isActive
                  ? colorScheme.surface
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            onChanged: (value) => _onTextChanged(rank, value),
          ),
          if (isProposing)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Will create new $rankDisplayName: "${_controllers[rank]!.text}"',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            )
          else if (existingId != null)
            _buildExistingOptions(rank)
          else
            _buildSearchResults(rank),
        ],
      ),
    );
  }

  Widget _buildExistingOptions(String rank) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final existing = widget.speciesProvider.getNodeById(
      _selectedExistingIds[rank]!,
    );
    if (existing == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle2, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Selected: ${existing.name} (${existing.rankEnum.displayName})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(String rank) {
    if (!(_isProposingNew[rank] ?? false)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final parentRankIndex = _ranks.indexOf(rank) - 1;
    if (parentRankIndex < 0) return const SizedBox.shrink();

    final parentRank = _ranks[parentRankIndex];
    final parentId = _selectedExistingIds[parentRank];
    if (parentId == null) return const SizedBox.shrink();

    final query = _controllers[rank]!.text.trim().toLowerCase();
    if (query.isEmpty) return const SizedBox.shrink();

    final results = widget.speciesProvider
        .getChildrenOfRank(parentId, rank)
        .where((n) => n.name.toLowerCase().contains(query))
        .toList();

    if (results.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: results.map((node) {
            return ListTile(
              dense: true,
              leading: Icon(
                _getIcon(node.iconKey),
                color: Color(node.colorValue),
              ),
              title: Text(node.name),
              subtitle: Text(node.rankEnum.displayName),
              onTap: () => _onSelectExisting(rank, node),
            );
          }).toList(),
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
      case 'crown':
        return LucideIcons.crown;
      case 'bookOpen':
        return LucideIcons.bookOpen;
      case 'list':
        return LucideIcons.list;
      case 'usersRound':
        return LucideIcons.usersRound;
      case 'book':
        return LucideIcons.book;
      default:
        return LucideIcons.folder;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
