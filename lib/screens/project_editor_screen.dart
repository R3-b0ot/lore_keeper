import 'package:flutter/material.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/modules/manuscript_module.dart'; // Import the new module
import 'package:lore_keeper/modules/character_module.dart'; // Import the new module
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/providers/link_provider.dart';
import 'package:lore_keeper/widgets/chapter_title_dialog.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/widgets/character_list_pane.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/widgets/settings_dialog.dart';
import 'package:lore_keeper/widgets/keyboard_aware_dialog.dart';
import 'package:lore_keeper/widgets/history_panel.dart';
import 'package:lore_keeper/widgets/ai_features_dialog.dart';

// -----------------------------------------------------------------
// Project Editor Screen (Four-Column Layout with Expandable Sidebar)
// -----------------------------------------------------------------

class ProjectEditorScreen extends StatefulWidget {
  final Project project;

  const ProjectEditorScreen({super.key, required this.project});

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  int _moduleIndex = 0;
  String _selectedChapterKey = '';
  String _selectedCharacterKey = '';

  bool _isSidebarExpanded = false;
  bool _isHistoryPanelVisible = false;
  bool _isMobile = false;

  final GlobalKey<State<ManuscriptEditor>> _projectEditorKey = GlobalKey(
    debugLabel: 'ManuscriptEditor',
  );

  final GlobalKey<CharacterModuleState> _characterModuleKey = GlobalKey(
    debugLabel: 'CharacterModule',
  );

  ChapterListProvider? _chapterListProvider;
  CharacterListProvider? _characterListProvider;
  LinkProvider? _linkProvider;

  final List<Map<String, dynamic>> _moduleItems = const <Map<String, dynamic>>[
    {'label': 'Manuscript', 'icon': Icons.menu_book},
    {'label': 'Characters', 'icon': Icons.person}, // Changed icon
    {'label': 'Timeline', 'icon': Icons.timeline},
    {'label': 'Maps', 'icon': Icons.map}, // Replaced 'World'
    {'label': 'Calendar', 'icon': Icons.calendar_today},
    {'label': 'Encyclopedia', 'icon': Icons.library_books},
    {'label': 'Magic', 'icon': Icons.auto_awesome},
    {'label': 'Languages', 'icon': Icons.translate},
    {'label': 'Research', 'icon': Icons.science_outlined}, // Changed icon
    {'label': 'Locations', 'icon': Icons.location_on},
    {'label': 'Arcs', 'icon': Icons.insights},
    {'label': 'Relationships', 'icon': Icons.link}, // Changed icon
    {'label': 'Items', 'icon': Icons.category},
    {'label': 'Species', 'icon': Icons.pets},
    {'label': 'Cultures', 'icon': Icons.diversity_3},
    {'label': 'Philosophies', 'icon': Icons.psychology_alt},
    {'label': 'Religions', 'icon': Icons.church},
    {'label': 'Systems', 'icon': Icons.schema},
  ];

  @override
  void initState() {
    super.initState();
    _chapterListProvider = ChapterListProvider(widget.project.key);
    _characterListProvider = CharacterListProvider(widget.project.key);
    _linkProvider = LinkProvider();
    _chapterListProvider!.addListener(() {
      // Also check for initial character selection here, in case chapters load first
      if (mounted &&
          _characterListProvider!.isInitialized &&
          _characterListProvider!.characters.isNotEmpty &&
          _selectedCharacterKey.isEmpty) {
        _onCharacterSelected(
          _characterListProvider!.characters.first.key.toString(),
        );
      }
      if (mounted &&
          _chapterListProvider!.isInitialized &&
          _chapterListProvider!.chapters.isNotEmpty) {
        // Only set the initial chapter if one isn't already selected.
        if (_selectedChapterKey.isEmpty) {
          setState(() {
            // Prioritize the last edited chapter, otherwise fall back to the first.
            _selectedChapterKey =
                widget.project.lastEditedChapterKey ??
                _chapterListProvider!.chapters.first.key.toString();
          });
        }
      }
    });

    _characterListProvider!.addListener(() {
      if (mounted &&
          _characterListProvider!.isInitialized &&
          _characterListProvider!.characters.isNotEmpty) {
        if (_selectedCharacterKey.isEmpty) {
          setState(
            () => _selectedCharacterKey = _characterListProvider!
                .characters
                .first
                .key
                .toString(),
          );
        }
      }
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  void _onModuleTapped(int index) {
    setState(() {
      _moduleIndex = index;
    });
  }

  void _onChapterSelected(String key, {bool closeDrawer = false}) {
    setState(() {
      _selectedChapterKey = key;
    });

    // If the key is cleared, it means no chapters are left.
    if (key.isEmpty) {
      widget.project.lastEditedChapterKey = null;
    }
  }

  void _onCharacterSelected(String key) {
    setState(() {
      _selectedCharacterKey = key;
    });
  }

  void _goToMainScreen() {
    Navigator.of(context).pop();
  }

  void _openSettings() {
    debugPrint('Opening settings...');
    // This is where you would add a button to open the dictionary manager.
    // For demonstration, I'm adding it here.
    // In your app, you'd open SettingsDialog, which would contain a button
    // to launch DictionaryManagerDialog.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SettingsDialog(
          project: widget.project,
          moduleIndex: _moduleIndex,
          chapterProvider: _chapterListProvider!,
          characterProvider: _characterListProvider!,
          onDictionaryOpened: _handleDictionaryClose,
        );
      },
    );
  }

  void _handleDictionaryClose() {
    // After the dictionary is closed, trigger a grammar check.
    _projectEditorKey.currentState?.triggerGrammarCheck();
  }

  void _openAIFeatures() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AIFeaturesDialog();
      },
    );
  }

  void _onChapterCreated(String newKey) {
    setState(() {
      _selectedChapterKey = newKey;
    });
    // FIX: No explicit cast needed. The extension method can be called directly on the State object.
    _projectEditorKey.currentState?.loadNewChapterContent();
  }

  @override
  void dispose() {
    _chapterListProvider?.dispose();
    _characterListProvider?.dispose();
    _linkProvider?.dispose();
    super.dispose();
  }

  void _handleRevert() {
    // Use the key to directly call the reload method on the CharacterModule's state.
    _characterModuleKey.currentState?.reload();
  }

  Future<void> _onCharacterCreated() async {
    final newName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final nameController = TextEditingController();
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text('Create New Character'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Character Name'),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Name cannot be empty'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(nameController.text.trim());
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (newName != null && mounted) {
      final newKey = await _characterListProvider!.createNewCharacter(newName);
      _onCharacterSelected(newKey.toString());
    }
  }

  Future<void> _showEditNameDialog(String characterKey) async {
    final character = _characterListProvider!.characters.firstWhere(
      (c) => c.key.toString() == characterKey,
      orElse: () => Character(name: '', parentProjectId: -1),
    );
    // If the character's project ID is -1, it means it's the placeholder and wasn't found.
    if (character.parentProjectId == -1) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final nameDialogController = TextEditingController(
          text: character.name,
        );
        final formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: const Text('Edit Character'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameDialogController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Character Name'),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Name cannot be empty'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop({'action': 'delete'}),
              child: const Text(
                'Delete Character',
                style: TextStyle(color: Colors.red),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'action': 'confirm',
                    'name': nameDialogController.text.trim(),
                  });
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) return;

    if (result['action'] == 'confirm') {
      final newName = result['name'] as String;
      await _characterListProvider!.updateCharacterName(characterKey, newName);
    } else if (result['action'] == 'delete') {
      await _characterListProvider!.deleteCharacter(characterKey);
      if (mounted) {
        // After deletion, the provider reloads its list. We can now select the new first character.
        if (_characterListProvider!.characters.isNotEmpty) {
          _onCharacterSelected(
            _characterListProvider!.characters.first.key.toString(),
          );
        } else {
          _onCharacterSelected(''); // Clear selection if no characters are left
        }
      }
    }
  }

  // Helper method to build the second column based on the selected module
  Widget _buildSecondColumn() {
    if (_moduleIndex == 0) {
      return ChapterPane(
        chapterProvider: _chapterListProvider!,
        selectedChapterKey: _selectedChapterKey,
        onChapterSelected: _onChapterSelected,
        onChapterCreated: _onChapterCreated,
        isMobile: _isMobile,
      );
    } else if (_moduleIndex == 1) {
      return CharacterListPane(
        characterProvider: _characterListProvider!,
        selectedCharacterKey: _selectedCharacterKey,
        onCharacterSelected: _onCharacterSelected,
        onCharacterCreated: _onCharacterCreated,
        onCharacterEdit: _showEditNameDialog,
        isMobile: _isMobile,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildModuleContent() {
    // Get the label for the current module from the _moduleItems list
    final String currentModuleName =
        _moduleItems[_moduleIndex]['label'] as String;

    if (_moduleIndex == 0) {
      return _selectedChapterKey.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ManuscriptModule(
              projectId: widget.project.key,
              selectedChapterKey: _selectedChapterKey,
              chapterProvider: _chapterListProvider!,
              onChapterSelected: _onChapterSelected,
              key: _projectEditorKey,
            );
    } else if (_moduleIndex == 1) {
      return _selectedCharacterKey.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CharacterModule(
              characterKey: _selectedCharacterKey,
              linkProvider: _linkProvider!, // Pass the provider down
              key: _characterModuleKey, // Assign the key here
              onReload: _handleRevert,
            );
    }
    return _ModulePlaceholder(
      moduleName: currentModuleName,
      color: Colors.blueGrey,
    );
  }

  void _toggleHistoryPanel() {
    setState(() {
      _isHistoryPanelVisible = !_isHistoryPanelVisible;
    });
  }

  Future<void> _createNewChapterForMobile() async {
    final title = await _showChapterTitleDialog(context);
    if (title != null && title.isNotEmpty && mounted) {
      final newKey = await _chapterListProvider!.createNewChapter(title);
      _onChapterSelected(newKey.toString());
    }
  }

  Future<String?> _showChapterTitleDialog(
    BuildContext context, {
    String? initialTitle,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          ChapterTitleDialog(initialTitle: initialTitle ?? ''),
    );
  }

  void _showSelectionDialog() {
    if (_moduleIndex == 0) {
      // Show chapter selection dialog with front matter and search
      showDialog(
        context: context,
        builder: (BuildContext context) {
          final searchController = TextEditingController();
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Select Chapter'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search chapters...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListenableBuilder(
                          listenable: _chapterListProvider!,
                          builder: (context, child) {
                            final frontPage = _chapterListProvider!.frontPage;
                            final indexPage = _chapterListProvider!.indexPage;
                            final aboutAuthorPage =
                                _chapterListProvider!.aboutAuthorPage;
                            final chapters = _chapterListProvider!.chapters;

                            final allItems = <Chapter>[];
                            if (frontPage != null) allItems.add(frontPage);
                            if (indexPage != null) allItems.add(indexPage);
                            if (aboutAuthorPage != null) {
                              allItems.add(aboutAuthorPage);
                            }
                            allItems.addAll(chapters);

                            final query = searchController.text.toLowerCase();
                            final filteredItems = allItems
                                .where(
                                  (item) =>
                                      item.title.toLowerCase().contains(query),
                                )
                                .toList();

                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final chapter = filteredItems[index];
                                final isSelected =
                                    chapter.key.toString() ==
                                    _selectedChapterKey;
                                final isFrontMatter = chapter.key
                                    .toString()
                                    .startsWith('front_matter_');
                                final displayTitle = isFrontMatter
                                    ? chapter.title
                                    : '${chapter.orderIndex + 1}. ${chapter.title}';
                                return ListTile(
                                  title: Text(displayTitle),
                                  selected: isSelected,
                                  onTap: () {
                                    _onChapterSelected(chapter.key.toString());
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
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
                ],
              );
            },
          );
        },
      );
    } else if (_moduleIndex == 1) {
      // Show character selection dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Character'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListenableBuilder(
                listenable: _characterListProvider!,
                builder: (context, child) {
                  final characters = _characterListProvider!.characters;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: characters.length,
                    itemBuilder: (context, index) {
                      final character = characters[index];
                      final isSelected =
                          character.key.toString() == _selectedCharacterKey;
                      return ListTile(
                        title: Text(character.name),
                        selected: isSelected,
                        onTap: () {
                          _onCharacterSelected(character.key.toString());
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
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
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _isMobile = constraints.maxWidth < 600;
        if (_isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    final double collapsedWidth = 60.0;
    final double expandedWidth = _isMobile && _isSidebarExpanded
        ? 400.0
        : 200.0;

    return Scaffold(
      appBar: null,
      body: Row(
        children: [
          // ------------------------------------------
          // 1. Module Bar (Leftmost Column - Animated)
          // ------------------------------------------
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _isSidebarExpanded ? expandedWidth : collapsedWidth,
            color: Theme.of(context).colorScheme.surface,
            child: ModuleSidebar(
              isExpanded: _isSidebarExpanded,
              moduleItems: _moduleItems,
              selectedIndex: _moduleIndex,
              onModuleTapped: _onModuleTapped,
              onToggleExpanded: _toggleSidebar,
              projectTitle: widget.project.title,
              onGoHome: _goToMainScreen,
              onOpenSettings: _openSettings,
            ),
          ),

          // ------------------------------------------
          // 2. Second Column (Chapter Pane or Character List Pane)
          // ------------------------------------------
          Expanded(
            flex: 1,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildSecondColumn(),
            ),
          ),

          // Vertical divider between Second Column and Editor
          (_moduleIndex == 0 || _moduleIndex == 1)
              ? const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey,
                )
              : const SizedBox.shrink(),

          // ------------------------------------------
          // 3. Word Editor / Main Content Area (Third Column)
          // ------------------------------------------
          Expanded(flex: 3, child: _buildModuleContent()),

          // --- HISTORY PANEL (Conditionally visible) ---
          if (_isHistoryPanelVisible &&
              (_moduleIndex == 0 || _moduleIndex == 1)) ...[
            const VerticalDivider(width: 1, thickness: 1),
            if (_moduleIndex == 0) // Manuscript
              HistoryPanel(
                targetKey: _selectedChapterKey.startsWith('front_matter_')
                    ? _selectedChapterKey
                    : int.tryParse(_selectedChapterKey),
                targetType: 'Chapter',
                onClose: _toggleHistoryPanel,
                onReverted: _handleRevert,
              ),
            if (_moduleIndex == 1) // Character
              HistoryPanel(
                targetKey: int.tryParse(_selectedCharacterKey),
                targetType: 'Character',
                onClose: _toggleHistoryPanel,
                onReverted: _handleRevert,
              ),
          ],

          // Vertical divider before the rightmost bar
          const VerticalDivider(width: 1, thickness: 1),

          // ------------------------------------------
          // 4. Specific Functions Bar (Rightmost Column)
          // ------------------------------------------
          Container(
            width: 48,
            color: Theme.of(context).colorScheme.surface,
            child: SpecificFunctionsBar(
              onHistoryPressed: _toggleHistoryPanel,
              isHistoryVisible: _isHistoryPanelVisible,
              // Only show history button for relevant modules
              showHistoryButton:
                  _moduleIndex == 0 ||
                  _moduleIndex == 1, // Manuscript or Character
              onSettingsPressed: _openSettings,
              onAIPressed: _openAIFeatures,
              isMobile: _isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    final String currentModuleName =
        _moduleItems[_moduleIndex]['label'] as String;
    return Scaffold(
      appBar: AppBar(
        title: Text(currentModuleName),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (_moduleIndex == 0 || _moduleIndex == 1)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'select':
                    _showSelectionDialog();
                  case 'history':
                    _toggleHistoryPanel();
                  case 'add':
                    if (_moduleIndex == 0) {
                      _createNewChapterForMobile();
                    } else if (_moduleIndex == 1) {
                      _onCharacterCreated();
                    }
                  case 'settings':
                    _openSettings();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'select',
                  child: Text(
                    _moduleIndex == 0 ? 'Select Chapter' : 'Select Character',
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'history',
                  child: Text(
                    _isHistoryPanelVisible ? 'Hide History' : 'Show History',
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'add',
                  child: Text(
                    _moduleIndex == 0 ? 'Add New Chapter' : 'Add New Character',
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Text('Settings'),
                ),
              ],
            ),
        ],
      ),
      drawer: Drawer(
        child: ModuleSidebar(
          isExpanded: true,
          moduleItems: _moduleItems,
          selectedIndex: _moduleIndex,
          onModuleTapped: (index) {
            _onModuleTapped(index);
            Navigator.of(context).pop(); // Close drawer
          },
          onToggleExpanded: () {}, // Not needed in drawer
          projectTitle: widget.project.title,
          onGoHome: () {
            _goToMainScreen();
            Navigator.of(context).pop();
          },
          onOpenSettings: () {
            _openSettings();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Main Content
          Expanded(child: _buildModuleContent()),
          // History Panel if visible
          if (_isHistoryPanelVisible &&
              (_moduleIndex == 0 || _moduleIndex == 1))
            SizedBox(
              height: 200,
              child: _moduleIndex == 0
                  ? HistoryPanel(
                      targetKey: _selectedChapterKey.startsWith('front_matter_')
                          ? _selectedChapterKey
                          : int.tryParse(_selectedChapterKey),
                      targetType: 'Chapter',
                      onClose: _toggleHistoryPanel,
                      onReverted: _handleRevert,
                    )
                  : HistoryPanel(
                      targetKey: int.tryParse(_selectedCharacterKey),
                      targetType: 'Character',
                      onClose: _toggleHistoryPanel,
                      onReverted: _handleRevert,
                    ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_moduleIndex == 0) {
            // Add chapter
            _createNewChapterForMobile();
          } else if (_moduleIndex == 1) {
            // Add character
            _onCharacterCreated();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// -------------------------------------------------------------
// --- ModuleSidebar Widget
// -------------------------------------------------------------

class ModuleSidebar extends StatelessWidget {
  final bool isExpanded;
  final List<Map<String, dynamic>> moduleItems;
  final int selectedIndex;
  final ValueChanged<int> onModuleTapped;
  final VoidCallback onToggleExpanded;
  final String projectTitle;
  final VoidCallback onGoHome;
  final VoidCallback onOpenSettings;

  const ModuleSidebar({
    super.key,
    required this.isExpanded,
    required this.moduleItems,
    required this.selectedIndex,
    required this.onModuleTapped,
    required this.onToggleExpanded,
    required this.projectTitle,
    required this.onGoHome,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Project Title Header Area
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          child: Column(
            children: [
              // Hamburger Menu Button (Replaces Add Button)
              IconButton(
                onPressed: onToggleExpanded,
                icon: Icon(
                  isExpanded ? Icons.close : Icons.menu,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              // Project Icon and Title (Moved from AppBar)
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.yellow,
                        size: 24,
                      ), // Placeholder Genre Icon
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          projectTitle,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Icon(
                  Icons.star,
                  color: Colors.yellow,
                  size: 24,
                ), // Collapsed Icon
            ],
          ),
        ),
        const Divider(height: 1),

        // Navigation Buttons (Scrollable Section)
        Expanded(
          child: ListView.builder(
            itemCount: moduleItems.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> item = moduleItems[index];
              return ModuleSidebarItem(
                index: index,
                item: item,
                isSelected: index == selectedIndex,
                isExpanded: isExpanded,
                onTap: onModuleTapped,
              );
            },
          ),
        ),

        const Divider(height: 1),

        // Fixed Footer Items
        // Home Button
        _FooterSidebarItem(
          icon: Icons.home,
          label: 'Home',
          isExpanded: isExpanded,
          // ignore: avoid_redundant_argument_values
          onTap: onGoHome,
        ),

        // Settings Button
        _FooterSidebarItem(
          icon: Icons.settings,
          label: 'Settings',
          isExpanded: isExpanded,
          onTap: onOpenSettings,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// -------------------------------------------------------------
// --- ModuleSidebarItem
// -------------------------------------------------------------

class ModuleSidebarItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final bool isSelected;
  final bool isExpanded;
  final ValueChanged<int> onTap;

  const ModuleSidebarItem({
    super.key,
    required this.index,
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color iconColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    Color textColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        height: 56,
        width: double.infinity,
        color: isSelected ? colorScheme.primaryContainer : null,
        padding: isExpanded
            ? const EdgeInsets.symmetric(horizontal: 16)
            : EdgeInsets.zero,
        child: isExpanded
            ? Row(
                children: [
                  Icon(item['icon'] as IconData, color: iconColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    item['label'].toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Tooltip(
                message: item['label'],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'] as IconData, color: iconColor, size: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

// -------------------------------------------------------------
// --- _FooterSidebarItem
// -------------------------------------------------------------

class _FooterSidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FooterSidebarItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        padding: isExpanded
            ? const EdgeInsets.symmetric(horizontal: 16)
            : EdgeInsets.zero,
        child: isExpanded
            ? Row(
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: iconColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Tooltip(
                message: label,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(icon, color: iconColor, size: 20)],
                ),
              ),
      ),
    );
  }
}

// -------------------------------------------------------------
// --- Other Placeholder Widgets (Included for completeness)
// -------------------------------------------------------------

class ChapterPane extends StatefulWidget {
  final ChapterListProvider chapterProvider;
  final String selectedChapterKey;
  final Function(String key, {bool closeDrawer}) onChapterSelected;
  final ValueChanged<String> onChapterCreated;
  final bool isMobile;

  const ChapterPane({
    super.key,
    required this.chapterProvider,
    required this.selectedChapterKey,
    required this.onChapterSelected,
    required this.onChapterCreated,
    required this.isMobile,
  });

  @override
  State<ChapterPane> createState() => _ChapterPaneState();
}

class _ChapterPaneState extends State<ChapterPane> {
  bool _isFrontMatterExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: ListenableBuilder(
        listenable: widget.chapterProvider,
        builder: (context, child) {
          final chapters = widget.chapterProvider.chapters;
          final frontPage = widget.chapterProvider.frontPage;
          final indexPage = widget.chapterProvider.indexPage;
          final aboutAuthorPage = widget.chapterProvider.aboutAuthorPage;

          final itemCount = chapters.isEmpty ? 2 : chapters.length + 1;

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: ReorderableListView.builder(
              itemCount: itemCount,
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex == 0 || newIndex == 0) return;
                widget.chapterProvider.reorderChapter(
                  oldIndex - 1,
                  newIndex - 1,
                );
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    key: const ValueKey('header'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Manuscript',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildExpandableButton(
                          context: context,
                          icon: _isFrontMatterExpanded
                              ? Icons.folder_open
                              : Icons.folder,
                          label: 'Front Matter',
                          isExpanded: _isFrontMatterExpanded,
                          onPressed: () {
                            setState(() {
                              _isFrontMatterExpanded = !_isFrontMatterExpanded;
                            });
                          },
                        ),
                        if (_isFrontMatterExpanded)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 24.0,
                              top: 4.0,
                            ),
                            child: Column(
                              children: [
                                if (frontPage != null)
                                  _buildFrontMatterItem(
                                    context,
                                    frontPage,
                                    widget.selectedChapterKey,
                                    (key) => widget.onChapterSelected(
                                      key,
                                      closeDrawer: true,
                                    ),
                                  ),
                                if (indexPage != null)
                                  _buildFrontMatterItem(
                                    context,
                                    indexPage,
                                    widget.selectedChapterKey,
                                    (key) => widget.onChapterSelected(
                                      key,
                                      closeDrawer: true,
                                    ),
                                  ),
                                if (aboutAuthorPage != null)
                                  _buildFrontMatterItem(
                                    context,
                                    aboutAuthorPage,
                                    widget.selectedChapterKey,
                                    (key) => widget.onChapterSelected(
                                      key,
                                      closeDrawer: true,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        _buildAddButton(
                          context,
                          Icons.add,
                          'New Chapter',
                          () async {
                            final title = await _showChapterTitleDialog(
                              context,
                            );
                            if (title != null && title.isNotEmpty) {
                              final newKey = await widget.chapterProvider
                                  .createNewChapter(title);
                              widget.onChapterCreated(newKey.toString());
                            }
                          },
                        ),
                        const Divider(height: 32),
                        const Text(
                          'Body',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                } else if (chapters.isEmpty) {
                  return Container(
                    key: const ValueKey('empty'),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('No chapters found.'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _createNewChapter(context),
                              child: const Text('Create New Chapter'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  final chapterIndex = index - 1;
                  final chapter = chapters[chapterIndex];
                  final isSelected =
                      chapter.key.toString() == widget.selectedChapterKey;
                  return Padding(
                    key: ValueKey(chapter.key),
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.drag_indicator,
                              color: Color(0x00808080),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildButton(
                            context,
                            Icons.person_outline,
                            '${chapter.orderIndex + 1}. ${chapter.title}',
                            isSelected,
                            onPressed: () => widget.onChapterSelected(
                              chapter.key.toString(),
                              closeDrawer: true,
                            ),
                            onRename: () async {
                              final newTitle = await _showChapterTitleDialog(
                                context,
                                initialTitle: chapter.title,
                              );
                              if (newTitle != null &&
                                  newTitle.isNotEmpty &&
                                  newTitle != chapter.title) {
                                widget.chapterProvider.updateChapterTitle(
                                  chapter.key as int,
                                  newTitle,
                                );
                              }
                            },
                            onDelete: () async {
                              final confirmed = await _showDeleteConfirmDialog(
                                context,
                                chapter.title,
                              );
                              if (confirmed == true) {
                                final currentIndex = chapters.indexOf(chapter);
                                await widget.chapterProvider.deleteChapter(
                                  chapter.key as int,
                                );

                                // After deletion, select a new chapter or clear the selection.
                                if (widget
                                    .chapterProvider
                                    .chapters
                                    .isNotEmpty) {
                                  final newIndex = (currentIndex > 0)
                                      ? currentIndex - 1
                                      : 0;
                                  // Ensure the index is valid for the new list length.
                                  if (newIndex <
                                      widget.chapterProvider.chapters.length) {
                                    widget.onChapterSelected(
                                      widget
                                          .chapterProvider
                                          .chapters[newIndex]
                                          .key
                                          .toString(),
                                    );
                                  } else {
                                    // Fallback if index logic fails, select the first.
                                    widget.onChapterSelected(
                                      widget.chapterProvider.chapters.first.key
                                          .toString(),
                                    );
                                  }
                                } else {
                                  widget.onChapterSelected(
                                    '',
                                  ); // No chapters left
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _createNewChapter(BuildContext context) async {
    final title = await _showChapterTitleDialog(context);
    if (title != null && title.isNotEmpty) {
      final newKey = await widget.chapterProvider.createNewChapter(title);
      widget.onChapterCreated(newKey.toString());
    }
  }

  Future<String?> _showChapterTitleDialog(
    BuildContext context, {
    String? initialTitle,
  }) {
    return showDialog<String>(
      context: context, // Use the context from the build method
      barrierDismissible: false, // Let KeyboardAwareDialog handle dismissal
      builder: (dialogContext) =>
          ChapterTitleDialog(initialTitle: initialTitle ?? ''),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(
    BuildContext context,
    String chapterTitle,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Let KeyboardAwareDialog handle dismissal
      builder: (context) => KeyboardAwareDialog(
        onConfirm: () => Navigator.of(context).pop(true),
        title: const Text('Delete Chapter'),
        content: Text(
          'Are you sure you want to delete "$chapterTitle"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isExpanded,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurface),
            const SizedBox(width: 8),
            Expanded(child: Text(label, softWrap: true)),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontMatterItem(
    BuildContext context,
    Chapter chapter,
    String selectedChapterKey,
    ValueChanged<String> onChapterSelected, // This is now just a key
  ) {
    final isSelected = chapter.key.toString() == selectedChapterKey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: _buildButton(
        context,
        Icons.article_outlined,
        chapter.title,
        isSelected,
        onPressed: () => onChapterSelected(chapter.key),
        // No rename/delete for front matter pages for now
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected, {
    required VoidCallback onPressed,
    VoidCallback? onRename,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final theme = Theme.of(context); // Now context is available
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: 16,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
            label: Text(label, softWrap: true),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              backgroundColor: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surface,
              foregroundColor: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface,
              side: BorderSide(
                // This was correct
                color: isSelected ? colorScheme.primary : colorScheme.outline,
              ),
              shape: onRename != null
                  ? const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (onRename != null)
          if (!widget.isMobile)
            _buildKebabMenu(
              context: context,
              isSelected: isSelected,
              onRename: onRename,
              onEdit: onEdit,
              onDelete: onDelete, // Pass the onDelete callback
            )
          else
            Container(
              width: 80,
              height: 36,
              margin: const EdgeInsets.only(left: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surface,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 18,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      onPressed: onRename,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  if (onDelete != null)
                    Expanded(
                      child: IconButton(
                        icon: Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildKebabMenu({
    required BuildContext context,
    required bool isSelected,
    required VoidCallback onRename,
    required VoidCallback? onEdit,
    required VoidCallback? onDelete,
  }) {
    final theme = Theme.of(context); // Now context is available
    final colorScheme = theme.colorScheme;
    return Container(
      width: 40,
      height: 36,
      margin: const EdgeInsets.only(left: 1),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outline,
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'rename') {
            onRename();
          } else if (value == 'edit' && onEdit != null) {
            // This was correct
            onEdit.call();
          } else if (value == 'delete') {
            onDelete?.call();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'rename', child: Text('Rename')),
          if (onEdit != null) // This was correct
            const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
          if (onDelete != null) // This was correct
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
        ],
        icon: Icon(
          Icons.more_vert,
          size: 18,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
        tooltip: 'More options',
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context); // Now context is available
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: theme.colorScheme.primary),
        label: Text(label, style: TextStyle(color: theme.colorScheme.primary)),
      ),
    );
  }
}

class _ModulePlaceholder extends StatelessWidget {
  final String moduleName;
  final Color color;

  const _ModulePlaceholder({required this.moduleName, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // This will take the available space
      color: Theme.of(context).canvasColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              moduleName,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Module Editor is currently active in this panel.'),
          ],
        ),
      ),
    );
  }
}

class SpecificFunctionsBar extends StatelessWidget {
  final VoidCallback onHistoryPressed;
  final bool isHistoryVisible;
  final bool showHistoryButton;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onAIPressed;
  final bool isMobile;

  const SpecificFunctionsBar({
    super.key,
    required this.onHistoryPressed,
    required this.isHistoryVisible,
    required this.showHistoryButton,
    this.onSettingsPressed,
    this.onAIPressed,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'history':
                  onHistoryPressed();
                  break;
                case 'settings':
                  onSettingsPressed?.call();
                  break;
                // Other items have no action
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (showHistoryButton)
                PopupMenuItem<String>(
                  value: 'history',
                  child: Text(
                    isHistoryVisible ? 'Hide History' : 'Show History',
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'bookmarks',
                child: Text('Bookmarks'),
              ),
              const PopupMenuItem<String>(
                value: 'comments',
                child: Text('Comments'),
              ),
              const PopupMenuItem<String>(
                value: 'add_block',
                child: Text('Add Block'),
              ),
              const PopupMenuItem<String>(
                value: 'download',
                child: Text('Download'),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (showHistoryButton)
            IconButton(
              icon: Icon(
                isHistoryVisible ? Icons.history_toggle_off : Icons.history,
              ),
              onPressed: onHistoryPressed,
              tooltip: isHistoryVisible ? 'Hide History' : 'Show History',
            ),
          if (onAIPressed != null)
            IconButton(
              icon: const Icon(Icons.smart_toy),
              onPressed: onAIPressed,
              tooltip: 'AI Features',
            ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: null,
            tooltip: 'Bookmarks',
          ),
          IconButton(
            icon: const Icon(Icons.comment),
            onPressed: null,
            tooltip: 'Comments',
          ),
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: null,
            tooltip: 'Add Block',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: null,
            tooltip: 'Download',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: onSettingsPressed,
            tooltip: 'Settings',
          ),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      );
    }
  }
}
