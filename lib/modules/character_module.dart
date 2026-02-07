import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/link.dart';
import 'package:lore_keeper/providers/link_provider.dart';
import 'package:lore_keeper/services/history_service.dart';
import 'package:lore_keeper/screens/relation_chart_screen.dart';
import 'package:lore_keeper/services/relationship_service.dart';
import 'package:lore_keeper/services/global_custom_field_service.dart';
import 'package:lore_keeper/services/global_custom_panel_service.dart';
import 'package:lore_keeper/screens/trait_editor_screen.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/widgets/modern_country_selection_dialog.dart';
import 'package:lore_keeper/widgets/native_crop_dialog.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

enum PanelType { bio, links, image, traits }

class CharacterModule extends StatefulWidget {
  final String characterKey;
  final LinkProvider linkProvider;
  final VoidCallback onReload;

  const CharacterModule({
    super.key,
    required this.characterKey,
    required this.linkProvider,
    required this.onReload,
  });

  @override
  State<CharacterModule> createState() => CharacterModuleState();
}

class CharacterModuleState extends State<CharacterModule>
    with TickerProviderStateMixin {
  Character? _character;
  Timer? _debounce;
  bool _isSaving = false;
  final HistoryService _historyService = HistoryService();
  final GlobalCustomPanelService _customPanelService =
      GlobalCustomPanelService();
  List<PanelType> panelOrder = [
    PanelType.bio,
    PanelType.links,
    PanelType.image,
    PanelType.traits,
  ];

  List<PanelType> singleColumnPanelOrder = [
    PanelType.bio,
    PanelType.image,
    PanelType.links,
  ];

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aliasesController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _customGenderController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  TabController? _tabController;
  int _currentIterationIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.linkProvider.addListener(_rebuild);
    _tabController = TabController(length: 1, vsync: this);
    _customPanelService.init();
    _loadCharacter();
  }

  @override
  void didUpdateWidget(CharacterModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.characterKey != oldWidget.characterKey ||
        _character?.iterations.length != _tabController?.length) {
      _debounce?.cancel(); // Cancel any pending save
      // Reset the iteration index when switching characters to avoid out-of-bounds errors.
      if (widget.characterKey != oldWidget.characterKey) {
        _currentIterationIndex = 0;
      }
      // If the number of iterations has changed, we might need to adjust the index.
      if (_character != null &&
          _currentIterationIndex >= _character!.iterations.length) {
        _currentIterationIndex = _character!.iterations.length - 1;
      }
      _loadCharacter(); // Re-initialize everything for the new character
    }
  }

  void reload() {
    _loadCharacter();
    widget.onReload();
  }

  CharacterIteration get _currentIteration {
    if (_character == null || _character!.iterations.isEmpty) {
      // This is a fallback, should not happen after migration
      return CharacterIteration(
        iterationName: 'The First',
        name: _character?.name,
      );
    }
    return _character!.iterations[_currentIterationIndex];
  }

  void _migrateToIterations() {
    if (_character != null && _character!.iterations.isEmpty) {
      final firstIteration = CharacterIteration(
        iterationName: 'The First',
        name: _character!.name,
        bio: _character!.bio,
        // Also migrate the old top-level lists
        aliases: _character!.aliases, // This was correct
        occupation: _character!.occupation, // This was correct
        gender: _character!.gender,
        customGender: _character!.customGender,
        customPanels: [], // Initialize empty list for custom panels
      );
      _character!.iterations.add(firstIteration);
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _updateUIForCurrentIteration() {
    if (_character == null) return;
    _nameController.text = _currentIteration.name ?? _character!.name;
    _aliasesController.text = (_currentIteration.aliases ?? []).join(', ');
    _occupationController.text = _currentIteration.occupation ?? '';
    _customGenderController.text = _currentIteration.customGender ?? '';
    _bioController.text = _currentIteration.bio ?? '';
  }

  void _onTabTapped(int index) {
    if (_tabController == null || _tabController!.indexIsChanging) {
      return;
    }
    _saveChanges(); // Save current tab before switching
    if (index >= (_character?.iterations.length ?? 0)) {
      // This can happen if a tab is deleted.
      index = (_character?.iterations.length ?? 1) - 1;
    }
    setState(() {
      _currentIterationIndex = index;
      _updateUIForCurrentIteration(); // Update the UI with the new iteration's data
    });
  }

  void _loadCharacter() {
    final box = Hive.box<Character>('characters');
    Character? character;
    // 1. Try to get the character using the key as a String.
    // This is the most common case for non-integer keys.
    character = box.get(widget.characterKey);
    // 2. If not found, try parsing the key as an integer.
    if (character == null) {
      final intKey = int.tryParse(widget.characterKey);
      if (intKey != null) {
        character = box.get(intKey);
      }
    }
    // Now, update the state.
    setState(() {
      _character = character;
      _migrateToIterations();
      final int tabLength = _character?.iterations.isEmpty ?? true
          ? 1
          : _character!.iterations.length;
      if (_tabController?.length != tabLength) {
        _tabController?.dispose();
        _tabController = TabController(
          length: tabLength,
          vsync: this,
          initialIndex: _currentIterationIndex.clamp(0, tabLength - 1),
        );
        _tabController!.addListener(() => _onTabTapped(_tabController!.index));
      }
      _updateUIForCurrentIteration();
    });
  }

  void _onFieldChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 750), () {
      _saveChanges();
    });
  }

  void _reorderSingleColumnPanel(int oldIndex, int newIndex) {
    setState(() {
      final panel = singleColumnPanelOrder.removeAt(oldIndex);
      singleColumnPanelOrder.insert(newIndex, panel);
    });
  }

  void _reorderCustomPanel(int oldIndex, int newIndex) {
    final customPanels = _currentIteration.customPanels;
    if (oldIndex < 0 ||
        oldIndex >= customPanels.length ||
        newIndex < 0 ||
        newIndex >= customPanels.length) {
      return;
    }
    final panel = customPanels.removeAt(oldIndex);
    customPanels.insert(newIndex, panel);
    // Update orders
    for (int i = 0; i < customPanels.length; i++) {
      customPanels[i].order = i;
    }
    _saveChanges();
  }

  Future<void> _saveChanges() async {
    if (_character == null || !mounted) return;
    setState(() {
      _isSaving = true;
    });
    // Save to the current iteration
    _currentIteration.name = _nameController.text;
    _currentIteration.aliases = _aliasesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _currentIteration.occupation = _occupationController.text;
    _currentIteration.customGender = _customGenderController.text;
    _currentIteration.bio = _bioController.text;
    // --- HISTORY LOGIC (Moved) ---
    // Save the character's state *after* applying changes but before final save.
    // We use the _character object itself as it now holds the new data.
    if (_character != null) {
      await _historyService.addHistoryEntry(
        targetKey: _character!.key,
        targetType: 'Character',
        objectToSave: _character!,
        projectId: _character!.parentProjectId,
      );
    }
    // --- END HISTORY LOGIC ---
    await _character!.save();
    debugPrint("Character '${_character!.name}' saved.");
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _showNewIterationDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _NewIterationDialog(),
    );
    if (!mounted) return;
    if (result != null && result['name'] != null) {
      final String name = result['name'] as String;
      final bool importData = result['import'] as bool? ?? false;
      final newIteration = CharacterIteration(iterationName: name);
      if (importData) {
        final sourceIteration = _currentIteration;
        newIteration.name = sourceIteration.name;
        newIteration.aliases = List.from(sourceIteration.aliases ?? []);
        newIteration.occupation = sourceIteration.occupation;
        newIteration.gender = sourceIteration.gender;
        newIteration.customGender = sourceIteration.customGender;
        newIteration.bio = sourceIteration.bio;
        newIteration.originCountry = sourceIteration.originCountry;
      } else {
        // When not importing, also initialize trait maps to avoid null issues later.
        newIteration.congenitalTraits = {};
        newIteration.leveledTraits = {};
        newIteration.personalityTraits = {};
        // Default the iteration's name to the character's primary name
        newIteration.name = _character!.name;
      }
      setState(() {
        _character!.iterations.add(newIteration);
        _currentIterationIndex = _character!.iterations.length - 1;
        // Recreate tab controller for new length
        _tabController?.dispose();
        _tabController = TabController(
          length: _character!.iterations.length,
          vsync: this,
          initialIndex: _currentIterationIndex,
        );
        _tabController!.addListener(() => _onTabTapped(_tabController!.index));
      });
      _saveChanges(); // Save the new iteration
    }
  }

  Future<void> _renameIteration(int index) async {
    final iteration = _character!.iterations[index];
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: iteration.iterationName);
        return AlertDialog(
          title: const Text('Rename Iteration'),
          content: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'New Name'),
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Name cannot be empty' : null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (newName != null && newName != iteration.iterationName) {
      setState(() {
        iteration.iterationName = newName;
      });
      _saveChanges();
    }
  }

  Future<void> _deleteIteration(int index) async {
    if (_character!.iterations.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the last iteration.')),
      );
      return;
    }
    final iteration = _character!.iterations[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Iteration'),
        content: Text(
          'Are you sure you want to delete "${iteration.iterationName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _character!.iterations.removeAt(index);
      await _character!.save();
      reload();
    }
  }

  Future<Link?> _showLinkCreationDialog({Link? initialLink}) {
    return showDialog<Link>(
      context: context,
      builder: (context) => _LinkCreationDialog(
        initialLink: initialLink,
        currentCharacterKey: _character?.key,
        currentCharacterIterationIndex: _currentIterationIndex,
        onDelete: (linkToDelete) {
          widget.linkProvider.deleteLink(linkToDelete);
          _saveChanges(); // Log history on delete
        },
      ),
    );
  }

  void _handleLinkAdded(Link? newLink) {
    if (newLink == null || newLink.description.isEmpty) return;
    // --- HISTORY LOGIC for Link Addition ---
    _historyService.addHistoryEntry(
      targetKey: _character!.key,
      targetType: 'Character',
      objectToSave: _character!,
      projectId: _character!.parentProjectId,
    );
    // Set the source of the link to the current character
    newLink.entity1Type = 'Character';
    newLink.entity1Key = _character!.key;
    // Save the source iteration index
    newLink.entity1IterationIndex = _currentIterationIndex;
    widget.linkProvider.addLink(newLink);
    // No need to call _onFieldChanged() as this is now in a separate database
  }

  void _viewRelationChart(BuildContext context, dynamic characterKey) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RelationChartScreen(
          startCharacterKey: characterKey,
          iterationIndex: _currentIterationIndex,
        ),
      ),
    );
  }

  Future<void> _showTraitEditor() async {
    if (_character == null) return;

    // Navigate to the TraitEditorScreen and wait for the result.
    final results = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => TraitEditorScreen(
          initialSelectedTraits: _currentIteration.congenitalTraits,
          // The getter 'leveledTraits' isn't defined for the type 'CharacterIteration'. - This is now fixed in the model
          initialPersonalityTraits: _currentIteration.personalityTraits,
          initialLeveledTraits: _currentIteration.leveledTraits,
        ),
      ),
    );

    // If the user saved changes, update the character's iteration.
    if (results != null) {
      setState(() {
        _currentIteration.congenitalTraits = Set<String>.from(
          results['congenital'] ?? {},
        );
        _currentIteration.leveledTraits = Map<String, int>.from(
          results['leveled'] ?? {},
        );
        _currentIteration.personalityTraits = Map<String, int>.from(
          results['personality'] ?? {},
        );
      });
      _saveChanges(); // Persist the changes
    }
  }

  Future<void> _showAddCustomFieldDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddCustomFieldDialog(),
    );
    if (result != null) {
      final customField = CustomField(
        name: result['name'],
        type: result['type'],
        value: result['value'],
      );
      // Add to global service
      final service = GlobalCustomFieldService();
      await service.init();
      await service.addCustomField(customField);
      // Set initial value in current iteration
      _currentIteration.customFieldValues[customField.name] = customField.value;
      _saveChanges();
    }
  }

  Future<void> _showAddCustomPanelDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddCustomPanelDialog(),
    );
    if (result != null) {
      final customPanel = CustomPanel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name'],
        type: result['type'],
        content: result['content'],
        items: result['items'] ?? [],
        order: _currentIteration.customPanels.length,
        column: result['column'] ?? 'right',
      );
      _currentIteration.customPanels.add(customPanel);
      _saveChanges();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _aliasesController.dispose();
    _occupationController.dispose();
    _customGenderController.dispose();
    _bioController.dispose();
    widget.linkProvider.removeListener(_rebuild);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_character == null) {
      return const Center(child: Text('Character not found.'));
    }
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.bgMain
          : AppColors.bgMainLight,
      child: Column(
        children: [
          // --- REDESIGNED ITERATION SELECTOR ---
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _character!.iterations.length,
                    itemBuilder: (context, index) {
                      final iter = _character!.iterations[index];
                      final isSelected = _currentIterationIndex == index;
                      final colorScheme = Theme.of(context).colorScheme;

                      return GestureDetector(
                        onTap: () {
                          if (_tabController != null &&
                              !_tabController!.indexIsChanging) {
                            _tabController!.animateTo(index);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.5)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    iter.iterationName.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          letterSpacing: 1.2,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.onSurfaceVariant
                                                    .withValues(alpha: 0.6),
                                        ),
                                  ),
                                  Text(
                                    iter.name ?? 'Unnamed',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.onSurface,
                                        ),
                                  ),
                                ],
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.settings,
                                    size: 16,
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'rename') {
                                      _renameIteration(index);
                                    } else if (value == 'delete') {
                                      _deleteIteration(index);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    final canDelete =
                                        _character!.iterations.length > 1;
                                    return [
                                      const PopupMenuItem(
                                        value: 'rename',
                                        child: Text('Rename Iteration'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        enabled: canDelete,
                                        child: Text(
                                          'Delete Iteration',
                                          style: TextStyle(
                                            color: canDelete
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  indent: 12,
                  endIndent: 12,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'New Iteration',
                    onPressed: _showNewIterationDialog,
                  ),
                ),
              ],
            ),
          ),
          // --- END REDESIGNED SELECTOR ---
          // Body
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine if we should use a single column (mobile) or two columns (tablet/desktop)
                final isLargeScreen = constraints.maxWidth > 800;
                return TabBarView(
                  controller: _tabController,
                  children: _character!.iterations.isEmpty
                      ? [const Center(child: CircularProgressIndicator())]
                      : _character!.iterations.map((iteration) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: isLargeScreen
                                ? _buildTwoColumnLayout(context, constraints)
                                : _buildSingleColumnLayout(context),
                          );
                        }).toList(),
                );
              },
            ),
          ),
          // Bottom status bar
          _buildBottomStatusBar(),
        ],
      ),
    );
  }

  // Layout for large screens (two columns) - CORRECTED
  Widget _buildTwoColumnLayout(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column Content
        Flexible(
          flex: 1,
          child: _PanelCard(
            title: 'Basic Information',
            onEdit: _showAddCustomFieldDialog,
            editIcon: Icons.add,
            editTooltip: 'Add Custom Field',
            content: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _BasicInfoForm(
                nameController: _nameController,
                aliasesController: _aliasesController,
                occupationController: _occupationController,
                customGenderController: _customGenderController,
                character: _currentIteration,
                onChanged: _onFieldChanged,
                onStateChanged: () => setState(() {}),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Right Column Content
        Flexible(
          flex: 1,
          child: Column(children: _buildRightColumnPanels(context)),
        ),
      ],
    );
  }

  List<Widget> _buildRightColumnPanels(BuildContext context) {
    final List<Widget> panels = [];
    for (int i = 0; i < panelOrder.length; i++) {
      final panelType = panelOrder[i];
      Widget panelWidget;
      switch (panelType) {
        case PanelType.bio:
          panelWidget = _PanelCard(
            title: 'Bio',
            content: _BioPanel(
              controller: _bioController,
              onChanged: _onFieldChanged,
            ),
          );
          break;
        case PanelType.links:
          panelWidget = _PanelCard(
            title: 'Links',
            content: _LinkPanel(
              character: _character!,
              iterationIndex: _currentIterationIndex,
              linkProvider: widget.linkProvider,
              onAddLink: ({Link? initialLink}) async {
                final newLink = await _showLinkCreationDialog(
                  initialLink: initialLink,
                );
                if (newLink != null) _handleLinkAdded(newLink);
              },
              onLinkAdded: _handleLinkAdded,
              onViewChart: (key) => _viewRelationChart(context, key),
              onReverted: reload,
            ),
          );
          break;
        case PanelType.image:
          panelWidget = _PanelCard(
            title: 'Image',
            content: _ImageUploadPanel(
              iteration: _currentIteration,
              characterIteration: _currentIterationIndex,
              onChanged: _onFieldChanged,
            ),
          );
          break;
        case PanelType.traits:
          panelWidget = _PanelCard(
            title: 'Traits',
            onEdit: _showTraitEditor,
            editIcon: Icons.edit,
            editTooltip: 'Edit Traits',
            content: _TraitsPanel(iteration: _currentIteration),
          );
          break;
      }
      panels.add(panelWidget);
      if (i < panelOrder.length - 1) {
        panels.add(const SizedBox(height: 16));
      }
    }
    // Add custom panels
    final customPanels = _currentIteration.customPanels
      ..sort((a, b) => a.order.compareTo(b.order));
    if (customPanels.isNotEmpty) {
      panels.add(const Divider());
      panels.add(const SizedBox(height: 16));
    }
    for (int i = 0; i < customPanels.length; i++) {
      final customPanel = customPanels[i];
      panels.add(
        _buildCustomPanelWidget(
          customPanel,
          onReorderUp: i > 0 ? () => _reorderCustomPanel(i, i - 1) : null,
          onReorderDown: i < customPanels.length - 1
              ? () => _reorderCustomPanel(i, i + 1)
              : null,
        ),
      );
      if (i < customPanels.length - 1) {
        panels.add(const SizedBox(height: 16));
      }
    }
    // Add button to add new custom panel
    if (customPanels.isNotEmpty) {
      panels.add(const SizedBox(height: 16));
    }
    panels.add(
      Center(
        child: ElevatedButton.icon(
          onPressed: _showAddCustomPanelDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Custom Panel'),
        ),
      ),
    );
    return panels;
  }

  Widget _buildSingleColumnLayout(BuildContext context) {
    final List<Widget> panels = [];

    // Basic Information (not reorderable)
    panels.add(
      _PanelCard(
        title: 'Basic Information',
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _BasicInfoForm(
            nameController: _nameController,
            aliasesController: _aliasesController,
            occupationController: _occupationController,
            customGenderController: _customGenderController,
            character: _currentIteration,
            onChanged: _onFieldChanged,
            onStateChanged: () => setState(() {}),
          ),
        ),
      ),
    );
    panels.add(const SizedBox(height: 16));

    // Reorderable panels
    for (int i = 0; i < singleColumnPanelOrder.length; i++) {
      final panelType = singleColumnPanelOrder[i];
      Widget panelWidget;
      switch (panelType) {
        case PanelType.bio:
          panelWidget = _PanelCard(
            title: 'Bio',
            onReorderUp: i > 0
                ? () => _reorderSingleColumnPanel(i, i - 1)
                : null,
            onReorderDown: i < singleColumnPanelOrder.length - 1
                ? () => _reorderSingleColumnPanel(i, i + 1)
                : null,
            content: _BioPanel(
              controller: _bioController,
              onChanged: _onFieldChanged,
            ),
          );
          break;
        case PanelType.image:
          panelWidget = _PanelCard(
            title: 'Image',
            onReorderUp: i > 0
                ? () => _reorderSingleColumnPanel(i, i - 1)
                : null,
            onReorderDown: i < singleColumnPanelOrder.length - 1
                ? () => _reorderSingleColumnPanel(i, i + 1)
                : null,
            showHeader: false,
            content: _ImageUploadPanel(
              iteration: _currentIteration,
              characterIteration: _currentIterationIndex,
              onChanged: _onFieldChanged,
            ),
          );
          break;
        case PanelType.links:
          panelWidget = _PanelCard(
            title: 'Links',
            onReorderUp: i > 0
                ? () => _reorderSingleColumnPanel(i, i - 1)
                : null,
            onReorderDown: i < singleColumnPanelOrder.length - 1
                ? () => _reorderSingleColumnPanel(i, i + 1)
                : null,
            content: _LinkPanel(
              character: _character!,
              iterationIndex: _currentIterationIndex,
              linkProvider: widget.linkProvider,
              onAddLink: ({Link? initialLink}) =>
                  _showLinkCreationDialog(initialLink: initialLink).then((
                    newLink,
                  ) {
                    if (newLink != null) _handleLinkAdded(newLink);
                  }),
              onLinkAdded: _handleLinkAdded,
              onViewChart: (key) => _viewRelationChart(context, key),
              onReverted: reload,
            ),
          );
          break;
        default:
          continue; // Skip unknown panel types
      }
      panels.add(panelWidget);
      if (i < singleColumnPanelOrder.length - 1) {
        panels.add(const SizedBox(height: 16));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: panels,
    );
  }

  Widget _buildBottomStatusBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      color: colorScheme.surfaceContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Saving Status Indicator
          Row(
            children: [
              if (_isSaving)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.check_circle, color: Colors.green[600], size: 14),
              const SizedBox(width: 4),
              Text(
                _isSaving ? 'Saving...' : 'Saved',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPanelWidget(
    CustomPanel customPanel, {
    VoidCallback? onReorderUp,
    VoidCallback? onReorderDown,
  }) {
    return _CustomPanelWidget(
      customPanel: customPanel,
      onChanged: _onFieldChanged,
      onReorderUp: onReorderUp,
      onReorderDown: onReorderDown,
      onEdit: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => _EditCustomPanelDialog(panel: customPanel),
        );
        if (result == 'delete') {
          _currentIteration.customPanels.remove(customPanel);
          _saveChanges();
        } else if (result == 'saved') {
          _onFieldChanged();
        }
      },
    );
  }
}

/// --- STAT CREATION DIALOG ---
class _StatCreationDialog extends StatefulWidget {
  const _StatCreationDialog();

  @override
  State<_StatCreationDialog> createState() => _StatCreationDialogState();
}

class _StatCreationDialogState extends State<_StatCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'value': _valueController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Stat'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Stat Name',
                hintText: 'e.g., Strength',
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Name cannot be empty'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'e.g., 14 or "High"',
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add Stat')),
      ],
    );
  }
}

/// --- LINK CREATION DIALOG ---
class _LinkCreationDialog extends StatefulWidget {
  final dynamic currentCharacterKey;
  final int currentCharacterIterationIndex;
  final Function(Link) onDelete;
  final Link? initialLink;

  const _LinkCreationDialog({
    required this.onDelete,
    this.initialLink,
    this.currentCharacterKey,
    required this.currentCharacterIterationIndex,
  });

  @override
  State<_LinkCreationDialog> createState() => _LinkCreationDialogState();
}

class _LinkCreationDialogState extends State<_LinkCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedEntityType = 'Character';
  dynamic _selectedEntityKey;
  int? _selectedEntityIterationIndex;
  String? _selectedRelationship;

  @override
  void initState() {
    super.initState();
    if (widget.initialLink != null) {
      // Editing existing link
      final link = widget.initialLink!;
      _descriptionController.text = link.description;
      _selectedEntityType = link.entity2Type;
      _dateController.text = link.date ?? '';
      _selectedEntityKey = link.entity2Key;
      _selectedRelationship = link.description;
      _selectedEntityIterationIndex = link.entity2IterationIndex;
    }

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _descriptionController.dispose();
    _searchController.dispose(); // Dispose the new controller
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newLink = Link()
        ..entity2Type = _selectedEntityType
        ..description = _selectedRelationship!
        ..date = _dateController.text.trim()
        // Use the selected entity key, or a placeholder if none is selected
        ..entity2Key = _selectedEntityKey ?? 'placeholder_key'
        ..entity1IterationIndex = widget.currentCharacterIterationIndex
        ..entity2IterationIndex = _selectedEntityIterationIndex;
      Navigator.of(context).pop(newLink);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the list of relationships for the currently selected entity type
    final relationshipOptions = RelationshipService().getRelationshipsForType(
      _selectedEntityType,
    );
    final isEditing = widget.initialLink != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Link' : 'Add New Link'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 600, // Give the dialog a fixed width
          height: 400, // and height
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Linked To (Character, Location, Etc)'),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Left Panel: Categories
                      Expanded(
                        flex: 2, // Give categories a bit less space
                        child: SizedBox(
                          width: 180,
                          child: ListView(
                            children:
                                [
                                      'Character',
                                      'Location',
                                      'Item',
                                      'Organization',
                                    ]
                                    .map(
                                      (type) => ListTile(
                                        title: Text(type),
                                        selected: _selectedEntityType == type,
                                        onTap: () => setState(() {
                                          _selectedEntityType = type;
                                          _selectedEntityKey = null;
                                          _selectedEntityIterationIndex = null;
                                          _selectedRelationship = null;
                                        }),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      // Right Panel: Items
                      Expanded(
                        flex: 3, // Give items a bit more space
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 20,
                                  ),
                                  isDense: true,
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _searchController.clear(),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(child: _buildEntityList()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedRelationship,
                      items: relationshipOptions
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRelationship = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Description cannot be empty'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Link',
                        hintText: 'e.g., "Since childhood" or a specific date',
                      ),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
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
          onPressed: _submit,
          child: Text(isEditing ? 'Save Changes' : 'Add Link'),
        ),
      ],
    );
  }

  // Builds the list for the right panel based on the selected entity type
  Widget _buildEntityList() {
    if (_selectedEntityType == 'Character') {
      final characterBox = Hive.box<Character>('characters');
      // Exclude the current character from the list of linkable entities
      final characters = characterBox.values
          .where(
            (char) =>
                char.key != widget.currentCharacterKey &&
                char.name.toLowerCase().contains(_searchQuery),
          )
          .toList();
      if (characters.isEmpty) {
        return const Center(child: Text('No other characters exist.'));
      }
      return ListView.builder(
        itemCount: characters.length,
        itemBuilder: (context, index) {
          final char = characters[index];
          return ListTile(
            title: Row(
              children: [
                Expanded(child: Text(char.name)),
                if (char.iterations.length > 1)
                  const Icon(Icons.layers, size: 16, color: Colors.grey),
              ],
            ),
            selected: _selectedEntityKey == char.key,
            onTap: () {
              setState(() {
                _selectedEntityKey = char.key;
                if (char.iterations.length <= 1) {
                  // If the character has only one iteration, select it automatically.
                  _selectedEntityIterationIndex = 0;
                  // No need to switch views, just confirm selection.
                  // The UI will reflect the selection.
                } else {
                  // If there are multiple iterations, switch to the iteration selection view.
                  _selectedEntityIterationIndex = null;
                  _selectedEntityType = 'Iteration';
                }
              });
            },
          );
        },
      );
    } else if (_selectedEntityType == 'Iteration') {
      final characterBox = Hive.box<Character>('characters');
      final character = characterBox.get(_selectedEntityKey);
      if (character == null || character.iterations.isEmpty) {
        return const Center(child: Text('No iterations found.'));
      }
      return ListView.builder(
        itemCount: character.iterations.length,
        itemBuilder: (context, index) {
          final iteration = character.iterations[index];
          return ListTile(
            title: Text(iteration.iterationName),
            subtitle: Text(iteration.name ?? ''),
            selected: _selectedEntityIterationIndex == index,
            onTap: () {
              setState(() {
                _selectedEntityIterationIndex = index;
                // After selecting an iteration, go back to the character list view
                // but keep the selections.
                _selectedEntityType = 'Character';
              });
            },
          );
        },
      );
    } else {
      // Placeholder for other types
      return Center(
        child: Text(
          'Listing for "$_selectedEntityType" is not yet implemented.',
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}

// --- NEW LINK PANEL WIDGET ---
class _LinkPanel extends StatelessWidget {
  final Character character;
  final int iterationIndex;
  final LinkProvider linkProvider;
  final Future<void> Function({Link? initialLink}) onAddLink;
  final Function(Link) onLinkAdded;
  final Function(dynamic) onViewChart;
  final VoidCallback onReverted;

  const _LinkPanel({
    required this.character,
    required this.iterationIndex,
    required this.linkProvider,
    required this.onAddLink,
    required this.onLinkAdded,
    required this.onViewChart,
    required this.onReverted,
  });

  @override
  Widget build(BuildContext context) {
    final links = linkProvider.getLinksForIteration(
      character.key,
      iterationIndex,
    );
    int countForType(String type) {
      return links.where((link) => link.entity2Type == type).length;
    }

    final characterCount = countForType('Character');
    final locationCount = countForType('Location');
    final itemCount = countForType('Item');
    final organizationCount = countForType('Organization');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2. Row of Four Square Category Buttons filling horizontal space
          Row(
            children: [
              Expanded(
                child: _LinkCategoryButton(
                  label: 'Characters',
                  icon: Icons.person_outline,
                  color: Colors.green,
                  count: characterCount,
                  onTap: () => onViewChart(character.key),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LinkCategoryButton(
                  label: 'Locations',
                  icon: Icons.map_outlined,
                  color: Colors.blue,
                  count: locationCount,
                  onTap: null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LinkCategoryButton(
                  label: 'Items',
                  icon: Icons.category_outlined,
                  color: Colors.orange,
                  count: itemCount,
                  onTap: null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LinkCategoryButton(
                  label: 'Organizations',
                  icon: Icons.group_work_outlined,
                  color: Colors.purple,
                  count: organizationCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkCategoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback? onTap;

  const _LinkCategoryButton({
    required this.label,
    required this.icon,
    required this.color,
    this.count = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1, // Creates a square
      child: InkWell(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha(50), color.withAlpha(150)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- REUSABLE PANEL WIDGETS ---
/// A reusable widget for the main container/box/panel in the UI.
class _PanelCard extends StatelessWidget {
  final String title;
  final Widget content;
  final bool showHeader;
  final VoidCallback? onEdit;
  final IconData? editIcon;
  final String? editTooltip;
  final VoidCallback? onReorderUp;
  final VoidCallback? onReorderDown;
  const _PanelCard({
    required this.title,
    required this.content,
    this.showHeader = true,
    this.onEdit,
    this.editIcon,
    this.editTooltip,
    this.onReorderUp,
    this.onReorderDown,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgPanel
            : AppColors.bgPanelLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Padding(
                padding: AppColors.panelTitlePadding,
                child: Row(
                  children: [
                    if (onReorderUp != null || onReorderDown != null) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        onPressed: onReorderUp,
                        tooltip: 'Move Up',
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        onPressed: onReorderDown,
                        tooltip: 'Move Down',
                      ),
                      const VerticalDivider(width: 16),
                    ],
                    Text(title, style: AppColors.panelTitleStyle(context)),
                    const Spacer(),
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(editIcon ?? Icons.edit_outlined),
                        onPressed: onEdit,
                        tooltip: editTooltip ?? 'Edit',
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            content,
          ],
        ),
      ),
    );
  }
}

class _TraitsPanel extends StatelessWidget {
  final CharacterIteration iteration;

  const _TraitsPanel({required this.iteration});
  // Note: In a larger application, it would be more efficient to pass the
  // fully loaded trait data (including custom traits) down to this widget
  // rather than looking it up here. For now, this approach is straightforward
  // and works correctly.

  @override
  Widget build(BuildContext context) {
    final hasCongenital = iteration.congenitalTraits.isNotEmpty;
    final hasLeveled = iteration.leveledTraits.isNotEmpty;

    // Get the list of valid personality trait group names from the source.
    final validPersonalityTraitNames =
        (traitData['personality'] as List<dynamic>)
            .cast<PersonalityTrait>()
            .map((t) => t.groupName)
            .toSet();

    // Filter the character's traits to only include valid ones.
    final validPersonalityTraits = iteration.personalityTraits.entries.where(
      (entry) => validPersonalityTraitNames.contains(entry.key),
    );

    final hasPersonality = validPersonalityTraits.isNotEmpty;

    if (!hasCongenital && !hasLeveled && !hasPersonality) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('No traits assigned yet. Click "Edit" to add some.'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCongenital) ...[
            Text(
              'Congenital & Physical',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: iteration.congenitalTraits.map((traitName) {
                final icon = _getCongenitalTraitIcon(traitName);
                return Chip(
                  avatar: icon.isNotEmpty ? Text(icon) : null,
                  label: Text(traitName),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (hasLeveled) ...[
            Text(
              'Leveled Traits',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...iteration.leveledTraits.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry.key)),
                    Row(
                      children: [
                        Text(_getLeveledTraitIcon(entry.key, entry.value)),
                        const SizedBox(width: 8),
                        Text(
                          _getLeveledTraitLabel(entry.key, entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (hasPersonality) ...[
            Text('Personality', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...validPersonalityTraits.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry.key)),
                    Row(
                      children: [
                        Text(_getPersonalityTraitIcon(entry.key, entry.value)),
                        const SizedBox(width: 8),
                        Text(
                          _getPersonalityTraitLabel(entry.key, entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCongenitalTraitIcon(String traitName) {
    // Combine all simple traits (default and custom) to find the icon.
    final allSimpleTraits = [
      ...(traitData['congenital'] as List<dynamic>).cast<SimpleTrait>(),
      ...(traitData['physical'] as List<dynamic>).cast<SimpleTrait>(),
    ];

    // This is a simplified lookup. For custom traits, we would need to
    // load them from TraitService here as well.
    try {
      final trait = allSimpleTraits.firstWhere((t) => t.name == traitName);
      return trait.icon;
    } catch (e) {
      return ''; // Return empty string if not found
    }
  }

  String _getLeveledTraitIcon(String traitName, int value) {
    final leveledTraitGroups =
        traitData['leveled'] as Map<String, List<dynamic>>?;
    if (leveledTraitGroups == null ||
        !leveledTraitGroups.containsKey(traitName)) {
      return '';
    }

    final traitsInGroup = leveledTraitGroups[traitName]!.cast<SimpleTrait>();
    if (value >= 0 && value < traitsInGroup.length) {
      return traitsInGroup[value].icon;
    }

    return '';
  }

  String _getLeveledTraitLabel(String traitName, int value) {
    const Map<String, List<String>> levels = {
      'Appearance': [
        'Disfigured',
        'Hideous',
        'Ugly',
        'Homely',
        'Comely',
        'Pretty/Handsome',
        'Beautiful',
        'Magnificent',
        'Celestial',
      ],
      'Intelligence': [
        'Incapable',
        'Imbecile',
        'Dull',
        'Slow',
        'Normal',
        'Clever',
        'Wise',
        'Brilliant',
        'Transcendent',
      ],
      'Physique': [
        'Dead Man/Woman',
        'Feeble',
        'Frail',
        'Weak',
        'Average',
        'Strong',
        'Robust',
        'Mighty',
        'Living God',
      ],
    };
    return levels[traitName]?[value] ?? 'Unknown';
  }

  String _getPersonalityTraitIcon(String traitName, int value) {
    final personalityTraitGroups =
        traitData['personality'] as List<PersonalityTrait>?;
    if (personalityTraitGroups == null) return '';

    try {
      final group = personalityTraitGroups.firstWhere(
        (g) => g.groupName == traitName,
      );
      final option = group.options.firstWhere(
        (o) => o.value == value,
        orElse: () =>
            TraitOption(name: 'Neutral', value: 0, icon: '', explanation: ''),
      );
      return option.icon;
    } catch (e) {
      return '';
    }
  }

  String _getPersonalityTraitLabel(String traitName, int value) {
    // Find the corresponding personality trait group from the main data source.
    final personalityTraitGroups =
        traitData['personality'] as List<PersonalityTrait>?;
    if (personalityTraitGroups == null) return 'Unknown';

    try {
      // Find the group that matches the traitName (e.g., "Temper").
      final group = personalityTraitGroups.firstWhere(
        (g) => g.groupName == traitName,
      );

      // Within that group, find the option that matches the selected value.
      final option = group.options.firstWhere(
        (o) => o.value == value,
        orElse: () =>
            TraitOption(name: 'Neutral', value: 0, icon: '', explanation: ''),
      );
      return option.name;
    } catch (e) {
      // If the trait group or option isn't found, return a fallback.
      return 'Unknown';
    }
  }
}

// --- BASIC INFORMATION FORM PANEL ---
class _BasicInfoForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController aliasesController;
  final TextEditingController occupationController;
  final TextEditingController customGenderController;
  final CharacterIteration character;
  final VoidCallback onChanged;
  final VoidCallback onStateChanged;

  const _BasicInfoForm({
    required this.nameController,
    required this.aliasesController,
    required this.occupationController,
    required this.customGenderController,
    required this.character,
    required this.onChanged,
    required this.onStateChanged,
  });

  @override
  State<_BasicInfoForm> createState() => __BasicInfoFormState();
}

class __BasicInfoFormState extends State<_BasicInfoForm> {
  List<String> _realWorldCountries = [];
  bool _isLoadingCountries = true;
  List<CustomField> _customFields = [];
  final Map<String, TextEditingController> _customFieldControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchCountries();
    _loadCustomFields().then((_) => _initializeControllers());
  }

  Future<void> _loadCustomFields() async {
    final service = GlobalCustomFieldService();
    await service.init();
    if (mounted) {
      setState(() {
        _customFields = service.getCustomFields().toList();
      });
    }
  }

  Future<void> _fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse('https://restcountries.com/v3.1/all?fields=name'),
      );
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<String> countries = data
            .map((c) => c['name']['common'] as String)
            .toList();
        countries.sort();
        setState(() {
          _realWorldCountries = countries;
          _isLoadingCountries = false;
        });
      } else {
        // Handle error or non-200 response
        if (mounted) setState(() => _isLoadingCountries = false);
      }
    } catch (e) {
      // Handle network errors
      debugPrint('Failed to fetch countries: $e');
      if (mounted) setState(() => _isLoadingCountries = false);
    }
  }

  void _showCountrySelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ModernCountrySelectionDialog(
          initialSelection: widget.character.originCountry != null
              ? LocationData(
                  label: widget.character.originCountry!,
                  isOfficial: _realWorldCountries.contains(
                    widget.character.originCountry,
                  ),
                )
              : null,
          onSelected: (LocationData location) {
            if (mounted) {
              // Use the label as the country string
              widget.character.originCountry = location.label;
              widget.onStateChanged();
              widget.onChanged();
            }
          },
        ),
      ),
    );
  }

  void _initializeControllers() {
    for (var field in _customFields) {
      final controller = TextEditingController(
        text: widget.character.customFieldValues[field.name] ?? field.value,
      );
      _customFieldControllers[field.name] = controller;
    }
  }

  void _refreshCustomFields() async {
    // Dispose existing controllers
    for (var controller in _customFieldControllers.values) {
      controller.dispose();
    }
    _customFieldControllers.clear();
    await _loadCustomFields();
    _initializeControllers();
    setState(() {});
  }

  Widget _buildCustomFieldItem(CustomField field) {
    final controller = _customFieldControllers[field.name];
    if (controller == null) return const SizedBox.shrink();

    Widget input;
    switch (field.type) {
      case 'text':
        input = TextField(
          controller: controller,
          readOnly: !field.visible,
          onChanged: (value) {
            widget.character.customFieldValues[field.name] = value;
            widget.onChanged();
          },
        );
        break;
      case 'number':
        input = TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          readOnly: !field.visible,
          onChanged: (value) {
            widget.character.customFieldValues[field.name] = value;
            widget.onChanged();
          },
        );
        break;
      case 'float':
        input = TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          readOnly: !field.visible,
          onChanged: (value) {
            widget.character.customFieldValues[field.name] = value;
            widget.onChanged();
          },
        );
        break;
      case 'large_text':
        input = TextField(
          controller: controller,
          maxLines: 5,
          readOnly: !field.visible,
          onChanged: (value) {
            widget.character.customFieldValues[field.name] = value;
            widget.onChanged();
          },
        );
        break;
      case 'calendar':
        input = TextField(
          controller: controller,
          readOnly: !field.visible,
          onChanged: (value) {
            widget.character.customFieldValues[field.name] = value;
            widget.onChanged();
          },
        );
        break;
      case 'date':
        input = TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'YYYY-MM-DD'),
          readOnly: !field.visible,
          onChanged: (value) {
            widget.character.customFieldValues[field.name] = value;
            widget.onChanged();
          },
        );
        break;
      default:
        input = TextField(
          controller: controller,
          readOnly: !field.visible,
          onChanged: (value) {
            widget.character.customFieldValues[field.name] = value;
            widget.onChanged();
          },
        );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(field.name, style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  final service = GlobalCustomFieldService();
                  await service.init();
                  if (!mounted) return;
                  switch (value) {
                    case 'edit':
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) =>
                            _EditCustomFieldDialog(field: field),
                      );
                      if (result != null) {
                        await service.removeCustomField(field.name);
                        final newField = CustomField(
                          name: result['name'],
                          type: result['type'],
                          value: result['value'],
                        );
                        await service.addCustomField(newField);
                        _refreshCustomFields();
                      }
                      break;
                    case 'delete':
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Custom Field'),
                          content: Text(
                            'Are you sure you want to delete "${field.name}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await service.removeCustomField(field.name);
                        _refreshCustomFields();
                      }
                      break;
                    case 'toggle':
                      await service.toggleVisibility(field.name);
                      _refreshCustomFields();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle',
                    child: Text(field.visible ? 'Disable' : 'Enable'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          input,
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _customFieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Using a list view inside the constrained box to make the content scrollable
        children: [
          // Full Name
          _FormItem(
            label: 'Full Name',
            widget: TextField(
              controller: widget.nameController,
              decoration: const InputDecoration(
                hintText: 'Enter iteration-specific name...',
              ),
              onChanged: (_) => widget.onChanged(),
            ),
          ),
          const SizedBox(height: 12),
          // Aliases
          _FormItem(
            label: 'Aliases',
            widget: TextField(
              controller: widget.aliasesController,
              decoration: const InputDecoration(
                hintText: 'Enter comma-separated aliases',
              ),
              onChanged: (_) => widget.onChanged(),
            ),
          ),
          const SizedBox(height: 12),
          // Origin Country
          _FormItem(
            label: 'Origin Country',
            widget: InkWell(
              onTap: _isLoadingCountries ? null : _showCountrySelectionDialog,
              child: InputDecorator(
                decoration: const InputDecoration(
                  hintText: 'Select or Type...',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                isEmpty: (widget.character.originCountry ?? '').trim().isEmpty,
                child: Text(
                  (widget.character.originCountry ?? '').trim().isEmpty
                      ? 'Select or Type...'
                      : widget.character.originCountry!,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Residence
          _FormItem(
            label: 'Residence',
            widget: TextField(
              decoration: const InputDecoration(hintText: 'Enter some text...'),
              onChanged: (_) => widget.onChanged(),
            ),
          ),
          const SizedBox(height: 12),
          // Gender
          _FormItem(
            label: 'Gender',
            widget: _buildDropdown(
              value: widget.character.gender ?? 'Male',
              items: ['Male', 'Female', 'Custom'],
              onChanged: (value) {
                widget.character.gender = value;
                widget.onStateChanged();
                widget.onChanged();
              },
              hint: 'Select or Type...',
            ),
          ),
          const SizedBox(height: 12),
          if (widget.character.gender == 'Custom') ...[
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: _FormItem(
                label: 'Custom Gender',
                widget: TextField(
                  controller: widget.customGenderController,
                  decoration: const InputDecoration(
                    hintText: 'Specify custom gender',
                  ),
                  onChanged: (String _) => widget.onChanged(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Formal Education
          _FormItem(
            label: 'Formal Education',
            widget: _buildDropdown(
              value: null, // Placeholder
              items: [],
              onChanged: (v) {},
              hint: 'Select or Type...',
            ),
          ),
          const SizedBox(height: 12),
          // Occupation
          _FormItem(
            label: 'Occupation',
            widget: TextField(
              controller: widget.occupationController,
              decoration: const InputDecoration(hintText: 'Enter some text...'),
              onChanged: (_) => widget.onChanged(),
            ),
          ),
          // Custom Fields
          ..._customFields.map((field) => _buildCustomFieldItem(field)),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    // If list is empty (or still loading), show a placeholder with the
    // same field styling as text inputs.
    if (items.isEmpty || _isLoadingCountries) {
      return _DropdownPlaceholder(hint: hint);
    }
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      hint: Text(hint),
    );
  }
}

class _NewIterationDialog extends StatefulWidget {
  const _NewIterationDialog();

  @override
  State<_NewIterationDialog> createState() => __NewIterationDialogState();
}

class __NewIterationDialogState extends State<_NewIterationDialog> {
  final _nameController = TextEditingController();
  bool _importData = true;
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(
        context,
      ).pop({'name': _nameController.text.trim(), 'import': _importData});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Column(
        children: [
          Icon(Icons.layers_outlined, size: 48, color: colorScheme.primary),
          const SizedBox(height: 16),
          const Text('Create New Iteration'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capture a different phase or version of this character.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: InputDecoration(
                labelText: 'Iteration Name',
                hintText: 'e.g., The Exile, Five Years Later...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Name cannot be empty'
                  : null,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primaryContainer),
              ),
              child: CheckboxListTile(
                title: const Text('Sync Initial Data'),
                subtitle: const Text('Start with current details & traits'),
                value: _importData,
                onChanged: (value) =>
                    setState(() => _importData = value ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Create Iteration'),
        ),
      ],
    );
  }
}

class _FormItem extends StatelessWidget {
  final String label;
  final Widget widget;

  const _FormItem({required this.label, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        widget,
      ],
    );
  }
}

class _DropdownPlaceholder extends StatelessWidget {
  final String hint;

  const _DropdownPlaceholder({required this.hint});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      isEmpty: true,
      child: Text(
        hint,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
      ),
    );
  }
}

/// --- BIO PANEL ---
class _BioPanel extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _BioPanel({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        maxLines: 10, // Set a reasonable max lines
        minLines: 5, // Add a min lines to give it some initial size
        // REMOVED 'expands: true'
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          hintText:
              'Type here to add notes, backstories, and anything else you need in this Text Panel!',
          border: InputBorder.none,
        ),
      ),
    );
  }
}

/// --- IMAGE UPLOAD PANEL ---
class _ImageUploadPanel extends StatefulWidget {
  final CharacterIteration iteration;
  final int characterIteration;
  final VoidCallback onChanged;

  const _ImageUploadPanel({
    required this.iteration,
    required this.characterIteration,
    required this.onChanged,
  });

  @override
  State<_ImageUploadPanel> createState() => _ImageUploadPanelState();
}

class _ImageUploadPanelState extends State<_ImageUploadPanel>
    with TickerProviderStateMixin {
  List<String> _iterationOrder = [];
  int _selectedTabIndex = 0;

  @override
  void didUpdateWidget(covariant _ImageUploadPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTabs();
  }

  void _syncTabs() {
    final nextTabs = _buildTabs();
    final nextSet = nextTabs.toSet();
    final ordered = _iterationOrder.where(nextSet.contains).toList();
    for (final tab in nextTabs) {
      if (!ordered.contains(tab)) ordered.add(tab);
    }
    if (ordered.isEmpty) {
      _iterationOrder = [];
      _selectedTabIndex = 0;
      return;
    }
    _iterationOrder = ordered;
    if (_selectedTabIndex >= _iterationOrder.length) {
      _selectedTabIndex = 0;
    }
  }

  Future<void> _addImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;

    final file = result.files.single;
    final bytes = file.bytes ?? await _readFileBytes(file.path);
    if (bytes == null) return;

    final cropResult = await _cropImage(bytes);
    if (cropResult == null) return;

    final newImage = await _showImageMetaDialog(
      cropResult.bytes,
      cropResult.ratio,
    );
    if (newImage == null) return;

    setState(() {
      widget.iteration.images = List<CharacterImage>.from(
        widget.iteration.images,
      )..add(newImage);
    });
    widget.onChanged();
    _syncTabs();
  }

  Future<void> _editImage(CharacterImage image) async {
    final updated = await _showImageMetaDialog(
      image.imageData,
      image.aspectRatio ?? 1.0,
      caption: image.caption,
      imageIteration: image.imageIteration,
      allowDelete: true,
      onDelete: () => _deleteImage(image),
    );
    if (updated == null) return;

    setState(() {
      final updatedList = List<CharacterImage>.from(widget.iteration.images);
      final idx = updatedList.indexOf(image);
      if (idx != -1) {
        updatedList[idx] = updated;
      }
      widget.iteration.images = updatedList;
    });
    widget.onChanged();
    _syncTabs();
  }

  Future<void> _deleteImage(CharacterImage image) async {
    setState(() {
      widget.iteration.images = List<CharacterImage>.from(
        widget.iteration.images,
      )..remove(image);
    });
    widget.onChanged();
    _syncTabs();
  }

  Future<CharacterImage?> _showImageMetaDialog(
    Uint8List bytes,
    double aspectRatio, {
    String? caption,
    String? imageIteration,
    bool allowDelete = false,
    VoidCallback? onDelete,
  }) async {
    final captionController = TextEditingController(text: caption ?? '');
    final iterationController = TextEditingController(
      text: imageIteration ?? '',
    );

    final result = await showDialog<CharacterImage>(
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
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(bytes, height: 160, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: captionController,
                  decoration: const InputDecoration(
                    labelText: 'Caption',
                    hintText: 'Add a caption...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: iterationController,
                  decoration: const InputDecoration(
                    labelText: 'Image Iteration',
                    hintText: 'e.g., Kid, Adult, Battle',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (allowDelete)
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete image?'),
                      content: const Text(
                        'This will permanently remove the image.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  onDelete?.call();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  CharacterImage(
                    imageData: bytes,
                    caption: captionController.text.trim(),
                    imageIteration: iterationController.text.trim(),
                    characterIteration: widget.characterIteration,
                    aspectRatio: aspectRatio,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<Uint8List?> _readFileBytes(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }

  Future<({Uint8List bytes, double ratio})?> _cropImage(Uint8List bytes) async {
    return showNativeCropDialog(context: context, bytes: bytes);
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.iteration.images
        .where((i) => i.characterIteration == widget.characterIteration)
        .toList();
    final cs = Theme.of(context).colorScheme;
    _syncTabs();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(child: _buildIterationTabs(cs)),
                IconButton(
                  onPressed: _addImage,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Image',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (images.isEmpty)
            Text(
              'No images yet. Add photos for this character iteration.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            )
          else
            _buildIterationGrid(cs, _filterImages(images)),
        ],
      ),
    );
  }

  Widget _buildIterationGrid(ColorScheme cs, List<CharacterImage> images) {
    if (images.isEmpty) return const SizedBox.shrink();
    final primary = images.first;
    final secondary = images.skip(1).toList();

    return FutureBuilder<double>(
      future: _resolveAspectRatio(primary),
      builder: (context, snapshot) {
        final ratio = snapshot.data ?? (primary.aspectRatio ?? 1.0);
        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final availableWidth = constraints.maxWidth - gap;
            final leftWidth = availableWidth * 0.75;
            final rightWidth = availableWidth * 0.25;
            final height = leftWidth / ratio;

            return SizedBox(
              height: height,
              child: Row(
                children: [
                  SizedBox(
                    width: leftWidth,
                    child: _buildImageCard(
                      cs,
                      primary,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      fit: BoxFit.fitWidth,
                      onTap: () => _showImageViewer(images, 0),
                    ),
                  ),
                  const SizedBox(width: gap),
                  SizedBox(
                    width: rightWidth,
                    child: _buildThumbnailColumn(
                      cs,
                      secondary,
                      height,
                      rightWidth,
                      images,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThumbnailColumn(
    ColorScheme cs,
    List<CharacterImage> images,
    double height,
    double width,
    List<CharacterImage> fullImages,
  ) {
    if (images.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(12),
          ),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Text(
          'No other images',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
      child: SizedBox(
        height: height,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: images.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final image = images[index];
            final ratio = image.aspectRatio ?? 1.0;
            return SizedBox(
              height: width / ratio,
              child: _buildImageCard(
                cs,
                image,
                borderRadius: BorderRadius.zero,
                fit: BoxFit.fitWidth,
                onTap: () => _showImageViewer(fullImages, index + 1),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<double> _resolveAspectRatio(CharacterImage image) async {
    if (image.aspectRatio != null && image.aspectRatio! > 0) {
      return image.aspectRatio!;
    }
    final decoded = await _decodeUiImage(image.imageData);
    final ratio = decoded.width / decoded.height;
    decoded.dispose();
    image.aspectRatio = ratio;
    widget.onChanged();
    return ratio;
  }

  Widget _buildImageCard(
    ColorScheme cs,
    CharacterImage image, {
    BorderRadius borderRadius = BorderRadius.zero,
    BoxFit fit = BoxFit.cover,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: image.caption.isEmpty ? 'No caption' : image.caption,
      child: InkWell(
        onTap: onTap ?? () => _editImage(image),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: borderRadius,
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: borderRadius,
                child: Image.memory(
                  image.imageData,
                  width: double.infinity,
                  height: double.infinity,
                  fit: fit,
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: IconButton(
                  icon: const Icon(Icons.edit),
                  color: cs.onSurface,
                  tooltip: 'Edit image',
                  onPressed: () => _editImage(image),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImageViewer(
    List<CharacterImage> images,
    int initialIndex,
  ) async {
    if (images.isEmpty) return;
    final safeIndex = initialIndex.clamp(0, images.length - 1);
    final characterName = widget.iteration.name?.trim().isNotEmpty == true
        ? widget.iteration.name!.trim()
        : 'Unknown';
    final iterationName = widget.iteration.iterationName.trim().isNotEmpty
        ? widget.iteration.iterationName.trim()
        : 'Iteration';
    final controller = TransformationController();
    int currentIndex = safeIndex;
    double currentScale = 1.0;
    Offset? lastFocalPoint;
    final viewerKey = GlobalKey();
    const minScale = 0.5;
    const maxScale = 4.0;
    final zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    double zoomStart = currentScale;
    double zoomEnd = currentScale;
    Offset? zoomFocal;
    StateSetter? dialogSetState;
    bool dialogActive = true;

    void applyScale(double targetScale, {Offset? focal}) {
      final box = viewerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final focalLocal =
          focal ?? lastFocalPoint ?? box.size.center(Offset.zero);
      lastFocalPoint = focalLocal;
      final newScale = targetScale.clamp(minScale, maxScale);
      final matrix = Matrix4.copy(controller.value);
      final inverse = Matrix4.inverted(matrix);
      final focalScene = inverse.transform3(
        Vector3(focalLocal.dx, focalLocal.dy, 0),
      );
      final scaleChange = newScale / currentScale;
      matrix
        ..translateByVector3(Vector3(focalScene.x, focalScene.y, 0))
        ..scaleByDouble(scaleChange, scaleChange, 1, 1)
        ..translateByVector3(Vector3(-focalScene.x, -focalScene.y, 0));
      controller.value = matrix;
      currentScale = newScale;
    }

    void animateScaleTo(double targetScale, {Offset? focal}) {
      zoomStart = currentScale;
      zoomEnd = targetScale.clamp(minScale, maxScale);
      zoomFocal = focal;
      zoomController.forward(from: 0);
    }

    void zoomListener() {
      if (!dialogActive || dialogSetState == null) return;
      final t = Curves.easeOutCubic.transform(zoomController.value);
      final nextScale = ui.lerpDouble(zoomStart, zoomEnd, t)!;
      dialogSetState!(() {
        applyScale(nextScale, focal: zoomFocal);
      });
    }

    zoomController.addListener(zoomListener);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setState) {
              dialogSetState = setState;
              final image = images[currentIndex];
              final caption = image.caption.trim().isNotEmpty
                  ? image.caption.trim()
                  : 'None';
              final imageIteration = image.imageIteration.trim().isNotEmpty
                  ? image.imageIteration.trim()
                  : 'None';
              final atStart = currentIndex == 0;
              final atEnd = currentIndex == images.length - 1;

              void resetZoom() {
                currentScale = 1.0;
                lastFocalPoint = null;
                controller.value = Matrix4.identity();
              }

              return Stack(
                children: [
                  Positioned.fill(
                    child: Listener(
                      onPointerSignal: (signal) {
                        if (signal is PointerScrollEvent) {
                          final box =
                              viewerKey.currentContext?.findRenderObject()
                                  as RenderBox?;
                          if (box == null) return;
                          final local = box.globalToLocal(signal.position);
                          lastFocalPoint = local;
                          final delta = -signal.scrollDelta.dy / 600;
                          final targetScale = currentScale * (1 + delta);
                          animateScaleTo(targetScale, focal: local);
                        }
                      },
                      child: InteractiveViewer(
                        key: viewerKey,
                        minScale: minScale,
                        maxScale: maxScale,
                        transformationController: controller,
                        onInteractionStart: (details) {
                          final box =
                              viewerKey.currentContext?.findRenderObject()
                                  as RenderBox?;
                          if (box == null) return;
                          lastFocalPoint = box.globalToLocal(
                            details.focalPoint,
                          );
                        },
                        onInteractionUpdate: (details) {
                          final box =
                              viewerKey.currentContext?.findRenderObject()
                                  as RenderBox?;
                          if (box == null) return;
                          lastFocalPoint = box.globalToLocal(
                            details.focalPoint,
                          );
                          final newScale = controller.value.getMaxScaleOnAxis();
                          if ((newScale - currentScale).abs() > 0.001) {
                            setState(() {
                              currentScale = newScale.clamp(minScale, maxScale);
                            });
                          }
                        },
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              image.imageData,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 48,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: DefaultTextStyle(
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall!.copyWith(color: cs.onSurface),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Details',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              _detailRow('Caption', caption),
                              const SizedBox(height: 6),
                              _detailRow('Image Iteration', imageIteration),
                              const SizedBox(height: 6),
                              _detailRow('Character', characterName),
                              const SizedBox(height: 6),
                              _detailRow('Character Iteration', iterationName),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              tooltip: 'Previous',
                              onPressed: atStart
                                  ? null
                                  : () {
                                      setState(() {
                                        currentIndex -= 1;
                                        resetZoom();
                                      });
                                    },
                              color: cs.onSurface,
                              disabledColor: cs.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            SizedBox(
                              width: 52,
                              child: Text(
                                '${(currentScale * 100).round()}%',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: cs.onSurface),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Slider(
                                min: minScale,
                                max: maxScale,
                                value: currentScale.clamp(minScale, maxScale),
                                divisions: ((maxScale - minScale) / 0.1)
                                    .round(),
                                onChanged: (value) {
                                  final snapped = (value * 10).round() / 10.0;
                                  animateScaleTo(snapped);
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Reset zoom',
                              onPressed: () {
                                animateScaleTo(1.0);
                              },
                              color: cs.onSurface,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              tooltip: 'Next',
                              onPressed: atEnd
                                  ? null
                                  : () {
                                      setState(() {
                                        currentIndex += 1;
                                        resetZoom();
                                      });
                                    },
                              color: cs.onSurface,
                              disabledColor: cs.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    dialogActive = false;
    zoomController.removeListener(zoomListener);
    zoomController.dispose();
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  List<String> _buildTabs() {
    final images = widget.iteration.images
        .where((i) => i.characterIteration == widget.characterIteration)
        .toList();
    final iterations = <String>[];
    for (final image in images) {
      final name = image.imageIteration.trim();
      if (name.isNotEmpty && !iterations.contains(name)) {
        iterations.add(name);
      }
    }
    return iterations;
  }

  List<CharacterImage> _filterImages(List<CharacterImage> images) {
    if (_iterationOrder.isEmpty) return images;
    final currentTab = _iterationOrder[_selectedTabIndex];
    return images
        .where((i) => i.imageIteration.trim().isNotEmpty)
        .where((i) => i.imageIteration == currentTab)
        .toList();
  }

  Widget _buildIterationTabs(ColorScheme cs) {
    if (_iterationOrder.isEmpty) {
      return Text(
        'No image iterations',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      );
    }

    return SizedBox(
      height: 32,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        padding: EdgeInsets.zero,
        itemCount: _iterationOrder.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _iterationOrder.removeAt(oldIndex);
            _iterationOrder.insert(newIndex, item);
            if (_selectedTabIndex == oldIndex) {
              _selectedTabIndex = newIndex;
            } else if (oldIndex < _selectedTabIndex &&
                newIndex >= _selectedTabIndex) {
              _selectedTabIndex -= 1;
            } else if (oldIndex > _selectedTabIndex &&
                newIndex <= _selectedTabIndex) {
              _selectedTabIndex += 1;
            }
          });
        },
        itemBuilder: (context, index) {
          final tab = _iterationOrder[index];
          final isSelected = index == _selectedTabIndex;
          return Container(
            key: ValueKey('imgtab_$tab'),
            margin: const EdgeInsets.only(right: 8),
            child: ReorderableDragStartListener(
              index: index,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _selectedTabIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    tab,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// --- ADD CUSTOM FIELD DIALOG ---
class _AddCustomFieldDialog extends StatefulWidget {
  const _AddCustomFieldDialog();

  @override
  State<_AddCustomFieldDialog> createState() => __AddCustomFieldDialogState();
}

class __AddCustomFieldDialogState extends State<_AddCustomFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  String _selectedType = 'text';

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'value': _valueController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Field'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Field Name',
                hintText: 'e.g., Favorite Color',
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Name cannot be empty'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Text')),
                DropdownMenuItem(value: 'number', child: Text('Number')),
                DropdownMenuItem(value: 'float', child: Text('Float')),
                DropdownMenuItem(
                  value: 'large_text',
                  child: Text('Large Text'),
                ),
                DropdownMenuItem(value: 'calendar', child: Text('Calendar')),
                DropdownMenuItem(value: 'date', child: Text('Date')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Field Type'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Initial Value',
                hintText: 'Enter initial value (optional)',
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add Field')),
      ],
    );
  }
}

/// --- EDIT CUSTOM FIELD DIALOG ---
class _EditCustomFieldDialog extends StatefulWidget {
  final CustomField field;

  const _EditCustomFieldDialog({required this.field});

  @override
  State<_EditCustomFieldDialog> createState() => __EditCustomFieldDialogState();
}

class __EditCustomFieldDialogState extends State<_EditCustomFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.field.name);
    _valueController = TextEditingController(text: widget.field.value);
    _selectedType = widget.field.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'value': _valueController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Custom Field'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Field Name',
                hintText: 'e.g., Favorite Color',
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Name cannot be empty'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Text')),
                DropdownMenuItem(value: 'number', child: Text('Number')),
                DropdownMenuItem(value: 'float', child: Text('Float')),
                DropdownMenuItem(
                  value: 'large_text',
                  child: Text('Large Text'),
                ),
                DropdownMenuItem(value: 'calendar', child: Text('Calendar')),
                DropdownMenuItem(value: 'date', child: Text('Date')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Field Type'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Default Value',
                hintText: 'Enter default value (optional)',
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save Changes')),
      ],
    );
  }
}

/// --- ADD CUSTOM PANEL DIALOG ---
class _AddCustomPanelDialog extends StatefulWidget {
  const _AddCustomPanelDialog();

  @override
  State<_AddCustomPanelDialog> createState() => __AddCustomPanelDialogState();
}

class __AddCustomPanelDialogState extends State<_AddCustomPanelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'large_text';
  final List<String> _items = [];

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'content': _contentController.text.trim(),
        'items': _items,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Panel'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Panel Name',
                hintText: 'e.g., Notes',
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Name cannot be empty'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              items: const [
                DropdownMenuItem(
                  value: 'large_text',
                  child: Text('Large Text'),
                ),
                DropdownMenuItem(
                  value: 'item_lister',
                  child: Text('Item Lister'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Panel Type'),
            ),
            const SizedBox(height: 16),
            if (_selectedType == 'large_text')
              TextFormField(
                controller: _contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Initial Content',
                  hintText: 'Enter initial text (optional)',
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add Panel')),
      ],
    );
  }
}

/// --- EDIT CUSTOM PANEL DIALOG ---
class _EditCustomPanelDialog extends StatefulWidget {
  final CustomPanel panel;

  const _EditCustomPanelDialog({required this.panel});

  @override
  State<_EditCustomPanelDialog> createState() => __EditCustomPanelDialogState();
}

class __EditCustomPanelDialogState extends State<_EditCustomPanelDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.panel.name);
    _contentController = TextEditingController(text: widget.panel.content);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.panel.name = _nameController.text.trim();
      if (widget.panel.type == 'large_text') {
        widget.panel.content = _contentController.text.trim();
      }
      Navigator.of(context).pop('saved');
    }
  }

  void _delete() {
    Navigator.of(context).pop('delete');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Using KeyboardAwareDialog to handle Escape key for cancellation.
      actionsPadding: const EdgeInsets.fromLTRB(8, 8, 24, 16),
      title: const Text('Edit Custom Panel'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Panel Name',
                hintText: 'e.g., Notes',
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Name cannot be empty'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            if (widget.panel.type == 'large_text')
              TextFormField(
                controller: _contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Enter text',
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Deletion'),
                content: Text(
                  'Are you sure you want to delete the panel "${widget.panel.name}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) _delete();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete Panel'),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: _submit, child: const Text('Save Changes')),
      ],
    );
  }
}

/// --- CUSTOM PANEL WIDGET ---
class _CustomPanelWidget extends StatefulWidget {
  final CustomPanel customPanel;
  final VoidCallback onChanged;
  final VoidCallback? onReorderUp;
  final VoidCallback? onReorderDown;
  final Function()? onEdit;

  const _CustomPanelWidget({
    required this.customPanel,
    required this.onChanged,
    this.onReorderUp,
    this.onReorderDown,
    this.onEdit,
  });

  @override
  State<_CustomPanelWidget> createState() => _CustomPanelWidgetState();
}

class _CustomPanelWidgetState extends State<_CustomPanelWidget> {
  late TextEditingController _contentController;
  late List<TextEditingController> _itemControllers;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.customPanel.content,
    );
    _itemControllers = widget.customPanel.items
        .map((item) => TextEditingController(text: item))
        .toList();
  }

  @override
  void didUpdateWidget(_CustomPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customPanel.content != widget.customPanel.content) {
      _contentController.text = widget.customPanel.content;
    }
    if (oldWidget.customPanel.items.length != widget.customPanel.items.length) {
      // Dispose old controllers
      for (var controller in _itemControllers) {
        controller.dispose();
      }
      // Create new ones
      _itemControllers = widget.customPanel.items
          .map((item) => TextEditingController(text: item))
          .toList();
    } else {
      // Update existing
      for (int i = 0; i < _itemControllers.length; i++) {
        if (_itemControllers[i].text != widget.customPanel.items[i]) {
          _itemControllers[i].text = widget.customPanel.items[i];
        }
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (widget.customPanel.type) {
      case 'large_text':
        content = Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _contentController,
            maxLines: 10,
            minLines: 5,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Enter text here...',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              widget.customPanel.content = value;
              widget.onChanged();
            },
          ),
        );
        break;
      case 'item_lister':
        content = Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              for (int i = 0; i < _itemControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: _itemControllers[i],
                    decoration: InputDecoration(
                      hintText: 'Item ${i + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      widget.customPanel.items[i] = value;
                      widget.onChanged();
                    },
                  ),
                ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.customPanel.items.add('');
                    _itemControllers.add(TextEditingController());
                  });
                  widget.onChanged();
                },
                child: const Text('Add Item'),
              ),
            ],
          ),
        );
        break;
      default:
        content = const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Unsupported panel type'),
        );
    }

    return _PanelCard(
      title: widget.customPanel.name,
      content: content,
      onReorderUp: widget.onReorderUp,
      onReorderDown: widget.onReorderDown,
      onEdit: widget.onEdit,
      editIcon: Icons.edit,
      editTooltip: 'Edit Panel',
    );
  }
}
