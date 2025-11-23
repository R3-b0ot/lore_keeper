import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hive/hive.dart';
import 'package:flutter/gestures.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:language_tool/language_tool.dart';
import 'package:lore_keeper/services/history_service.dart';
import 'package:lore_keeper/widgets/index_page_widget.dart';

// Custom embed for page breaks
class PageBreakEmbed extends Embeddable {
  const PageBreakEmbed() : super('page_break', null);

  @override
  Map<String, dynamic> toJson() => {'type': 'page_break'};

  static PageBreakEmbed fromJson(Map<String, dynamic> json) =>
      const PageBreakEmbed();
}

// Builder for page break embed
class PageBreakEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'page_break';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return Container(
      height: 20,
      alignment: Alignment.center,
      child: const Text(
        '--- Page Break ---',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

// The main application widget for the editor module
class ManuscriptModule extends StatelessWidget {
  final int projectId;
  final String selectedChapterKey;
  final ChapterListProvider chapterProvider;
  final ValueChanged<String> onChapterSelected;

  const ManuscriptModule({
    super.key,
    required this.projectId,
    required this.selectedChapterKey,
    required this.chapterProvider,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ManuscriptEditor(
      projectId: projectId,
      selectedChapterKey: selectedChapterKey,
      chapterProvider: chapterProvider,
      onChapterSelected: onChapterSelected,
    );
  }
}

// Stateful widget to manage the editor state, autosave, and Firestore interaction.
class ManuscriptEditor extends StatefulWidget {
  final int projectId;
  final String selectedChapterKey;
  final ChapterListProvider chapterProvider;
  final ValueChanged<String> onChapterSelected;
  const ManuscriptEditor({
    super.key,
    required this.projectId,
    required this.selectedChapterKey,
    required this.chapterProvider,
    required this.onChapterSelected,
  });
  @override
  // Fix: library_private_types_in_public_api
  State<ManuscriptEditor> createState() => _ManuscriptEditorState();
}

// Fix: library_private_types_in_public_api
class _ManuscriptEditorState extends State<ManuscriptEditor> {
  late final QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

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
  // State for status bar features
  int _wordCount = 0;
  double _zoomFactor = 1.0;
  final String _proofingLanguage =
      'en-US'; // Use valid language code for the API

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _languageTool = LanguageTool(language: _proofingLanguage);
    _loadIgnoredWords();
    _loadContent();
    // Listen for any text change to trigger the autosave debounce function
    _controller.addListener(_onTextChanged);
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
      // Immediately save any pending changes for the old chapter.
      _autosaveTimer?.cancel();
      _saveContent(
        isChangingChapter: true,
        chapterKeyToSave: oldWidget.selectedChapterKey,
      );

      // Load the content for the new chapter.
      _loadContent();
    }
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

  // 6. Debounced Text Change Handler
  void _onTextChanged() {
    if (_isLoading) return;

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
      _updateWordCount();
    });
  }

  void _loadIndexPage() {
    // This method is now just a placeholder to stop the editor loading process.
    // The actual UI is handled in the build method.
    setState(() {
      _isLoading = false;
      // Clear the controller to ensure no old text is shown.
      _controller.clear();
    });
  }

  void _loadStandardContent(Chapter? chapter) {
    final contentJson = chapter?.richTextJson;
    if (contentJson != null && contentJson.isNotEmpty) {
      try {
        final doc = jsonDecode(contentJson);
        _controller.document = Document.fromJson(doc);
      } catch (e) {
        debugPrint("Error loading document: $e. Loading default.");
        _controller.document = Document();
      }
    } else {
      _controller.document = Document();
    }

    setState(() {
      _isLoading = false;
      _updateWordCount();
      _performGrammarCheck();
    });
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
    _controller.removeListener(_onTextChanged);
    _controller.dispose(); // QuillController has a dispose method
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildEditorContent(Color backgroundColor) {
    // Determine text color based on background lightness
    final textColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

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
        embedBuilders: [
          ...FlutterQuillEmbeds.editorBuilders(),
          PageBreakEmbedBuilder(),
        ],
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            TextStyle(fontSize: 16, height: 1.5, color: textColor),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(6, 0),
            const VerticalSpacing(0, 0),
            null,
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
                  QuillSimpleToolbar(
                    controller: _controller,
                    config: QuillSimpleToolbarConfig(
                      customButtons: [
                        QuillToolbarCustomButtonOptions(
                          icon: const Icon(Icons.insert_page_break),
                          onPressed: () {
                            final index = _controller.selection.baseOffset;
                            _controller.document.insert(
                              index,
                              PageBreakEmbed(),
                            );
                            _controller.moveCursorToPosition(index + 1);
                          },
                          tooltip: 'Insert Page Break',
                        ),
                      ],
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
                              child: Transform.scale(
                                scale: _zoomFactor,
                                child: Scrollbar(
                                  controller: _scrollController,
                                  child: Listener(
                                    onPointerSignal: (pointerSignal) {
                                      if (pointerSignal is PointerScrollEvent) {
                                        _scrollController.jumpTo(
                                          _scrollController.offset +
                                              pointerSignal.scrollDelta.dy,
                                        );
                                      }
                                    },
                                    child: _buildEditorContent(Colors.white),
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
                            child: Container(
                              width: 1,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          // Horizontal ruler on the top
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          // Vertical ruler on the right
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 1,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          // Horizontal ruler on the bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
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
                        Icons.check_circle,
                        color: _grammarErrors.isEmpty
                            ? Colors.green
                            : Colors.orange,
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

  /// Public method to allow parent widgets to trigger a grammar check.
  void triggerGrammarCheck() {
    final state = this as _ManuscriptEditorState;
    state.triggerGrammarCheck();
  }
}

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

  @override
  void initState() {
    super.initState();
    _mistakes = List.from(widget.initialMistakes);
  }

  void _nextMistake() {
    setState(() {
      if (_mistakes.isNotEmpty) {
        _currentIndex = (_currentIndex + 1) % _mistakes.length;
      }
    });
  }

  void _ignore() {
    setState(() {
      _mistakes.removeAt(_currentIndex);
      if (_currentIndex >= _mistakes.length && _mistakes.isNotEmpty) {
        _currentIndex = 0;
      }
    });
  }

  void _fix(String replacement) {
    final mistakeToFix = _mistakes[_currentIndex];
    widget.onFix(mistakeToFix, replacement);
    _ignore(); // Remove from the local list after sending the fix command
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

  @override
  Widget build(BuildContext context) {
    final bool hasMistakes = _mistakes.isNotEmpty;
    final WritingMistake? currentMistake = hasMistakes
        ? _mistakes[_currentIndex]
        : null;

    return AlertDialog(
      title: Text('Proofing (${_mistakes.length} issues)'),
      content: SizedBox(
        width: 400,
        height: 250,
        child: hasMistakes && currentMistake != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentMistake.message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"...${currentMistake.context.text}..."',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  const Text('Suggestions:'),
                  if (currentMistake.replacements.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      children: currentMistake.replacements
                          .take(3)
                          .map(
                            (rep) => ActionChip(
                              label: Text(rep),
                              onPressed: () => _fix(rep),
                            ),
                          )
                          .toList(),
                    )
                  else
                    const Text(
                      'No suggestions available.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _ignore,
                        child: const Text('Ignore'),
                      ),
                      TextButton(
                        onPressed: _addToDictionary,
                        child: const Text('Add to Dictionary'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _nextMistake,
                        tooltip: 'Next Issue',
                      ),
                    ],
                  ),
                ],
              )
            : const Center(child: Text('No issues found. Great work!')),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onDialogClosed(_mistakes);
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
