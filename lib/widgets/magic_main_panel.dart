import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/models/magic_node.dart';
import 'package:lore_keeper/providers/magic_tree_provider.dart';
import 'package:lore_keeper/utils/magic_icons.dart';
import 'package:lore_keeper/utils/magic_type_specs.dart';

class MagicMainPanel extends StatelessWidget {
  final MagicTreeProvider provider;

  const MagicMainPanel({super.key, required this.provider});

  static List<String> _typeOptions() => magicTypeKeysForDropdown();
  static const Set<String> _nonEditableTypes = {
    'magic_system',
    'fuel_category',
    'trigger_category',
    'discipline_category',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.bgPanel : AppColors.bgPanelLight;
    final panelLighter = isDark
        ? AppColors.bgPanelLighter
        : AppColors.bgPanelLighterLight;
    final node = provider.selectedNode;

    if (node == null) {
      return Center(
        child: Text(
          'Select an entry from the list',
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    if (_nonEditableTypes.contains(node.type)) {
      return Container(
        color: isDark ? AppColors.bgMain : AppColors.bgMainLight,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Select a fuel, trigger, discipline, spell, or enchantment to edit.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    return Container(
      color: isDark ? AppColors.bgMain : AppColors.bgMainLight,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _HeaderRow(
            node: node,
            provider: provider,
            panelLighter: panelLighter,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _ImageCard(
                        node: node,
                        provider: provider,
                        panelColor: panelColor,
                        panelLighter: panelLighter,
                      ),
                      const SizedBox(height: 16),
                      _ContentCard(
                        node: node,
                        provider: provider,
                        panelColor: panelColor,
                        panelLighter: panelLighter,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _AttributesCard(
                    node: node,
                    provider: provider,
                    panelColor: panelColor,
                    panelLighter: panelLighter,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final MagicNode node;
  final MagicTreeProvider provider;
  final Color panelLighter;

  const _HeaderRow({
    required this.node,
    required this.provider,
    required this.panelLighter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = magicIconMap[node.iconKey] ?? LucideIcons.bookOpen;
    final isRoot = provider.selectedSystem?.rootNodeId == node.id;
    String dropdownValue = node.type;
    String? migrateTo;
    if (node.type == 'category') {
      dropdownValue = 'discipline_category';
      migrateTo = 'discipline_category';
    } else if (node.type == 'system') {
      dropdownValue = 'magic_system';
      migrateTo = 'magic_system';
    } else if (node.type == 'system_category') {
      dropdownValue = 'discipline_category';
      migrateTo = 'discipline_category';
    } else if (node.type == 'spell_category') {
      dropdownValue = 'spells_category';
      migrateTo = 'spells_category';
    } else if (node.type == 'enchantment_category') {
      dropdownValue = 'enchantments_category';
      migrateTo = 'enchantments_category';
    } else if (node.type == 'method') {
      dropdownValue = 'trigger';
      migrateTo = 'trigger';
    } else if (node.type == 'fuel_cat') {
      dropdownValue = 'fuel_category';
      migrateTo = 'fuel_category';
    } else if (node.type == 'usage_cat') {
      dropdownValue = 'trigger_category';
      migrateTo = 'trigger_category';
    } else if (node.type == 'schools_cat') {
      dropdownValue = 'discipline_category';
      migrateTo = 'discipline_category';
    } else if (node.type == 'school') {
      dropdownValue = 'discipline';
      migrateTo = 'discipline';
    } else if (node.type == 'spells_cat') {
      dropdownValue = 'spells_category';
      migrateTo = 'spells_category';
    } else if (node.type == 'enchantments_cat') {
      dropdownValue = 'enchantments_category';
      migrateTo = 'enchantments_category';
    } else if (node.type == 'indi_use') {
      dropdownValue = 'trigger';
      migrateTo = 'trigger';
    }

    if (migrateTo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.updateNodeType(node.id, migrateTo!);
      });
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => _showIconPicker(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: panelLighter,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Icon(iconData, color: Color(node.colorValue), size: 28),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DropdownButton<String>(
                    value: dropdownValue,
                    items: MagicMainPanel._typeOptions()
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(specForType(type).label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.updateNodeType(node.id, value);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showColorPicker(context),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Color(node.colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                key: ValueKey('magic-title-${node.id}'),
                initialValue: node.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                ),
                onChanged: (value) => provider.updateNodeTitle(node.id, value),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (!isRoot)
          IconButton(
            onPressed: () => provider.deleteNode(node.id),
            icon: const Icon(LucideIcons.trash2),
            tooltip: 'Delete',
          ),
      ],
    );
  }

  Future<void> _showIconPicker(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => const _IconPickerDialog(),
    );
    if (selected != null) {
      provider.updateNodeIcon(node.id, selected);
    }
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (context) => const _ColorPickerDialog(),
    );
    if (selected != null) {
      provider.updateNodeColor(node.id, selected);
    }
  }
}

class _ImageCard extends StatefulWidget {
  final MagicNode node;
  final MagicTreeProvider provider;
  final Color panelColor;
  final Color panelLighter;

  const _ImageCard({
    required this.node,
    required this.provider,
    required this.panelColor,
    required this.panelLighter,
  });

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard> {
  static const String _defaultState = 'Base';
  String _selectedState = _defaultState;

  @override
  void initState() {
    super.initState();
    _syncSelectedState(force: true);
  }

  @override
  void didUpdateWidget(covariant _ImageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      _selectedState = _defaultState;
    }
    _syncSelectedState();
  }

  void _syncSelectedState({bool force = false}) {
    final states = _collectStates();
    if (states.isEmpty) {
      if (force) {
        _selectedState = _defaultState;
      } else if (_selectedState != _defaultState && mounted) {
        setState(() => _selectedState = _defaultState);
      }
      return;
    }
    if (!states.contains(_selectedState)) {
      if (force) {
        _selectedState = states.first;
      } else if (mounted) {
        setState(() => _selectedState = states.first);
      }
    }
  }

  String _normalizeState(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? _defaultState : trimmed;
  }

  List<String> _collectStates() {
    final states = <String>{};
    for (final image in widget.node.images) {
      states.add(_normalizeState(image.state));
    }
    if (states.isEmpty) {
      states.add(_defaultState);
    }
    return states.toList();
  }

  List<MapEntry<int, MagicImage>> _imagesForState() {
    final selected = _normalizeState(_selectedState);
    return widget.node.images.asMap().entries.where((entry) {
      return _normalizeState(entry.value.state) == selected;
    }).toList();
  }

  Future<void> _addImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;

    final image = await _showImageMetaDialog(bytes, state: _selectedState);
    if (image == null) return;

    await widget.provider.addImage(widget.node.id, image);
    if (!mounted) return;
    setState(() => _selectedState = _normalizeState(image.state));
  }

  Future<void> _editImage(int index, MagicImage image) async {
    final updated = await _showImageMetaDialog(
      image.imageData,
      caption: image.caption,
      state: image.state,
      allowDelete: true,
      onDelete: () => widget.provider.deleteImage(widget.node.id, index),
    );
    if (updated == null) return;

    await widget.provider.updateImage(
      widget.node.id,
      index,
      caption: updated.caption,
      state: updated.state,
    );
    if (!mounted) return;
    setState(() => _selectedState = _normalizeState(updated.state));
  }

  Future<MagicImage?> _showImageMetaDialog(
    Uint8List bytes, {
    String? caption,
    String? state,
    bool allowDelete = false,
    VoidCallback? onDelete,
  }) async {
    final captionController = TextEditingController(text: caption ?? '');
    final stateController = TextEditingController(
      text: state ?? _selectedState,
    );

    final result = await showDialog<MagicImage>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Image Details'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(bytes, height: 160, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stateController,
                  decoration: const InputDecoration(labelText: 'State'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: captionController,
                  decoration: const InputDecoration(labelText: 'Caption'),
                ),
              ],
            ),
          ),
          actions: [
            if (allowDelete)
              TextButton.icon(
                onPressed: () {
                  onDelete?.call();
                  Navigator.of(context).pop();
                },
                icon: const Icon(LucideIcons.trash2),
                label: const Text('Delete'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(
                  MagicImage(
                    imageData: bytes,
                    caption: captionController.text.trim(),
                    state: _normalizeState(stateController.text),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    captionController.dispose();
    stateController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final states = _collectStates();
    final images = _imagesForState();

    return _MagicPanelCard(
      title: 'Image',
      panelColor: widget.panelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final state in states)
                        ChoiceChip(
                          label: Text(state),
                          selected: _selectedState == state,
                          onSelected: (_) {
                            setState(() => _selectedState = state);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _addImage,
                icon: const Icon(LucideIcons.imagePlus),
                label: const Text('Add Image'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (images.isEmpty)
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: widget.panelLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.image,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add an image for this state',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final entry = images[index];
                  return _MagicImageTile(
                    image: entry.value,
                    panelLighter: widget.panelLighter,
                    onEdit: () => _editImage(entry.key, entry.value),
                    onDelete: () =>
                        widget.provider.deleteImage(widget.node.id, entry.key),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MagicImageTile extends StatelessWidget {
  final MagicImage image;
  final Color panelLighter;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MagicImageTile({
    required this.image,
    required this.panelLighter,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(image.imageData, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: panelLighter.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.ellipsis, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Tooltip(
            message: image.caption.isEmpty ? 'No caption' : image.caption,
            child: Text(
              image.caption.isEmpty ? 'Untitled' : image.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatefulWidget {
  final MagicNode node;
  final MagicTreeProvider provider;
  final Color panelColor;
  final Color panelLighter;

  const _ContentCard({
    required this.node,
    required this.provider,
    required this.panelColor,
    required this.panelLighter,
  });

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _saveTimer;
  late String _nodeId;

  @override
  void initState() {
    super.initState();
    _nodeId = widget.node.id;
    _controller = _buildController(widget.node.content);
    _controller.addListener(_onDocumentChanged);
  }

  @override
  void didUpdateWidget(covariant _ContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      _controller.removeListener(_onDocumentChanged);
      _controller.dispose();
      _nodeId = widget.node.id;
      _controller = _buildController(widget.node.content);
      _controller.addListener(_onDocumentChanged);
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _controller.removeListener(_onDocumentChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  QuillController _buildController(String rawContent) {
    if (rawContent.trim().isEmpty) {
      return QuillController.basic();
    }
    try {
      final decoded = jsonDecode(rawContent);
      if (decoded is List) {
        final document = Document.fromJson(decoded);
        return QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (_) {}

    final document = Document()..insert(0, rawContent);
    return QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _onDocumentChanged() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), () {
      final deltaJson = _controller.document.toDelta().toJson();
      final encoded = jsonEncode(deltaJson);
      widget.provider.updateNodeContent(_nodeId, encoded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _MagicPanelCard(
        title: 'Lore',
        panelColor: widget.panelColor,
        expandContent: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: widget.panelLighter,
                borderRadius: BorderRadius.circular(10),
              ),
              child: QuillSimpleToolbar(
                controller: _controller,
                config: const QuillSimpleToolbarConfig(
                  showFontFamily: false,
                  showFontSize: false,
                  showBoldButton: true,
                  showItalicButton: true,
                  showUnderLineButton: true,
                  showStrikeThrough: true,
                  showInlineCode: true,
                  showClearFormat: true,
                  showAlignmentButtons: true,
                  showHeaderStyle: true,
                  showListNumbers: true,
                  showListBullets: true,
                  showListCheck: true,
                  showCodeBlock: true,
                  showQuote: true,
                  showIndent: true,
                  showLink: true,
                  showUndo: true,
                  showRedo: true,
                  showSearchButton: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.panelLighter,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QuillEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  config: const QuillEditorConfig(
                    padding: EdgeInsets.all(16),
                    autoFocus: false,
                    expands: true,
                    placeholder: 'Describe the lore and context...',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributesCard extends StatelessWidget {
  final MagicNode node;
  final MagicTreeProvider provider;
  final Color panelColor;
  final Color panelLighter;

  const _AttributesCard({
    required this.node,
    required this.provider,
    required this.panelColor,
    required this.panelLighter,
  });

  @override
  Widget build(BuildContext context) {
    return _MagicPanelCard(
      title: 'Properties',
      panelColor: panelColor,
      expandContent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: node.attributes.length,
              itemBuilder: (context, index) {
                final attr = node.attributes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('magic-attr-key-${node.id}-$index'),
                              initialValue: attr.label,
                              decoration: const InputDecoration(
                                labelText: 'Key',
                              ),
                              onChanged: (value) => provider.updateAttribute(
                                node.id,
                                index,
                                label: value,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                provider.deleteAttribute(node.id, index),
                            icon: const Icon(LucideIcons.x),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: ValueKey('magic-attr-value-${node.id}-$index'),
                        initialValue: attr.value,
                        decoration: const InputDecoration(labelText: 'Value'),
                        onChanged: (value) => provider.updateAttribute(
                          node.id,
                          index,
                          value: value,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => provider.addAttribute(node.id),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Property'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MagicPanelCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color panelColor;
  final bool expandContent;

  const _MagicPanelCard({
    required this.title,
    required this.child,
    required this.panelColor,
    this.expandContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: panelColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppColors.panelTitlePadding,
            child: Text(title, style: AppColors.panelTitleStyle(context)),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          if (expandContent)
            Expanded(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            )
          else
            Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _IconPickerDialog extends StatelessWidget {
  const _IconPickerDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Select Icon'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            children: magicIconCategories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.label, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: category.icons
                          .map(
                            (iconKey) => IconButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(iconKey),
                              icon: Icon(
                                magicIconMap[iconKey] ?? LucideIcons.bookOpen,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ColorPickerDialog extends StatelessWidget {
  const _ColorPickerDialog();

  static const List<Color> _palette = [
    AppColors.primary,
    AppColors.primaryDark,
    AppColors.primaryLight,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    AppColors.borderDark,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Color'),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _palette
            .map(
              (color) => GestureDetector(
                onTap: () => Navigator.of(context).pop(color),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
