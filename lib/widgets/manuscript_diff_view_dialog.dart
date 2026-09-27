import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/history_entry.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/utils/manuscript_text_stats.dart';

/// Compare-and-revert dialog for a [HistoryEntry] whose target is a
/// manuscript document (MS-007 / MS-020).
///
/// Every piece of data arrives through the constructor. The dialog performs no
/// storage access of its own: it never opens `Hive.box<Chapter>` (or any box),
/// never deserializes the snapshot as a legacy `Chapter`, and never writes back
/// directly. Persisting the revert is the caller's job, via [onRevert] — the
/// manuscript path routes that through
/// `ManuscriptBinderProvider.updateContent`.
///
/// The diff rendering is the same `DiffMatchPatch` approach
/// `ChapterDiffViewDialog` uses, applied to the document's *plain text* so the
/// author sees prose changes rather than Delta-JSON punctuation.
class ManuscriptDocumentDiffViewDialog extends StatelessWidget {
  const ManuscriptDocumentDiffViewDialog({
    super.key,
    required this.historyEntry,
    required this.currentTitle,
    required this.currentRichTextJson,
    required this.historicalRichTextJson,
    required this.onRevert,
    required this.onReverted,
  });

  /// The snapshot being compared; only its timestamp is displayed.
  final HistoryEntry historyEntry;

  /// Title of the live document, shown above the diff.
  final String? currentTitle;

  /// `richTextJson` of the live document, or null when it is unavailable.
  final String? currentRichTextJson;

  /// `richTextJson` recovered from the snapshot.
  final String historicalRichTextJson;

  /// Persists the revert. Receives the historical `richTextJson` to write.
  final Future<void> Function(String historicalRichTextJson) onRevert;

  /// Invoked after a successful revert so the caller can refresh the shell.
  final VoidCallback onReverted;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Compare and Revert: '
        '${DateFormat.yMMMd().add_jm().format(historyEntry.timestamp)}',
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentTitle != null) ...[
                Text(
                  currentTitle!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Document Text',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              _buildTextDiff(
                context,
                _diffSource(currentRichTextJson),
                _diffSource(historicalRichTextJson),
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
            await onRevert(historicalRichTextJson);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            onReverted();
          },
        ),
      ],
    );
  }

  /// The text a human actually wrote, decoded from the stored Delta.
  ///
  /// Falls back to the raw JSON when it cannot be decoded, so an unreadable
  /// snapshot still diffs visibly instead of appearing as an empty document.
  static String _diffSource(String? richTextJson) {
    if (richTextJson == null || richTextJson.isEmpty) return '';
    final plainText = ManuscriptTextStats.plainTextOfDeltaJson(richTextJson);
    return plainText.isEmpty ? richTextJson : plainText;
  }

  Widget _buildTextDiff(
    BuildContext context,
    String currentText,
    String historicalText,
  ) {
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(currentText, historicalText);

    // Show only the changes: insertions and deletions.
    final filteredDiffs = diffs
        .where((diff) => diff.operation != DIFF_EQUAL)
        .toList();

    if (filteredDiffs.isEmpty) {
      return const Text('No changes in text.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: filteredDiffs.map((diff) {
        final Color color;
        final String prefix;
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
          overflow: TextOverflow.visible,
          softWrap: true,
          style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12),
        );
      }).toList(),
    );
  }
}
