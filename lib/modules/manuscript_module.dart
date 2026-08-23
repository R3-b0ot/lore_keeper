// lib/modules/manuscript_module.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:lore_keeper/widgets/find_replace_dialog.dart';
import 'package:language_tool/language_tool.dart';

import 'package:lore_keeper/services/history_service.dart';
import 'package:lore_keeper/widgets/index_page_widget.dart';
import 'package:lore_keeper/widgets/cover_page_form.dart';
import 'package:lore_keeper/widgets/about_author_form.dart';
import 'package:lore_keeper/widgets/manuscript_binder.dart';
import 'package:lore_keeper/widgets/manuscript_corkboard.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/widgets/responsive_layout.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/widgets/reference_autocomplete_controller.dart';
import 'package:lore_keeper/widgets/reference_autocomplete_overlay.dart';
import 'package:lore_keeper/services/reference_attribute.dart';
import 'package:lore_keeper/services/manuscript_reference_service.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/database_manager.dart';

enum _EditorType { title, manuscript }
enum _LeftPanelMode { binder, corkboard, outliner }

class ManuscriptModule extends StatelessWidget {
  final int projectId;
  final String selectedChapterKey;
  final ChapterListProvider chapterProvider;
  final CharacterListProvider characterProvider;
  final ValueChanged<String> onChapterSelected;
  final ValueChanged<QuillController?> onControllerReady;
  final ValueChanged<Future<void> Function()?> onGrammarCheckReady;
  final ValueChanged<String>? onReferenceNavigate;

  const ManuscriptModule({
    super.key,
    required this.projectId,
    required this.selectedChapterKey,
    required this.chapterProvider,
    required this.characterProvider,
    required this.onChapterSelected,
    required this.onControllerReady,
    required this.onGrammarCheckReady,
    this.onReferenceNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ManuscriptEditor(
      projectId: projectId,
      selectedChapterKey: selectedChapterKey,
      chapterProvider: chapterProvider,
      characterProvider: characterProvider,
      onChapterSelected: onChapterSelected,
      onControllerReady: onControllerReady,
      onGrammarCheckReady: onGrammarCheckReady,
      onReferenceNavigate: onReferenceNavigate,
    );
  }
}

class ManuscriptEditor extends StatefulWidget {
  final int projectId;
  final String selectedChapterKey;
  final ChapterListProvider chapterProvider;
  final CharacterListProvider characterProvider;
  final ValueChanged<String> onChapterSelected;
  final ValueChanged<QuillController?> onControllerReady;
  final ValueChanged<Future<void> Function()?> onGrammarCheckReady;
  final ValueChanged<String>? onReferenceNavigate;

  const ManuscriptEditor({
    super.key,
    required this.projectId,
    required this.selectedChapterKey,
    required this.chapterProvider,
    required this.characterProvider,
    required this.onChapterSelected,
    required this.onControllerReady,
    required this.onGrammarCheckReady,
    this.onReferenceNavigate,
  });

  @override
  State<ManuscriptEditor> createState() => _ManuscriptEditorState();
}

class _ManuscriptEditorState extends State<ManuscriptEditor> {
  late final QuillController _controller;
  late final QuillController _titleController;
  _EditorType? _activeEditor;
  Project? _project;
  final FocusNode _focusNode = FocusNode();
  late final FocusNode _titleFocusNode;
  final ScrollController _scrollController = ScrollController();

  Timer? _titleAutosaveTimer;
  Timer? _autosaveTimer;
  Timer? _grammarDebounce;
  final Duration _autosaveDelay = const Duration(seconds: 2);
  final Duration _grammarDelay = const Duration(milliseconds: 600);

  final HistoryService _historyService = HistoryService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSwitchingChapter = false;
  int _wordCount = 0;
  double _zoomFactor = 1.0;
  bool _isCheckingGrammar = false;
  int _grammarIssueCount = 0;
  bool _hasExternalProofingConsent = false;
  Size? _lastEditorSize;
  final List<_GrammarIssue> _issues = [];
  bool _showGrammarPanel = false;
  String? _activeCategory;
  bool _focusMode = false;
  _LeftPanelMode _leftPanelMode = _LeftPanelMode.binder;

  ManuscriptBinderProvider? _binderProvider;
  String? _selectedDocumentId;
  ManuscriptDocument? _selectedDocument;
  ManuscriptReferenceService? _referenceService;

  // @mention autocomplete
  late final ReferenceAutocompleteController _autocompleteController;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _titleController = QuillController.basic();
    widget.onControllerReady(_controller);
    widget.onGrammarCheckReady(_runGrammarCheck);
    _titleFocusNode = FocusNode();

    // Initialize @mention autocomplete controller with all entity types
    _autocompleteController = ReferenceAutocompleteController(
      quillController: _controller,
      charactersProvider: () => widget.characterProvider.characters,
    );
    _autocompleteController.onStateChanged = () {
      if (mounted) setState(() {});
    };

    _loadProject();
    _initBinderProvider();
    _initReferenceService();
    _loadContent();

    _titleController.addListener(_onTitleChanged);
    _controller.addListener(_onTextChanged);
    _titleFocusNode.addListener(_onFocusChange);
    _focusNode.addListener(_onFocusChange);
  }

  Future<void> _initBinderProvider() async {
    _binderProvider = ManuscriptBinderProvider(widget.projectId);
    // Wait for initialization
    while (!_binderProvider!.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Select the document corresponding to the current chapter key
    _selectDocumentForChapterKey(widget.selectedChapterKey);

    if (mounted) setState(() {});
  }

  Future<void> _initReferenceService() async {
    final db = DatabaseManager.instance;
    _referenceService = ManuscriptReferenceService(
      projectId: widget.projectId,
      referenceEngine: ReferenceEngine(),
      documentBox: db.manuscriptDocuments,
      characterBox: db.characters,
    );
    // Initial index build
    await _referenceService!.rebuildIndex();
  }

  void _selectDocumentForChapterKey(String chapterKey) {
    if (_binderProvider == null) return;

    String? docId;
    if (chapterKey.startsWith('front_matter_')) {
      // Find front matter document
      final docs = _binderProvider!.getDocumentsByType(ManuscriptDocumentType.frontMatter);
      for (final doc in docs) {
        // Match by order index or title
        if (chapterKey.contains('front_matter_-1') && doc.title.toLowerCase().contains('front')) {
          docId = doc.id;
          break;
        } else if (chapterKey.contains('front_matter_-2') && doc.title.toLowerCase().contains('index')) {
          docId = doc.id;
          break;
        } else if (chapterKey.contains('front_matter_-3') && doc.title.toLowerCase().contains('author')) {
          docId = doc.id;
          break;
        }
      }
      docId ??= docs.firstOrNull?.id;
    } else {
      // Find chapter document
      final chapterKeyInt = int.tryParse(chapterKey);
      if (chapterKeyInt != null) {
        final docs = _binderProvider!.getDocumentsByType(ManuscriptDocumentType.chapter);
        for (final doc in docs) {
          if (doc.id == 'chapter_$chapterKeyInt') {
            docId = doc.id;
            break;
          }
        }
      }
    }

    if (docId != null) {
      _selectedDocumentId = docId;
      _selectedDocument = _binderProvider!.getDocument(docId);
    }
  }

  @override
  void didUpdateWidget(covariant ManuscriptEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedChapterKey.isEmpty) return;
    if (widget.selectedChapterKey != oldWidget.selectedChapterKey) {
      _isSwitchingChapter = true;
      _autosaveTimer?.cancel();
      _titleAutosaveTimer?.cancel();

      _switchChapter(oldWidget.selectedChapterKey);
    }
  }

  Future<void> _switchChapter(String oldKey) async {
    await _saveContent(isChangingChapter: true, chapterKeyToSave: oldKey);
    await _saveTitle(isChangingChapter: true, chapterKeyToSave: oldKey);
    _selectDocumentForChapterKey(widget.selectedChapterKey);
    _loadContent();
  }

  void _loadProject() {
    final projectBox = Hive.box<Project>('projects');
    _project = projectBox.get(widget.projectId);
    if (_project != null) {
      setState(() {
        // Project loaded
      });
    }
  }

  void _loadContent() {
    if (!mounted) return;
    setState(() => _isLoading = true);

    if (_selectedDocument == null) {
      _loadEmptyContent();
      return;
    }

    final doc = _selectedDocument!;

    // Load title
    _titleController.document = Document.fromDelta(
      Delta()..insert('${doc.title}\n', {'header': 1}),
    );

    // Load content
    if (doc.richTextJson != null && doc.richTextJson!.isNotEmpty) {
      try {
        final jsonDoc = jsonDecode(doc.richTextJson!);
        final documentMap = jsonDoc is List
            ? {'ops': jsonDoc}
            : (jsonDoc as Map<String, dynamic>);
        _controller.document = Document.fromJson(_cleanDocument(documentMap));
      } catch (e) {
        _controller.document = Document();
      }
    } else {
      _controller.document = Document();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSwitchingChapter = false;
        _updateWordCount();
        _updateDocumentWordCount();
      });
    }
  }

  List<dynamic> _cleanDocument(Map<String, dynamic> doc) {
    final ops = doc['ops'] as List<dynamic>? ?? [];
    return ops
        .where(
          (op) =>
              !(op['insert'] is Map &&
                  (op['insert'] as Map).containsKey('page-break')),
        )
        .toList();
  }

  void _loadEmptyContent() {
    _titleController.document = Document();
    _controller.document = Document();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSwitchingChapter = false;
        _wordCount = 0;
      });
    }
  }

  void _updateDocumentWordCount() {
    if (_selectedDocument != null) {
      _selectedDocument!.wordCount = _wordCount;
      _selectedDocument!.characterCount = _controller.document.toPlainText().length;
    }
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {
      _activeEditor = _titleFocusNode.hasFocus
          ? _EditorType.title
          : (_focusNode.hasFocus ? _EditorType.manuscript : _activeEditor);
    });
  }

  void _onTitleChanged() {
    if (_isLoading) return;
    _titleAutosaveTimer?.cancel();
    _titleAutosaveTimer = Timer(_autosaveDelay, _saveTitle);
  }

  void _onTextChanged() {
    if (_isLoading || _isSwitchingChapter) return;
    _updateWordCount();
    _autosaveTimer?.cancel();

    _autosaveTimer = Timer(_autosaveDelay, _saveContent);

    // Update @mention autocomplete
    _autocompleteController.onTextChanged();

    final text = _controller.document.toPlainText();
    if (text.isNotEmpty &&
        (text.endsWith(' ') || text.endsWith('\t') || text.endsWith('\n'))) {
      _grammarDebounce?.cancel();
      _grammarDebounce = Timer(_grammarDelay, () {
        if (_hasExternalProofingConsent && !_isCheckingGrammar) {
          _runGrammarCheck();
        }
      });
    }
  }

  void _updateWordCount() {
    final plainText = _controller.document.toPlainText().trim();
    if (mounted) {
      setState(
        () => _wordCount = plainText.isEmpty
            ? 0
            : plainText.split(RegExp(r'\s+')).length,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // @mention autocomplete keyboard handling
  // ---------------------------------------------------------------------------

  KeyEventResult _onAutocompleteKeyHandler(FocusNode node, KeyEvent event) {
    if (_autocompleteController.handleKeyEvent(event)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Handle taps on inline reference links.
  ///
  /// Links with the `ref:` prefix are internal references to Characters,
  /// Locations, etc. Other URLs open externally.
  Future<void> _onReferenceLaunch(String url) async {
    var link = url;
    // LinkValidator may have prepended https:// to unrecognized prefixes.
    if (link.startsWith('https://ref:') || link.startsWith('http://ref:')) {
      link = link.substring(link.indexOf('ref:'));
    }
    if (!link.startsWith('ref:')) return;

    final target = ReferenceTarget.decode(link);
    if (target == null) return;

    widget.onReferenceNavigate?.call(target.encode());
  }

  Future<void> _saveTitle({
    bool isChangingChapter = false,
    String? chapterKeyToSave,
  }) async {
    if (_selectedDocument == null) return;
    final newTitle = _titleController.document.toPlainText().trim();
    if (newTitle.isEmpty) return;
    if (_selectedDocument!.title != newTitle) {
      await _binderProvider?.updateTitle(_selectedDocument!.id, newTitle);
      _selectedDocument!.title = newTitle;
    }
  }

  Future<void> _saveContent({
    bool isChangingChapter = false,
    String? chapterKeyToSave,
  }) async {
    if (_selectedDocument == null) return;
    if (!isChangingChapter && mounted) setState(() => _isSaving = true);
    final content = jsonEncode(_controller.document.toDelta().toJson());
    await _binderProvider?.updateContent(_selectedDocument!.id, content);
    _selectedDocument!.richTextJson = content;
    _updateDocumentWordCount();

    // Add history entry
    await _historyService.addHistoryEntry(
      targetKey: _selectedDocument!.id,
      targetType: 'ManuscriptDocument',
      objectToSave: _selectedDocument!,
      projectId: widget.projectId,
    );

    // Rebuild reference index for this document
    await _referenceService?.rebuildIndex();

    if (_project != null) {
      _project!.lastModified = DateTime.now();
      await _project!.save();
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleAutosaveTimer?.cancel();
    _grammarDebounce?.cancel();

    widget.onControllerReady(null);
    widget.onGrammarCheckReady(null);

    _titleController.removeListener(_onTitleChanged);
    _controller.removeListener(_onTextChanged);
    _titleFocusNode.removeListener(_onFocusChange);
    _focusNode.removeListener(_onFocusChange);

    _autocompleteController.onStateChanged = null;
    _autocompleteController.dismiss();

    _controller.document = Document();
    _titleController.document = Document();
    _controller.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    _titleFocusNode.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bgColor = theme.brightness == Brightness.dark
        ? AppColors.bgMain
        : AppColors.bgMainLight;

    if (_focusMode) {
      return _buildFocusModeView(bgColor);
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading || _binderProvider == null
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left Panel
                SizedBox(
                  width: 280,
                  child: _buildLeftPanel(),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: cs.outlineVariant,
                ),
                // Editor Panel (Center) - Flexible
                Expanded(
                  child: Column(
                    children: [
                      if (!widget.selectedChapterKey.startsWith('front_matter_'))
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: _activeEditor == _EditorType.title
                              ? _buildTitleToolbar()
                              : _buildMainToolbar(),
                        ),
                      const SizedBox(height: 16),
                      Expanded(child: _buildEditorView(bgColor)),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: cs.outlineVariant,
                ),
                // Inspector Panel (Right)
                SizedBox(
                  width: 300,
                  child: _buildInspectorPanel(),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomStatusBar(),
    );
  }

  Widget _buildFocusModeView(Color bgColor) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Minimal toolbar in focus mode
          Container(
            height: 48,
            color: cs.surfaceContainerHighest,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  _selectedDocument?.title ?? 'Manuscript',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.maximize),
                  tooltip: 'Exit Focus Mode',
                  onPressed: () => setState(() => _focusMode = false),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: bgColor,
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _buildEditorContent(),
                ),
              ),
            ),
          ),
          // Minimal status bar
          Container(
            height: 32,
            color: cs.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Words: $_wordCount',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'Zoom: ${(_zoomFactor * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // BINDER HANDLERS
  // ========================================================================

  void _onDocumentSelected(String documentId) {
    setState(() {
      _selectedDocumentId = documentId;
      _selectedDocument = _binderProvider!.getDocument(documentId);
    });

    // If it's a chapter document, update the chapter key and load content
    if (_selectedDocument != null) {
      if (_selectedDocument!.documentType == ManuscriptDocumentType.chapter) {
        // Extract chapter key from document ID (format: chapter_<key>)
        final parts = _selectedDocument!.id.split('_');
        if (parts.length >= 2) {
          final chapterKey = parts.sublist(1).join('_');
          widget.onChapterSelected(chapterKey);
        }
      } else if (_selectedDocument!.documentType == ManuscriptDocumentType.frontMatter) {
        widget.onChapterSelected(_selectedDocument!.id);
      }
    }
    _loadContent();
  }

  void _onDocumentRenamed(String documentId) {
    // Update chapter provider if it's a chapter
    final doc = _binderProvider!.getDocument(documentId);
    if (doc != null && doc.documentType == ManuscriptDocumentType.chapter) {
      // The chapter provider will be updated via the binder provider
    }
  }

  void _onDocumentMoved(String documentId) {
    // Handle document moved - could update ordering in chapter provider if needed
  }

  // ========================================================================
  // INSPECTOR PANEL
  // ========================================================================

  Widget _buildInspectorPanel() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_selectedDocument == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.info, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Select a document',
              style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Inspector shows metadata,\nreferences, and links',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return Container(
      color: cs.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                Icon(_getIconForType(_selectedDocument!.documentType),
                    size: 20, color: _getColorForType(_selectedDocument!.documentType, cs)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Inspector',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InspectorSection(
                    title: 'Document',
                    children: [
                      _InspectorRow('Type', _selectedDocument!.documentType.label),
                      _InspectorRow('Status', _selectedDocument!.status.label),
                      _InspectorRow('Words', '${_selectedDocument!.wordCount}'),
                      _InspectorRow('Characters', '${_selectedDocument!.characterCount}'),
                      if (_selectedDocument!.createdAt != null)
                        _InspectorRow('Created', _formatDate(_selectedDocument!.createdAt!)),
                      if (_selectedDocument!.modifiedAt != null)
                        _InspectorRow('Modified', _formatDate(_selectedDocument!.modifiedAt!)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedDocument!.isLeaf) ...[
                    _InspectorSection(
                      title: 'Scene Metadata',
                      children: [
                        _InspectorRow('POV Character', _selectedDocument!.povCharacterId ?? '—'),
                        _InspectorRow('Location', _selectedDocument!.locationId ?? '—'),
                        _InspectorRow('Timeline', _selectedDocument!.timelineEventId ?? '—'),
                        _InspectorRow('Plotline', _selectedDocument!.plotline ?? '—'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedDocument!.characterIds.isNotEmpty) ...[
                    _InspectorSection(
                      title: 'Characters (${_selectedDocument!.characterIds.length})',
                      children: _selectedDocument!.characterIds
                          .map((id) => _InspectorRow('•', id))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedDocument!.tagIds.isNotEmpty) ...[
                    _InspectorSection(
                      title: 'Tags (${_selectedDocument!.tagIds.length})',
                      children: _selectedDocument!.tagIds
                          .map((id) => _InspectorRow('•', id))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedDocument!.summary != null && _selectedDocument!.summary!.isNotEmpty) ...[
                    _InspectorSection(
                      title: 'Summary',
                      children: [
                        _InspectorRow('', _selectedDocument!.summary!),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  _InspectorSection(
                    title: 'Hierarchy',
                    children: [
                      _InspectorRow('Parent', _getParentTitle() ?? 'Root'),
                      _InspectorRow('Children', '${_binderProvider!.getChildren(_selectedDocument!.id).length}'),
                      _InspectorRow('Depth', '${_getDepth(_selectedDocument!.id)}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildReferencesSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferencesSection() {
    if (_referenceService == null || _selectedDocument == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Get outgoing references from this document
    final outgoingRefs = _referenceService!.getReferencesFrom(_selectedDocument!);

    // Get incoming references (backlinks) to this document
    final docRef = EntityRef.fromKey(
      key: _selectedDocument!.id,
      entityType: 'ManuscriptDocument',
      projectId: widget.projectId.toString(),
    );
    final backlinks = _referenceService!.getBacklinksTo(docRef);

    if (outgoingRefs.isEmpty && backlinks.isEmpty) {
      return _InspectorSection(
        title: 'References',
        children: [
          _InspectorRow('', 'No references found'),
        ],
      );
    }

    return _InspectorSection(
      title: 'References',
      children: [
        if (outgoingRefs.isNotEmpty) ...[
          Text(
            'References (${outgoingRefs.length})',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...outgoingRefs.map((ref) => _buildReferenceTile(ref, isOutgoing: true)),
          const SizedBox(height: 12),
        ],
        if (backlinks.isNotEmpty) ...[
          Text(
            'Backlinks (${backlinks.length})',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...backlinks.map((ref) => _buildReferenceTile(ref, isOutgoing: false)),
        ],
      ],
    );
  }

  Widget _buildReferenceTile(ReferenceIndexEntry ref, {required bool isOutgoing}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isOutgoing = ref.source.id == _selectedDocument!.id;

    String displayName = ref.target.id;
    String entityType = ref.target.entityType;

    // Try to get a better display name from the character box
    if (ref.target.entityType == EntityType.character) {
      final character = DatabaseManager.instance.characters.get(ref.target.asKey);
      if (character != null) {
        displayName = character.name;
      }
    }

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isOutgoing ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
        size: 16,
        color: isOutgoing ? cs.primary : cs.secondary,
      ),
      title: Text(
        displayName,
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$entityType • ${ref.kind}',
        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      onTap: () {
        // Navigate to the referenced document/entity
        if (!isOutgoing && ref.source.entityType == 'ManuscriptDocument') {
          _onDocumentSelected(ref.source.id);
        }
      },
    );
  }

  String? _getParentTitle() {
    if (_selectedDocument!.parentId == null) return null;
    final parent = _binderProvider!.getDocument(_selectedDocument!.parentId!);
    return parent?.title;
  }

  int _getDepth(String documentId) {
    int depth = 0;
    String? currentId = documentId;
    while (currentId != null) {
      final doc = _binderProvider!.getDocument(currentId);
      if (doc?.parentId == null) break;
      currentId = doc!.parentId;
      depth++;
    }
    return depth;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

// ========================================================================
// LEFT PANEL
// ========================================================================

Widget _buildLeftPanel() {
  switch (_leftPanelMode) {
    case _LeftPanelMode.binder:
      return ManuscriptBinder(
        provider: _binderProvider!,
        selectedDocumentId: _selectedDocumentId,
        onDocumentSelected: _onDocumentSelected,
        onDocumentRenamed: _onDocumentRenamed,
        onDocumentMoved: _onDocumentMoved,
      );
    case _LeftPanelMode.corkboard:
      return ManuscriptCorkboard(
        provider: _binderProvider!,
        containerDocumentId: _selectedDocumentId ?? _binderProvider!.manuscriptRoot!.id,
        onDocumentSelected: _onDocumentSelected,
        onDocumentRenamed: _onDocumentRenamed,
      );
    case _LeftPanelMode.outliner:
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.list, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Outliner view - Coming soon',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
  }
}

// ========================================================================
// TOOLBARS & EDITOR
// ========================================================================

Widget _buildTitleToolbar() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: QuillSimpleToolbar(
      controller: _titleController,
      config: const QuillSimpleToolbarConfig(
        showUndo: false,
        showRedo: false,
        showFontFamily: false,
        showFontSize: false,
        showHeaderStyle: false,
        showInlineCode: false,
        showClearFormat: false,
      ),
    ),
  );

  Widget _buildMainToolbar() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        // View switcher for left panel
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: ToggleButtons(
            isSelected: [
              _leftPanelMode == _LeftPanelMode.binder,
              _leftPanelMode == _LeftPanelMode.corkboard,
              _leftPanelMode == _LeftPanelMode.outliner,
            ],
            onPressed: (index) {
              setState(() {
                _leftPanelMode = _LeftPanelMode.values[index];
              });
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
            fillColor: Theme.of(context).colorScheme.primaryContainer,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
            children: [
              Tooltip(
                message: 'Binder (Tree View)',
                child: Icon(LucideIcons.listTree, size: 18),
              ),
              Tooltip(
                message: 'Corkboard (Card View)',
                child: Icon(LucideIcons.layoutGrid, size: 18),
              ),
              Tooltip(
                message: 'Outliner (Table View)',
                child: Icon(LucideIcons.list, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Quill Toolbar
        SizedBox(
          width: 600, // Limit toolbar width
          child: QuillSimpleToolbar(
            controller: _controller,
            config: QuillSimpleToolbarConfig(
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: true,
              showAlignmentButtons: true,
              showHeaderStyle: true,
              showQuote: true,
              showUndo: true,
              showRedo: true,
              customButtons: [
                QuillToolbarCustomButtonOptions(
                  icon: const Icon(LucideIcons.search),
                  onPressed: _openFindReplaceDialog,
                ),
                QuillToolbarCustomButtonOptions(
                  icon: const Icon(LucideIcons.maximize),
                  tooltip: 'Focus Mode',
                  onPressed: () => setState(() => _focusMode = true),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildEditorView(Color bgColor) {
    return Container(
      decoration: BoxDecoration(color: bgColor),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_showGrammarPanel && constraints.maxWidth < 820) {
              return Column(
                children: [
                  Expanded(flex: 3, child: _buildEditorCard()),
                  const SizedBox(height: 12),
                  Expanded(flex: 2, child: _buildProofingCard()),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: _showGrammarPanel ? 7 : 10,
                  child: _buildEditorCard(),
                ),
                if (_showGrammarPanel) const SizedBox(width: 12),
                if (_showGrammarPanel)
                  Expanded(flex: 3, child: _buildProofingCard()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditorCard() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InteractiveViewer(
        panEnabled: false,
        scaleEnabled: false,
        child: Scrollbar(
          controller: _scrollController,
          child: Column(
            children: [
              if (!widget.selectedChapterKey.startsWith('front_matter_'))
                QuillEditor(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  scrollController: ScrollController(),
                  config: QuillEditorConfig(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    autoFocus: false,
                    expands: false,
                    customStyles: DefaultStyles(
                      h1: DefaultTextBlockStyle(
                        Theme.of(context).textTheme.displaySmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        const HorizontalSpacing(0, 0),
                        const VerticalSpacing(16, 8),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _lastEditorSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return _buildEditorContent();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProofingCard() {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      shadowColor: Colors.black12,
      child: _GrammarPanel(
        issues: _filteredIssues,
        categories: _categories,
        activeCategory: _activeCategory,
        onCategorySelected: (cat) {
          setState(() => _activeCategory = cat);
        },
        onAccept: _acceptIssue,
        onDismiss: _dismissIssue,
        onClose: () {
          setState(() => _showGrammarPanel = false);
        },
      ),
    );
  }

  Widget _buildEditorContent() {
    if (_project == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.selectedChapterKey.startsWith('front_matter_')) {
      final kp = int.tryParse(widget.selectedChapterKey.split('_').last);
      if (kp == -1) return CoverPageForm(project: _project!);
      if (kp == -2) {
        return IndexPageWidget(
          chapterProvider: widget.chapterProvider,
          onChapterSelected: widget.onChapterSelected,
        );
      }
      if (kp == -3) return AboutAuthorForm(project: _project!);
    }
    return Stack(
      children: [
        Focus(
          onKeyEvent: _onAutocompleteKeyHandler,
          child: QuillEditor(
            controller: _controller,
            focusNode: _focusNode,
            scrollController: _scrollController,
            config: QuillEditorConfig(
              padding: const EdgeInsets.all(16),
              placeholder: 'Write your story...',
              embedBuilders: [...FlutterQuillEmbeds.editorBuilders()],
              onLaunchUrl: _onReferenceLaunch,
              customLinkPrefixes: const ['ref:'],
            ),
          ),
        ),
        if (_autocompleteController.isActive)
          Positioned(
            left: 16,
            bottom: 16,
            child: ReferenceAutocompleteOverlay(
              controller: _autocompleteController,
            ),
          ),
      ],
    );
  }

  void _openFindReplaceDialog() => showDialog(
    context: context,
    builder: (context) => FindReplaceDialog(controller: _controller),
  );

  Widget _buildBottomStatusBar() {
    final cs = Theme.of(context).colorScheme;
    return ResponsiveStatusBar(
      color: cs.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: [
        Text(
          'Words: $_wordCount',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 28),
          ),
          icon: Icon(
            _grammarIssueCount == 0
                ? LucideIcons.circleCheck
                : LucideIcons.triangleAlert,
            size: 16,
            color: _grammarIssueCount == 0 ? cs.primary : cs.errorContainer,
          ),
          label: Text(
            _isCheckingGrammar
                ? 'Checking…'
                : _grammarIssueCount == 0
                ? 'Grammar'
                : 'Issues: $_grammarIssueCount',
            style: TextStyle(fontSize: 12, color: cs.onSurface),
          ),
          onPressed: _isCheckingGrammar
              ? null
              : () {
                  setState(() => _showGrammarPanel = true);
                  _runGrammarCheck();
                },
        ),
        IconButton(
          icon: const Icon(LucideIcons.wand, size: 16),
          tooltip: 'Auto-correct with LanguageTool',
          onPressed: _isCheckingGrammar ? null : _runAutoCorrect,
        ),
      ],
      trailing: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text(
              'Saving...',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
        Text(
          'Zoom: ${(_zoomFactor * 100).toInt()}%',
          style: const TextStyle(fontSize: 12),
        ),
        IconButton(
          icon: const Icon(LucideIcons.minus, size: 16),
          onPressed: () =>
              setState(() => _zoomFactor = (_zoomFactor - 0.1).clamp(0.5, 2.0)),
        ),
        IconButton(
          icon: const Icon(LucideIcons.plus, size: 16),
          onPressed: () =>
              setState(() => _zoomFactor = (_zoomFactor + 0.1).clamp(0.5, 2.0)),
        ),
      ],
    );
  }

  void _buildIssues(List<WritingMistake> issues, String text) {
    if (_lastEditorSize == null || issues.isEmpty) return;

    final textStyle = DefaultTextStyle.of(context).style;
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(text: text, style: textStyle),
    );
    painter.layout(maxWidth: _lastEditorSize!.width - 16);

    _issues.clear();
    for (final issue in issues) {
      final issueId = '${issue.offset}-${issue.length}-${issue.message}';
      _issues.add(
        _GrammarIssue(
          id: issueId,
          category: issue.issueType,
          message: issue.message,
          replacement: issue.replacements.isNotEmpty
              ? issue.replacements.first
              : null,
          context: issue.context.text,
          offset: issue.offset,
          length: issue.length,
        ),
      );
    }
    setState(() {});
  }

  Future<void> _runGrammarCheck() async {
    final plainText = _controller.document.toPlainText();
    if (plainText.trim().isEmpty) {
      if (!mounted) return;
      return;
    }
    if (!await _ensureExternalProofingConsent()) return;

    if (!mounted) return;

    setState(() {
      _isCheckingGrammar = true;
      _grammarIssueCount = 0;
    });

    try {
      final languageTool = LanguageTool(language: 'en-US', picky: true);
      final mistakes = await languageTool.check(plainText);
      final filtered = mistakes.where((m) {
        final end = math.min(plainText.length, m.offset + m.length);
        final word = plainText.substring(m.offset, end);
        return !(_project?.ignoredWords?.contains(word) ?? false);
      }).toList();

      if (!mounted) return;
      setState(() {
        _grammarIssueCount = filtered.length;
        _showGrammarPanel = filtered.isNotEmpty;
      });
      _buildIssues(filtered, plainText);
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() => _isCheckingGrammar = false);
      }
    }
  }

  Future<void> _runAutoCorrect() async {
    final plainText = _controller.document.toPlainText();
    if (plainText.trim().isEmpty) {
      if (!mounted) return;
      return;
    }
    if (!await _ensureExternalProofingConsent()) return;

    if (!mounted) return;

    setState(() => _isCheckingGrammar = true);
    try {
      final languageTool = LanguageTool(language: 'en-US', picky: true);
      final mistakes = await languageTool.check(plainText);
      // Apply from the end to keep offsets stable
      final sortedMistakes =
          mistakes.where((m) => m.replacements.isNotEmpty).where((m) {
            final end = math.min(plainText.length, m.offset + m.length);
            final word = plainText.substring(m.offset, end);
            return !(_project?.ignoredWords?.contains(word) ?? false);
          }).toList()..sort((a, b) => b.offset.compareTo(a.offset));

      for (final mistake in sortedMistakes) {
        final replacement = mistake.replacements.first;
        _controller.replaceText(
          mistake.offset,
          mistake.length,
          replacement,
          null,
        );
      }

      if (!mounted) return;
      setState(() {
        _grammarIssueCount = 0;
        _updateWordCount();
        _issues.clear();
        _showGrammarPanel = false;
      });
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() => _isCheckingGrammar = false);
      }
    }
  }

  Future<bool> _ensureExternalProofingConsent() async {
    if (_hasExternalProofingConsent) return true;
    if (!mounted) return false;

    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use External Proofing?'),
        content: const Text(
          'Grammar and auto-correct send manuscript text to LanguageTool over HTTPS for analysis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (!mounted || consent != true) return false;
    setState(() => _hasExternalProofingConsent = true);
    return true;
  }

  List<_GrammarIssue> get _filteredIssues {
    if (_activeCategory == null) return List.unmodifiable(_issues);
    return _issues
        .where((i) => i.category.toLowerCase() == _activeCategory)
        .toList();
  }

  List<String> get _categories {
    final set = <String>{};
    for (final i in _issues) {
      set.add(i.category.toLowerCase());
    }
    return set.toList()..sort();
  }

  void _acceptIssue(_GrammarIssue issue) {
    if (issue.replacement != null) {
      _controller.replaceText(
        issue.offset,
        issue.length,
        issue.replacement!,
        null,
      );
      _updateWordCount();
    }
    _removeIssue(issue.id);
  }

  void _dismissIssue(_GrammarIssue issue) {
    _removeIssue(issue.id);
  }

  void _removeIssue(String id) {
    _issues.removeWhere((i) => i.id == id);
    setState(() {
      _grammarIssueCount = _issues.length;
      if (_issues.isEmpty) _showGrammarPanel = false;
    });
  }
}

class _GrammarIssue {
  _GrammarIssue({
    required this.id,
    required this.category,
    required this.message,
    required this.context,
    this.replacement,
    required this.offset,
    required this.length,
  });

  final String id;
  final String category;
  final String message;
  final String context;
  final String? replacement;
  final int offset;
  final int length;
}

class _GrammarPanel extends StatelessWidget {
  const _GrammarPanel({
    required this.issues,
    required this.categories,
    required this.activeCategory,
    required this.onCategorySelected,
    required this.onAccept,
    required this.onDismiss,
    required this.onClose,
  });

  final List<_GrammarIssue> issues;
  final List<String> categories;
  final String? activeCategory;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<_GrammarIssue> onAccept;
  final ValueChanged<_GrammarIssue> onDismiss;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Suggestions ${issues.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: onClose,
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: activeCategory == null,
                onSelected: (_) => onCategorySelected(null),
              ),
              const SizedBox(width: 8),
              ...categories.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: activeCategory == cat,
                    onSelected: (_) => onCategorySelected(cat),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: issues.isEmpty
              ? const Center(child: Text('No issues'))
              : ListView.builder(
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    final issue = issues[index];
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Card(
                        elevation: 0,
                        color: cs.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.shield,
                                    size: 16,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      issue.category,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                issue.message,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                issue.context,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  FilledButton(
                                    onPressed: issue.replacement != null
                                        ? () => onAccept(issue)
                                        : null,
                                    child: Text(
                                      issue.replacement != null
                                          ? 'Accept'
                                          : 'No fix',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => onDismiss(issue),
                                    child: const Text('Dismiss'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _InspectorSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InspectorSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: children.map((child) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: child,
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _InspectorRow extends StatelessWidget {
  final String label;
  final String value;

  const _InspectorRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}