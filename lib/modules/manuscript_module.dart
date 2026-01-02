import 'dart:async';
import 'dart:convert';
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

// The main application widget for the editor module
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

// Stateful widget to manage the editor state, autosave, and Firestore interaction.
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
  // Fix: library_private_types_in_public_api
  State<ManuscriptEditor> createState() => _ManuscriptEditorState();
}

// Fix: library_private_types_in_public_api
class _ManuscriptEditorState extends State<ManuscriptEditor> {
  late final QuillController _controller;
  // Enum to track which editor is currently focused
  _EditorType? _activeEditor;

  // ... existing code ...
  late final QuillController _titleController;
  final FocusNode _focusNode = FocusNode();
  late final FocusNode _titleFocusNode; // Declare as late final
  final ScrollController _scrollController = ScrollController();

  Timer? _titleAutosaveTimer;

  // Autosave logic
  Timer? _autosaveTimer;
  final Duration _autosaveDelay = const Duration(seconds: 2);

  // Grammar check logic
  late LanguageTool _languageTool;
  Timer? _grammarCheckTimer;
  final Duration _grammarCheckDelay = const Duration(milliseconds: 2500);
  List<WritingMistake> _grammarErrors = [];
  final HistoryService _historyService = HistoryService();
  final Set<String> _ignoredWords = {}; // For "Add to Dictionary"
  bool _isCheckingGrammar = false;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSwitchingChapter = false;
  // State for status bar features
  int _wordCount = 0;
  double _zoomFactor = 1.0;
  final String _proofingLanguage =
      'en-US'; // Use valid language code for the API

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _titleController = QuillController.basic();
    widget.onControllerReady(_controller);

    // Initialize _titleFocusNode here.
    _titleFocusNode = FocusNode();

    _languageTool = LanguageTool(language: _proofingLanguage);
    _loadIgnoredWords();
    _loadContent();

    // Listen for any text change to trigger the autosave debounce function
    _titleController.addListener(_onTitleChanged);
    _controller.addListener(_onTextChanged);

    // Add listeners to track which editor has focus
    // These listeners need to be added after _focusNode is initialized.
    _titleFocusNode.addListener(_onFocusChange);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _onFocusChange();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ManuscriptEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the selected chapter key is empty (e.g., on initial load), do nothing.
    if (widget.selectedChapterKey.isEmpty) {
      return;
    }

    // If the selected chapter has changed, save the old content and load the new one.
    if (widget.selectedChapterKey != oldWidget.selectedChapterKey) {
      _isSwitchingChapter = true;
      // Cancel any pending autosave timers
      _autosaveTimer?.cancel();
      _titleAutosaveTimer?.cancel();
      // Switch chapter with proper sequencing
      _switchChapter(oldWidget.selectedChapterKey);
    }
  }

  Future<void> _switchChapter(String oldKey) async {
    // Save old chapter content
    await _saveContent(isChangingChapter: true, chapterKeyToSave: oldKey);
    // Save old chapter title
    await _saveTitle(isChangingChapter: true, chapterKeyToSave: oldKey);
    // Now load the new content
    _loadContent();
  }

  // Load ignored words from the project in Hive
  void _loadIgnoredWords() {
    final projectBox = Hive.box<Project>('projects');
    final project = projectBox.get(widget.projectId);
    if (project != null) {
      setState(() {
        _ignoredWords.addAll(project.ignoredWords ?? []);
      });
    }
  }

  // 5. Load Document Content from Firestore
  void _loadContent() {
    setState(() {
      _isLoading = true;
    });

    debugPrint(
      'EDITOR: Loading content for Project: ${widget.projectId}, Chapter Key: ${widget.selectedChapterKey}',
    );

    // Correctly handle both string and int keys
    dynamic chapterKey;
    if (widget.selectedChapterKey.startsWith('front_matter_')) {
      chapterKey = widget.selectedChapterKey;
    } else {
      chapterKey = int.tryParse(widget.selectedChapterKey);
    }

    final chapter = widget.chapterProvider.getChapter(chapterKey);

    // Handle special pages by their new, reliable negative keys.
    if (widget.selectedChapterKey.startsWith('front_matter_')) {
      final keyPart = int.tryParse(widget.selectedChapterKey.split('_').last);

      if (keyPart == -2) {
        // Index page - We no longer load content, the build method will show the widget.
        _loadIndexPage();
        return;
      } else if (keyPart == -3 &&
          (chapter?.richTextJson == null || chapter?.richTextJson == '[]')) {
        // This is an empty "About Author" page, pre-populate it
        _loadAboutAuthorTemplate();
        return;
      }
    }
    _loadStandardContent(chapter);
  }

  // New method to handle focus changes and update the active editor
  void _onFocusChange() {
    // Use a post-frame callback to ensure the focus state is updated
    // before we rebuild the widget.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final newActiveEditor = _titleFocusNode.hasFocus
          ? _EditorType.title
          : (_focusNode.hasFocus ? _EditorType.manuscript : _activeEditor);

      if (newActiveEditor == _activeEditor) return;

      setState(() {
        _activeEditor = newActiveEditor;
      });
    });
  }

  void _onTitleChanged() {
    if (_isLoading) return;

    _titleAutosaveTimer?.cancel();
    _titleAutosaveTimer = Timer(_autosaveDelay, _saveTitle);
  }

  // 6. Debounced Text Change Handler
  void _onTextChanged() {
    if (_isLoading || _isSwitchingChapter) return;

    _updateWordCount();

    // Cancel any existing timer to debounce the save operation
    _autosaveTimer?.cancel();
    _grammarCheckTimer?.cancel();

    // Start a new timer
    _autosaveTimer = Timer(_autosaveDelay, _saveContent);
    _grammarCheckTimer = Timer(_grammarCheckDelay, _performGrammarCheck);
  }

  // Grammar Check Logic
  Future<void> _performGrammarCheck() async {
    if (!mounted) return;
    setState(() {
      _isCheckingGrammar = true;
    });

    final text = _controller.document.toPlainText();

    try {
      final result = await _languageTool.check(text);

      if (mounted) {
        // Filter out mistakes for words that are in our ignored list.
        final filteredResult = result.where((mistake) {
          final wordInContext = mistake.context.text.substring(
            mistake.context.offset,
            mistake.context.offset + mistake.context.length,
          );
          // Keep the mistake if the word is NOT in the ignored list.
          return !_ignoredWords.contains(wordInContext.toLowerCase());
        }).toList();
        setState(() => _grammarErrors = filteredResult);
      }
    } catch (e) {
      debugPrint('Error checking grammar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingGrammar = false;
        });
      }
    }
  }

  // Word Count Logic
  void _updateWordCount() {
    final plainText = _controller.document.toPlainText().trim();
    final wordCount = plainText.isEmpty
        ? 0
        : plainText.split(RegExp(r'\s+')).length;
    setState(() => _wordCount = wordCount);
  }

  void _loadAboutAuthorTemplate() {
    final projectBox = Hive.box<Project>('projects');
    final project = projectBox.get(widget.projectId);
    final authorName = project?.authors ?? 'Author Name';

    final delta = Delta()
      ..insert('About the Author\n', {'header': 1})
      ..insert('Name: $authorName\n', {'bold': true})
      ..insert('Email: \n')
      ..insert('Website: \n')
      ..insert('\n[Your bio here...]\n');

    _controller.document = Document.fromDelta(delta);
    setState(() {
      _isLoading = false;
      _isSwitchingChapter = false;
      _updateWordCount();
    });
  }

  void _loadIndexPage() {
    // This method is now just a placeholder to stop the editor loading process.
    // The actual UI is handled in the build method.
    setState(() {
      _isLoading = false;
      _isSwitchingChapter = false;
      // Clear the title controller as well
      _titleController.document = Document.fromDelta(
        Delta()..insert('Index\n', {'header': 1}),
      );
      // Clear the controller to ensure no old text is shown.
      _controller.clear();
    });
  }

  void _loadStandardContent(Chapter? chapter) {
    final contentJson = chapter?.richTextJson;
    debugPrint(
      'Loading chapter: ${chapter?.title}, key: ${chapter?.key}, contentJson: $contentJson',
    );

    // Load title
    if (chapter != null) {
      final titleDelta = Delta()..insert('${chapter.title}\n', {'header': 1});
      _titleController.document = Document.fromDelta(titleDelta);
    } else {
      _titleController.document = Document();
    }

    if (contentJson != null && contentJson.isNotEmpty) {
      try {
        final doc = jsonDecode(contentJson);
        // Handle both formats: direct ops list or map with ops
        Map<String, dynamic> documentMap;
        if (doc is List) {
          // Direct ops list
          documentMap = {'ops': doc};
        } else if (doc is Map<String, dynamic>) {
          // Map with ops
          documentMap = doc;
        } else {
          throw Exception('Unexpected document format');
        }
        // Clean the document by removing any page break embeds
        final cleanedDoc = _cleanDocument(documentMap);
        _controller.document = Document.fromJson(cleanedDoc);
      } catch (e) {
        debugPrint("Error loading document: $e. Loading default.");
        _controller.document = Document();
      }
    } else {
      _controller.document = Document();
    }

    setState(() {
      _isLoading = false;
      _isSwitchingChapter = false;
      _updateWordCount();
      _performGrammarCheck();
    });
  }

  // Clean document by removing page break embeds
  List<dynamic> _cleanDocument(Map<String, dynamic> doc) {
    final ops = doc['ops'] as List<dynamic>?;
    if (ops == null) return [];

    final cleanedOps = ops.where((op) {
      final insert = op['insert'];
      if (insert is Map<String, dynamic>) {
        // Remove page break embeds
        return !insert.containsKey('page-break');
      }
      return true;
    }).toList();

    return cleanedOps;
  }

  /// Public method to allow parent widgets to trigger a grammar check.
  void triggerGrammarCheck() {
    _performGrammarCheck();
  }

  // Callback function for the proofing dialog to update the editor state
  void _applyProofingFix(WritingMistake mistake, String replacement) {
    _controller.replaceText(
      mistake.offset,
      mistake.length,
      replacement,
      const TextSelection.collapsed(offset: 0),
    );
    // After applying a fix, it's good practice to re-run the check.
    // The text change will automatically trigger a debounced grammar check.
  }

  // Callback for adding a word to the dictionary
  Future<void> _addToDictionary(String word) async {
    final lowerCaseWord = word.toLowerCase();
    if (_ignoredWords.add(lowerCaseWord)) {
      // Word was added (it wasn't already in the set)
      setState(() {}); // Update UI if needed

      // Persist the change to Hive
      final projectBox = Hive.box<Project>('projects');
      final project = projectBox.get(widget.projectId);
      if (project != null) {
        (project.ignoredWords ??= []).add(lowerCaseWord);
        await project.save();
      }

      _performGrammarCheck(); // Re-run the check with the updated dictionary
    }
  }

  Future<void> _saveTitle({
    bool isChangingChapter = false,
    String? chapterKeyToSave,
  }) async {
    final key = chapterKeyToSave ?? widget.selectedChapterKey;
    final newTitle = _titleController.document.toPlainText().trim();

    // Prevent saving an empty title
    if (newTitle.isEmpty) return;

    // Handle both string and int keys
    dynamic chapterKey;
    if (key.startsWith('front_matter_')) {
      chapterKey = key;
    } else {
      chapterKey = int.tryParse(key);
    }

    if (chapterKey != null) {
      // Check if title has actually changed to avoid unnecessary saves
      final currentChapter = widget.chapterProvider.getChapter(chapterKey);
      if (currentChapter?.title != newTitle) {
        await widget.chapterProvider.updateChapterTitle(chapterKey, newTitle);
      }
    }
  }

  // 7. Autosave Content to Firestore
  Future<void> _saveContent({
    bool isChangingChapter = false,
    String? chapterKeyToSave,
  }) async {
    // If we are changing chapters, we don't need to show the "Saving..." indicator.
    if (!isChangingChapter) {
      setState(() {
        _isSaving = true;
      });
    }

    // --- HISTORY LOGIC ---
    final keyForHistory = chapterKeyToSave ?? widget.selectedChapterKey;
    dynamic parsedKeyForHistory;
    if (keyForHistory.startsWith('front_matter_')) {
      parsedKeyForHistory = keyForHistory;
    } else {
      parsedKeyForHistory = int.tryParse(keyForHistory);
    }
    final currentChapterState = widget.chapterProvider.getChapter(
      parsedKeyForHistory,
    );
    if (currentChapterState != null) {
      await _historyService.addHistoryEntry(
        targetKey: currentChapterState.key,
        targetType: 'Chapter',
        objectToSave: currentChapterState,
        projectId: widget.projectId,
      );
    }
    // --- END HISTORY LOGIC ---
    final contentToSave = jsonEncode(_controller.document.toDelta().toJson());
    debugPrint('Content to save: $contentToSave');
    final key = chapterKeyToSave ?? widget.selectedChapterKey;

    // Handle both string and int keys
    dynamic chapterKey;
    if (key.startsWith('front_matter_')) {
      chapterKey = key;
    } else {
      chapterKey = int.tryParse(key);
    }

    if (chapterKey != null) {
      widget.chapterProvider.updateChapterContent(chapterKey, contentToSave);
    }

    // Also update the project's last modified time
    final projectBox = Hive.box<Project>('projects');
    final project = projectBox.get(widget.projectId);
    if (project != null) {
      project.lastModified = DateTime.now();
      project.save();
    }
    debugPrint('PROVIDER: Autosaved content successfully.');

    setState(() {
      _isSaving = false;
    });
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _grammarCheckTimer?.cancel();
    _titleAutosaveTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose(); // QuillController has a dispose method
    _titleController.dispose();
    _focusNode.dispose();
    _titleFocusNode.dispose();
    // Remove listeners to prevent memory leaks
    _titleFocusNode.removeListener(_onFocusChange);
    _focusNode.removeListener(_onFocusChange);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildEditorContent(Color backgroundColor) {
    // Check if the selected page is the Index page
    if (widget.selectedChapterKey == 'front_matter_-2') {
      return IndexPageWidget(
        chapterProvider: widget.chapterProvider,
        onChapterSelected: widget.onChapterSelected,
      );
    }

    // Otherwise, return the standard Quill editor
    return QuillEditor(
      controller: _controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: QuillEditorConfig(
        padding: const EdgeInsets.all(16),
        placeholder: 'Start writing your epic manuscript here...',
        embedBuilders: [...FlutterQuillEmbeds.editorBuilders()],
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            const TextStyle(fontSize: 16, height: 1.5, color: Colors.black),
            // Vertical spacing before and after
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(6, 0), // Vertical spacing before and after
            const VerticalSpacing(0, 0), // Vertical spacing between lines
            null, // Decoration
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = () {
      final theme = Theme.of(context);
      final baseColor = theme.colorScheme.surface;
      final hsl = HSLColor.fromColor(baseColor);
      return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
    }();

    return Scaffold(
      // The AppBar is handled by the parent screen, so it's removed here.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Don't show toolbars for the Index page
                  if (widget.selectedChapterKey != 'front_matter_-2')
                    // Conditionally render the correct toolbar based on focus
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: _activeEditor == _EditorType.title
                          ? QuillSimpleToolbar(
                              key: const ValueKey('title_toolbar'),
                              controller: _titleController,
                              config: const QuillSimpleToolbarConfig(
                                showUndo: false,
                                showRedo: false,
                                showFontFamily: false,
                                showFontSize: false,
                                showSubscript: false,
                                showSuperscript: false,
                                showListBullets: false,
                                showListNumbers: false,
                                showListCheck: false,
                                showCodeBlock: false,
                                showQuote: false,
                                showIndent: false,
                                showLink: false,
                                showSearchButton: false,
                                showInlineCode: false,
                                showClearFormat: false,
                                showBackgroundColorButton: false,
                                showHeaderStyle: false,
                              ),
                            )
                          : QuillSimpleToolbar(
                              key: const ValueKey('main_toolbar'),
                              controller: _controller,
                              config: QuillSimpleToolbarConfig(
                                showBoldButton: true,
                                showItalicButton: true,
                                showUnderLineButton: true,
                                showStrikeThrough: true,
                                showColorButton: true,
                                showBackgroundColorButton: true,
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
                                showFontSize: true,
                                showFontFamily: true,
                                showInlineCode: true,
                                showSubscript: true,
                                showSuperscript: true,
                                embedButtons:
                                    FlutterQuillEmbeds.toolbarButtons(),
                                showSearchButton: false,
                                customButtons: [
                                  QuillToolbarCustomButtonOptions(
                                    icon: Icon(Icons.search),
                                    onPressed: _openFindReplaceDialog,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).round()),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Page container
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(
                                    (0.2 * 255).round(),
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: InteractiveViewer(
                              boundaryMargin: const EdgeInsets.all(
                                double.infinity,
                              ),
                              minScale: 0.5,
                              maxScale: 4.0,
                              scaleEnabled:
                                  false, // Disable user scaling gestures
                              panEnabled:
                                  false, // Disable panning to allow keyboard shortcuts
                              child: Transform.scale(
                                scale: _zoomFactor,
                                child: Scrollbar(
                                  controller: _scrollController,
                                  child: Column(
                                    children: [
                                      if (widget.selectedChapterKey !=
                                          'front_matter_-2')
                                        QuillEditor(
                                          controller: _titleController,
                                          focusNode: _titleFocusNode,
                                          scrollController: ScrollController(),
                                          // Use a dummy controller
                                          config: QuillEditorConfig(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            autoFocus: false,
                                            expands: false,
                                            customStyles: DefaultStyles(
                                              h1: DefaultTextBlockStyle(
                                                Theme.of(context)
                                                    .textTheme
                                                    .displaySmall!
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ), // TextStyle
                                                // Vertical spacing before and after
                                                // Vertical spacing between lines
                                                const HorizontalSpacing(0, 0),
                                                const VerticalSpacing(16, 8),
                                                const VerticalSpacing(
                                                  0,
                                                  0,
                                                ), // Horizontal spacing
                                                null, // Decoration
                                              ),
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: _buildEditorContent(
                                          Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Vertical ruler on the left
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 3, color: Colors.white),
                          ),
                          // Horizontal ruler on the top
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(height: 3, color: Colors.white),
                          ),
                          // Vertical ruler on the right
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 3, color: Colors.white),
                          ),
                          // Horizontal ruler on the bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(height: 3, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomStatusBar(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Words: $_wordCount',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const VerticalDivider(),
              InkWell(
                onTap: () => _showGrammarIssues(context),
                child: Row(
                  children: [
                    if (_isCheckingGrammar)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        _grammarErrors.isEmpty
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: _grammarErrors.isEmpty
                            ? Colors.green
                            : Colors.yellow,
                        size: 14,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      '${_grammarErrors.length} Issues',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        decoration: _grammarErrors.isNotEmpty
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Zoom: ${(_zoomFactor * 100).toInt()}%',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 150, // Give the slider a fixed width
                child: Slider(
                  value: _zoomFactor,
                  min: 0.5, // 50%
                  max: 2.5, // 250%
                  divisions: 20,
                  onChanged: (newZoom) {
                    setState(() => _zoomFactor = newZoom);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.center_focus_strong_outlined),
                iconSize: 18,
                color: colorScheme.onSurfaceVariant,
                tooltip: 'Reset Zoom',
                onPressed: () {
                  setState(() => _zoomFactor = 1.0);
                },
              ),
            ],
          ),
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
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 14,
                ),
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

  void _showGrammarIssues(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ProofingDialog(
          initialMistakes: _grammarErrors,
          onFix: _applyProofingFix,
          onAddToDictionary: _addToDictionary,
          onDialogClosed: (remainingMistakes) {
            // Update the main screen's error list when the dialog is closed
            setState(() {
              _grammarErrors = remainingMistakes;
            });
          },
        );
      },
    );
  }

  void _openFindReplaceDialog() {
    final state = this as _ManuscriptEditorState;
    showDialog(
      context: context,
      builder: (context) => FindReplaceDialog(controller: state._controller),
    );
  }
}

extension ManuscriptEditorStateExtension on State<ManuscriptEditor> {
  /// Public method to allow parent widgets to trigger a content load,
  /// for example when a new chapter is created.
  void loadNewChapterContent() {
    final state = this as _ManuscriptEditorState;
    // Immediately save any pending changes for the old chapter.
    state._autosaveTimer?.cancel();
    state._saveContent(
      isChangingChapter: true,
      chapterKeyToSave: state.widget.selectedChapterKey,
    );

    // Load the content for the new chapter, indicating it's new.
    // Note: The logic to insert the title as a heading on new chapter creation
    // would need to be re-added to _loadContent if desired.
    state._loadContent();
  }

  void saveTitleAndContent() {
    final state = this as _ManuscriptEditorState;
    state._saveTitle();
  }

  /// Public method to allow parent widgets to trigger a grammar check.
  void triggerGrammarCheck() {
    final state = this as _ManuscriptEditorState;
    state.triggerGrammarCheck();
  }

  /// Public method to get the QuillController for find and replace functionality.
  QuillController getController() {
    final state = this as _ManuscriptEditorState;
    return state._controller;
  }

  void _openFindReplaceDialog() {
    final state = this as _ManuscriptEditorState;
    showDialog(
      context: context,
      builder: (context) => FindReplaceDialog(controller: state._controller),
    );
  }
}

enum _EditorType { title, manuscript }

// A dedicated stateful widget for the proofing dialog
class _ProofingDialog extends StatefulWidget {
  final List<WritingMistake> initialMistakes;
  final Function(WritingMistake, String) onFix;
  final Function(String) onAddToDictionary;
  final Function(List<WritingMistake>) onDialogClosed;

  const _ProofingDialog({
    required this.initialMistakes,
    required this.onFix,
    required this.onAddToDictionary,
    required this.onDialogClosed,
  });

  @override
  State<_ProofingDialog> createState() => _ProofingDialogState();
}

class _ProofingDialogState extends State<_ProofingDialog> {
  late List<WritingMistake> _mistakes;
  int _currentIndex = 0;
  String? _selectedSuggestion;

  @override
  void initState() {
    super.initState();
    _mistakes = List.from(widget.initialMistakes);
  }

  void _nextMistake() {
    setState(() {
      if (_mistakes.isNotEmpty) {
        _currentIndex = (_currentIndex + 1) % _mistakes.length;
        _selectedSuggestion = null;
      }
    });
  }

  void _ignore() {
    setState(() {
      _mistakes.removeAt(_currentIndex);
      if (_currentIndex >= _mistakes.length && _mistakes.isNotEmpty) {
        _currentIndex = 0;
      }
      _selectedSuggestion = null;
    });
  }

  void _ignoreAll() {
    final currentMistake = _mistakes[_currentIndex];
    final wordToIgnore = currentMistake.context.text.substring(
      currentMistake.context.offset,
      currentMistake.context.offset + currentMistake.context.length,
    );
    setState(() {
      _mistakes.removeWhere((mistake) {
        final mistakeWord = mistake.context.text.substring(
          mistake.context.offset,
          mistake.context.offset + mistake.context.length,
        );
        return mistakeWord.toLowerCase() == wordToIgnore.toLowerCase();
      });
      if (_currentIndex >= _mistakes.length && _mistakes.isNotEmpty) {
        _currentIndex = 0;
      }
      _selectedSuggestion = null;
    });
  }

  void _fix(String replacement) {
    final mistakeToFix = _mistakes[_currentIndex];
    widget.onFix(mistakeToFix, replacement);
    _ignore(); // Remove from the local list after sending the fix command
  }

  void _changeAll(String replacement) {
    final currentMistake = _mistakes[_currentIndex];
    final wordToReplace = currentMistake.context.text.substring(
      currentMistake.context.offset,
      currentMistake.context.offset + currentMistake.context.length,
    );

    // Apply the fix to all instances of this word
    final mistakesToFix = _mistakes.where((mistake) {
      final mistakeWord = mistake.context.text.substring(
        mistake.context.offset,
        mistake.context.offset + mistake.context.length,
      );
      return mistakeWord.toLowerCase() == wordToReplace.toLowerCase();
    }).toList();

    for (final mistake in mistakesToFix) {
      widget.onFix(mistake, replacement);
    }

    // Remove all these mistakes from the list
    setState(() {
      _mistakes.removeWhere((mistake) {
        final mistakeWord = mistake.context.text.substring(
          mistake.context.offset,
          mistake.context.offset + mistake.context.length,
        );
        return mistakeWord.toLowerCase() == wordToReplace.toLowerCase();
      });
      if (_currentIndex >= _mistakes.length && _mistakes.isNotEmpty) {
        _currentIndex = 0;
      }
      _selectedSuggestion = null;
    });
  }

  void _addToDictionary() {
    final mistake = _mistakes[_currentIndex];
    // Extract the incorrect word from the context
    final word = mistake.context.text.substring(
      mistake.context.offset,
      mistake.context.offset + mistake.context.length,
    );
    widget.onAddToDictionary(word);
    _ignore(); // Remove from local list
  }

  Widget _buildHighlightedContext(WritingMistake mistake) {
    final before = mistake.context.text.substring(0, mistake.context.offset);
    final error = mistake.context.text.substring(
      mistake.context.offset,
      mistake.context.offset + mistake.context.length,
    );
    final after = mistake.context.text.substring(
      mistake.context.offset + mistake.context.length,
    );

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(
          context,
        ).style.copyWith(fontStyle: FontStyle.italic, fontSize: 14),
        children: [
          TextSpan(text: '"...$before'),
          TextSpan(
            text: error,
            style: const TextStyle(
              backgroundColor: Colors.yellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: '$after..."'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool hasMistakes = _mistakes.isNotEmpty;
    final WritingMistake? currentMistake = hasMistakes
        ? _mistakes[_currentIndex]
        : null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.spellcheck, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Spelling and Grammar',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hasMistakes) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1} of ${_mistakes.length}',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              widget.onDialogClosed(_mistakes);
              Navigator.of(context).pop();
            },
            tooltip: 'Close',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 500,
          maxWidth: 500,
          minHeight: 300,
          maxHeight: 400,
        ),
        child: hasMistakes && currentMistake != null
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Error message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentMistake.message,
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Context with highlighted error
                    const Text(
                      'Context:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.3,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _buildHighlightedContext(currentMistake),
                    ),
                    const SizedBox(height: 16),

                    // Suggestions
                    const Text(
                      'Suggestions:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (currentMistake.replacements.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: currentMistake.replacements.length,
                          itemBuilder: (context, index) {
                            final suggestion =
                                currentMistake.replacements[index];
                            final isSelected =
                                _selectedSuggestion == suggestion;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedSuggestion = isSelected
                                      ? null
                                      : suggestion;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primaryContainer
                                      : Colors.transparent,
                                  borderRadius: index == 0
                                      ? const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        )
                                      : index ==
                                            currentMistake.replacements.length -
                                                1
                                      ? const BorderRadius.only(
                                          bottomLeft: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        )
                                      : BorderRadius.zero,
                                ),
                                child: Text(
                                  suggestion,
                                  style: TextStyle(
                                    color: isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'No suggestions available.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _ignore,
                          icon: const Icon(Icons.skip_next, size: 18),
                          label: const Text('Ignore'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _ignoreAll,
                          icon: const Icon(Icons.skip_next, size: 18),
                          label: const Text('Ignore All'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_selectedSuggestion != null) ...[
                          ElevatedButton.icon(
                            onPressed: () => _fix(_selectedSuggestion!),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Change'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _changeAll(_selectedSuggestion!),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Change All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                          ),
                        ],
                        TextButton.icon(
                          onPressed: _addToDictionary,
                          icon: const Icon(Icons.library_add, size: 18),
                          label: const Text('Add to Dictionary'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.secondary,
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _nextMistake,
                          icon: const Icon(Icons.arrow_forward),
                          tooltip: 'Next Issue',
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No issues found. Great work!',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
