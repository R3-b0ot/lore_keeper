import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/link.dart';
import 'package:lore_keeper/providers/link_provider.dart';
import 'package:lore_keeper/services/relationship_service.dart';
import 'package:lore_keeper/services/history_service.dart';
import 'package:lore_keeper/screens/relation_chart_screen.dart';

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
  List<String> _personalityTraits = [];
  List<Map<String, String>> _statistics = [];
  List<Map<String, String>> _physicalTraits = [];
  final HistoryService _historyService = HistoryService();

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
      debugPrint(
        'Migrating character "${_character!.name}" to iteration format.',
      );
      final firstIteration = CharacterIteration(
        iterationName: 'The First',
        name: _character!.name,
        bio: _character!.bio,
        // Also migrate the old top-level lists
        aliases: _character!.aliases,
        occupation: _character!.occupation,
        gender: _character!.gender,
        customGender: _character!.customGender,
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
    _personalityTraits = List<String>.from(
      _currentIteration.personalityTraits ?? [],
    );
    _statistics = List<Map<String, String>>.from(
      _currentIteration.statistics ?? [],
    );
    _physicalTraits = List<Map<String, String>>.from(
      _currentIteration.physicalTraits ?? [],
    );
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
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), () {
      _saveChanges();
    });
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
    _currentIteration.personalityTraits = _personalityTraits;
    _currentIteration.statistics = _statistics;
    _currentIteration.physicalTraits = _physicalTraits;
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

  void _handleTraitsSelected(Set<String>? selectedTraitTitles) {
    if (selectedTraitTitles == null) return; // Allow empty list to clear traits
    setState(() {
      _personalityTraits = selectedTraitTitles.toList();
    });
    _onFieldChanged();
  }

  Future<void> _showNewIterationDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _NewIterationDialog(),
    );
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
        // Import traits and stats
        newIteration.personalityTraits = List.from(
          sourceIteration.personalityTraits ?? [],
        );
        newIteration.statistics = List.from(sourceIteration.statistics ?? []);
        newIteration.physicalTraits = List.from(
          sourceIteration.physicalTraits ?? [],
        );
      } else {
        newIteration.name = _character!.name; // Default to primary name
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

  Future<Map<String, String>?> _showStatCreationDialog({
    Map<String, String>? initialStat,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _StatCreationDialog(initialStat: initialStat),
    );
  }

  void _handleStatAdded(Map<String, String> newStat) {
    if (newStat['name']!.isEmpty) return; // Don't add stats with no name
    setState(() {
      _statistics.add(newStat);
    });
    _onFieldChanged(); // Trigger autosave
  }

  void _handleStatEdited(int index, Map<String, String> updatedStat) {
    if (updatedStat['name']!.isEmpty) return;
    setState(() {
      _statistics[index] = updatedStat;
    });
    _onFieldChanged();
  }

  Future<Map<String, String>?> _showPhysicalTraitCreationDialog({
    Map<String, String>? initialTrait,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) =>
          _PhysicalTraitCreationDialog(initialTrait: initialTrait),
    );
  }

  void _handlePhysicalTraitAdded(Map<String, String> newTrait) {
    if (newTrait['name']!.isEmpty) return;
    setState(() {
      _physicalTraits.add(newTrait);
    });
    _onFieldChanged();
  }

  void _handlePhysicalTraitEdited(int index, Map<String, String> updatedTrait) {
    if (updatedTrait['name']!.isEmpty) return;
    setState(() {
      _physicalTraits[index] = updatedTrait;
    });
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
      return const Scaffold(body: Center(child: Text('Character not found.')));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: kToolbarHeight,
        titleSpacing: 0,
        flexibleSpace: Row(
          children: [
            Expanded(
              child: TabBar(
                controller: _tabController,
                onTap: (index) => _onTabTapped(index),
                isScrollable: true,
                tabs: _character!.iterations.isEmpty
                    ? [const Tab(text: 'The First')]
                    : _character!.iterations.asMap().entries.map((entry) {
                        final index = entry.key;
                        final iter = entry.value;
                        return Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(iter.iterationName),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18),
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
                                      child: Text('Rename'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      enabled: canDelete,
                                      child: Tooltip(
                                        message: (canDelete
                                            ? 'Delete this iteration'
                                            : "The character must have at least one iteration. To remove the character entirely, use the main character list."),
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: (canDelete
                                                ? Colors.red
                                                : Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                indicator: const UnderlineTabIndicator(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New Iteration',
              onPressed: _showNewIterationDialog,
            ),
            const SizedBox(width: 8), // Some padding
          ],
        ),
      ),
      body: LayoutBuilder(
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
                          ? _buildTwoColumnLayout(context)
                          : _buildSingleColumnLayout(context),
                    );
                  }).toList(),
          );
        },
      ),
      bottomNavigationBar: _buildBottomStatusBar(),
    );
  }

  // Layout for large screens (two columns)
  Widget _buildTwoColumnLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column Content
        Expanded(
          child: Column(
            children: [
              _PanelCard(
                title: 'Basic Information',
                content: _BasicInfoForm(
                  nameController: _nameController,
                  aliasesController: _aliasesController,
                  occupationController: _occupationController,
                  customGenderController: _customGenderController,
                  character: _currentIteration,
                  onChanged: _onFieldChanged,
                  onStateChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: _PanelCard(
                      title: 'Image',
                      content: _ImageUploadPanel(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AddItemPanel(
                      title: 'Statistics',
                      helperText:
                          'Use stats to detail specific values connected to your element. Organize stats by adding sections.',
                      items: _statistics,
                      onAdd: () async {
                        final newStat = await _showStatCreationDialog();
                        if (newStat != null) {
                          _handleStatAdded(newStat);
                        }
                      },
                      onEdit: (index) async {
                        final newStat = await _showStatCreationDialog(
                          initialStat: _statistics[index],
                        );
                        if (newStat != null) {
                          _handleStatEdited(index, newStat);
                        }
                      },
                      onDelete: (index) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Stat'),
                            content: Text(
                              'Are you sure you want to delete "${_statistics[index]['name']}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          setState(() => _statistics.removeAt(index));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right Column Content
        Expanded(
          child: Column(
            children: [
              _PanelCard(
                title: 'Bio',
                content: _BioPanel(
                  controller: _bioController,
                  onChanged: _onFieldChanged,
                ),
              ),
              const SizedBox(height: 16),
              _LinkPanel(
                character: _character!,
                iterationIndex: _currentIterationIndex,
                linkProvider: widget.linkProvider,
                onAddLink: ({Link? initialLink}) async {
                  final newLink = await _showLinkCreationDialog(
                    initialLink: initialLink,
                  );
                  if (newLink != null) {
                    _handleLinkAdded(newLink);
                  }
                },
                onLinkAdded: _handleLinkAdded,
                onViewChart: (key) => _viewRelationChart(context, key),
                onReverted: reload,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AddItemPanel(
                      title: 'Physical Traits',
                      helperText:
                          'Detail physical characteristics like eye color, height, or distinguishing marks.',
                      items: _physicalTraits,
                      onAdd: () async {
                        final newTrait =
                            await _showPhysicalTraitCreationDialog();
                        if (newTrait != null) {
                          _handlePhysicalTraitAdded(newTrait);
                        }
                      },
                      onEdit: (index) async {
                        final newTrait = await _showPhysicalTraitCreationDialog(
                          initialTrait: _physicalTraits[index],
                        );
                        if (newTrait != null) {
                          _handlePhysicalTraitEdited(index, newTrait);
                        }
                      },
                      onDelete: (index) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Trait'),
                            content: Text(
                              'Are you sure you want to delete "${_physicalTraits[index]['name']}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          setState(() => _physicalTraits.removeAt(index));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AddItemPanel(
                      title: 'Personality Traits',
                      helperText:
                          'Lists help organize your work. Organize list items by adding sections.',
                      items: _personalityTraits,
                      onAdd: () async {
                        final selectedTraitTitles =
                            await showDialog<Set<String>?>(
                              context: context,
                              builder: (context) => _TraitSelectionDialog(
                                initialTraits: _personalityTraits,
                              ),
                            );
                        _handleTraitsSelected(selectedTraitTitles);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Layout for small screens (single column)
  Widget _buildSingleColumnLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Basic Information
        _PanelCard(
          title: 'Basic Information',
          content: _BasicInfoForm(
            nameController: _nameController,
            aliasesController: _aliasesController,
            occupationController: _occupationController,
            customGenderController: _customGenderController,
            character: _currentIteration,
            onChanged: _onFieldChanged,
            onStateChanged: () => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        // Bio
        _PanelCard(
          title: 'Bio',
          content: _BioPanel(
            controller: _bioController,
            onChanged: _onFieldChanged,
          ),
        ),
        const SizedBox(height: 16),
        // Physical Traits
        _AddItemPanel(
          title: 'Physical Traits',
          helperText:
              'Detail physical characteristics like eye color, height, or distinguishing marks.',
          items: _physicalTraits,
          onAdd: () async {
            final newTrait = await _showPhysicalTraitCreationDialog();
            if (newTrait != null) {
              _handlePhysicalTraitAdded(newTrait);
            }
          },
          onEdit: (index) async {
            final newTrait = await _showPhysicalTraitCreationDialog(
              initialTrait: _physicalTraits[index],
            );
            if (newTrait != null) {
              _handlePhysicalTraitEdited(index, newTrait);
            }
          },
          onDelete: (index) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Trait'),
                content: Text(
                  'Are you sure you want to delete "${_physicalTraits[index]['name']}"?',
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
              setState(() => _physicalTraits.removeAt(index));
            }
          },
        ),
        const SizedBox(height: 16),
        // Personality Traits
        _AddItemPanel(
          title: 'Personality Traits',
          helperText:
              'Select from a comprehensive list of traits to define your character\'s personality.',
          items: _personalityTraits,
          onAdd: () async {
            // Add the onAdd functionality back
            final selectedTraitTitles = await showDialog<Set<String>?>(
              context: context,
              builder: (context) =>
                  _TraitSelectionDialog(initialTraits: _personalityTraits),
            );
            _handleTraitsSelected(selectedTraitTitles);
          },
        ),
        const SizedBox(height: 16),
        // Image
        const _PanelCard(title: 'Image', content: _ImageUploadPanel()),
        const SizedBox(height: 16),
        // Statistics
        _AddItemPanel(
          title: 'Statistics',
          helperText:
              'Use stats to detail specific values connected to your element. Organize stats by adding sections.',
          items: _statistics,
          onAdd: () async {
            final newStat = await _showStatCreationDialog();
            if (newStat != null) {
              _handleStatAdded(newStat);
            }
          },
          onEdit: (index) async {
            final newStat = await _showStatCreationDialog(
              initialStat: _statistics[index],
            );
            if (newStat != null) {
              _handleStatEdited(index, newStat);
            }
          },
          onDelete: (index) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Stat'),
                content: Text(
                  'Are you sure you want to delete "${_statistics[index]['name']}"?',
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
              setState(() => _statistics.removeAt(index));
            }
          },
        ),
        const SizedBox(height: 16),
        // Links
        _LinkPanel(
          character: _character!,
          iterationIndex: _currentIterationIndex,
          linkProvider: widget.linkProvider,
          onAddLink: ({Link? initialLink}) =>
              _showLinkCreationDialog(initialLink: initialLink).then((newLink) {
                if (newLink != null) _handleLinkAdded(newLink);
              }),
          onLinkAdded: _handleLinkAdded,
          onViewChart: (key) => _viewRelationChart(context, key),
          onReverted: reload,
        ),
      ],
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
    return _PanelCard(
      title: 'Links',
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 2. Row of Three Square Category Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                const SizedBox(width: 16),
                Expanded(
                  child: _LinkCategoryButton(
                    label: 'Locations',
                    icon: Icons.map_outlined,
                    color: Colors.blue,
                    count: locationCount,
                    onTap: null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _LinkCategoryButton(
                    label: 'Items',
                    icon: Icons.category_outlined,
                    color: Colors.orange,
                    count: itemCount,
                    onTap: null,
                  ),
                ),
                const SizedBox(width: 16),
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
    );
  }
}

// --- REUSABLE PANEL WIDGETS ---
/// A reusable widget for the main container/box/panel in the UI.
class _PanelCard extends StatelessWidget {
  final String title;
  final Widget content;

  const _PanelCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.more_vert, color: Colors.transparent),
              ],
            ),
          ),
          const Divider(height: 1),
          content,
        ],
      ),
    );
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

  @override
  void initState() {
    super.initState();
    _fetchCountries();
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

  void _showCountrySelectionDialog() async {
    final selectedCountry = await showDialog<String>(
      context: context,
      builder: (context) => _CountrySelectionDialog(
        initialCountry: widget.character.originCountry,
        realWorldCountries: _realWorldCountries,
        customLocations: const ['Gondor', 'The Shire', 'Hogwarts'],
      ),
    );
    if (selectedCountry != null && mounted) {
      widget.character.originCountry = selectedCountry;
      widget.onStateChanged();
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        // Using a list view inside the constrained box to make the content scrollable
        children: [
          // Full Name
          _FormItem(
            label: 'Full Name',
            widget: TextField(
              controller: widget.nameController,
              decoration: const InputDecoration(hintText: 'Enter some text...'),
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
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  widget.character.originCountry ?? 'Select or Type...',
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
          if (widget.character.gender == 'Custom')
            _FormItem(
              label: 'Custom Gender',
              widget: TextField(
                controller: widget.customGenderController,
                decoration: const InputDecoration(
                  hintText: 'Specify custom gender',
                ),
                onChanged: (_) => widget.onChanged(),
              ),
            ),
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
          const SizedBox(height: 12),
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
    // If countries are loading or the list is empty, show a placeholder.
    if (_isLoadingCountries && items.isEmpty) {
      return const _DropdownPlaceholder(hint: 'Select or Type...');
    }
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(border: InputBorder.none),
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
    return AlertDialog(
      title: const Text('New Character Iteration'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Iteration Name',
                hintText: 'e.g., The Second, Alternate Self',
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Name cannot be empty'
                  : null,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Import data from current iteration'),
              value: _importData,
              onChanged: (value) =>
                  setState(() => _importData = value ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          widget,
        ],
      ),
    );
  }
}

class _DropdownPlaceholder extends StatelessWidget {
  final String hint;

  const _DropdownPlaceholder({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: TextStyle(color: Colors.grey.shade600)),
          const Icon(Icons.arrow_drop_down),
        ],
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
      padding: const EdgeInsets.all(16.0),
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

/// --- ADD ITEM (TRAITS, STATS, LINKS) PANEL ---
class _AddItemPanel extends StatelessWidget {
  final String title;
  final String helperText;
  final List<dynamic>? items; // Can be List<String> or List<Map>
  final VoidCallback? onAdd;
  final Function(int)? onEdit;
  final Function(int)? onDelete;

  const _AddItemPanel({
    required this.title,
    required this.helperText,
    this.items,
    this.onAdd,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: title,
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            (items == null || items!.isEmpty)
                ? _buildHelperContent(context)
                : _buildItemsList(context),
            // Add Item Button
            ElevatedButton.icon(
              onPressed:
                  onAdd ??
                  () {
                    debugPrint('Add $title Item clicked!');
                  },
              icon: const Icon(Icons.add_circle_outline),
              label: Text(
                title == 'Statistics'
                    ? 'Add Stat'
                    : (title == 'Links' ? 'Add Link' : 'Add List Item'),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: Colors.indigo.shade50,
                foregroundColor: Colors.indigo.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.indigo.shade300),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(helperText, style: TextStyle(color: Colors.grey.shade600)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Click + Add List Item below to begin.',
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items!.length, // This should be safe due to the check above
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Card(
            elevation: 0.5,
            child: (items![index] is Map || items![index] is Link)
                ? _buildStatTile(context, index)
                : ListTile(title: Text(items![index] as String), dense: true),
          ),
        );
      },
    );
  }

  Widget _buildStatTile(BuildContext context, int index) {
    final itemData = items![index];
    final isLink = title == 'Links';
    String tileTitle;
    String? dateText;
    String trailingText;
    if (isLink) {
      final link = itemData as Link;
      final characterBox = Hive.box<Character>('characters');
      final linkedCharacter = characterBox.get(link.entity2Key);
      tileTitle = '${link.description} ${linkedCharacter?.name ?? '[Unknown]'}';
      dateText = link.date;
      trailingText = link.entity2Type;
    } else {
      final itemMap = itemData as Map<String, String>;
      tileTitle = itemMap['name'] ?? 'Unnamed';
      dateText = null;
      trailingText = itemMap['value']!;
    }
    return ListTile(
      title: Text(tileTitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLink)
            if (dateText != null && dateText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  dateText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          if (isLink)
            Chip(
              label: Text(trailingText),
              padding: EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.bodySmall,
            )
          else
            Text(trailingText, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isLink ? Icons.link_off : Icons.delete_outline,
              color: Colors.red,
            ),
            onPressed: () => onDelete?.call(index),
            tooltip: isLink ? 'Delete Link' : 'Delete Stat',
          ),
        ],
      ),
      onTap: () => onEdit?.call(index),
      dense: true,
    );
  }
}

/// --- IMAGE UPLOAD PANEL ---
class _ImageUploadPanel extends StatelessWidget {
  const _ImageUploadPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Image Upload UI'));
  }
}

/// --- COUNTRY SELECTION DIALOG ---
class _CountrySelectionDialog extends StatefulWidget {
  final String? initialCountry;
  final List<String> realWorldCountries;
  final List<String> customLocations;

  const _CountrySelectionDialog({
    this.initialCountry,
    required this.realWorldCountries,
    required this.customLocations,
  });

  @override
  State<_CountrySelectionDialog> createState() =>
      __CountrySelectionDialogState();
}

class __CountrySelectionDialogState extends State<_CountrySelectionDialog> {
  late String _selectedCategory;
  String? _selectedCountry;
  late final ScrollController _scrollController;
  late final Map<String, List<String>> _countrySources;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _countrySources = {
      'Real World': widget.realWorldCountries,
      'Custom': widget.customLocations,
    };
    // Determine initial selection
    if (widget.initialCountry != null) {
      _selectedCountry = widget.initialCountry;
      if (widget.customLocations.contains(widget.initialCountry)) {
        _selectedCategory = 'Custom';
      } else {
        _selectedCategory = 'Real World';
      }
    } else {
      _selectedCategory = 'Real World';
    }
  }

  void _selectCountry(String country) {
    Navigator.of(context).pop(country);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> currentCountries = _countrySources[_selectedCategory]!;
    // By wrapping the AlertDialog in a Dialog and then a Builder, we get a new
    // context that is a descendant of the Dialog. This prevents crashes when
    // scrolling, as list items are built with the correct, non-stale context.
    return Dialog(
      child: Builder(
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Origin Country'),
            content: SizedBox(
              width: 600,
              height: 400,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Pane: Category List
                  SizedBox(
                    width: 180,
                    child: ListView(
                      children: _countrySources.keys.map((category) {
                        final isSelected = _selectedCategory == category;
                        return ListTile(
                          title: Text(
                            category,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                              _selectedCountry =
                                  null; // Clear selection on category change
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const VerticalDivider(),
                  // Right Pane: Country List
                  Expanded(
                    child: currentCountries.isEmpty
                        ? Center(
                            child: Text(
                              'No $_selectedCategory locations found.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : Scrollbar(
                            controller: _scrollController, // Provide controller
                            child: ListView.builder(
                              controller:
                                  _scrollController, // Provide controller
                              itemCount: currentCountries.length,
                              itemBuilder: (context, index) {
                                final country = currentCountries[index];
                                return ListTile(
                                  title: Text(country),
                                  selected: _selectedCountry == country,
                                  onTap: () {
                                    setState(() {
                                      _selectedCountry = country;
                                      _selectCountry(country);
                                    });
                                  },
                                );
                              },
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
            ],
          );
        },
      ),
    );
  }
}

class _PhysicalTraitCreationDialog extends StatefulWidget {
  final Map<String, String>? initialTrait;

  const _PhysicalTraitCreationDialog({this.initialTrait});

  @override
  State<_PhysicalTraitCreationDialog> createState() =>
      __PhysicalTraitCreationDialogState();
}

class __PhysicalTraitCreationDialogState
    extends State<_PhysicalTraitCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialTrait != null) {
      _nameController.text = widget.initialTrait!['name'] ?? '';
      _valueController.text = widget.initialTrait!['value'] ?? '';
    }
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
    final isEditing = widget.initialTrait != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Physical Trait' : 'Add Physical Trait'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Trait Name',
                hintText: 'e.g., Eye Color',
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
                labelText: 'Description',
                hintText: 'e.g., Hazel',
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
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save Changes' : 'Add Trait'),
        ),
      ],
    );
  }
}

/// --- STAT CREATION DIALOG ---
class _StatCreationDialog extends StatefulWidget {
  final Map<String, String>? initialStat;

  const _StatCreationDialog({this.initialStat});

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
    if (widget.initialStat != null) {
      _nameController.text = widget.initialStat!['name']!;
      _valueController.text = widget.initialStat!['value']!;
    }
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
    final isEditing = widget.initialStat != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Stat' : 'Add New Stat'),
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
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save Changes' : 'Add Stat'),
        ),
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
  // Add search controller and query state
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
    // Add listener for search
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
                      SizedBox(
                        width: 180,
                        child: ListView(
                          children:
                              ['Character', 'Location', 'Item', 'Organization']
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
                      const VerticalDivider(width: 1),
                      // Right Panel: Items
                      Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
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

/// --- TRAIT SELECTION DIALOG ---
class Trait {
  final int id;
  final String title;
  final String description;
  final String svgId;
  final String category;
  final Color color;

  Trait({
    required this.id,
    required this.title,
    required this.description,
    required this.svgId,
    required this.category,
    required this.color,
  });
}

class _TraitSelectionDialog extends StatefulWidget {
  final List<String> initialTraits;

  const _TraitSelectionDialog({this.initialTraits = const []});

  @override
  State<_TraitSelectionDialog> createState() => _TraitSelectionDialogState();
}

class _TraitSelectionDialogState extends State<_TraitSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Trait> _allTraits = [];
  List<Trait> _filteredTraits = [];
  String _selectedCategory = 'Positive';
  final Set<String> _selectedTraitTitles = {};
  bool _isLoading = true;
  final List<String> _categories = ['Positive', 'Neutral', 'Negative'];

  @override
  void initState() {
    super.initState();
    _loadTraits();
    _searchController.addListener(_filterTraits);
    // Initialize the selected traits from the provided initial list
    _selectedTraitTitles.addAll(widget.initialTraits);
  }

  Future<void> _loadTraits() async {
    setState(() => _isLoading = true);
    try {
      final jsonString = await rootBundle.loadString('assets/traits.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      int idCounter = 1;
      final colorMap = {
        'Positive': Colors.green,
        'Neutral': Colors.amber,
        'Negative': Colors.red,
      };
      final loadedTraits = jsonList.map((json) {
        final category = json['category'] as String;
        return Trait(
          id: idCounter++,
          title: json['name'] as String,
          description: json['description'] as String,
          svgId: json['svg_id'] as String,
          category: category,
          color: colorMap[category] ?? Colors.grey,
        );
      }).toList();
      if (mounted) {
        setState(() {
          _allTraits = loadedTraits;
          _isLoading = false;
          _filterTraits();
        });
      }
    } catch (e, s) {
      debugPrint('Failed to load traits: $e\n$s');
      if (mounted) {
        setState(() => _isLoading = false);
        // Optionally, show an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not load traits.')),
        );
        Navigator.of(context).pop(); // Close the dialog on error
      }
    }
  }

  void _filterTraits() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTraits = _allTraits.where((trait) {
        final categoryMatch = trait.category == _selectedCategory;
        final queryMatch =
            query.isEmpty ||
            trait.title.toLowerCase().contains(query) ||
            trait.description.toLowerCase().contains(query);
        return categoryMatch && queryMatch;
      }).toList();
    });
  }

  void _toggleTraitSelection(Trait trait) {
    setState(() {
      if (_selectedTraitTitles.contains(trait.title)) {
        _selectedTraitTitles.remove(trait.title);
      } else {
        _selectedTraitTitles.add(trait.title);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: Builder(
        builder: (context) {
          return AlertDialog(
            // Using AlertDialog for standard dialog structure
            title: const Text('Comprehensive Trait Selection'),
            content: SizedBox(
              width:
                  MediaQuery.of(context).size.width *
                  0.7, // 70% of screen width
              height:
                  MediaQuery.of(context).size.height *
                  0.75, // 75% of screen height
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select any number of traits from the list below.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search ${_allTraits.length} traits...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Chip(
                              label: Text(
                                '${_selectedTraitTitles.length} Traits Selected',
                              ),
                              backgroundColor: theme.colorScheme.primary,
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8.0,
                          children: _categories.map((category) {
                            final count = _allTraits
                                .where((t) => t.category == category)
                                .length;
                            return ChoiceChip(
                              label: Text('$category ($count)'),
                              selected: _selectedCategory == category,
                              onSelected: (isSelected) {
                                if (isSelected) {
                                  setState(() {
                                    _selectedCategory = category;
                                    _filterTraits();
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const Divider(height: 24),
                        Expanded(
                          child: _filteredTraits.isEmpty
                              ? const Center(child: Text('No traits found.'))
                              : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 350,
                                        childAspectRatio: 2.5,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                      ),
                                  itemCount: _filteredTraits.length,
                                  itemBuilder: (context, index) {
                                    final trait = _filteredTraits[index];
                                    final isSelected = _selectedTraitTitles
                                        .contains(trait.title);
                                    return _TraitCard(
                                      trait: trait,
                                      isSelected: isSelected,
                                      onTap: () => _toggleTraitSelection(trait),
                                    );
                                  },
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
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(_selectedTraitTitles),
                child: Text(
                  'Confirm Selection (${_selectedTraitTitles.length})',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TraitCard extends StatelessWidget {
  final Trait trait;
  final bool isSelected;
  final VoidCallback onTap;

  const _TraitCard({
    required this.trait,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      clipBehavior: Clip
          .antiAlias, // Important for the gradient to respect rounded corners
      child: Stack(
        children: [
          // Animated Gradient Layer using Transform
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            transform: isSelected
                ? Matrix4.identity()
                : Matrix4.translationValues(350, 0, 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    trait.color.withAlpha(0),
                    trait.color.withAlpha(51), // 0.2 * 255
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          // Content Layer
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: _CategoryIcon(category: trait.category),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: trait.title,
                          child: Text(
                            trait.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Tooltip(
                          message: trait.description,
                          child: Text(
                            trait.description,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ), // Closes Row
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String category;

  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String svgData;
    switch (category) {
      case 'Positive':
        color = Colors.green;
        // SVG for a check mark
        svgData =
            '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>';
        break;
      case 'Neutral':
        color = Colors.amber;
        // SVG for a plus sign
        svgData =
            '<svg viewBox="0 0 24 24"><path fill="white" d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/></svg>';
        break;
      case 'Negative':
        color = Colors.red;
        // SVG for a cross (X)
        svgData =
            '<svg viewBox="0 0 24 24"><path fill="white" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></svg>';
        break;
      default:
        color = Colors.grey;
        svgData =
            '<svg viewBox="0 0 24 24"><path fill="white" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z"/></svg>';
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Padding(
        padding: const EdgeInsets.all(4.0), // Adjust padding for icon size
        child: SvgPicture.string(svgData),
      ),
    );
  }
}
