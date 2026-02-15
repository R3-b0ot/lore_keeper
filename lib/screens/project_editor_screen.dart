import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/modules/manuscript_module.dart'; // Import the new module
import 'package:lore_keeper/modules/character_module.dart'; // Import the new module
import 'package:lore_keeper/modules/map_module.dart'; // Import the new module
import 'package:lore_keeper/modules/magic_module.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/providers/link_provider.dart';
import 'package:lore_keeper/providers/magic_tree_provider.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/widgets/chapter_list_pane.dart';
import 'package:lore_keeper/widgets/character_list_pane.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/widgets/history_panel.dart';
import 'package:lore_keeper/widgets/project_editor/chapter_selection_dialog.dart';
import 'package:lore_keeper/widgets/project_editor/character_selection_dialog.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_actions.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_dialogs.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_desktop_layout.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_mobile_layout.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_module_resolver.dart';

import 'package:lore_keeper/widgets/find_replace_dialog.dart';
import 'package:lore_keeper/providers/map_list_provider.dart';
import 'package:lore_keeper/widgets/map_list_pane.dart';
import 'package:lore_keeper/widgets/magic_list_pane.dart';

// -----------------------------------------------------------------
// Project Editor Screen (Four-Column Layout with Expandable Sidebar)
// -----------------------------------------------------------------

class ProjectEditorScreen extends StatefulWidget {
  final Project project;
  final int? initialModuleIndex;
  final String? initialChapterKey;
  final String? initialCharacterKey;
  final String? initialMapKey;

  const ProjectEditorScreen({
    super.key,
    required this.project,
    this.initialModuleIndex,
    this.initialChapterKey,
    this.initialCharacterKey,
    this.initialMapKey,
  });

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  int _moduleIndex = 0;
  String _selectedChapterKey = '';
  String _selectedCharacterKey = '';
  String _selectedMapKey = '';

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
  MapListProvider? _mapListProvider;
  MagicTreeProvider? _magicTreeProvider;
  LinkProvider? _linkProvider;

  final List<Map<String, dynamic>> _moduleItems = const <Map<String, dynamic>>[
    {'label': 'Manuscript', 'icon': LucideIcons.bookOpen},
    {'label': 'Characters', 'icon': LucideIcons.user}, // Changed icon
    {'label': 'Maps', 'icon': LucideIcons.map},
    {'label': 'Timeline', 'icon': LucideIcons.chartLine},
    {'label': 'Calendar', 'icon': LucideIcons.calendar},
    {'label': 'Encyclopedia', 'icon': LucideIcons.library},
    {'label': 'Magic', 'icon': LucideIcons.sparkles},
    {'label': 'Languages', 'icon': LucideIcons.languages},
    {'label': 'Research', 'icon': LucideIcons.flaskConical}, // Changed icon
    {'label': 'Locations', 'icon': LucideIcons.mapPin},
    {'label': 'Arcs', 'icon': LucideIcons.chartLine},
    {'label': 'Relationships', 'icon': LucideIcons.link}, // Changed icon
    {'label': 'Items', 'icon': LucideIcons.tag},
    {'label': 'Species', 'icon': LucideIcons.pawPrint},
    {'label': 'Cultures', 'icon': LucideIcons.usersRound},
    {'label': 'Philosophies', 'icon': LucideIcons.brain},
    {'label': 'Religions', 'icon': LucideIcons.church},
    {'label': 'Systems', 'icon': LucideIcons.chartNetwork},
  ];

  @override
  void initState() {
    super.initState();
    _moduleIndex = widget.initialModuleIndex ?? 0;
    _selectedChapterKey = widget.initialChapterKey ?? '';
    _selectedCharacterKey = widget.initialCharacterKey ?? '';
    _selectedMapKey = widget.initialMapKey ?? '';

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
                widget.project.lastEditedChapterKey?.toString() ??
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

    _mapListProvider = MapListProvider(widget.project.key);
    _mapListProvider!.addListener(() {
      if (mounted &&
          _mapListProvider!.isInitialized &&
          _mapListProvider!.maps.isNotEmpty) {
        if (_selectedMapKey.isEmpty) {
          setState(
            () => _selectedMapKey = _mapListProvider!.maps.first.key.toString(),
          );
        }
      }
    });

    _magicTreeProvider = MagicTreeProvider(widget.project.key);
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
    showProjectSettingsDialog(
      context,
      project: widget.project,
      moduleIndex: _moduleIndex,
      chapterProvider: _chapterListProvider!,
      characterProvider: _characterListProvider!,
      onDictionaryOpened: _handleDictionaryClose,
    );
  }

  void _handleDictionaryClose() {
    // After the dictionary is closed, trigger a grammar check.
    final manuscriptEditor =
        _projectEditorKey.currentWidget as ManuscriptEditor?;
    manuscriptEditor?.triggerGrammarCheck();
  }

  void _openFindReplaceDialog() {
    // Only allow for manuscript module
    if (_moduleIndex != 0) return;
    // Get the controller from the manuscript module
    final manuscriptEditor =
        _projectEditorKey.currentWidget as ManuscriptEditor?;
    final controller = manuscriptEditor?.getController();
    if (controller != null) {
      // Unfocus any focused widget to avoid keyboard event conflicts
      FocusScope.of(context).unfocus();
      // Delay the dialog opening to ensure keyboard events are processed
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return FindReplaceDialog(controller: controller);
            },
          );
        }
      });
    }
  }

  void _onChapterCreated(String newKey) {
    setState(() {
      _selectedChapterKey = newKey;
    });
    // FIX: No explicit cast needed. The extension method can be called directly on the State object.
    final manuscriptEditor =
        _projectEditorKey.currentWidget as ManuscriptEditor?;
    manuscriptEditor?.loadNewChapterContent();
  }

  @override
  void dispose() {
    _chapterListProvider?.dispose();
    _characterListProvider?.dispose();
    _linkProvider?.dispose();
    _magicTreeProvider?.dispose();
    super.dispose();
  }

  void _handleRevert() {
    // Use the key to directly call the reload method on the CharacterModule's state.
    _characterModuleKey.currentState?.reload();
  }

  Future<void> _onCharacterCreated() async {
    final newName = await showCreateCharacterDialog(context);

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

    final result = await showEditCharacterDialog(
      context,
      initialName: character.name,
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
      return ChapterListPane(
        chapterProvider: _chapterListProvider!,
        selectedChapterKey: _selectedChapterKey,
        onChapterSelected: (key, {bool closeDrawer = false}) =>
            _onChapterSelected(key),
        onChapterCreated: (key) => _onChapterCreated(key),
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
    } else if (_moduleIndex == 2) {
      return MapListPane(
        mapProvider: _mapListProvider!,
        selectedMapKey: _selectedMapKey,
        onMapSelected: (key) => setState(() => _selectedMapKey = key),
        isMobile: _isMobile,
      );
    } else if (_moduleIndex == 6) {
      return MagicListPane(
        magicProvider: _magicTreeProvider!,
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
              onControllerReady: (QuillController? controller) {
                // Controller ready
              },
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
    } else if (_moduleIndex == 2) {
      return MapModule(
        projectId: widget.project.key,
        mapProvider: _mapListProvider!,
        selectedMapKey: _selectedMapKey,
        onReload: _handleRevert,
      );
    } else if (_moduleIndex == 6) {
      return MagicModule(magicProvider: _magicTreeProvider!);
    }
    return _ModulePlaceholder(
      moduleName: currentModuleName,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  void _toggleHistoryPanel() {
    setState(() {
      _isHistoryPanelVisible = !_isHistoryPanelVisible;
    });
  }

  Future<void> _createNewChapterForMobile() async {
    final title = await showChapterTitleDialog(context);
    if (title != null && title.isNotEmpty && mounted) {
      final newKey = await _chapterListProvider!.createNewChapter(title);
      _onChapterSelected(newKey.toString());
    }
  }

  void _showSelectionDialog() {
    if (_moduleIndex == 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ChapterSelectionDialog(
            chapterProvider: _chapterListProvider!,
            selectedChapterKey: _selectedChapterKey,
            onChapterSelected: _onChapterSelected,
          );
        },
      );
    } else if (_moduleIndex == 1) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CharacterSelectionDialog(
            characterProvider: _characterListProvider!,
            selectedCharacterKey: _selectedCharacterKey,
            onCharacterSelected: _onCharacterSelected,
          );
        },
      );
    }
  }

  Widget? _buildHistoryPanel() {
    if (_moduleIndex == 0) {
      return HistoryPanel(
        targetKey: _selectedChapterKey.startsWith('front_matter_')
            ? _selectedChapterKey
            : int.tryParse(_selectedChapterKey),
        targetType: 'Chapter',
        onClose: _toggleHistoryPanel,
        onReverted: _handleRevert,
      );
    }
    if (_moduleIndex == 1) {
      return HistoryPanel(
        targetKey: int.tryParse(_selectedCharacterKey),
        targetType: 'Character',
        onClose: _toggleHistoryPanel,
        onReverted: _handleRevert,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _isMobile = constraints.maxWidth < 600;
        final moduleResolver = ProjectEditorModuleResolver(
          moduleItems: _moduleItems,
          moduleIndex: _moduleIndex,
          buildSecondColumn: _buildSecondColumn,
          buildModuleContent: _buildModuleContent,
        );
        final moduleResolution = moduleResolver.resolve();
        final actions = ProjectEditorActions(
          moduleIndex: _moduleIndex,
          isHistoryVisible: _isHistoryPanelVisible,
          onShowSelectionDialog: _showSelectionDialog,
          onToggleHistoryPanel: _toggleHistoryPanel,
          onOpenFindReplace: _openFindReplaceDialog,
          onCreateChapter: _createNewChapterForMobile,
          onCreateCharacter: _onCharacterCreated,
          onOpenSettings: _openSettings,
        );
        final Widget? historyPanel = _isHistoryPanelVisible
            ? _buildHistoryPanel()
            : null;

        if (_isMobile) {
          return ProjectEditorMobileLayout(
            currentModuleName: moduleResolver.currentModuleName,
            showModuleActions: actions.supportsHistory,
            showFindReplace: actions.showFindReplace,
            isHistoryPanelVisible: _isHistoryPanelVisible,
            selectionLabel: actions.selectionLabel,
            addLabel: actions.addLabel,
            onShowSelectionDialog: actions.onShowSelectionDialog,
            onToggleHistoryPanel: actions.onToggleHistoryPanel,
            onOpenFindReplace: actions.onOpenFindReplace,
            onOpenSettings: actions.onOpenSettings,
            onFloatingAction: actions.onFloatingAction,
            moduleContent: moduleResolution.moduleContent,
            historyPanel: historyPanel,
            moduleItems: _moduleItems,
            selectedModuleIndex: _moduleIndex,
            onModuleTapped: _onModuleTapped,
            projectTitle: widget.project.title,
            onGoHome: _goToMainScreen,
          );
        }

        return ProjectEditorDesktopLayout(
          isSidebarExpanded: _isSidebarExpanded,
          moduleItems: _moduleItems,
          selectedModuleIndex: _moduleIndex,
          onModuleTapped: _onModuleTapped,
          onToggleSidebar: _toggleSidebar,
          projectTitle: widget.project.title,
          onGoHome: _goToMainScreen,
          onOpenSettings: _openSettings,
          secondColumn: moduleResolution.secondColumn,
          moduleContent: moduleResolution.moduleContent,
          showSecondColumnDivider: moduleResolution.showSecondColumnDivider,
          isHistoryPanelVisible: _isHistoryPanelVisible,
          historyPanel: historyPanel,
          showHistoryButton: moduleResolver.supportsHistory,
          onToggleHistoryPanel: actions.onToggleHistoryPanel,
          onFindReplacePressed: actions.showFindReplace
              ? actions.onOpenFindReplace
              : null,
          isFindReplaceAvailable: actions.showFindReplace,
        );
      },
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
