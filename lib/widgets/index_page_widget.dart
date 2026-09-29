import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';

/// The front-matter Index page: a searchable list of the manuscript's chapters
/// and scenes (MS-019).
///
/// The list is read from [ManuscriptBinderProvider], never from the legacy
/// `chapters` box. A chapter created through the binder after the 2026
/// redesign has no legacy `Chapter` row at all, so a legacy read silently
/// omitted every document authored since the cutover and the page looked
/// plausible while being wrong.
///
/// Selection reports a **manuscript document id**, matching the convention the
/// rest of the manuscript UI already uses ([ManuscriptBinderProvider] is asked
/// for the document directly, rather than a legacy chapter key being translated
/// back into a document id).
class IndexPageWidget extends StatefulWidget {
  final ManuscriptBinderProvider binderProvider;
  final ValueChanged<String> onDocumentSelected;

  const IndexPageWidget({
    super.key,
    required this.binderProvider,
    required this.onDocumentSelected,
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

  /// The indexable documents, in the order the binder holds them.
  ///
  /// `getDocumentsByType` preserves the binder's `(parent, orderIndex)` sort, so
  /// no extra ordering is applied here — the page must agree with the outline.
  List<ManuscriptDocument> _indexedDocuments() {
    final binder = widget.binderProvider;
    return [
      ...binder.getDocumentsByType(ManuscriptDocumentType.chapter),
      ...binder.getDocumentsByType(ManuscriptDocumentType.scene),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use a ListenableBuilder to automatically update when documents change
    return ListenableBuilder(
      listenable: widget.binderProvider,
      builder: (context, child) {
        final filteredDocuments = _indexedDocuments().where((document) {
          return document.title.toLowerCase().contains(_searchQuery);
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
                  prefixIcon: const Icon(LucideIcons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredDocuments.length,
                  itemBuilder: (context, index) {
                    final document = filteredDocuments[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          // Position within the Index list rather than the
                          // document's own orderIndex: chapters and scenes are
                          // numbered independently by the binder, so an
                          // orderIndex badge would repeat "1" down the page.
                          child: Text('${index + 1}'),
                        ),
                        title: Text(document.title),
                        onTap: () => widget.onDocumentSelected(document.id),
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
