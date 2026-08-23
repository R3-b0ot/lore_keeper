// lib/widgets/manuscript_outliner.dart

import 'package:flutter/material.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum OutlinerColumn {
  title('Title'),
  pov('POV'),
  location('Location'),
  timeline('Timeline'),
  words('Words'),
  status('Status'),
  plotline('Plotline');

  const OutlinerColumn(this.label);
  final String label;
}

class ManuscriptOutliner extends StatefulWidget {
  final ManuscriptBinderProvider provider;
  final String containerDocumentId;
  final ValueChanged<String> onDocumentSelected;

  const ManuscriptOutliner({
    super.key,
    required this.provider,
    required this.containerDocumentId,
    required this.onDocumentSelected,
  });

  @override
  State<ManuscriptOutliner> createState() => _ManuscriptOutlinerState();
}

class _ManuscriptOutlinerState extends State<ManuscriptOutliner> {
  late List<ManuscriptDocument> _rows;
  ManuscriptDocument? _containerDocument;
  final Set<OutlinerColumn> _visibleColumns = {
    OutlinerColumn.title,
    OutlinerColumn.pov,
    OutlinerColumn.location,
    OutlinerColumn.timeline,
    OutlinerColumn.words,
    OutlinerColumn.status,
    OutlinerColumn.plotline,
  };

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  @override
  void didUpdateWidget(covariant ManuscriptOutliner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.containerDocumentId != widget.containerDocumentId) {
      _loadRows();
    }
  }

  void _loadRows() {
    _containerDocument = widget.provider.getDocument(widget.containerDocumentId);
    _rows = _getAllDescendants(widget.containerDocumentId);
    setState(() {});
  }

  List<ManuscriptDocument> _getAllDescendants(String parentId) {
    final result = <ManuscriptDocument>[];
    final children = widget.provider.getChildren(parentId);
    for (final child in children) {
      result.add(child);
      if (child.isContainer) {
        result.addAll(_getAllDescendants(child.id));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_containerDocument == null) {
      return _buildEmptyContainer(theme, cs);
    }

    return Column(
      children: [
        _buildHeader(theme, cs),
        const Divider(height: 1),
        _buildColumnSelector(theme, cs),
        const Divider(height: 1),
        Expanded(
          child: _rows.isEmpty ? _buildEmptyState(theme, cs) : _buildOutlinerTable(theme, cs),
        ),
      ],
    );
  }

  Widget _buildEmptyContainer(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.list, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Select a container (Part, Chapter, or Manuscript)',
            style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(
            _getIconForType(_containerDocument!.documentType),
            color: _getColorForType(_containerDocument!.documentType, cs),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _containerDocument!.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Outliner • ${_rows.length} item${_rows.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Row'),
            onPressed: _showAddRowDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildColumnSelector(ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cs.surfaceContainerHighest,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: OutlinerColumn.values.map((col) {
            final isVisible = _visibleColumns.contains(col);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(col.label),
                selected: isVisible,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _visibleColumns.add(col);
                    } else {
                      if (_visibleColumns.length > 1) {
                        _visibleColumns.remove(col);
                      }
                    }
                  });
                },
                showCheckmark: false,
                selectedColor: cs.primaryContainer,
                labelStyle: TextStyle(
                  color: isVisible ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  fontWeight: isVisible ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.list, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No items in outline', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add First Row'),
            onPressed: _showAddRowDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildOutlinerTable(ThemeData theme, ColorScheme cs) {
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
          child: DataTable(
            headingRowColor: WidgetStateProperty.resolveWith((states) => cs.surfaceContainer),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return cs.primaryContainer;
              if (states.contains(WidgetState.hovered)) return cs.surfaceContainerHighest;
              return null;
            }),
            columnSpacing: 16,
            horizontalMargin: 16,
            columns: _buildColumns(theme, cs),
            rows: _buildRows(theme, cs),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns(ThemeData theme, ColorScheme cs) {
    return _visibleColumns.map((col) {
      return DataColumn(
        label: Text(
          col.label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        numeric: col == OutlinerColumn.words,
      );
    }).toList();
  }

  List<DataRow> _buildRows(ThemeData theme, ColorScheme cs) {
    return _rows.map((doc) {
      return DataRow(
        onSelectChanged: (_) => widget.onDocumentSelected(doc.id),
        cells: _visibleColumns.map((col) => DataCell(_buildCell(doc, col, theme, cs))).toList(),
      );
    }).toList();
  }

  Widget _buildCell(ManuscriptDocument doc, OutlinerColumn col, ThemeData theme, ColorScheme cs) {
    return switch (col) {
      OutlinerColumn.title => _buildTitleCell(doc, theme, cs),
      OutlinerColumn.pov => _buildTextCell(doc.povCharacterId ?? '—', theme, cs),
      OutlinerColumn.location => _buildTextCell(doc.locationId ?? '—', theme, cs),
      OutlinerColumn.timeline => _buildTextCell(doc.timelineEventId ?? '—', theme, cs),
      OutlinerColumn.words => _buildWordsCell(doc, theme, cs),
      OutlinerColumn.status => _StatusBadge(status: doc.status),
      OutlinerColumn.plotline => _buildTextCell(doc.plotline ?? '—', theme, cs),
    };
  }

  Widget _buildTitleCell(ManuscriptDocument doc, ThemeData theme, ColorScheme cs) {
    return Row(
      children: [
        Icon(_getIconForType(doc.documentType), size: 16, color: _getColorForType(doc.documentType, cs)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            doc.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: doc.documentType == ManuscriptDocumentType.manuscript ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (doc.documentType == ManuscriptDocumentType.manuscript)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ROOT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextCell(String text, ThemeData theme, ColorScheme cs) {
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: text == '—' ? cs.onSurfaceVariant : cs.onSurface,
        fontStyle: text == '—' ? FontStyle.italic : FontStyle.normal,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildWordsCell(ManuscriptDocument doc, ThemeData theme, ColorScheme cs) {
    final totalWords = (doc.wordCount + widget.provider.getDescendants(doc.id).fold(0, (sum, d) => sum + d.wordCount)) as int;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatCount(doc.wordCount),
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        if (totalWords > doc.wordCount) ...[
          const SizedBox(width: 4),
          Text(
            '(${_formatCount(totalWords)} total)',
            style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  void _showAddRowDialog() {
    final titleController = TextEditingController();
    ManuscriptDocumentType selectedType = _getDefaultChildType();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Row'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ManuscriptDocumentType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ManuscriptDocumentType.values
                    .where((t) => _isValidChildType(t))
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title', hintText: 'Enter row title'),
                autofocus: true,
                onSubmitted: (_) => _createRow(selectedType, titleController.text),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => _createRow(selectedType, titleController.text), child: const Text('Create')),
          ],
        ),
      ),
    );
  }

  void _createRow(ManuscriptDocumentType type, String title) {
    if (title.trim().isEmpty) return;
    Navigator.pop(context);

    widget.provider.createChild(
      parentId: widget.containerDocumentId,
      title: title.trim(),
      type: type,
    ).then((doc) {
      _loadRows();
      widget.onDocumentSelected(doc.id);
    });
  }

  ManuscriptDocumentType _getDefaultChildType() {
    return switch (_containerDocument!.documentType) {
      ManuscriptDocumentType.manuscript => ManuscriptDocumentType.part,
      ManuscriptDocumentType.part => ManuscriptDocumentType.chapter,
      ManuscriptDocumentType.chapter => ManuscriptDocumentType.scene,
      ManuscriptDocumentType.section => ManuscriptDocumentType.scene,
      _ => ManuscriptDocumentType.note,
    };
  }

  bool _isValidChildType(ManuscriptDocumentType type) {
    final parentType = _containerDocument!.documentType;
    return switch (parentType) {
      ManuscriptDocumentType.manuscript => [
          ManuscriptDocumentType.part,
          ManuscriptDocumentType.chapter,
          ManuscriptDocumentType.frontMatter,
          ManuscriptDocumentType.backMatter,
        ].contains(type),
      ManuscriptDocumentType.part => [
          ManuscriptDocumentType.chapter,
          ManuscriptDocumentType.section,
        ].contains(type),
      ManuscriptDocumentType.chapter => [ManuscriptDocumentType.scene].contains(type),
      ManuscriptDocumentType.section => [
          ManuscriptDocumentType.scene,
          ManuscriptDocumentType.note,
          ManuscriptDocumentType.research,
        ].contains(type),
      _ => false,
    };
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          fontSize: 10,
        ),
      ),
    );
  }
}