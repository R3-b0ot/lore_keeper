import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/history_entry.dart';

class DiffViewDialog extends StatelessWidget {
  final HistoryEntry historyEntry;
  final VoidCallback onReverted;

  const DiffViewDialog({
    super.key,
    required this.historyEntry,
    required this.onReverted,
  });

  @override
  Widget build(BuildContext context) {
    final characterBox = Hive.box<Character>('characters');
    final currentCharacter = characterBox.get(historyEntry.targetKey);
    final historicalCharacter = Character.fromJson(
      jsonDecode(historyEntry.data),
    );

    if (currentCharacter == null) {
      return const AlertDialog(
        title: Text('Error'),
        content: Text('Could not find the current version of the character.'),
      );
    }

    final currentIteration = currentCharacter.iterations.isNotEmpty
        ? currentCharacter.iterations.first
        : null;
    final historicalIteration = historicalCharacter.iterations.isNotEmpty
        ? historicalCharacter.iterations.first
        : null;

    return AlertDialog(
      title: Text(
        'Compare and Revert: ${DateFormat.yMMMd().add_jm().format(historyEntry.timestamp)}',
      ),
      content: SizedBox(
        width: 800,
        height: 600,
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Current Version
              Expanded(
                child: _buildDiffColumn(
                  context,
                  'Current Version',
                  currentIteration,
                ),
              ),
              const VerticalDivider(),
              // Right Column: Historical Version
              Expanded(
                child: _buildDiffColumn(
                  context,
                  'Historical Version',
                  historicalIteration,
                  isHistorical: true,
                ),
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
          icon: const Icon(Icons.restore),
          label: const Text('Revert to this Version'),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.orange.shade700),
          ),
          onPressed: () async {
            await characterBox.put(historyEntry.targetKey, historicalCharacter);
            if (context.mounted) {
              Navigator.of(context).pop(); // Close the diff dialog
            }
            onReverted(); // Trigger the reload callback
          },
        ),
      ],
    );
  }

  Widget _buildDiffColumn(
    BuildContext context,
    String title,
    CharacterIteration? iteration, {
    bool isHistorical = false,
  }) {
    final historicalCharacter = Character.fromJson(
      jsonDecode(historyEntry.data),
    );
    final historicalIteration = historicalCharacter.iterations.isNotEmpty
        ? historicalCharacter.iterations.first
        : null;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          _buildDiffRow(
            'Name',
            iteration?.name,
            historicalIteration?.name,
            isHistorical: isHistorical,
          ),
          _buildDiffRow(
            'Aliases',
            (iteration?.aliases ?? []).join(', '),
            (historicalIteration?.aliases ?? []).join(', '),
            isHistorical: isHistorical,
          ),
          _buildDiffRow(
            'Occupation',
            iteration?.occupation,
            historicalIteration?.occupation,
            isHistorical: isHistorical,
          ),
          _buildDiffRow(
            'Bio',
            iteration?.bio,
            historicalIteration?.bio,
            isHistorical: isHistorical,
            maxLines: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildDiffRow(
    String label,
    String? currentValue,
    String? historicalValue, {
    bool isHistorical = false,
    int maxLines = 1,
  }) {
    final value = isHistorical ? historicalValue : currentValue;
    final bool hasChanged = currentValue != historicalValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: hasChanged ? Colors.orange.shade700 : null),
          ),
        ],
      ),
    );
  }
}
