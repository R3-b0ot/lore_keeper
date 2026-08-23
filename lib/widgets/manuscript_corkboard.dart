// lib/widgets/manuscript_corkboard.dart

import 'package:flutter/material.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ManuscriptCorkboard extends StatefulWidget {
  final ManuscriptBinderProvider provider;
  final String containerDocumentId;
  final ValueChanged<String> onDocumentSelected;
  final ValueChanged<String>? onDocumentRenamed;

  const ManuscriptCorkboard({
    super.key,
    required this.provider,
    required this.containerDocumentId,
    required this.onDocumentSelected,
    this.onDocumentRenamed,
  });

  @override
  State<ManuscriptCorkboard> createState() => _ManuscriptCorkboardState();
}

class _ManuscriptCorkboardState extends State<ManuscriptCorkboard> {
  late List<ManuscriptDocument> _cards;
  ManuscriptDocument? _containerDocument;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void didUpdateWidget(covariant ManuscriptCorkboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.containerDocumentId != widget.containerDocumentId) {
      _loadCards();
    }
  }

  void _loadCards() {
    _containerDocument = widget.provider.getDocument(widget.containerDocumentId);
    _cards = widget.provider.getChildren(widget.containerDocumentId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_containerDocument == null) {
      return _buildEmptyContainer(context);
    }

    return Column(
      children: [
        _buildHeader(context),
        const Divider(height: 1),
        Expanded(
          child: _cards.isEmpty ? _buildEmptyState(context) : _buildCorkboardGrid(context),
        ),
      ],
    );
  }

  Widget _buildEmptyContainer(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.folderOpen, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
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
          _buildHeaderIcon(cs),
          const SizedBox(width: 12),
          _buildHeaderTitle(theme),
          const Spacer(),
          _buildAddCardButton(context),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(ColorScheme cs) {
    return Icon(
      _getIconForType(_containerDocument!.documentType),
      color: _getColorForType(_containerDocument!.documentType, cs),
      size: 24,
    );
  }

  Widget _buildHeaderTitle(ThemeData theme) {
    return Expanded(
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
            'Corkboard • ${_cards.length} card${_cards.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardButton(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(LucideIcons.plus, size: 18),
      label: const Text('Add Card'),
      onPressed: _showAddCardDialog,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.squarePen, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No cards yet', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            'Add scenes, notes, or research cards to organize your story',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add First Card'),
            onPressed: _showAddCardDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildCorkboardGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return _CorkboardCard(
          key: ValueKey(card.id),
          document: card,
          index: index,
          onTap: () => widget.onDocumentSelected(card.id),
          onReorder: _onReorder,
          onDelete: () => _confirmDelete(card),
          onDuplicate: () => _duplicateCard(card),
          onEditMetadata: () => _showEditMetadataDialog(card),
        );
      },
    );
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    final card = _cards.removeAt(oldIndex);
    _cards.insert(newIndex, card);

    for (int i = 0; i < _cards.length; i++) {
      _cards[i].orderIndex = i;
      await widget.provider.updateMetadata(_cards[i].id, isExpanded: _cards[i].isExpanded);
    }

    setState(() {});
    widget.onDocumentSelected(card.id);
  }

  void _showAddCardDialog() {
    final titleController = TextEditingController();
    final selectedTypeNotifier = ValueNotifier<ManuscriptDocumentType>(_getDefaultChildType());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Card'),
          content: _buildAddCardDialogContent(setState, selectedTypeNotifier, titleController),
          actions: _buildAddCardDialogActions(setState, selectedTypeNotifier, titleController),
        ),
      ),
    );
  }

  Widget _buildAddCardDialogContent(StateSetter setState, ValueNotifier<ManuscriptDocumentType> selectedType, TextEditingController titleController) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTypeDropdown(setState, selectedType),
        const SizedBox(height: 12),
        _buildTitleTextField(titleController, selectedType),
      ],
    );
  }

  Widget _buildTypeDropdown(StateSetter setState, ValueNotifier<ManuscriptDocumentType> selectedType) {
    return DropdownButtonFormField<ManuscriptDocumentType>(
      value: selectedType.value,
      decoration: const InputDecoration(labelText: 'Type'),
      items: ManuscriptDocumentType.values
          .where((t) => _isValidChildType(t))
          .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          selectedType.value = v;
          setState(() {});
        }
      },
    );
  }

  Widget _buildTitleTextField(TextEditingController titleController, ValueNotifier<ManuscriptDocumentType> selectedType) {
    return TextField(
      controller: titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        hintText: 'Enter card title',
      ),
      autofocus: true,
      onSubmitted: (_) => _createCard(selectedType.value, titleController.text),
    );
  }

  List<Widget> _buildAddCardDialogActions(StateSetter setState, ValueNotifier<ManuscriptDocumentType> selectedType, TextEditingController titleController) {
    return [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => _createCard(selectedType.value, titleController.text), child: const Text('Create')),
    ];
  }

  void _createCard(ManuscriptDocumentType type, String title) {
    if (title.trim().isEmpty) return;
    Navigator.pop(context);

    widget.provider.createChild(
      parentId: widget.containerDocumentId,
      title: title.trim(),
      type: type,
    ).then((doc) {
      _loadCards();
      widget.onDocumentSelected(doc.id);
    });
  }

  void _duplicateCard(ManuscriptDocument card) async {
    final copy = await widget.provider.createChild(
      parentId: widget.containerDocumentId,
      title: '${card.title} (Copy)',
      type: card.documentType,
      orderIndex: _cards.indexOf(card) + 1,
      richTextJson: card.richTextJson,
      status: card.status,
      summary: card.summary,
      povCharacterId: card.povCharacterId,
      locationId: card.locationId,
      timelineEventId: card.timelineEventId,
      plotline: card.plotline,
      characterIds: card.characterIds,
      tagIds: card.tagIds,
    );
    _loadCards();
    widget.onDocumentSelected(copy.id);
  }

  void _confirmDelete(ManuscriptDocument card) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Delete "${card.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () { Navigator.pop(context); _deleteCard(card); },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteCard(ManuscriptDocument card) async {
    await widget.provider.deleteDocument(card.id);
    _loadCards();
    if (_cards.isNotEmpty) {
      widget.onDocumentSelected(_cards.first.id);
    } else {
      widget.onDocumentSelected(widget.containerDocumentId);
    }
  }

  void _showEditMetadataDialog(ManuscriptDocument card) {
    final controllers = _createMetadataControllers(card);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${card.title} Metadata'),
        content: _buildMetadataDialogContent(controllers),
        actions: _buildMetadataDialogActions(controllers, card),
      ),
    );
  }

  _MetadataControllers _createMetadataControllers(ManuscriptDocument card) {
    return _MetadataControllers(
      summary: TextEditingController(text: card.summary ?? ''),
      pov: TextEditingController(text: card.povCharacterId ?? ''),
      location: TextEditingController(text: card.locationId ?? ''),
      timeline: TextEditingController(text: card.timelineEventId ?? ''),
      plotline: TextEditingController(text: card.plotline ?? ''),
    );
  }

  Widget _buildMetadataDialogContent(_MetadataControllers controllers) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialogTextField(controllers.summary, 'Summary', maxLines: 3),
          const SizedBox(height: 12),
          _buildDialogTextField(controllers.pov, 'POV Character ID'),
          const SizedBox(height: 12),
          _buildDialogTextField(controllers.location, 'Location ID'),
          const SizedBox(height: 12),
          _buildDialogTextField(controllers.timeline, 'Timeline Event ID'),
          const SizedBox(height: 12),
          _buildDialogTextField(controllers.plotline, 'Plotline'),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
    );
  }

  List<Widget> _buildMetadataDialogActions(_MetadataControllers controllers, ManuscriptDocument card) {
    return [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          Navigator.pop(context);
          _updateMetadata(card, controllers);
        },
        child: const Text('Save'),
      ),
    ];
  }

  void _updateMetadata(ManuscriptDocument card, _MetadataControllers controllers) async {
    await widget.provider.updateMetadata(
      card.id,
      summary: controllers.summary.text.isEmpty ? null : controllers.summary.text,
      povCharacterId: controllers.pov.text.isEmpty ? null : controllers.pov.text,
      locationId: controllers.location.text.isEmpty ? null : controllers.location.text,
      timelineEventId: controllers.timeline.text.isEmpty ? null : controllers.timeline.text,
      plotline: controllers.plotline.text.isEmpty ? null : controllers.plotline.text,
    );
    _loadCards();
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
      ManuscriptDocumentType.manuscript => [ManuscriptDocumentType.part, ManuscriptDocumentType.chapter, ManuscriptDocumentType.frontMatter, ManuscriptDocumentType.backMatter].contains(type),
      ManuscriptDocumentType.part => [ManuscriptDocumentType.chapter, ManuscriptDocumentType.section].contains(type),
      ManuscriptDocumentType.chapter => [ManuscriptDocumentType.scene].contains(type),
      ManuscriptDocumentType.section => [ManuscriptDocumentType.scene, ManuscriptDocumentType.note, ManuscriptDocumentType.research].contains(type),
      _ => false,
    };
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

class _MetadataControllers {
  final TextEditingController summary;
  final TextEditingController pov;
  final TextEditingController location;
  final TextEditingController timeline;
  final TextEditingController plotline;

  _MetadataControllers({
    required this.summary,
    required this.pov,
    required this.location,
    required this.timeline,
    required this.plotline,
  });
}

class _CorkboardCard extends StatelessWidget {
  final ManuscriptDocument document;
  final int index;
  final VoidCallback onTap;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onEditMetadata;

  const _CorkboardCard({
    super.key,
    required this.document,
    required this.index,
    required this.onTap,
    required this.onReorder,
    required this.onDelete,
    required this.onDuplicate,
    required this.onEditMetadata,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return RepaintBoundary(
      child: Material(
        color: cs.surfaceContainerHighest,
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onSecondaryTap: _showContextMenu,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(context, cs),
              _buildCardContent(context, theme, cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          _buildDragHandle(context),
          const SizedBox(width: 8),
          _TypeBadge(documentType: document.documentType),
          const Spacer(),
          _StatusBadge(status: document.status),
          const SizedBox(width: 4),
          _buildMenuButton(context, cs),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Icon(LucideIcons.gripVertical, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );
  }

  Widget _buildMenuButton(BuildContext context, ColorScheme cs) {
    return PopupMenuButton<String>(
      icon: Icon(LucideIcons.moreVertical, size: 16, color: cs.onSurfaceVariant),
      onSelected: _handleMenuSelection,
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: _buildMenuItem(LucideIcons.edit, 'Edit Metadata')),
        PopupMenuItem(value: 'duplicate', child: _buildMenuItem(LucideIcons.copy, 'Duplicate')),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'delete', child: _buildMenuItem(LucideIcons.trash2, 'Delete', color: Colors.red)),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String text, {Color? color}) {
    return Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 8), Text(text, style: TextStyle(color: color))]);
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'edit': onEditMetadata(); break;
      case 'duplicate': onDuplicate(); break;
      case 'delete': onDelete(); break;
    }
  }

  Widget _buildCardContent(BuildContext context, ThemeData theme, ColorScheme cs) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(document.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            if (document.summary != null && document.summary!.isNotEmpty) ...[
              Text(document.summary!, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
            ],
            if (document.isLeaf) _buildMetadataPreview(theme, cs),
            const Spacer(),
            _buildCardFooter(theme, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataPreview(ThemeData theme, ColorScheme cs) {
    return Column(
      children: [
        _MetadataRow(icon: LucideIcons.user, label: 'POV', value: document.povCharacterId ?? '—'),
        _MetadataRow(icon: LucideIcons.mapPin, label: 'Location', value: document.locationId ?? '—'),
        _MetadataRow(icon: LucideIcons.calendar, label: 'Timeline', value: document.timelineEventId ?? '—'),
        if (document.plotline != null && document.plotline!.isNotEmpty)
          _MetadataRow(icon: LucideIcons.gitBranch, label: 'Plotline', value: document.plotline!),
      ],
    );
  }

  Widget _buildCardFooter(ThemeData theme, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (document.wordCount > 0)
          Text('${_formatCount(document.wordCount)} words', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        Text('#${index + 1}', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
      ],
    );
  }

  void _showContextMenu() {
    // Handled by PopupMenuButton
  }

  String _formatCount(int count) => count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : count.toString();
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 10)),
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
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 9)),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetadataRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text('$label: ', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}