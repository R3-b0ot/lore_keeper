// lib/widgets/manuscript_collections.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/database/database_manager.dart';
import 'package:lore_keeper/models/manuscript_collection.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lore_keeper/services/manuscript_collections_service.dart';

enum CollectionType {
  allDocuments('All Documents', LucideIcons.files),
  manuscript('Manuscript', LucideIcons.bookOpen),
  parts('Parts', LucideIcons.folderKanban),
  chapters('Chapters', LucideIcons.book),
  scenes('Scenes', LucideIcons.fileText),
  notes('Notes', LucideIcons.stickyNote),
  research('Research', LucideIcons.search),
  frontMatter('Front Matter', LucideIcons.fileInput),
  backMatter('Back Matter', LucideIcons.fileOutput),
  draft('Draft', LucideIcons.edit),
  revised('Revised', LucideIcons.refreshCw),
  complete('Complete', LucideIcons.checkCircle),
  needsRevision('Needs Revision', LucideIcons.alertTriangle),
  archived('Archived', LucideIcons.archive),
  recent('Recent', LucideIcons.clock),
  favorites('Favorites', LucideIcons.star);

  const CollectionType(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ManuscriptCollections extends StatefulWidget {
  final ManuscriptBinderProvider provider;
  final ValueChanged<String> onDocumentSelected;

  const ManuscriptCollections({
    super.key,
    required this.provider,
    required this.onDocumentSelected,
  });

  @override
  State<ManuscriptCollections> createState() => _ManuscriptCollectionsState();
}

class _ManuscriptCollectionsState extends State<ManuscriptCollections> {
  CollectionType _selectedCollection = CollectionType.allDocuments;
  String? _selectedCustomCollectionId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  ManuscriptCollectionsService? _service;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ManuscriptCollectionsService get _collectionsService {
    return _service ??= ManuscriptCollectionsService(
      projectId: widget.provider.projectId,
      collectionBox: DatabaseManager.instance.manuscriptCollections,
      documentBox: DatabaseManager.instance.manuscriptDocuments,
      referenceEngine: widget.provider.referenceEngine,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const Divider(height: 1),
        _buildCollectionTabs(context),
        const Divider(height: 1),
        _buildSearchBar(context),
        const Divider(height: 1),
        Expanded(child: _buildResultsList(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.folderSearch, color: cs.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collections',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Smart views and filtered document lists',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('New Collection'),
            onPressed: _showCreateCollectionDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionTabs(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final customCollections = _collectionsService.getAllCollections();

    return Container(
      color: cs.surfaceContainerHighest,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ...CollectionType.values.map((type) {
              final isSelected =
                  _selectedCollection == type &&
                  _selectedCustomCollectionId == null;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getIconForType(type), size: 16),
                      const SizedBox(width: 6),
                      Text(type.label),
                      const SizedBox(width: 6),
                      _buildCountBadge(type),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() {
                    _selectedCollection = type;
                    _selectedCustomCollectionId = null;
                  }),
                  showCheckmark: false,
                  selectedColor: cs.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              );
            }),
            if (customCollections.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: VerticalDivider(width: 1),
              ),
              const SizedBox(width: 8),
              Text(
                'Custom',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              ...customCollections.map((collection) {
                final isSelected = _selectedCustomCollectionId == collection.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.tag, size: 16),
                        const SizedBox(width: 6),
                        Text(collection.name),
                      ],
                    ),
                    onDeleted: () {
                      _collectionsService.deleteCollection(collection.id);
                      if (_selectedCustomCollectionId == collection.id) {
                        setState(() {
                          _selectedCustomCollectionId = null;
                          _selectedCollection = CollectionType.allDocuments;
                        });
                      }
                      setState(() {});
                    },
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      _selectedCustomCollectionId = collection.id;
                      _selectedCollection = CollectionType.allDocuments;
                    }),
                    showCheckmark: false,
                    selectedColor: cs.secondaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? cs.onSecondaryContainer
                          : cs.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge(CollectionType type) {
    final count = _getCountForCollection(type);
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cs.surfaceContainerHighest,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search in $_currentCollectionLabel...',
          prefixIcon: Icon(LucideIcons.search, color: cs.onSurfaceVariant),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: cs.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          filled: true,
          fillColor: cs.surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    final results = _getFilteredResults();

    if (results.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final doc = results[index];
        return _CollectionListTile(
          document: doc,
          provider: widget.provider,
          onTap: () => widget.onDocumentSelected(doc.id),
          onToggleFavorite: () => _toggleFavorite(doc.id),
        );
      },
    );
  }

  Future<void> _toggleFavorite(String documentId) async {
    await widget.provider.toggleFavorite(documentId);
    if (mounted) setState(() {});
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? LucideIcons.searchX
                : LucideIcons.folderOpen,
            size: 64,
            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : 'No documents in $_currentCollectionLabel',
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Text('Clear search'),
            ),
        ],
      ),
    );
  }

  List<ManuscriptDocument> _getFilteredResults() {
    List<ManuscriptDocument> docs;

    if (_selectedCustomCollectionId != null) {
      ManuscriptCollection? collection;
      for (final c in _collectionsService.getAllCollections()) {
        if (c.id == _selectedCustomCollectionId) {
          collection = c;
          break;
        }
      }
      docs = collection != null
          ? _collectionsService.documentsForCollection(collection)
          : <ManuscriptDocument>[];
    } else {
      docs = _getDocumentsForCollection(_selectedCollection);
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      docs = docs.where((doc) {
        return doc.title.toLowerCase().contains(query) ||
            (doc.summary?.toLowerCase().contains(query) ?? false) ||
            (doc.richTextJson?.toLowerCase().contains(query) ?? false) ||
            (doc.plotline?.toLowerCase().contains(query) ?? false) ||
            doc.characterIds.any((id) => id.toLowerCase().contains(query)) ||
            doc.tagIds.any((id) => id.toLowerCase().contains(query));
      }).toList();
    }

    return docs;
  }

  List<ManuscriptDocument> _getDocumentsForCollection(CollectionType type) {
    return switch (type) {
      CollectionType.allDocuments => widget.provider.allDocuments,
      CollectionType.manuscript => widget.provider.getDocumentsByType(
        ManuscriptDocumentType.manuscript,
      ),
      CollectionType.parts => widget.provider.getDocumentsByType(
        ManuscriptDocumentType.part,
      ),
      CollectionType.chapters => widget.provider.getDocumentsByType(
        ManuscriptDocumentType.chapter,
      ),
      CollectionType.scenes => widget.provider.getDocumentsByType(
        ManuscriptDocumentType.scene,
      ),
      CollectionType.notes => widget.provider.getDocumentsByType(
        ManuscriptDocumentType.note,
      ),
      CollectionType.research => widget.provider.getDocumentsByType(
        ManuscriptDocumentType.research,
      ),
      CollectionType.frontMatter => widget.provider.getDocumentsByType(
        ManuscriptDocumentType.frontMatter,
      ),
      CollectionType.backMatter => widget.provider.getDocumentsByType(
        ManuscriptDocumentType.backMatter,
      ),
      CollectionType.draft => widget.provider.getDocumentsByStatus(
        ManuscriptDocumentStatus.draft,
      ),
      CollectionType.revised => widget.provider.getDocumentsByStatus(
        ManuscriptDocumentStatus.revised,
      ),
      CollectionType.complete => widget.provider.getDocumentsByStatus(
        ManuscriptDocumentStatus.complete,
      ),
      CollectionType.needsRevision => widget.provider.getDocumentsByStatus(
        ManuscriptDocumentStatus.revised,
      ),
      CollectionType.archived => widget.provider.getDocumentsByStatus(
        ManuscriptDocumentStatus.archived,
      ),
      CollectionType.recent => _getRecentDocuments(),
      CollectionType.favorites => _getFavorites(),
    };
  }

  List<ManuscriptDocument> _getRecentDocuments() {
    final docs = List<ManuscriptDocument>.from(widget.provider.allDocuments);
    docs.sort(
      (a, b) => (b.modifiedAt ?? DateTime(1970)).compareTo(
        a.modifiedAt ?? DateTime(1970),
      ),
    );
    return docs.take(20).toList();
  }

  List<ManuscriptDocument> _getFavorites() {
    return widget.provider.allDocuments.where((d) => d.isFavorite).toList();
  }

  int _getCountForCollection(CollectionType type) {
    return _getDocumentsForCollection(type).length;
  }

  String get _currentCollectionLabel {
    if (_selectedCustomCollectionId != null) {
      for (final c in _collectionsService.getAllCollections()) {
        if (c.id == _selectedCustomCollectionId) return c.name;
      }
    }
    return _selectedCollection.label;
  }

  void _showCreateCollectionDialog() {
    final nameController = TextEditingController();
    ManuscriptDocumentType? filterType;
    ManuscriptDocumentStatus? filterStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Smart Collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Collection Name',
                  hintText: "e.g., Aria's Scenes, War Chapter",
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ManuscriptDocumentType>(
                initialValue: filterType,
                decoration: const InputDecoration(
                  labelText: 'Filter by Type (optional)',
                ),
                hint: const Text('Any Type'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any Type')),
                  ...ManuscriptDocumentType.values.map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                  ),
                ],
                onChanged: (v) => setState(() => filterType = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ManuscriptDocumentStatus>(
                initialValue: filterStatus,
                decoration: const InputDecoration(
                  labelText: 'Filter by Status (optional)',
                ),
                hint: const Text('Any Status'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Any Status'),
                  ),
                  ...ManuscriptDocumentStatus.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                  ),
                ],
                onChanged: (v) => setState(() => filterStatus = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _createCustomCollection(
                  nameController.text,
                  filterType,
                  filterStatus,
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _createCustomCollection(
    String name,
    ManuscriptDocumentType? type,
    ManuscriptDocumentStatus? status,
  ) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection name cannot be empty')),
      );
      return;
    }

    _collectionsService.createCollection(
      name: trimmed,
      documentType: type,
      status: status,
    );
    setState(() {});
  }

  IconData _getIconForType(CollectionType type) {
    return type.icon;
  }
}

class _CollectionListTile extends StatelessWidget {
  final ManuscriptDocument document;
  final ManuscriptBinderProvider provider;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _CollectionListTile({
    required this.document,
    required this.provider,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              _getIconForDocType(document.documentType),
              size: 20,
              color: _getColorForDocType(document.documentType, cs),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          document.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _TypeBadge(documentType: document.documentType),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _StatusBadge(status: document.status),
                      const SizedBox(width: 8),
                      if (document.wordCount > 0)
                        Text(
                          '${_formatCount(document.wordCount)} words',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      if (document.documentType ==
                              ManuscriptDocumentType.chapter ||
                          document.documentType ==
                              ManuscriptDocumentType.part) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${provider.getChildren(document.id).length} children',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onToggleFavorite,
              tooltip: document.isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              icon: Icon(
                document.isFavorite ? LucideIcons.star : LucideIcons.star,
                size: 16,
                color: document.isFavorite
                    ? Colors.amber
                    : cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  IconData _getIconForDocType(ManuscriptDocumentType type) {
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

  Color _getColorForDocType(ManuscriptDocumentType type, ColorScheme cs) {
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
}

class _TypeBadge extends StatelessWidget {
  final ManuscriptDocumentType documentType;

  const _TypeBadge({required this.documentType});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (documentType) {
      ManuscriptDocumentType.part => ('Part', cs.tertiary),
      ManuscriptDocumentType.chapter => ('Chapter', cs.secondary),
      ManuscriptDocumentType.scene => ('Scene', cs.primary),
      ManuscriptDocumentType.section => ('Section', cs.tertiary),
      ManuscriptDocumentType.note => ('Note', Colors.amber),
      ManuscriptDocumentType.research => ('Research', Colors.blue),
      ManuscriptDocumentType.frontMatter => ('Front Matter', Colors.purple),
      ManuscriptDocumentType.backMatter => ('Back Matter', Colors.purple),
      _ => ('Doc', cs.outline),
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ManuscriptDocumentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}
