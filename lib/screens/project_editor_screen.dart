import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/modules/manuscript_module.dart'; // Import the new module
import 'package:lore_keeper/modules/character_module.dart'; // Import the new module
import 'package:lore_keeper/modules/calendar_module.dart';
import 'package:lore_keeper/modules/timeline_module.dart';

import 'package:lore_keeper/modules/magic_module.dart';
import 'package:lore_keeper/modules/map/map_module.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/providers/link_provider.dart';
import 'package:lore_keeper/providers/magic_tree_provider.dart';
import 'package:lore_keeper/providers/timeline_event_provider.dart';
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
import 'package:lore_keeper/widgets/project_editor/project_editor_module_item.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_module_resolver.dart';

import 'package:lore_keeper/widgets/find_replace_dialog.dart';

import 'package:lore_keeper/widgets/calendar_list_pane.dart';
import 'package:lore_keeper/widgets/magic_list_pane.dart';

// -----------------------------------------------------------------
// Project Editor Screen (Four-Column Layout with Expandable Sidebar)
// -----------------------------------------------------------------

class ProjectEditorScreen extends StatefulWidget {
  final Project project;
  final int? initialModuleIndex;
  final String? initialChapterKey;
  final String? initialCharacterKey;

  const ProjectEditorScreen({
    super.key,
    required this.project,
    this.initialModuleIndex,
    this.initialChapterKey,
    this.initialCharacterKey,
  });

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  int _moduleIndex = 0;
  String _selectedChapterKey = '';
  String _selectedCharacterKey = '';

  bool _isSidebarExpanded = false;
  bool _isListPaneCollapsed = false;
  bool _isHistoryPanelVisible = false;

  QuillController? _manuscriptController;
  Future<void> Function()? _runManuscriptGrammarCheck;

  final GlobalKey<CharacterModuleState> _characterModuleKey = GlobalKey(
    debugLabel: 'CharacterModule',
  );

  ChapterListProvider? _chapterListProvider;
  CharacterListProvider? _characterListProvider;

  MagicTreeProvider? _magicTreeProvider;
  CalendarTreeProvider? _calendarTreeProvider;
  TimelineEventProvider? _timelineEventProvider;
  LinkProvider? _linkProvider;

  final List<ProjectEditorModuleItem>
  _moduleItems = const <ProjectEditorModuleItem>[
    ProjectEditorModuleItem(label: 'Manuscript', icon: LucideIcons.bookOpen),
    ProjectEditorModuleItem(label: 'Characters', icon: LucideIcons.user),
    ProjectEditorModuleItem(label: 'Map', icon: LucideIcons.map),
    ProjectEditorModuleItem(label: 'Timeline', icon: LucideIcons.chartLine),
    ProjectEditorModuleItem(label: 'Calendar', icon: LucideIcons.calendar),
    ProjectEditorModuleItem(label: 'Languages', icon: LucideIcons.languages),
    ProjectEditorModuleItem(label: 'Magic', icon: LucideIcons.sparkles),
    ProjectEditorModuleItem(label: 'Research', icon: LucideIcons.flaskConical),
    ProjectEditorModuleItem(label: 'Arcs', icon: LucideIcons.chartLine),
    ProjectEditorModuleItem(label: 'Relationships', icon: LucideIcons.link),
    ProjectEditorModuleItem(label: 'Items', icon: LucideIcons.tag),
    ProjectEditorModuleItem(label: 'Species', icon: LucideIcons.pawPrint),
    ProjectEditorModuleItem(label: 'Cultures', icon: LucideIcons.usersRound),
    ProjectEditorModuleItem(label: 'Philosophies', icon: LucideIcons.brain),
    ProjectEditorModuleItem(label: 'Religions', icon: LucideIcons.church),
    ProjectEditorModuleItem(label: 'Systems', icon: LucideIcons.chartNetwork),
  ];

  @override
  void initState() {
    super.initState();
    _moduleIndex = _normalizeModuleIndex(widget.initialModuleIndex);
    _selectedChapterKey = widget.initialChapterKey ?? '';
    _selectedCharacterKey = widget.initialCharacterKey ?? '';

    _chapterListProvider = ChapterListProvider(widget.project.key);
    _characterListProvider = CharacterListProvider(widget.project.key);
    _linkProvider = LinkProvider();
    _chapterListProvider!.addListener(() {
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

    _characterListProvider!.addListener(_selectInitialCharacterIfNeeded);

    _magicTreeProvider = MagicTreeProvider(widget.project.key);
    _calendarTreeProvider = CalendarTreeProvider(widget.project.key);
    _timelineEventProvider = TimelineEventProvider(widget.project.key);
  }

  int _normalizeModuleIndex(int? index) {
    if (index == null) return 0;
    if (index < 0 || index >= _moduleItems.length) return 0;
    return index;
  }

  void _selectInitialCharacterIfNeeded() {
    final provider = _characterListProvider;
    if (!mounted ||
        provider == null ||
        !provider.isInitialized ||
        provider.characters.isEmpty ||
        _selectedCharacterKey.isNotEmpty) {
      return;
    }

    setState(() {
      _selectedCharacterKey = provider.characters.first.key.toString();
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  void _onModuleTapped(int index) {
    if (_moduleIndex == index || index < 0 || index >= _moduleItems.length) {
      return;
    }
    setState(() {
      _moduleIndex = index;
      _isListPaneCollapsed = false;
    });
  }

  void _toggleListPane() {
    setState(() {
      _isListPaneCollapsed = !_isListPaneCollapsed;
    });
  }

  void _onChapterSelected(String key) {
    if (_selectedChapterKey != key) {
      setState(() {
        _selectedChapterKey = key;
      });
    }

    // If the key is cleared, it means no chapters are left.
    if (key.isEmpty) {
      widget.project.lastEditedChapterKey = null;
    }
  }

  void _onCharacterSelected(String key) {
    if (_selectedCharacterKey == key) return;
    setState(() {
      _selectedCharacterKey = key;
    });
  }

  void _onReferenceNavigate(String encodedTarget) {
    // Parse "ref:Character:42" → navigate to character module
    if (!encodedTarget.startsWith('ref:')) return;
    final rest = encodedTarget.substring(4);
    final colonIndex = rest.indexOf(':');
    if (colonIndex == -1) return;
    final typeLabel = rest.substring(0, colonIndex);
    final id = rest.substring(colonIndex + 1);

    if (typeLabel == 'Character') {
      // Switch to character module and select the character.
      setState(() {
        _moduleIndex = 1;
        _selectedCharacterKey = id;
      });
    }
    // Location, Item, Organization: not yet implemented.
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
    _runManuscriptGrammarCheck?.call();
  }

  void _openFindReplaceDialog() {
    // Only allow for manuscript module
    if (_moduleIndex != 0) return;
    final controller = _manuscriptController;
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
  }

  @override
  void dispose() {
    _chapterListProvider?.dispose();
    _characterListProvider?.dispose();

    _linkProvider?.dispose();
    _magicTreeProvider?.dispose();
    _calendarTreeProvider?.dispose();
    _timelineEventProvider?.dispose();
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

    switch (result) {
      case ConfirmCharacterName(:final name):
        await _characterListProvider!.updateCharacterName(characterKey, name);
      case DeleteCharacter():
        await _characterListProvider!.deleteCharacter(characterKey);
        if (mounted) {
          // After deletion, the provider reloads its list. We can now select the new first character.
          if (_characterListProvider!.characters.isNotEmpty) {
            _onCharacterSelected(
              _characterListProvider!.characters.first.key.toString(),
            );
          } else {
            _onCharacterSelected(
              '',
            ); // Clear selection if no characters are left
          }
        }
    }
  }

  // Helper method to build the second column based on the selected module
  Widget _buildSecondColumn({required bool isMobile}) {
    if (_moduleIndex == 0) {
      return ChapterListPane(
        chapterProvider: _chapterListProvider!,
        selectedChapterKey: _selectedChapterKey,
        onChapterSelected: _onChapterSelected,
        onChapterCreated: (key) => _onChapterCreated(key),
        isMobile: isMobile,
      );
    } else if (_moduleIndex == 1) {
      return CharacterListPane(
        characterProvider: _characterListProvider!,
        selectedCharacterKey: _selectedCharacterKey,
        onCharacterSelected: _onCharacterSelected,
        onCharacterCreated: _onCharacterCreated,
        onCharacterEdit: _showEditNameDialog,
        isMobile: isMobile,
      );
    } else if (_moduleIndex == 4) {
      return CalendarListPane(
        calendarProvider: _calendarTreeProvider!,
        isMobile: isMobile,
      );
    } else if (_moduleIndex == 6) {
      return MagicListPane(
        magicProvider: _magicTreeProvider!,
        isMobile: isMobile,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildModuleContent() {
    // Get the label for the current module from the _moduleItems list
    final currentModuleName = _moduleItems[_moduleIndex].label;

    if (_moduleIndex == 0) {
      return _selectedChapterKey.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ManuscriptModule(
              projectId: widget.project.key,
              selectedChapterKey: _selectedChapterKey,
              chapterProvider: _chapterListProvider!,
              characterProvider: _characterListProvider!,
              onChapterSelected: _onChapterSelected,
              onControllerReady: (controller) {
                _manuscriptController = controller;
              },
              onGrammarCheckReady: (grammarCheck) {
                _runManuscriptGrammarCheck = grammarCheck;
              },
              onReferenceNavigate: _onReferenceNavigate,
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
      return MapModule(projectId: widget.project.key);
    } else if (_moduleIndex == 3) {
      return TimelineModule(
        calendarProvider: _calendarTreeProvider!,
        eventProvider: _timelineEventProvider!,
      );
    } else if (_moduleIndex == 4) {
      return CalendarModule(calendarProvider: _calendarTreeProvider!);
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
      final targetKey = _selectedChapterKey.startsWith('front_matter_')
          ? _selectedChapterKey
          : int.tryParse(_selectedChapterKey);
      if (targetKey == null) return null;

      return HistoryPanel(
        targetKey: targetKey,
        targetType: 'Chapter',
        onClose: _toggleHistoryPanel,
        onReverted: _handleRevert,
      );
    }
    if (_moduleIndex == 1) {
      final targetKey = int.tryParse(_selectedCharacterKey);
      if (targetKey == null) return null;

      return HistoryPanel(
        targetKey: targetKey,
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
        final isMobile = constraints.maxWidth < 600;
        final moduleResolver = ProjectEditorModuleResolver(
          moduleItems: _moduleItems,
          moduleIndex: _moduleIndex,
          buildSecondColumn: () => _buildSecondColumn(isMobile: isMobile),
          buildModuleContent: _buildModuleContent,
        );
        final moduleResolution = moduleResolver.resolve();
        final actions = ProjectEditorActions(
          moduleIndex: _moduleIndex,
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

        if (isMobile) {
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
          isListPaneCollapsed: _isListPaneCollapsed,
          moduleItems: _moduleItems,
          selectedModuleIndex: _moduleIndex,
          onModuleTapped: _onModuleTapped,
          onToggleSidebar: _toggleSidebar,
          onToggleListPane: _toggleListPane,
          moduleContent: moduleResolution.moduleContent,
          projectTitle: widget.project.title,
          onGoHome: _goToMainScreen,
          onOpenSettings: _openSettings,
          secondColumn: moduleResolution.secondColumn,
          showSecondColumnDivider: moduleResolution.showSecondColumnDivider,
          isHistoryPanelVisible: _isHistoryPanelVisible,
          historyPanel: historyPanel,
          showHistoryButton: moduleResolver.supportsHistory,
          onToggleHistoryPanel: actions.onToggleHistoryPanel,
          onFindReplacePressed: actions.showFindReplace
              ? actions.onOpenFindReplace
              : null,
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
