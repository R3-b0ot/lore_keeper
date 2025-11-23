import 'package:flutter/material.dart';
import 'package:language_tool/language_tool.dart';

class AIFeaturesDialog extends StatefulWidget {
  const AIFeaturesDialog({super.key});

  @override
  State<AIFeaturesDialog> createState() => _AIFeaturesDialogState();
}

class _AIFeaturesDialogState extends State<AIFeaturesDialog> {
  final TextEditingController _textController = TextEditingController();
  String _result = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _performGrammarCheck() async {
    if (_textController.text.isEmpty) {
      setState(() {
        _result = 'Please enter some text to check.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _result = 'Checking grammar...';
    });

    try {
      final languageTool = LanguageTool(language: 'en-US');
      final mistakes = await languageTool.check(_textController.text);

      if (mistakes.isEmpty) {
        setState(() {
          _result = 'No grammar issues found. Great job!';
        });
      } else {
        final issues = mistakes.map((m) => '- ${m.message}').join('\n');
        setState(() {
          _result = 'Grammar Issues Found:\n$issues';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error checking grammar: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _improveLanguage() {
    if (_textController.text.isEmpty) {
      setState(() {
        _result = 'Please enter some text to improve.';
      });
      return;
    }

    // Simple language improvement suggestions
    String improved = _textController.text
        .replaceAll('i ', 'I ') // Capitalize 'I'
        .replaceAll(' i ', ' I ') // Capitalize 'I' in middle
        .replaceAll('i\'', 'I\'') // Capitalize 'I' in contractions
        .replaceAll('  ', ' ') // Remove double spaces
        .trim();

    setState(() {
      _result = 'Improved Text:\n$improved';
    });
  }

  void _improveWriting() {
    if (_textController.text.isEmpty) {
      setState(() {
        _result = 'Please enter some text to improve.';
      });
      return;
    }

    // Simple writing improvement suggestions
    String suggestions = 'Writing Improvement Suggestions:\n';
    suggestions += '- Consider varying sentence length for better rhythm.\n';
    suggestions += '- Use active voice where possible.\n';
    suggestions += '- Check for unnecessary words or redundancy.\n';
    suggestions += '- Ensure clear topic sentences in paragraphs.';

    setState(() {
      _result = suggestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Features'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Enter text for AI analysis',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _performGrammarCheck,
                    icon: const Icon(Icons.spellcheck),
                    label: const Text('Grammar Check'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _improveLanguage,
                    icon: const Icon(Icons.edit),
                    label: const Text('Improve Language'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _improveWriting,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Improve Writing'),
            ),
            const SizedBox(height: 16),
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_result),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
