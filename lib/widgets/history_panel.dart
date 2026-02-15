import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lore_keeper/models/history_entry.dart';
import 'package:lore_keeper/widgets/diff_view_dialog.dart';
import 'package:lore_keeper/widgets/chapter_diff_view_dialog.dart';

class HistoryPanel extends StatefulWidget {
  final dynamic targetKey;
  final String targetType;
  final VoidCallback onClose;
  final VoidCallback onReverted;

  const HistoryPanel({
    super.key,
    required this.targetKey,
    required this.targetType,
    required this.onClose,
    required this.onReverted,
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
