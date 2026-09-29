// lib/modules/manuscript_module.dart
//
// Manuscript Module — Column 3 (editor) + Column 4 (inspector).
//
// ManuscriptModule is a StatefulWidget that owns the combined Column 3+4 slot
// assigned to it by the Project Editor shell.  It renders:
//
//   ┌─────────────────────────────────┬──────────────────┐
//   │  ManuscriptEditor  (Column 3)   │ ManuscriptInspector (Column 4) │
//   └─────────────────────────────────┴──────────────────┘
//
// The module owns the _selectedDocument and _referenceService that both
// columns need.  When the user activates a backlink in the Inspector, the
// module calls the shell's onDocumentSelected callback so the Binder in
// Column 2 stays in sync (spec §12 / P1-4 fix).

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
import 'package:lore_keeper/services/history_snapshot_policy.dart';
import 'package:lore_keeper/widgets/index_page_widget.dart';
import 'package:lore_keeper/widgets/cover_page_form.dart';
import 'package:lore_keeper/widgets/about_author_form.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/widgets/responsive_layout.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/providers/species_provider.dart';
import 'package:lore_keeper/providers/timeline_event_provider.dart';
import 'package:lore_keeper/widgets/reference_autocomplete_controller.dart';
import 'package:lore_keeper/widgets/reference_autocomplete_overlay.dart';
import 'package:lore_keeper/services/reference_attribute.dart';
import 'package:lore_keeper/services/manuscript_reference_service.dart';
import 'package:lore_keeper/services/entity_reference_entries.dart';
import 'package:lore_keeper/services/reference_name_resolver.dart';
import 'package:lore_keeper/utils/manuscript_text_stats.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/database_manager.dart';

import 'package:lore_keeper/widgets/manuscript_inspector.dart';

// Canonical stable key for the editor column (spec §5.2).
const Key kManuscriptEditorKey = Key('manuscript-editor');

enum _EditorType { title, manuscript }

// =============================================================================
// ManuscriptModule
// =============================================================================
//
// Owns the combined Column 3+4 slot and renders:
//   ManuscriptEditor (Column 3)  |  ManuscriptInspector (Column 4)
//
// This is a StatefulWidget so it can hold _selectedDocument and
// _referenceService — state that both columns need.

class ManuscriptModule extends StatefulWidget {
  final int projectId;
  final String selectedChapterKey;
  final ChapterListProvider chapterProvider;
  final CharacterListProvider characterProvider;
  final ValueChanged<String> onChapterSelected;
  final ValueChanged<QuillController?> onControllerReady;
  final ValueChanged<Future<void> Function()?> onGrammarCheckReady;
  final ValueChanged<String>? onReferenceNavigate;
  final ManuscriptBinderProvider? binderProvider;
  final CalendarTreeProvider? calendarProvider;
  final SpeciesProvider? speciesProvider;
  final TimelineEventProvider? timelineProvider;
  final ReferenceEngine? sharedReferenceEngine;
  final String selectedDocumentId;

  /// Shell-level callback — must update _selectedManuscriptDocumentId in the
  /// ProjectEditorScreen so the Binder and editor stay in sync (spec §12).
  final ValueChanged<String>? onDocumentSelected;

  /// Bumped by the shell whenever a history revert overwrites the open
  /// document (Cycle 3b-3).
  ///
  /// The editor cannot detect the overwrite on its own: the revert mutates the
  /// document in place, so no widget property it observes actually changes.
  /// A monotonic token is the smallest honest signal, and a no-op bump is
  /// harmless.
  final int revertSignal;

  const ManuscriptModule({
    super.key,
    required this.projectId,
    required this.selectedChapterKey,
    required this.chapterProvider,
    required this.characterProvider,
    required this.onChapterSelected,
    required this.onControllerReady,
    required this.onGrammarCheckReady,
    this.revertSignal = 0,
    this.onReferenceNavigate,
    this.binderProvider,
    this.calendarProvider,
    this.speciesProvider,
    this.timelineProvider,
    this.sharedReferenceEngine,
    this.selectedDocumentId = '',
    this.onDocumentSelected,
  });

  @override
  State<ManuscriptModule> createState() => _ManuscriptModuleState();
}

class _ManuscriptModuleState extends State<ManuscriptModule> {
  // Shared state owned by the module and passed to both Column 3 and Column 4.
  ManuscriptDocument? _selectedDocument;
  ManuscriptReferenceService? _referenceService;
  late final ReferenceNameResolver _nameResolver;

  @override
  void initState() {
    super.initState();
    _nameResolver = ReferenceNameResolver.fromDatabase(widget.projectId);
    _initReferenceService();
  }

  /// The one [ManuscriptReferenceService] for this module session (MS-015).
  ///
  /// Exposed so the editor and the topology test can assert identity rather
  /// than infer it. Previously the editor built a second service of its own, so
  /// the module and the editor held two services over one engine — each
  /// running its own `rebuildIndex()` on the shared index.
  ManuscriptReferenceService? get referenceService => _referenceService;

  Future<void> _initReferenceService() async {
    final engine =
        widget.sharedReferenceEngine ??
        widget.binderProvider?.referenceEngine ??
        ReferenceEngine();
    final db = DatabaseManager.instance;
    final svc = ManuscriptReferenceService(
      projectId: widget.projectId,
      referenceEngine: engine,
      documentBox: db.manuscriptDocuments,
    );
    await svc.rebuildIndex();
    if (mounted) {
      setState(() => _referenceService = svc);
    }
  }

  /// Called by ManuscriptEditor when its active document changes.
  void _onEditorDocumentChanged(ManuscriptDocument? doc) {
    if (mounted) setState(() => _selectedDocument = doc);
  }

  /// Called when the Inspector activates a backlink navigation.
  ///
  /// Updates shell selection (Column 2 Binder) AND editor via the single
  /// canonical onDocumentSelected callback path (spec §12 / P1-4 fix).
  void _onBacklinkNavigate(String documentId) {
    widget.onDocumentSelected?.call(documentId);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        // ── Column 3: ManuscriptEditor ────────────────────────────────────
        Expanded(
          child: ManuscriptEditor(
            key: kManuscriptEditorKey,
            projectId: widget.projectId,
            selectedChapterKey: widget.selectedChapterKey,
            chapterProvider: widget.chapterProvider,
            characterProvider: widget.characterProvider,
            onChapterSelected: widget.onChapterSelected,
            onControllerReady: widget.onControllerReady,
            onGrammarCheckReady: widget.onGrammarCheckReady,
            onReferenceNavigate: widget.onReferenceNavigate,
            binderProvider: widget.binderProvider,
            calendarProvider: widget.calendarProvider,
            speciesProvider: widget.speciesProvider,
            timelineProvider: widget.timelineProvider,
            sharedReferenceEngine: widget.sharedReferenceEngine,
            selectedDocumentId: widget.selectedDocumentId,
            referenceService: _referenceService,
            onDocumentSelected: widget.onDocumentSelected,
            onSelectedDocumentChanged: _onEditorDocumentChanged,
            revertSignal: widget.revertSignal,
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant),
        // ── Column 4: ManuscriptInspector ─────────────────────────────────
        SizedBox(
          width: 300,
          child: ManuscriptInspector(
            selectedDocument: _selectedDocument,
            binderProvider: widget.binderProvider,
            nameResolver: _nameResolver,
            referenceService: _referenceService,
            projectId: widget.projectId,
            onDocumentSelected: _onBacklinkNavigate,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ManuscriptEditor  (Column 3 only)
// =============================================================================

class ManuscriptEditor extends StatefulWidget {
  final int projectId;
  final String selectedChapterKey;
  final ChapterListProvider chapterProvider;
  final CharacterListProvider characterProvider;
  final ValueChanged<String> onChapterSelected;
  final ValueChanged<QuillController?> onControllerReady;
  final ValueChanged<Future<void> Function()?> onGrammarCheckReady;
  final ValueChanged<String>? onReferenceNavigate;
  final ManuscriptBinderProvider? binderProvider;
  final CalendarTreeProvider? calendarProvider;
  final SpeciesProvider? speciesProvider;
  final TimelineEventProvider? timelineProvider;
  final ReferenceEngine? sharedReferenceEngine;
  final String selectedDocumentId;

  /// The module's single [ManuscriptReferenceService] (MS-015).
  ///
  /// The editor must use *this* instance, never one it constructs itself:
  /// a second service over the shared engine means a second `rebuildIndex()`
  /// and no single owner of the index. It is null on the first build, before
  /// the module's async init completes; the editor falls back to a
  /// [ManuscriptBinderProvider]-derived engine until it arrives and re-reads
  /// it in [didUpdateWidget].
  final ManuscriptReferenceService? referenceService;

  /// Shell-level callback — updates the canonical selection in
  /// ProjectEditorScreen so Binder and Inspector stay in sync (spec §12).
  final ValueChanged<String>? onDocumentSelected;

  /// Notifies the owning ManuscriptModule whenever the active document changes
  /// so the Inspector can be updated (Column 3 → Column 4 communication).
  final ValueChanged<ManuscriptDocument?>? onSelectedDocumentChanged;

  /// Bumped when a history revert overwrites the open document (Cycle 3b-3);
  /// see [ManuscriptModule.revertSignal].
  final int revertSignal;

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
    this.binderProvider,
    this.calendarProvider,
    this.speciesProvider,
    this.timelineProvider,
    this.sharedReferenceEngine,
    this.selectedDocumentId = '',
    this.referenceService,
    this.onDocumentSelected,
    this.onSelectedDocumentChanged,
    this.revertSignal = 0,
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

  /// S-34 (spec 11.3): the content autosave debounce target is ~2s.
  ///
  /// Snapshot *pacing* is a separate concern, handled by
  /// `HistorySnapshotPolicy`; this value only controls how quickly content
  /// reaches storage.
  final Duration _autosaveDelay = const Duration(seconds: 2);
  final Duration _grammarDelay = const Duration(milliseconds: 600);

  /// The exact rich-text payload last persisted for the selected document.
  ///
  /// MS-008: Quill notifies its listeners for cursor moves, selection changes
  /// and undo bookkeeping, so the autosave debounce can fire repeatedly for one
  /// edit. Comparing against the last *persisted* payload — rather than
  /// counting keystrokes — is what makes the guard correct: any real edit
  /// produces different Delta JSON and is saved, and only a byte-identical
  /// re-save is dropped, so the history panel never fills with duplicates.
  ///
  /// Seeded on every load (see [_loadContent]) so the first save after opening
  /// a document is not mistaken for a no-op.
  String? _lastSavedContent;

  /// The content carried by the most recent history snapshot, if any.
  ///
  /// Deliberately *not* the same field as [_lastSavedContent]: content is
  /// written on every autosave, snapshots are paced by
  /// [HistorySnapshotPolicy.autosaveSnapshotInterval]. Sharing one baseline
  /// would make a close/switch believe an edit had already been snapshotted
  /// (content was just written) and silently drop it.
  ///
  /// Seeded on load (see [_loadContent]) so the first save after opening a
  /// document is recognised as unchanged rather than stored as a new revision.
  String? _lastSnapshottedContent;

  /// When [_lastSnapshottedContent] was captured, or null if there is none.
  DateTime? _lastSnapshotAt;

  /// The single authority on snapshot pacing and change detection.
  static const HistorySnapshotPolicy _snapshotPolicy = HistorySnapshotPolicy();

  final HistoryService _historyService = HistoryService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSwitchingChapter = false;
  int _wordCount = 0;
  int _characterCount = 0;
  double _zoomFactor = 1.0;
  bool _isCheckingGrammar = false;
  int _grammarIssueCount = 0;
  bool _hasExternalProofingConsent = false;
  Size? _lastEditorSize;
  final List<_GrammarIssue> _issues = [];
  bool _showGrammarPanel = false;
  String? _activeCategory;
  bool _focusMode = false;

  ManuscriptBinderProvider? _binderProvider;
  ManuscriptDocument? _selectedDocument;

  /// The module's single [ManuscriptReferenceService] (MS-015).
  ///
  /// Never constructed here — see [_adoptReferenceService].
  ManuscriptReferenceService? _referenceService;

  /// The service the editor is currently using.
  ///
  /// Exposed so MS-015's identity test can assert the module and the editor
  /// hold one instance rather than two services over one engine.
  ManuscriptReferenceService? get referenceService => _referenceService;

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
      entityProviders: _buildEntityProviders(),
    );
    _autocompleteController.onStateChanged = () {
      if (mounted) setState(() {});
    };

    _loadProject();
    _initBinderProvider();
    // MS-015: adopt the module's service instead of building a second one. On
    // the first build it is still null (the module inits asynchronously), so
    // the editor has no service until the module's first rebuild hands it
    // over; didUpdateWidget then adopts the canonical instance.
    _referenceService = widget.referenceService;
    _loadContent();

    _titleController.addListener(_onTitleChanged);
    _controller.addListener(_onTextChanged);
    _titleFocusNode.addListener(_onFocusChange);
    _focusNode.addListener(_onFocusChange);
  }

  /// Resolve the single shared [ReferenceEngine].
  /// Prefers the shell-owned engine; falls back to a private one only when
  /// running standalone (tests / preview).
  ReferenceEngine? _sharedEngine;
  ReferenceEngine _resolveSharedEngine() {
    return _sharedEngine ??= widget.sharedReferenceEngine ?? ReferenceEngine();
  }

  Future<void> _initBinderProvider() async {
    _binderProvider ??=
        widget.binderProvider ??
        ManuscriptBinderProvider(
          widget.projectId,
          referenceEngine: _resolveSharedEngine(),
        );
    while (!_binderProvider!.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _selectDocumentForChapterKey(widget.selectedChapterKey);
    if (mounted) setState(() {});
  }

  /// Adopt the module's [ManuscriptReferenceService] when it becomes available.
  ///
  /// MS-015: the editor must not construct its own. The module builds its
  /// service asynchronously, so on the very first build there is nothing to
  /// adopt; until it arrives [_referenceService] is null and the editor simply
  /// has no service. The next build picks up the canonical instance. The engine
  /// was never at risk of duplication here — only the service was.
  void _adoptReferenceService() {
    final shared = widget.referenceService;
    if (shared == null || identical(shared, _referenceService)) return;
    _referenceService = shared;
  }

  Map<String, EntityProvider> _buildEntityProviders() {
    final providers = <String, EntityProvider>{
      EntityType.character: () => widget.characterProvider.characters
          .map((c) => c.toReferenceEntry())
          .toList(),
    };
    final species = widget.speciesProvider;
    if (species != null) {
      providers[EntityType.species] = () =>
          species.getRootNodes().map((n) => n.toReferenceEntry()).toList();
    }
    final timeline = widget.timelineProvider;
    if (timeline != null) {
      providers[EntityType.timelineEvent] = () =>
          timeline.events.map((e) => e.toReferenceEntry()).toList();
    }
    final binder = _binderProvider;
    if (binder != null) {
      providers[EntityType.manuscriptDocument] = () =>
          binder.allDocuments.map((d) => d.toReferenceEntry()).toList();
    } else {
      providers[EntityType.manuscriptDocument] = () {
        final ready = _binderProvider;
        if (ready == null) return const [];
        return ready.allDocuments.map((d) => d.toReferenceEntry()).toList();
      };
    }
    return providers;
  }

  void _selectDocumentForChapterKey(String chapterKey) {
    if (_binderProvider == null) return;

    String? docId;
    if (chapterKey.startsWith('front_matter_')) {
      final docs = _binderProvider!.getDocumentsByType(
        ManuscriptDocumentType.frontMatter,
      );
      for (final doc in docs) {
        if (chapterKey.contains('front_matter_-1') &&
            doc.title.toLowerCase().contains('front')) {
          docId = doc.id;
          break;
        } else if (chapterKey.contains('front_matter_-2') &&
            doc.title.toLowerCase().contains('index')) {
          docId = doc.id;
          break;
        } else if (chapterKey.contains('front_matter_-3') &&
            doc.title.toLowerCase().contains('author')) {
          docId = doc.id;
          break;
        }
      }
      docId ??= docs.firstOrNull?.id;
    } else {
      final chapterKeyInt = int.tryParse(chapterKey);
      if (chapterKeyInt != null) {
        final docs = _binderProvider!.getDocumentsByType(
          ManuscriptDocumentType.chapter,
        );
        for (final doc in docs) {
          if (doc.id == 'chapter_$chapterKeyInt') {
            docId = doc.id;
            break;
          }
        }
      }
    }

    _setSelectedDocument(
      docId != null ? _binderProvider!.getDocument(docId) : null,
    );
  }

  /// Set the active document and notify the parent module so the Inspector
  /// stays in sync without coupling Column 3 to Column 4 directly.
  ///
  /// The notification is deferred to post-frame to avoid calling setState on
  /// an ancestor that is still being built during the same frame (e.g. when
  /// initState → _initBinderProvider → _selectDocumentForChapterKey fires
  /// synchronously during the first build).
  void _setSelectedDocument(ManuscriptDocument? doc) {
    _selectedDocument = doc;
    if (widget.onSelectedDocumentChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onSelectedDocumentChanged?.call(doc);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ManuscriptEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // MS-015: the module's service arrives asynchronously; adopt it as soon as
    // it does so the editor stops holding its own instance.
    _adoptReferenceService();

    // A history revert overwrote the document in place, so this is the only
    // observable change. Re-sync before any chapter switch so the editor never
    // displays text that storage no longer holds (Cycle 3b-3).
    if (widget.revertSignal != oldWidget.revertSignal) {
      _applyExternalRevert();
    }

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
    if (_project != null) setState(() {});
  }

  /// The exact encoding [_saveContent] persists, so the MS-008 comparison is
  /// between like and like.
  String _currentContentJson() =>
      jsonEncode(_controller.document.toDelta().toJson());

  void _loadContent() {
    if (!mounted) return;
    setState(() => _isLoading = true);

    if (_selectedDocument == null) {
      _loadEmptyContent();
      return;
    }

    final doc = _selectedDocument!;

    _titleController.document = Document.fromDelta(
      Delta()..insert('${doc.title}\n', {'header': 1}),
    );

    _applyDocumentContent(doc);
    _resyncBaselines();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSwitchingChapter = false;
        _updateCounts();
        _updateDocumentWordCount();
      });
    }
  }

  /// Decodes a document's persisted rich text into the editor.
  ///
  /// Shared by [_loadContent] and [_applyExternalRevert] so a document loaded
  /// normally and a document reloaded after a revert go through one decode
  /// path — a divergent copy is how a revert ends up rendering differently
  /// from the same content opened fresh.
  void _applyDocumentContent(ManuscriptDocument doc) {
    if (doc.richTextJson != null && doc.richTextJson!.isNotEmpty) {
      try {
        final jsonDoc = jsonDecode(doc.richTextJson!);
        final ops = jsonDoc is List
            ? jsonDoc
            : (jsonDoc as Map<String, dynamic>)['ops'] as List<dynamic>? ?? [];
        _controller.document = Document.fromJson(ops);
      } catch (e) {
        _controller.document = Document();
      }
    } else {
      _controller.document = Document();
    }
  }

  /// Re-bases both "unchanged" baselines on what the editor now displays.
  ///
  /// The snapshot baseline is reset rather than carried over: a freshly opened
  /// or freshly reverted document has no snapshot *of its own* yet, so the
  /// author's next real edit is a revision.
  void _resyncBaselines() {
    _lastSavedContent = _currentContentJson();
    _lastSnapshottedContent = _lastSavedContent;
    _lastSnapshotAt = null;
  }

  /// Re-syncs the editor with a document that was overwritten outside it
  /// (Cycle 3b-3 — a history revert).
  ///
  /// Without this the editor keeps displaying the pre-revert prose while
  /// storage holds the historical text. Worse, its stale content baseline says
  /// "nothing changed", so the next autosave ignores the revert entirely and
  /// the author's next keystroke — the fix they type because the revert appears
  /// not to have worked — overwrites it.
  ///
  /// Pending timers are cancelled first: a debounce armed before the revert
  /// carries the *old* text and would write it back.
  void _applyExternalRevert() {
    _autosaveTimer?.cancel();
    _grammarDebounce?.cancel();
    if (_isLoading || _isSwitchingChapter) return;

    final doc = _selectedDocument;
    if (doc == null) return;

    // Re-read the canonical document rather than trusting the reference this
    // state already holds: the revert wrote through the binder provider, and
    // the editor's own baseline is exactly what cannot be trusted here.
    final fresh = _binderProvider?.getDocument(doc.id) ?? doc;
    _selectedDocument = fresh;

    _applyDocumentContent(fresh);
    _resyncBaselines();

    if (mounted) {
      setState(() {
        _updateCounts();
        _updateDocumentWordCount();
      });
    }
  }

  void _loadEmptyContent() {
    _titleController.document = Document();
    _controller.document = Document();
    _resyncBaselines();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSwitchingChapter = false;
        _wordCount = 0;
        _characterCount = 0;
      });
    }
  }

  void _updateDocumentWordCount() {
    if (_selectedDocument != null) {
      _selectedDocument!.wordCount = _wordCount;
      _selectedDocument!.characterCount = ManuscriptTextStats.characterCount(
        _controller.document.toPlainText(),
      );
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
    _updateCounts();
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDelay, _saveContent);

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

  /// Computes both live counts from a single `toPlainText()` call so the
  /// status bar can never show a word count and character count that were
  /// measured from different snapshots of the document (MS-026).
  void _updateCounts() {
    final plainText = _controller.document.toPlainText();
    if (mounted) {
      setState(() {
        _wordCount = ManuscriptTextStats.wordCount(plainText);
        _characterCount = ManuscriptTextStats.characterCount(plainText);
      });
    }
  }

  // ── @mention autocomplete ──────────────────────────────────────────────────

  KeyEventResult _onAutocompleteKeyHandler(FocusNode node, KeyEvent event) {
    if (_autocompleteController.handleKeyEvent(event)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _onReferenceLaunch(String url) async {
    var link = url;
    if (link.startsWith('https://ref:') || link.startsWith('http://ref:')) {
      link = link.substring(link.indexOf('ref:'));
    }
    if (!link.startsWith('ref:')) return;
    final target = ReferenceTarget.decode(link);
    if (target == null) return;
    widget.onReferenceNavigate?.call(target.encode());
  }

  // ── Persistence ────────────────────────────────────────────────────────────

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
    final content = _currentContentJson();
    // MS-008: nothing on disk changed, so do not write — and above all do not
    // add another HistoryEntry, which is what filled the history panel with
    // identical snapshots. Checked before [_isSaving] so a no-op save never
    // flashes the saving indicator either.
    if (_lastSavedContent == content) return;
    if (!isChangingChapter && mounted) setState(() => _isSaving = true);
    await _binderProvider?.updateContent(_selectedDocument!.id, content);
    _lastSavedContent = content;
    _selectedDocument!.richTextJson = content;
    _updateDocumentWordCount();

    // 3b-2: whether this save becomes a history snapshot is the policy's call,
    // not the editor's. Content is always persisted above (S-34); the snapshot
    // is a revision record, so it is change-gated and paced, and leaving the
    // document always records the pending change.
    final decision = _snapshotPolicy.evaluate(
      newRichTextJson: content,
      lastSnapshottedRichTextJson: _lastSnapshottedContent,
      sinceLastSnapshot: _lastSnapshotAt == null
          ? null
          : DateTime.now().difference(_lastSnapshotAt!),
      trigger: isChangingChapter
          ? HistorySnapshotTrigger.documentClose
          : HistorySnapshotTrigger.autosave,
    );

    if (decision.shouldSnapshot) {
      await _historyService.addHistoryEntry(
        targetKey: _selectedDocument!.id,
        targetType: 'ManuscriptDocument',
        objectToSave: _selectedDocument!,
        projectId: widget.projectId,
      );
      _lastSnapshottedContent = content;
      _lastSnapshotAt = DateTime.now();
    }

    // Cycle 4b: only this document's body changed, so re-index just it. The
    // full rebuildIndex() stays for module-session init and for structural
    // operations (see ManuscriptReferenceService.rebuildIndexFor's scope note).
    await _referenceService?.rebuildIndexFor(_selectedDocument!.id);

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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          : Column(
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
          Container(
            height: 48,
            color: cs.surfaceContainerHighest,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  _selectedDocument?.title ?? 'Manuscript',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                const SizedBox(width: 8),
                Text(
                  'Chars: $_characterCount',
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

  // ── Toolbars ───────────────────────────────────────────────────────────────

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
        SizedBox(
          width: 600,
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

  // ── Editor view ────────────────────────────────────────────────────────────

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
        onCategorySelected: (cat) => setState(() => _activeCategory = cat),
        onAccept: _acceptIssue,
        onDismiss: _dismissIssue,
        onClose: () => setState(() => _showGrammarPanel = false),
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
        Text(
          'Chars: $_characterCount',
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

  // ── Grammar checking ───────────────────────────────────────────────────────

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
    if (plainText.trim().isEmpty || !mounted) return;
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
      if (mounted) setState(() => _isCheckingGrammar = false);
    }
  }

  Future<void> _runAutoCorrect() async {
    final plainText = _controller.document.toPlainText();
    if (plainText.trim().isEmpty || !mounted) return;
    if (!await _ensureExternalProofingConsent()) return;
    if (!mounted) return;

    setState(() => _isCheckingGrammar = true);
    try {
      final languageTool = LanguageTool(language: 'en-US', picky: true);
      final mistakes = await languageTool.check(plainText);
      final sortedMistakes =
          mistakes.where((m) => m.replacements.isNotEmpty).where((m) {
            final end = math.min(plainText.length, m.offset + m.length);
            final word = plainText.substring(m.offset, end);
            return !(_project?.ignoredWords?.contains(word) ?? false);
          }).toList()..sort((a, b) => b.offset.compareTo(a.offset));

      for (final mistake in sortedMistakes) {
        _controller.replaceText(
          mistake.offset,
          mistake.length,
          mistake.replacements.first,
          null,
        );
      }

      if (!mounted) return;
      setState(() {
        _grammarIssueCount = 0;
        _updateCounts();
        _issues.clear();
        _showGrammarPanel = false;
      });
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isCheckingGrammar = false);
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
      _updateCounts();
    }
    _removeIssue(issue.id);
  }

  void _dismissIssue(_GrammarIssue issue) => _removeIssue(issue.id);

  void _removeIssue(String id) {
    _issues.removeWhere((i) => i.id == id);
    setState(() {
      _grammarIssueCount = _issues.length;
      if (_issues.isEmpty) _showGrammarPanel = false;
    });
  }
}

// =============================================================================
// Private grammar helpers
// =============================================================================

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
