import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:lore_keeper/widgets/find_replace_dialog.dart';
import 'package:language_tool/language_tool.dart';

import 'package:lore_keeper/services/history_service.dart';
import 'package:lore_keeper/widgets/index_page_widget.dart';
import 'package:lore_keeper/widgets/cover_page_form.dart';
import 'package:lore_keeper/widgets/about_author_form.dart';
import 'package:lore_keeper/theme/app_colors.dart';

class ManuscriptModule extends StatelessWidget {
  final int projectId;
  final String selectedChapterKey;
  final ChapterListProvider chapterProvider;
  final ValueChanged<String> onChapterSelected;
  final Function(QuillController?) onControllerReady;

  const ManuscriptModule({
    super.key,
    required this.projectId,
    required this.selectedChapterKey,
    required this.chapterProvider,
    required this.onChapterSelected,
    required this.onControllerReady,
  });

  @override
  Widget build(BuildContext context) {
    return ManuscriptEditor(
      projectId: projectId,
      selectedChapterKey: selectedChapterKey,
      chapterProvider: chapterProvider,
      onChapterSelected: onChapterSelected,
      onControllerReady: onControllerReady,
    );
  }
}

class ManuscriptEditor extends StatefulWidget {
  final int projectId;
  final String selectedChapterKey;
  final ChapterListProvider chapterProvider;
  final ValueChanged<String> onChapterSelected;
  final Function(QuillController?) onControllerReady;

  const ManuscriptEditor({
    super.key,
    required this.projectId,
    required this.selectedChapterKey,
    required this.chapterProvider,
    required this.onChapterSelected,
    required this.onControllerReady,
  });

  @override
  State<ManuscriptEditor> createState() => _ManuscriptEditorState();

  // Public methods to access state methods

  QuillController? getController() {
    final state = key as GlobalKey<State<ManuscriptEditor>>?;
    return (state?.currentState as _ManuscriptEditorState?)?.getController();
  }

  void loadNewChapterContent() {
    final state = key as GlobalKey<State<ManuscriptEditor>>?;
    (state?.currentState as _ManuscriptEditorState?)?.loadNewChapterContent();
  }

  Future<void> triggerGrammarCheck() {
    final state = key as GlobalKey<State<ManuscriptEditor>>?;
    return (state?.currentState as _ManuscriptEditorState?)
            ?._runGrammarCheck() ??
        Future.value();
  }

  Future<void> autoCorrect() {
    final state = key as GlobalKey<State<ManuscriptEditor>>?;
    return (state?.currentState as _ManuscriptEditorState?)
            ?._runAutoCorrect() ??
        Future.value();
  }
}

enum _EditorType { title, manuscript }

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
  Size? _lastEditorSize;
  final List<_GrammarIssue> _issues = [];
  bool _showGrammarPanel = false;
  String? _activeCategory;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _titleController = QuillController.basic();
    widget.onControllerReady(_controller);
    _titleFocusNode = FocusNode();

    _loadProject();

    _loadContent();

    _titleController.addListener(_onTitleChanged);
    _controller.addListener(_onTextChanged);
    _titleFocusNode.addListener(_onFocusChange);
    _focusNode.addListener(_onFocusChange);
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
    dynamic chapterKey = widget.selectedChapterKey.startsWith('front_matter_')
        ? widget.selectedChapterKey
        : int.tryParse(widget.selectedChapterKey);

    final chapter = widget.chapterProvider.getChapter(chapterKey);

    if (widget.selectedChapterKey.startsWith('front_matter_')) {
      final keyPart = int.tryParse(widget.selectedChapterKey.split('_').last);
      if (keyPart == -2) {
        _loadIndexPage();
        return;
      }
      if (keyPart == -3 &&
          (chapter?.richTextJson == null ||
              (chapter?.richTextJson ?? '').isEmpty ||
              chapter?.richTextJson == '[]')) {
        _loadAboutAuthorTemplate();
        return;
      }
    }
    _loadStandardContent(chapter);
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

    final text = _controller.document.toPlainText();
    if (text.isNotEmpty &&
        (text.endsWith(' ') || text.endsWith('\t') || text.endsWith('\n'))) {
      _grammarDebounce?.cancel();
      _grammarDebounce = Timer(_grammarDelay, () {
        if (!_isCheckingGrammar) {
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

  void _loadAboutAuthorTemplate() {
    final authorName = _project?.authors ?? 'Author Name';
    final delta = Delta()
      ..insert('About the Author\n', {'header': 1})
      ..insert('Name: $authorName\n', {'bold': true})
      ..insert('\n[Author Bio...]\n');
    _controller.document = Document.fromDelta(delta);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSwitchingChapter = false;
        _updateWordCount();
      });
    }
  }

  void _loadIndexPage() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSwitchingChapter = false;
        _titleController.document = Document.fromDelta(
          Delta()..insert('Index\n', {'header': 1}),
        );
        _controller.document = Document();
      });
    }
  }

  void _loadStandardContent(Chapter? chapter) {
    if (chapter != null) {
      _titleController.document = Document.fromDelta(
        Delta()..insert('${chapter.title}\n', {'header': 1}),
      );
    } else {
      _titleController.document = Document();
    }

    if (chapter?.richTextJson != null && chapter!.richTextJson!.isNotEmpty) {
      try {
        final doc = jsonDecode(chapter.richTextJson!);
        final documentMap = doc is List
            ? {'ops': doc}
            : (doc as Map<String, dynamic>);
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

  Future<void> _saveTitle({
    bool isChangingChapter = false,
    String? chapterKeyToSave,
  }) async {
    final key = chapterKeyToSave ?? widget.selectedChapterKey;
    final newTitle = _titleController.document.toPlainText().trim();
    if (newTitle.isEmpty) return;
    dynamic cKey = key.startsWith('front_matter_') ? key : int.tryParse(key);
    if (cKey != null) {
      final curr = widget.chapterProvider.getChapter(cKey);
      if (curr?.title != newTitle) {
        await widget.chapterProvider.updateChapterTitle(cKey, newTitle);
      }
    }
  }

  Future<void> _saveContent({
    bool isChangingChapter = false,
    String? chapterKeyToSave,
  }) async {
    if (!isChangingChapter && mounted) setState(() => _isSaving = true);
    final key = chapterKeyToSave ?? widget.selectedChapterKey;
    dynamic cKey = key.startsWith('front_matter_') ? key : int.tryParse(key);
    if (cKey != null) {
      final curr = widget.chapterProvider.getChapter(cKey);
      if (curr != null) {
        await _historyService.addHistoryEntry(
          targetKey: curr.key,
          targetType: 'Chapter',
          objectToSave: curr,
          projectId: widget.projectId,
        );
      }
      await widget.chapterProvider.updateChapterContent(
        cKey,
        jsonEncode(_controller.document.toDelta().toJson()),
      );
    }
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
    final bgColor = theme.brightness == Brightness.dark
        ? AppColors.bgMain
        : AppColors.bgMainLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
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
      bottomNavigationBar: _buildBottomStatusBar(),
    );
  }

  Widget _buildTitleToolbar() => QuillSimpleToolbar(
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
  );

  Widget _buildMainToolbar() => QuillSimpleToolbar(
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
          icon: const Icon(Icons.search),
          onPressed: _openFindReplaceDialog,
        ),
      ],
    ),
  );

  Widget _buildEditorView(Color bgColor) {
    return Container(
      decoration: BoxDecoration(color: bgColor),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
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
    return QuillEditor(
      controller: _controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: QuillEditorConfig(
        padding: const EdgeInsets.all(16),
        placeholder: 'Write your story...',
        embedBuilders: [...FlutterQuillEmbeds.editorBuilders()],
      ),
    );
  }

  void _openFindReplaceDialog() => showDialog(
    context: context,
    builder: (context) => FindReplaceDialog(controller: _controller),
  );

  Widget _buildBottomStatusBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: cs.surfaceContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Words: $_wordCount',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
              const VerticalDivider(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                ),
                icon: Icon(
                  _grammarIssueCount == 0
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: _grammarIssueCount == 0
                      ? cs.primary
                      : cs.errorContainer,
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
                icon: const Icon(Icons.auto_fix_high, size: 16),
                tooltip: 'Auto-correct with LanguageTool',
                onPressed: _isCheckingGrammar ? null : _runAutoCorrect,
              ),
            ],
          ),
          Row(
            children: [
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
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () => setState(
                  () => _zoomFactor = (_zoomFactor - 0.1).clamp(0.5, 2.0),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () => setState(
                  () => _zoomFactor = (_zoomFactor + 0.1).clamp(0.5, 2.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  QuillController? getController() {
    return _controller;
  }

  void loadNewChapterContent() {
    _loadContent();
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
                icon: const Icon(Icons.close),
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
                                    Icons.shield_outlined,
                                    size: 16,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    issue.category,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                issue.message,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                issue.context,
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
