import 'package:flutter/material.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';

class IndexPageWidget extends StatefulWidget {
  final ChapterListProvider chapterProvider;
  final ValueChanged<String> onChapterSelected;

  const IndexPageWidget({
    super.key,
    required this.chapterProvider,
    required this.onChapterSelected,
  });

  @override
  State<IndexPageWidget> createState() => _IndexPageWidgetState();
}

class _IndexPageWidgetState extends State<IndexPageWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use a ListenableBuilder to automatically update when chapters change
    return ListenableBuilder(
      listenable: widget.chapterProvider,
      builder: (context, child) {
        final allChapters = widget.chapterProvider.chapters;
        final filteredChapters = allChapters.where((chapter) {
          return chapter.title.toLowerCase().contains(_searchQuery);
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Index', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Chapters',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredChapters.length,
                  itemBuilder: (context, index) {
                    final chapter = filteredChapters[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${chapter.orderIndex + 1}'),
                        ),
                        title: Text(chapter.title),
                        onTap: () =>
                            widget.onChapterSelected(chapter.key.toString()),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
