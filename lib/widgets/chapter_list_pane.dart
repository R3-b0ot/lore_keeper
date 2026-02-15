import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/theme/app_colors.dart';
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
  bool _isFrontMatterExpanded = false;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: colorScheme.surface,
      child: ListenableBuilder(
        listenable: widget.chapterProvider,
        builder: (context, child) {
          final chapters = widget.chapterProvider.chapters;
          final frontMatter = [
            if (widget.chapterProvider.frontPage != null)
              widget.chapterProvider.frontPage!,
            if (widget.chapterProvider.indexPage != null)
              widget.chapterProvider.indexPage!,
            if (widget.chapterProvider.aboutAuthorPage != null)
              widget.chapterProvider.aboutAuthorPage!,
          ];

          final filterText = _filterController.text.toLowerCase();
          final filteredFrontMatter = frontMatter
              .where((c) => c.title.toLowerCase().contains(filterText))
              .toList();
          final filteredChapters = chapters
              .where((c) => c.title.toLowerCase().contains(filterText))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pane Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Text(
                      'MANUSCRIPT',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _showFilter ? LucideIcons.searchX : LucideIcons.search,
                        size: 20,
                      ),
                      onPressed: () => setState(() {
                        _showFilter = !_showFilter;
                        if (!_showFilter) _filterController.clear();
                      }),
                      tooltip: 'Search Chapters',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.circlePlus, size: 20),
                      onPressed: () async {
                        final title = await _showChapterTitleDialog(context);
                        if (title != null && title.isNotEmpty) {
                          final newKey = await widget.chapterProvider
                              .createNewChapter(title);
                          widget.onChapterCreated(newKey.toString());
                        }
                      },
                      tooltip: 'New Chapter',
                    ),
                  ],
                ),
              ),

              // Integrated Search Bar
              if (_showFilter)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _filterController,
                    autofocus: true,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Filter by title...',
                      prefixIcon: const Icon(LucideIcons.listFilter, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      fillColor: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            )
                          : colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

              const SizedBox(height: 8),

              // Scrollable List
              Expanded(
                child: ReorderableListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    if (_filterController.text.isNotEmpty) return;

                    int frontMatterHeaderCount =
                        (filteredFrontMatter.isNotEmpty || !_showFilter)
                        ? 1
                        : 0;
                    int expandedFrontMatterCount = _isFrontMatterExpanded
                        ? filteredFrontMatter.length
                        : 0;
                    int bodyChaptersHeaderCount =
                        (filteredChapters.isNotEmpty || !_showFilter) ? 1 : 0;

                    final bodyChaptersStartIndex =
                        frontMatterHeaderCount +
                        expandedFrontMatterCount +
                        bodyChaptersHeaderCount;

                    if (oldIndex < bodyChaptersStartIndex) {
                      return;
                    }

                    if (newIndex < bodyChaptersStartIndex) {
                      newIndex = bodyChaptersStartIndex;
                    }

                    final adjustedOld = oldIndex - bodyChaptersStartIndex;
                    final adjustedNew = newIndex - bodyChaptersStartIndex;

                    if (adjustedOld < 0 ||
                        adjustedOld >= chapters.length ||
                        adjustedNew < 0 ||
                        adjustedNew > chapters.length) {
                      return;
                    }

                    widget.chapterProvider.reorderChapter(
                      adjustedOld,
                      adjustedNew,
                    );
                  },
                  children: [
                    // Front Matter Header
                    if (filteredFrontMatter.isNotEmpty || !_showFilter)
                      Container(
                        key: const ValueKey('front_matter_header'),
                        child: _buildExpandableHeader(
                          'Front Matter',
                          _isFrontMatterExpanded,
                          () => setState(
                            () => _isFrontMatterExpanded =
                                !_isFrontMatterExpanded,
                          ),
                        ),
                      ),

                    // Front Matter Items (only if expanded)
                    if (_isFrontMatterExpanded)
                      ...filteredFrontMatter.map(
                        (c) => _buildChapterTile(
                          c,
                          true,
                          key: ValueKey('front_${c.key}'),
                        ),
                      ),

                    // Body Chapters Header
                    if (filteredChapters.isNotEmpty || !_showFilter)
                      Container(
                        key: const ValueKey('body_chapters_header'),
                        child: _buildSectionHeader('Body Chapters'),
                      ),

                    // Body Chapters Items
                    ...filteredChapters.map((c) {
                      final absIndex = chapters.indexOf(c);
                      return _buildChapterTile(
                        c,
                        false,
                        key: ValueKey('body_${c.key}'),
                        absIndex: absIndex,
                        frontMatterCount: filteredFrontMatter.length,
                      );
                    }),

                    // No Results Message
                    if (filteredChapters.isEmpty &&
                        filteredFrontMatter.isEmpty &&
                        _showFilter)
                      Padding(
                        key: const ValueKey('no_results'),
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No chapters found',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpandableHeader(
    String title,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildChapterTile(
    Chapter chapter,
    bool isFrontMatter, {
    required Key key,
    int? absIndex,
    int? frontMatterCount,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = chapter.key.toString() == widget.selectedChapterKey;
    final displayTitle = isFrontMatter && chapter.key.toString().endsWith('_-1')
        ? 'Cover Page'
        : chapter.title;

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => widget.onChapterSelected(chapter.key.toString()),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Reorder Handle (hidden if front matter or searching)
              if (!isFrontMatter &&
                  _filterController.text.isEmpty &&
                  absIndex != null &&
                  frontMatterCount != null)
                ReorderableDragStartListener(
                  index:
                      absIndex +
                      ((frontMatterCount > 0 || !_showFilter) ? 1 : 0) +
                      (_isFrontMatterExpanded ? frontMatterCount : 0) +
                      ((widget.chapterProvider.chapters.isNotEmpty ||
                              !_showFilter)
                          ? 1
                          : 0),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      LucideIcons.gripVertical,
                      size: 14,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.5,
                            )
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),

              // Active Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 4,
                height: isSelected ? 24 : 0,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Icon
              Icon(
                isFrontMatter ? LucideIcons.fileText : LucideIcons.bookOpen,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  displayTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Actions
              if (!isFrontMatter)
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.pencil,
                    size: 16,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  onSelected: (value) {
                    if (value == 'rename') _handleRename(chapter);
                    if (value == 'delete') _handleDelete(chapter);
                  },
                  tooltip: 'Options',
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(LucideIcons.pencil, size: 18),
                          SizedBox(width: 12),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: AppColors.getError(context),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: AppColors.getError(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRename(Chapter chapter) async {
    final title = await _showChapterTitleDialog(
      context,
      initialTitle: chapter.title,
    );
    if (title != null && title.isNotEmpty && title != chapter.title) {
      await widget.chapterProvider.updateChapterTitle(chapter.key, title);
    }
  }

  Future<void> _handleDelete(Chapter chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chapter'),
        content: Text('Delete "${chapter.title}" forever?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.chapterProvider.deleteChapter(chapter.key);
      if (widget.selectedChapterKey == chapter.key.toString()) {
        widget.onChapterSelected('', closeDrawer: false);
      }
    }
  }

  Future<String?> _showChapterTitleDialog(
    BuildContext context, {
    String? initialTitle,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ChapterTitleDialog(initialTitle: initialTitle ?? ''),
    );
  }
}
