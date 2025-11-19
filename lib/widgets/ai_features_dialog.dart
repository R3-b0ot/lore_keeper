import 'package:flutter/material.dart';

class AIFeaturesDialog extends StatelessWidget {
  const AIFeaturesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Features'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              // TODO: Implement grammar check using language_tool
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Grammar Check: Feature coming soon'),
                ),
              );
            },
            child: const Text('Grammar Check'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement language improvement
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Improve Language: Feature coming soon'),
                ),
              );
            },
            child: const Text('Improve Language'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement writing improvement
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Improve Writing: Feature coming soon'),
                ),
              );
            },
            child: const Text('Improve Writing'),
          ),
        ],
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
