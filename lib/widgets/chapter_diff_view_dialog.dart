import 'dart:convert';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/history_entry.dart';

class ChapterDiffViewDialog extends StatelessWidget {
  final HistoryEntry historyEntry;
  final VoidCallback onReverted;

  const ChapterDiffViewDialog({
    super.key,
    required this.historyEntry,
    required this.onReverted,
  });

  @override
  Widget build(BuildContext context) {
    final chapterBox = Hive.box<Chapter>('chapters');
    final currentChapter = chapterBox.get(historyEntry.targetKey);
    final historicalChapter = chapterFromJson(jsonDecode(historyEntry.data));

    if (currentChapter == null) {
      return const AlertDialog(
        title: Text('Error'),
        content: Text('Could not find the current version of the chapter.'),
      );
    }

    return AlertDialog(
      title: Text(
        'Compare and Revert: ${DateFormat.yMMMd().add_jm().format(historyEntry.timestamp)}',
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter Title
              _buildDiffRow(
                context,
                'Title',
                currentChapter.title,
                historicalChapter.title,
              ),
              const SizedBox(height: 16),
              // Order Index
              _buildDiffRow(
                context,
                'Order Index',
                currentChapter.orderIndex.toString(),
                historicalChapter.orderIndex.toString(),
              ),
              const SizedBox(height: 16),
              // Chapter Text Diff
              Text(
                'Chapter Text',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              _buildTextDiff(
                context,
                currentChapter.richTextJson ?? '',
                historicalChapter.richTextJson ?? '',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(LucideIcons.rotateCcw),
          label: const Text('Revert to this Version'),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              AppColors.getWarning(context),
            ),
          ),
          onPressed: () async {
            await chapterBox.put(historyEntry.targetKey, historicalChapter);
            if (context.mounted) {
              Navigator.of(context).pop(); // Close the diff dialog
            }
            onReverted(); // Trigger the reload callback
          },
        ),
      ],
    );
  }

  Widget _buildDiffRow(
    BuildContext context,
    String label,
    String? currentValue,
    String? historicalValue,
  ) {
    final bool hasChanged = currentValue != historicalValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          currentValue ?? 'N/A',
          style: TextStyle(
            color: hasChanged ? AppColors.getWarning(context) : null,
          ),
        ),
        if (hasChanged)
          Text(
            'Previous: ${historicalValue ?? 'N/A'}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildTextDiff(
    BuildContext context,
    String currentText,
    String historicalText,
  ) {
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(currentText, historicalText);

    // Filter to show only changes: additions and deletions
    final filteredDiffs = diffs
        .where((diff) => diff.operation != DIFF_EQUAL)
        .toList();

    if (filteredDiffs.isEmpty) {
      return const Text('No changes in text.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filteredDiffs.map((diff) {
        Color color;
        String prefix;
        if (diff.operation == DIFF_INSERT) {
          color = AppColors.getSuccess(context);
          prefix = '+ ';
        } else if (diff.operation == DIFF_DELETE) {
          color = AppColors.getError(context);
          prefix = '- ';
        } else {
          color = Theme.of(context).colorScheme.onSurface;
          prefix = '';
        }
        return Text(
          '$prefix${diff.text}',
          style: TextStyle(color: color, fontFamily: 'monospace'),
        );
      }).toList(),
    );
  }
}
