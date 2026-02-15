import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';

/// Presents chapter selection with search and front matter support.
class ChapterSelectionDialog extends StatefulWidget {
  final ChapterListProvider chapterProvider;
  final String selectedChapterKey;
  final ValueChanged<String> onChapterSelected;

  const ChapterSelectionDialog({
    super.key,
    required this.chapterProvider,
    required this.selectedChapterKey,
    required this.onChapterSelected,
  });

  @override
  State<ChapterSelectionDialog> createState() => _ChapterSelectionDialogState();
}

class _ChapterSelectionDialogState extends State<ChapterSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Chapter> _buildChapterList() {
    final frontPage = widget.chapterProvider.frontPage;
    final indexPage = widget.chapterProvider.indexPage;
    final aboutAuthorPage = widget.chapterProvider.aboutAuthorPage;
    final chapters = widget.chapterProvider.chapters;

    final allItems = <Chapter>[];
    if (frontPage != null) allItems.add(frontPage);
    if (indexPage != null) allItems.add(indexPage);
    if (aboutAuthorPage != null) allItems.add(aboutAuthorPage);
    allItems.addAll(chapters);

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return allItems;

    return allItems
        .where((item) => item.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Chapter'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search chapters...',
                prefixIcon: Icon(LucideIcons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.chapterProvider,
                builder: (context, child) {
                  final filteredItems = _buildChapterList();

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final chapter = filteredItems[index];
                      final isSelected =
                          chapter.key.toString() == widget.selectedChapterKey;
                      final isFrontMatter = chapter.key.toString().startsWith(
                        'front_matter_',
                      );
                      final displayTitle = isFrontMatter
                          ? chapter.title
                          : '${chapter.orderIndex + 1}. ${chapter.title}';
                      return ListTile(
                        title: Text(displayTitle),
                        selected: isSelected,
                        onTap: () {
                          widget.onChapterSelected(chapter.key.toString());
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
