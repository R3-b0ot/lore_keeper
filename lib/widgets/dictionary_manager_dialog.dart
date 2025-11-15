import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/project.dart';

class DictionaryManagerDialog extends StatefulWidget {
  final int projectId;

  const DictionaryManagerDialog({super.key, required this.projectId});

  @override
  State<DictionaryManagerDialog> createState() =>
      _DictionaryManagerDialogState();
}

class _DictionaryManagerDialogState extends State<DictionaryManagerDialog> {
  late Project _project;
  late List<String> _ignoredWords;

  @override
  void initState() {
    super.initState();
    final projectBox = Hive.box<Project>('projects');
    _project = projectBox.get(widget.projectId)!;
    // Create a mutable copy and sort it for display
    _ignoredWords = List.from(_project.ignoredWords ?? [])..sort();
  }

  Future<void> _removeWord(String word) async {
    setState(() {
      _ignoredWords.remove(word);
      _project.ignoredWords?.remove(word);
    });
    await _project.save();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom Dictionary'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400, maxHeight: 500),
        child: _ignoredWords.isEmpty
            ? const Center(
                child: Text(
                  'Your custom dictionary is empty.\nUse the "Add to Dictionary" option in the proofing tool.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _ignoredWords.length,
                  itemBuilder: (context, index) {
                    final word = _ignoredWords[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(word),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Remove from dictionary',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Removal'),
                                content: Text(
                                  'Are you sure you want to remove "$word" from the dictionary?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              _removeWord(word);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // A full grammar re-check should be triggered after closing.
            Navigator.of(context).pop(true);
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
