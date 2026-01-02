import 'package:flutter/material.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/widgets/chapter_title_dialog.dart';

class ChapterListPane extends StatefulWidget {
  final ChapterListProvider chapterProvider;
  final String? selectedChapterKey;
  final Function(String key, {bool closeDrawer}) onChapterSelected;
  final ValueChanged<String> onChapterCreated;
  final bool isMobile;

  const ChapterListPane({
    super.key,
    required this.chapterProvider,
    required this.selectedChapterKey,
    required this.onChapterSelected,
    required this.onChapterCreated,
    required this.isMobile,
  });

  @override
  State<ChapterListPane> createState() => _ChapterListPaneState();
}

class _ChapterListPaneState extends State<ChapterListPane> {
  late TextEditingController _filterController;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(12.0),
      child: ListenableBuilder(
        listenable: widget.chapterProvider,
        builder: (context, child) {
          final coverPage = widget.chapterProvider.frontPage;
          final indexPage = widget.chapterProvider.indexPage;
          final aboutAuthorPage = widget.chapterProvider.aboutAuthorPage;
          final chapters = widget.chapterProvider.chapters;

          // Separate front matter from regular chapters
          final frontMatterItems = <Chapter>[];
          if (coverPage != null) frontMatterItems.add(coverPage);
          if (indexPage != null) frontMatterItems.add(indexPage);
          if (aboutAuthorPage != null) frontMatterItems.add(aboutAuthorPage);

          // Apply filter if shown
          final filterText = _filterController.text.toLowerCase();
          final filteredFrontMatter =
              _showFilter && _filterController.text.isNotEmpty
              ? frontMatterItems
                    .where((c) => c.title.toLowerCase().contains(filterText))
                    .toList()
              : frontMatterItems;
          final filteredChapters =
              _showFilter && _filterController.text.isNotEmpty
              ? chapters
                    .where((c) => c.title.toLowerCase().contains(filterText))
                    .toList()
              : chapters;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manuscript',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showFilter = !_showFilter;
                        if (!_showFilter) {
                          _filterController.clear();
                        }
                      });
                    },
                    icon: Icon(
                      _showFilter ? Icons.search_off : Icons.search,
                      size: 18,
                    ),
                    tooltip: _showFilter
                        ? 'Hide Search Box'
                        : 'Search Chapters',
                  ),
                ],
              ),
              if (_showFilter) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _filterController,
                  decoration: const InputDecoration(
                    hintText: 'Search chapters...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {}); // Trigger rebuild for filtering
                  },
                ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final title = await _showChapterTitleDialog(context);
                  if (title != null && title.isNotEmpty) {
                    final newKey = await widget.chapterProvider
                        .createNewChapter(title);
                    widget.onChapterCreated(newKey.toString());
                  }
                },
                icon: Icon(
                  Icons.add,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  'New Chapter',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    ...filteredFrontMatter.map((chapter) {
                      final isSelected =
                          chapter.key.toString() == widget.selectedChapterKey;
                      // The title for the front page is now "Cover Page"
                      final title = chapter.key.toString().endsWith('_-1')
                          ? 'Cover Page'
                          : chapter.title;
                      return _buildChapterItem(
                        context,
                        chapter,
                        isSelected,
                        true,
                        title,
                      );
                    }),
                    if (filteredFrontMatter.isNotEmpty &&
                        filteredChapters.isNotEmpty)
                      const Divider(height: 24),
                    ...filteredChapters.map((chapter) {
                      final isSelected =
                          chapter.key.toString() == widget.selectedChapterKey;
                      final title =
                          '${chapter.orderIndex + 1}. ${chapter.title}';
                      return _buildChapterItem(
                        context,
                        chapter,
                        isSelected,
                        false,
                        title,
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChapterItem(
    BuildContext context,
    Chapter chapter,
    bool isSelected,
    bool isFrontMatter,
    String title,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => widget.onChapterSelected(chapter.key.toString()),
              icon: Icon(
                isFrontMatter
                    ? Icons.article_outlined
                    : Icons.menu_book_outlined,
                size: 16,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              label: Text(title),
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
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                ),
              ),
            ),
          ),
          if (!isFrontMatter)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Chapter'),
                    content: Text(
                      'Are you sure you want to permanently delete "${chapter.title}"? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await widget.chapterProvider.deleteChapter(chapter.key);
                  // If the deleted chapter was the selected one, clear the selection.
                  if (widget.selectedChapterKey == chapter.key.toString()) {
                    widget.onChapterSelected('', closeDrawer: false);
                  }
                }
              },
              tooltip: 'Delete Chapter',
            ),
        ],
      ),
    );
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
}
