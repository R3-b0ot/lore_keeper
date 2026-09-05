import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/modules/manuscript_module.dart';
import 'package:lore_keeper/modules/character_module.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/providers/link_provider.dart';
import 'package:lore_keeper/providers/magic_tree_provider.dart';
import 'package:lore_keeper/providers/species_provider.dart';
import 'package:lore_keeper/widgets/species_tree.dart';
import 'package:lore_keeper/providers/timeline_event_provider.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
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
import 'package:lore_keeper/widgets/project_editor/overview_module.dart';
import 'package:lore_keeper/widgets/project_editor/world_building_tabs.dart';
import 'package:lore_keeper/widgets/project_editor/lore_map_stub.dart';

import 'package:lore_keeper/widgets/find_replace_dialog.dart';

import 'package:lore_keeper/widgets/calendar_list_pane.dart';
import 'package:lore_keeper/widgets/magic_list_pane.dart';
import 'package:lore_keeper/widgets/timeline_list_pane.dart';

import 'package:lore_keeper/widgets/manuscript_list_pane.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';

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

  /// Current tab index within World Building module (moduleIndex == 3).
  int _worldTabIndex = 0;
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
  SpeciesProvider? _speciesProvider;
  LinkProvider? _linkProvider;

  ManuscriptBinderProvider? _manuscriptBinderProvider;
  ReferenceEngine? _referenceEngine;
  String _selectedManuscriptDocumentId = '';

  // New navigation structure: Overview | Manuscripts | Characters | World Building | Lore Map
  // Internal index mapping:
  //   0 = Overview (NEW default landing)
  //   1 = Manuscripts (was index 0)
  //   2 = Characters (was index 1)
  //   3 = World Building (consolidates old indices 2–15)
  //   4 = Lore Map (stub)
  final List<ProjectEditorModuleItem>
  _moduleItems = const <ProjectEditorModuleItem>[
    ProjectEditorModuleItem(
      label: 'Overview',
      icon: LucideIcons.layoutDashboard,
    ),
    ProjectEditorModuleItem(label: 'Manuscripts', icon: LucideIcons.bookOpen),
    ProjectEditorModuleItem(label: 'Characters', icon: LucideIcons.users),
    ProjectEditorModuleItem(label: 'World Building', icon: LucideIcons.globe),
    ProjectEditorModuleItem(label: 'Lore Map', icon: LucideIcons.map),
  ];

  // World Building tab labels/icons for placeholders in second column
  static const List<String> _worldBuildingTabLabels = [
    'Magic',
    'Timelines',
    'Calendars',
    'Species',
    'Locations',
    'Languages',
    'Items',
    'Cultures',
    'Philosophies',
    'Religions',
    'Systems',
    'Research',
    'Arcs',
    'Relationships',
  ];

  static const List<IconData> _worldBuildingTabIcons = [
    LucideIcons.sparkles,
    LucideIcons.chartLine,
    LucideIcons.calendar,
    LucideIcons.pawPrint,
    LucideIcons.mapPin,
    LucideIcons.languages,
    LucideIcons.tag,
    LucideIcons.usersRound,
    LucideIcons.brain,
    LucideIcons.church,
    LucideIcons.chartNetwork,
    LucideIcons.flaskConical,
    LucideIcons.chartLine,
    LucideIcons.link,
  ];

  @override
  void initState() {
    super.initState();
    // Default to Overview (index 0) unless deep-linked
    _moduleIndex = _normalizeModuleIndex(widget.initialModuleIndex);
    _selectedChapterKey = widget.initialChapterKey ?? '';
    _selectedCharacterKey = widget.initialCharacterKey ?? '';

    _chapterListProvider = ChapterListProvider(widget.project.key);

    // Shared ReferenceEngine for cross-module reference integrity. Created
    // before the entity/binder providers so every deletion flow and the
    // manuscript pipeline observe ONE index.
    final sharedReferenceEngine = ReferenceEngine();
    _referenceEngine = sharedReferenceEngine;

    _characterListProvider = CharacterListProvider(
      widget.project.key,
      referenceEngine: sharedReferenceEngine,
    );
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
    _timelineEventProvider = TimelineEventProvider(
      widget.project.key,
      referenceEngine: sharedReferenceEngine,
    );
    _speciesProvider = SpeciesProvider(
      widget.project.key,
      referenceEngine: sharedReferenceEngine,
    );

    // Shared binder provider for the Manuscript list pane (Column 2)
    // and editor (Column 3).
    _manuscriptBinderProvider = ManuscriptBinderProvider(
      widget.project.key,
      referenceEngine: sharedReferenceEngine,
    );
    _manuscriptBinderProvider!.addListener(_onBinderProviderChanged);

    // Wire calendar system selection → timeline events filter
    _calendarTreeProvider!.addListener(() {
      if (!mounted) return;
      final selectedKey = _calendarTreeProvider!.selectedSystem?.key as int?;
      if (selectedKey != null &&
          selectedKey != _timelineEventProvider!.selectedSystemKey) {
        _timelineEventProvider!.setSelectedSystemKey(selectedKey);
      }
    });
  }

  int _normalizeModuleIndex(int? index) {
    if (index == null) return 0; // Default to Overview
    // Handle deep links with old indices (0-15) by mapping to new indices (0-4)
    if (index >= 0 && index <= 15) {
      // Old mapping: 0=Manuscript, 1=Characters, 2=Map, 3=Timeline, 4=Calendar, 5=Languages, 6=Magic, 7=Research, 8=Arcs, 9=Relationships, 10=Items, 11=Species, 12=Cultures, 13=Philosophies, 14=Religions, 15=Systems
      // New mapping: 0=Overview, 1=Manuscripts, 2=Characters, 3=World Building, 4=Lore Map
      switch (index) {
        case 0:
          return 1; // Manuscript -> Manuscripts
        case 1:
          return 2; // Characters -> Characters
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
        case 10:
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
          return 3; // All world-building modules -> World Building
      }
    }
    // If index is already in new range (0-4), use it
    if (index >= 0 && index < _moduleItems.length) {
      return index;
    }
    return 0;
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
        _moduleIndex = 2; // Characters is index 2 in new nav
        _selectedCharacterKey = id;
      });
    }
    // Location, Item, Organization: not yet implemented.
  }

  void _goToMainScreen() {
    Navigator.of(context).pop();
  }

  /// Sync from the shared binder provider when data changes.
  void _onBinderProviderChanged() {
    if (!mounted || _manuscriptBinderProvider == null) return;
    // If the currently selected document no longer exists (e.g. deleted),
    // clear the selection.
    if (_selectedManuscriptDocumentId.isNotEmpty &&
        _manuscriptBinderProvider!.getDocument(_selectedManuscriptDocumentId) ==
            null) {
      setState(() => _selectedManuscriptDocumentId = '');
    }
  }

  /// Called when a document is selected in the Manuscript list pane (Column 2).
  void _onManuscriptDocumentSelected(String documentId) {
    setState(() => _selectedManuscriptDocumentId = documentId);

    // Keep legacy chapter key in sync for deep-linking / other consumers.
    final doc = _manuscriptBinderProvider!.getDocument(documentId);
    if (doc != null) {
      final chapterKey = _chapterKeyFromDocumentId(documentId);
      if (chapterKey != null) {
        _selectedChapterKey = chapterKey;
      }
    }
  }

  /// Derive a legacy chapter key from a manuscript document ID.
  String? _chapterKeyFromDocumentId(String documentId) {
    if (documentId.startsWith('chapter_')) {
      return documentId.substring('chapter_'.length);
    }
    // Non-chapter documents (parts, scenes, notes) don't have a legacy key.
    return null;
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
    // Only allow for manuscript module (index 1)
    if (_moduleIndex != 1) return;
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

  @override
  void dispose() {
    _manuscriptBinderProvider?.removeListener(_onBinderProviderChanged);
    _manuscriptBinderProvider?.dispose();
    _chapterListProvider?.dispose();
    _characterListProvider?.dispose();

    _linkProvider?.dispose();
    _magicTreeProvider?.dispose();
    _calendarTreeProvider?.dispose();
    _timelineEventProvider?.dispose();
    _speciesProvider?.dispose();
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
  // New indices: 0=Overview, 1=Manuscripts, 2=Characters, 3=World Building, 4=Lore Map
  Widget _buildSecondColumn({required bool isMobile}) {
    if (_moduleIndex == 1) {
      // Manuscripts — Column 2 hosts the Binder / Corkboard / Outliner / Collections
      return ManuscriptListPane(
        provider: _manuscriptBinderProvider!,
        selectedDocumentId: _selectedManuscriptDocumentId,
        onDocumentSelected: _onManuscriptDocumentSelected,
      );
    } else if (_moduleIndex == 2) {
      // Characters
      return CharacterListPane(
        characterProvider: _characterListProvider!,
        selectedCharacterKey: _selectedCharacterKey,
        onCharacterSelected: _onCharacterSelected,
        onCharacterCreated: _onCharacterCreated,
        onCharacterEdit: _showEditNameDialog,
        isMobile: isMobile,
      );
    } else if (_moduleIndex == 3) {
      // World Building - switch second column based on active world tab
      switch (_worldTabIndex) {
        case 0:
          // Magic
          return MagicListPane(
            magicProvider: _magicTreeProvider!,
            isMobile: isMobile,
          );
        case 1:
          // Timelines → show event list pane
          return TimelineListPane(
            calendarProvider: _calendarTreeProvider!,
            eventProvider: _timelineEventProvider!,
            isMobile: isMobile,
          );
        case 2:
          // Calendars
          return CalendarListPane(
            calendarProvider: _calendarTreeProvider!,
            isMobile: isMobile,
          );
        case 3:
          // Species - shows in second column (tree/list)
          return SpeciesTree(
            speciesProvider: _speciesProvider!,
            isMobile: isMobile,
          );
        default:
          // Other domains (Locations, Languages, Items, etc.) - placeholder
          return _WorldBuildingPlaceholder(
            label: _worldTabIndex < _worldBuildingTabLabels.length
                ? _worldBuildingTabLabels[_worldTabIndex]
                : 'World Building',
            icon: _worldTabIndex < _worldBuildingTabIcons.length
                ? _worldBuildingTabIcons[_worldTabIndex]
                : LucideIcons.globe,
          );
      }
    }
    // Overview (0) and Lore Map (4) hide the second column
    return const SizedBox.shrink();
  }

  Widget _buildModuleContent() {
    // New indices: 0=Overview, 1=Manuscripts, 2=Characters, 3=World Building, 4=Lore Map

    if (_moduleIndex == 0) {
      // Overview (NEW)
      return OverviewModule(
        project: widget.project,
        chapterProvider: _chapterListProvider!,
        characterProvider: _characterListProvider!,
        magicProvider: _magicTreeProvider!,
        calendarProvider: _calendarTreeProvider!,
        timelineProvider: _timelineEventProvider!,
        onNavigate: (module) {
          final index = _moduleItems.indexWhere(
            (m) => m.label == module.label && m.icon == module.icon,
          );
          if (index >= 0) {
            setState(() {
              _moduleIndex = index;
              _isListPaneCollapsed = false;
            });
          }
        },
      );
    } else if (_moduleIndex == 1) {
      // Manuscripts — editor + inspector (Column 3 & 4).
      // Binder / Corkboard / Outliner / Collections live in Column 2.
      return ManuscriptModule(
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
        binderProvider: _manuscriptBinderProvider,
        speciesProvider: _speciesProvider,
        timelineProvider: _timelineEventProvider,
        sharedReferenceEngine: _referenceEngine,
        selectedDocumentId: _selectedManuscriptDocumentId,
        onDocumentSelected: _onManuscriptDocumentSelected,
      );
    } else if (_moduleIndex == 2) {
      // Characters
      return _selectedCharacterKey.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CharacterModule(
              characterKey: _selectedCharacterKey,
              linkProvider: _linkProvider!,
              key: _characterModuleKey,
              onReload: _handleRevert,
            );
    } else if (_moduleIndex == 3) {
      // World Building (consolidated)
      return WorldBuildingTabs(
        calendarProvider: _calendarTreeProvider!,
        magicProvider: _magicTreeProvider!,
        speciesProvider: _speciesProvider!,
        timelineProvider: _timelineEventProvider!,
        characterProvider: _characterListProvider!,
        initialTabIndex: _worldTabIndex,
        onTabChanged: (index) {
          setState(() {
            _worldTabIndex = index;
          });
        },
      );
    } else if (_moduleIndex == 4) {
      // Lore Map (stub)
      return const LoreMapStub();
    }

    return const SizedBox.shrink();
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
    if (_moduleIndex == 1) {
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
    } else if (_moduleIndex == 2) {
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
    // History supported for Manuscripts (index 1) and Characters (index 2)
    if (_moduleIndex == 1) {
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
    if (_moduleIndex == 2) {
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

class _WorldBuildingPlaceholder extends StatelessWidget {
  final String label;
  final IconData icon;

  const _WorldBuildingPlaceholder({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Second column for this domain — coming soon',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
