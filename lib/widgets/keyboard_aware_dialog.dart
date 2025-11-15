// lib/widgets/keyboard_aware_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An intent to signify a confirmation action, typically triggered by the Enter key.
class ConfirmIntent extends Intent {
  const ConfirmIntent();
}

/// An intent to signify a cancellation action, typically triggered by the Escape key.
class CancelIntent extends Intent {
  const CancelIntent();
}

/// A reusable dialog that responds to keyboard shortcuts.
/// - `Enter`: Triggers the `onConfirm` callback.
/// - `Escape`: Triggers the `onCancel` callback (or pops the dialog if null).
class KeyboardAwareDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const KeyboardAwareDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // If onCancel is not provided, default to popping the current context.
    final VoidCallback effectiveOnCancel =
        onCancel ?? () => Navigator.of(context).pop();

    // By wrapping our Shortcuts in a Focus widget with autofocus, we create a new
    // focus scope. This ensures that our local shortcuts (like for Escape) are
    // prioritized over the global ones provided by MaterialApp.
    return Focus(
      autofocus: true,
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.escape): const CancelIntent(),
          // Only map Enter if a confirm action is provided.
          if (onConfirm != null)
            LogicalKeySet(LogicalKeyboardKey.enter): const ConfirmIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            CancelIntent: CallbackAction<CancelIntent>(
              onInvoke: (_) => effectiveOnCancel,
            ),
            if (onConfirm != null)
              ConfirmIntent: CallbackAction<ConfirmIntent>(
                onInvoke: (_) => onConfirm!(),
              ),
          },
          // The AlertDialog itself doesn't need to be focused, as the parent
          // Focus widget now handles the scope.
          child: AlertDialog(title: title, content: content, actions: actions),
        ),
      ),
    );
  }
}
