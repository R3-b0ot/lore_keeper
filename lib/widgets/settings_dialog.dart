// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // For debounce timer
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:lore_keeper/widgets/genre_selection_dialog.dart';
import 'package:lore_keeper/widgets/dictionary_manager_dialog.dart';

// -------------------------------------------------------------
// --- Settings Dialog Widget
// -------------------------------------------------------------

class SettingsDialog extends StatefulWidget {
  final Project? project;
  final int moduleIndex;
  final ChapterListProvider? chapterProvider;
  final CharacterListProvider? characterProvider;
  final VoidCallback onDictionaryOpened;

  const SettingsDialog({
    super.key,
    this.project,
    required this.moduleIndex,
    this.chapterProvider,
    this.characterProvider,
    required this.onDictionaryOpened,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  int _selectedCategoryIndex = 0; // This can't be final as it changes
  late final List<String> _categories;
  Set<String> _oxford5000Words = {};
  bool _isLoadingWords = true;
  Timer? _debounce;

  // Controllers for Metadata editing
  late TextEditingController _titleController;
  late TextEditingController _bookTitleController;
  late TextEditingController _authorsController;
  String _selectedGenre = '';
  late double _historyLimit;

  @override
  void initState() {
    super.initState();
    _loadCommonWords();
    // Determine categories based on whether it's global or project settings
    if (widget.project == null) {
      _categories = ['About', 'Appearance'];
    } else {
      _categories = [
        'Information',
        'Cast Overview',
        'Metadata',
        'Proofing',
        'History',
        'Appearance',
      ];
      _titleController = TextEditingController(text: widget.project!.title);
      _bookTitleController = TextEditingController(
        text: widget.project!.bookTitle ?? '',
      );
      _authorsController = TextEditingController(
        text: widget.project!.authors ?? '',
      );
      _selectedGenre = widget.project!.genre ?? 'N/A';
      _historyLimit = (widget.project!.historyLimit ?? 10).toDouble();

      // Add listeners for autosave
      _titleController.addListener(_onFieldChanged);
      _bookTitleController.addListener(_onFieldChanged);
      _authorsController.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.project != null) {
      _titleController.dispose();
      _bookTitleController.dispose();
      _authorsController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCommonWords() async {
    try {
      debugPrint('Loading common words from local asset...');
      final String jsonString = await rootBundle.loadString(
        // rootBundle is now defined
        'assets/oxford_5000.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      if (mounted) {
        setState(() {
          _oxford5000Words = Set<String>.from(
            jsonList.map((e) => e.toString().toLowerCase()),
          );
          _isLoadingWords = false;
        });
        debugPrint(
          'Loaded ${_oxford5000Words.length} common words from asset.',
        );
      }
    } catch (e) {
      debugPrint('Failed to load common words: $e');
      if (mounted) {
        setState(() => _isLoadingWords = false);
      }
    }
  }

  void _onFieldChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), _saveMetadata);
  }

  Future<void> _saveMetadata() async {
    if (widget.project == null) return;

    widget.project!.title = _titleController.text;
    widget.project!.bookTitle = _bookTitleController.text;
    widget.project!.authors = _authorsController.text;
    widget.project!.genre = _selectedGenre;
    widget.project!.historyLimit = _historyLimit.toInt();
    await widget.project!.save();
    debugPrint("Project metadata saved for '${widget.project!.title}'.");
  }

  Future<void> _deleteProject() async {
    final project = widget.project;
    if (project == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to permanently delete "${project.title}"? This will also delete all chapters, characters, and links associated with it. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final projectId = project.key;

      // 1. Delete Chapters
      final chapterBox = await Hive.openBox<Chapter>('chapters');
      final chapterKeysToDelete = chapterBox.values
          .where((c) => c.parentProjectId == projectId)
          .map((c) => c.key)
          .toList();
      await chapterBox.deleteAll(chapterKeysToDelete);

      // 2. Delete Characters
      final characterBox = await Hive.openBox<Character>('characters');
      final characterKeysToDelete = characterBox.values
          .where((c) => c.parentProjectId == projectId)
          .map((c) => c.key)
          .toList();
      await characterBox.deleteAll(characterKeysToDelete);

      // 3. Delete the Project itself
      await project.delete();

      // 4. Navigate back to the home screen
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget _buildSettingsContent() {
    switch (_categories[_selectedCategoryIndex]) {
      case 'Information':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Information',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoCategory('Overview', {
                'Project Title': widget.project?.title ?? 'N/A',
                'Created On': widget.project?.createdAt != null
                    ? DateFormat.yMMMd().format(widget.project!.createdAt)
                    : 'N/A',
                'Last Modified': widget.project?.lastModified != null
                    ? DateFormat.yMMMd().format(widget.project!.lastModified!)
                    : 'N/A',
              }),
              const Divider(height: 32),
              if (widget.chapterProvider != null)
                _buildManuscriptInfo(widget.chapterProvider!),
            ],
          ),
        );
      case 'Cast Overview':
        return _buildCastOverview(widget.characterProvider!);
      case 'Metadata':
        return _buildMetadataContent();
      case 'About':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Lore Keeper',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildCreditTile('flutter_quill', 'For the rich text editor.'),
              _buildCreditTile(
                'language_tool',
                'For grammar and style checking.',
              ),
              _buildCreditTile(
                'hive / hive_flutter',
                'For fast, local database storage.',
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showLicenses(context),
                  child: const Text('View All Licenses'),
                ),
              ),
            ],
          ),
        );
      case 'Proofing':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Custom Dictionary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage the words you have added to your project\'s dictionary.',
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openDictionaryManager,
                icon: const Icon(Icons.book_outlined),
                label: const Text('Manage Dictionary'),
              ),
            ],
          ),
        );
      case 'History':
        return _buildHistorySettings();
      case 'Appearance':
        return Consumer<ThemeNotifier>(
          builder: (context, themeNotifier, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('System Default'), // This was correct
                    leading: Radio<ThemeMode>.adaptive(
                      value: ThemeMode.system, // This was correct
                      groupValue: themeNotifier.themeMode, // This was correct
                      onChanged: (ThemeMode? value) =>
                          themeNotifier.setTheme(ThemeMode.system),
                    ), // This was correct
                    onTap: () => themeNotifier.setTheme(ThemeMode.system),
                  ),
                  ListTile(
                    title: const Text('Light'),
                    leading: Radio<ThemeMode>.adaptive(
                      value: ThemeMode.light, // This was correct
                      groupValue: themeNotifier.themeMode, // This was correct
                      onChanged: (ThemeMode? value) =>
                          themeNotifier.setTheme(ThemeMode.light),
                    ), // This was correct
                    onTap: () => themeNotifier.setTheme(ThemeMode.light),
                  ),
                  ListTile(
                    title: const Text('Dark'),
                    leading: Radio<ThemeMode>.adaptive(
                      value: ThemeMode.dark, // This was correct
                      groupValue: themeNotifier.themeMode, // This was correct
                      onChanged: (ThemeMode? value) =>
                          themeNotifier.setTheme(ThemeMode.dark),
                    ), // This was correct
                    onTap: () => themeNotifier.setTheme(ThemeMode.dark),
                  ),
                ],
              ),
            );
          },
        );
      default:
        return const Center(child: Text('Select a category'));
    }
  }

  Widget _buildMetadataContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Metadata',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Project Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bookTitleController,
            decoration: const InputDecoration(
              labelText: 'Book Title',
              hintText: 'The formal title of your manuscript',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _authorsController,
            decoration: const InputDecoration(
              labelText: 'Author(s)',
              hintText: 'e.g., John Doe, Jane Smith',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Genre'),
            subtitle: Text(_selectedGenre),
            trailing: const Icon(Icons.edit),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            onTap: () async {
              final newGenre = await showDialog<String>(
                context: context,
                builder: (context) =>
                    GenreSelectionDialog(initialGenre: _selectedGenre),
              );
              if (newGenre != null && newGenre != _selectedGenre) {
                setState(() {
                  _selectedGenre = newGenre;
                });
                _onFieldChanged(); // Trigger save
              }
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete Project',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text(
              'This will permanently delete the project and all its contents.',
            ),
            onTap: _deleteProject,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('History Limit'),
            subtitle: Text(
              'Keep the last ${_historyLimit.toInt()} versions of each item.',
            ),
          ),
          Slider(
            value: _historyLimit,
            min: 1,
            max: 50,
            divisions: 49,
            label: _historyLimit.round().toString(),
            onChanged: (double value) {
              setState(() {
                _historyLimit = value;
              });
            },
            onChangeEnd: (double value) {
              // Trigger save when user finishes sliding
              _onFieldChanged();
            },
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Warning: Increasing the history limit will store more data for each change, which can significantly increase the size of your project file over time.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCastOverview(CharacterListProvider characterProvider) {
    final characters = characterProvider.characters;
    final totalCharacters = characters.length;

    // Gender Breakdown
    final genderCounts = <String, int>{};
    for (final char in characters) {
      final gender = char.gender ?? 'Unknown';
      genderCounts[gender] = (genderCounts[gender] ?? 0) + 1;
    }

    // Characters without Bio
    final noBioCount = characters
        .where((c) => c.bio == null || c.bio!.trim().isEmpty)
        .length;

    // Most Common Traits
    final traitCounts = <String, int>{};
    for (final char in characters) {
      for (final iteration in char.iterations) {
        for (final trait in iteration.personalityTraits ?? []) {
          traitCounts[trait] = (traitCounts[trait] ?? 0) + 1;
        }
      }
    }
    final sortedTraits = traitCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTraits = sortedTraits.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCategory('Ensemble', {
            'Total Characters': totalCharacters.toString(),
            'Characters without Bio': noBioCount.toString(),
          }),
          const Divider(height: 32),
          _buildInfoCategory(
            'Gender Breakdown',
            genderCounts.map((key, value) => MapEntry(key, value.toString())),
          ),
          const Divider(height: 32),
          _buildInfoCategory(
            'Most Common Traits',
            Map.fromEntries(
              topTraits.map(
                (entry) => MapEntry(entry.key, '${entry.value} characters'),
              ),
            ),
            descriptions: {
              'Most Common Traits':
                  'The top 5 most frequently used personality traits across your cast.',
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManuscriptInfo(ChapterListProvider chapterProvider) {
    // Calculate statistics
    final chapters = chapterProvider.chapters;
    int totalChapters = chapters.length;
    int totalWords = 0;
    int totalSentences = 0;
    int totalCharacters = 0;
    Set<String> uniqueWords = {};

    for (var chapter in chapters) {
      if (chapter.richTextJson != null && chapter.richTextJson!.isNotEmpty) {
        try {
          final doc = Document.fromJson(jsonDecode(chapter.richTextJson!));
          final text = doc.toPlainText().trim();
          if (text.isNotEmpty) {
            final words = text.split(RegExp(r'\s+'));
            totalWords += words.length;
            totalCharacters += text.length;
            totalSentences += RegExp(
              r'[\.!?]+',
            ).allMatches(text).length.clamp(1, 9999);
            uniqueWords.addAll(words.map((w) => w.toLowerCase()));
          }
        } catch (e) {
          debugPrint('Error processing chapter for stats: $e');
        }
      }
    }

    double avgWordCount = totalChapters > 0 ? totalWords / totalChapters : 0;
    double readingTime = totalWords / 200; // Avg reading speed: 200 wpm
    double speakingTime = totalWords / 130; // Avg speaking speed: 130 wpm
    double avgSentenceLength = totalSentences > 0
        ? totalWords / totalSentences
        : 0;
    double avgWordLength = totalWords > 0 ? totalCharacters / totalWords : 0;

    // Flesch Reading Ease Score
    double fleschScore = 0;
    if (totalWords > 100) {
      fleschScore =
          206.835 -
          (1.015 * avgSentenceLength) -
          (84.6 *
              (totalCharacters /
                  totalWords)); // Syllables are hard, using avg word length as proxy
    }

    // Vocabulary - Rare Words Calculation
    int rareWords = uniqueWords
        .where((word) => !_oxford5000Words.contains(word.toLowerCase()))
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCategory('Overview', {
            'Total Chapters': totalChapters.toString(),
            'Total Word Count': totalWords.toString(),
            'Average Word Count': avgWordCount.toStringAsFixed(0),
            'Characters': totalCharacters.toString(),
            'Sentences': totalSentences.toString(),
            'Estimated Reading Time': '${readingTime.toStringAsFixed(1)} min',
            'Estimated Speaking Time': '${speakingTime.toStringAsFixed(1)} min',
          }),
          const Divider(height: 32),
          _buildInfoCategory(
            'Readability',
            {
              'Average Word Length': avgWordLength.toStringAsFixed(2),
              'Average Sentence Length': avgSentenceLength.toStringAsFixed(1),
              'Readability Score': fleschScore.toStringAsFixed(1),
            },
            infoWidgets: {
              'Readability Score': Tooltip(
                message:
                    'In the Flesch reading-ease test, higher scores indicate material that is easier to read.',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            },
          ),
          const Divider(height: 32),
          _buildInfoCategory(
            'Vocabulary',
            {
              'Unique Words': uniqueWords.length.toString(),
              'Rare Words': _isLoadingWords
                  ? 'Loading...'
                  : rareWords.toString(),
            },
            descriptions: {
              'Unique Words':
                  'Measures vocabulary diversity by calculating the number of unique words.',
              'Rare Words':
                  'Measures depth of vocabulary by identifying words that are not among the 5,000 most common English words.',
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCategory(
    String title,
    Map<String, String> data, {
    Map<String, Widget>? infoWidgets,
    Map<String, String>? descriptions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...data.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (infoWidgets != null &&
                            infoWidgets.containsKey(entry.key)) ...[
                          const SizedBox(width: 8),
                          infoWidgets[entry.key]!,
                        ],
                      ],
                    ),
                    Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                if (descriptions != null && descriptions.containsKey(entry.key))
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      descriptions[entry.key]!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCreditTile(String title, String subtitle) {
    // Renamed from _buildCreditTile to buildCreditTile
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    // Renamed from _showLicenses to showLicenses
    showLicensePage(
      context: context,
      applicationName: 'Lore Keeper',
      applicationVersion: '1.0.0',
    );
  }

  void _openDictionaryManager() {
    // Renamed from _openDictionaryManager to openDictionaryManager
    // First, notify the parent that we are opening the dictionary.
    widget.onDictionaryOpened();

    // Then, show the dictionary dialog.
    showDialog(
      context: context,
      // Use rootNavigator: true to show it above the settings dialog
      useRootNavigator: true,
      builder: (dialogContext) {
        return DictionaryManagerDialog(projectId: widget.project!.key);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.project != null
            ? 'Settings for "${widget.project!.title}"'
            : 'Application Settings',
      ),
      contentPadding: const EdgeInsets.all(0),
      content: SizedBox(
        width: 700,
        height: 500,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Category List
            SizedBox(
              width: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return ListTile(
                    title: Text(
                      _categories[index],
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha(26),
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
            const VerticalDivider(width: 1),
            // Right column: Settings Content
            Expanded(child: _buildSettingsContent()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
