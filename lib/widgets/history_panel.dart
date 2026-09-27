import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lore_keeper/models/history_entry.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lore_keeper/widgets/diff_view_dialog.dart';
import 'package:lore_keeper/widgets/chapter_diff_view_dialog.dart';
import 'package:lore_keeper/widgets/manuscript_diff_view_dialog.dart';

class HistoryPanel extends StatefulWidget {
  final dynamic targetKey;
  final String targetType;
  final VoidCallback onClose;
  final VoidCallback onReverted;

  /// Canonical manuscript state owner, required to diff and revert a
  /// `ManuscriptDocument` snapshot (MS-007).
  ///
  /// The panel deliberately has no storage access of its own for that target
  /// type: the current document and the revert both go through this provider,
  /// so the legacy `chapters` box is never read or written (MS-020).
  final ManuscriptBinderProvider? binderProvider;

  const HistoryPanel({
    super.key,
    required this.targetKey,
    required this.targetType,
    required this.onClose,
    required this.onReverted,
    this.binderProvider,
  });

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  late Box<HistoryEntry> _historyBox;

  @override
  void initState() {
    super.initState();
    _historyBox = Hive.box<HistoryEntry>('history');
  }

  /// Recovers the `richTextJson` a manuscript snapshot was taken with.
  ///
  /// The snapshot is `jsonEncode(document.toJson())` (see
  /// `HistoryService.addHistoryEntry`), so the field is read straight out of
  /// the decoded map. Deliberately NOT `chapterFromJson` — a manuscript
  /// snapshot is a `ManuscriptDocument`, and parsing it with the legacy
  /// `Chapter` deserializer is the bug MS-007 exists to remove.
  static String? _historicalRichTextJson(HistoryEntry entry) {
    try {
      final decoded = jsonDecode(entry.data);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['richTextJson'];
        if (value is String) return value;
      }
    } on FormatException {
      // Unreadable snapshot: fall through and treat it as empty.
    }
    return null;
  }

  Future<void> _showDiffAndRevert(HistoryEntry entry) async {
    if (entry.targetType == 'Character') {
      showDialog(
        context: context,
        builder: (context) => DiffViewDialog(
          historyEntry: entry,
          onReverted: () {
            widget.onReverted();
            widget.onClose();
          },
        ),
      );
    } else if (entry.targetType == 'ManuscriptDocument') {
      await _showManuscriptDiffAndRevert(entry);
    } else if (entry.targetType == 'Chapter') {
      showDialog(
        context: context,
        builder: (context) => ChapterDiffViewDialog(
          historyEntry: entry,
          onReverted: () {
            widget.onReverted();
            widget.onClose();
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diff view not supported for this type.')),
      );
    }
  }

  /// Manuscript revision flow: diff the snapshot against the live document and
  /// revert through [ManuscriptBinderProvider.updateContent] (MS-007).
  Future<void> _showManuscriptDiffAndRevert(HistoryEntry entry) async {
    final binderProvider = widget.binderProvider;
    final documentId = widget.targetKey;

    if (binderProvider == null || documentId is! String) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revert is unavailable: manuscript state is missing.'),
        ),
      );
      return;
    }

    final current = binderProvider.getDocument(documentId);
    final historicalRichTextJson = _historicalRichTextJson(entry);

    if (current == null || historicalRichTextJson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read the current document or snapshot.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => ManuscriptDocumentDiffViewDialog(
        historyEntry: entry,
        currentTitle: current.title,
        currentRichTextJson: current.richTextJson,
        historicalRichTextJson: historicalRichTextJson,
        onRevert: (richTextJson) =>
            binderProvider.updateContent(documentId, richTextJson),
        onReverted: () {
          widget.onReverted();
          widget.onClose();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: widget.onClose,
                  tooltip: 'Close History',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // History List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _historyBox.listenable(),
              builder: (context, Box<HistoryEntry> box, _) {
                final entries = box.values
                    .where(
                      (e) =>
                          e.targetKey == widget.targetKey &&
                          e.targetType == widget.targetType,
                    )
                    .toList();

                // Sort descending by timestamp (newest first)
                entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                if (entries.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No history found for this item yet. Changes will be logged here as you make them.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(
                          DateFormat.yMMMd().add_jm().format(entry.timestamp),
                        ),
                        subtitle: const Text('Version snapshot'),
                        leading: const Icon(LucideIcons.history),
                        trailing: IconButton(
                          icon: Icon(
                            LucideIcons.rotateCcw,
                            color: AppColors.getWarning(context),
                          ),
                          tooltip: 'Revert to this version',
                          onPressed: () => _showDiffAndRevert(entry),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
