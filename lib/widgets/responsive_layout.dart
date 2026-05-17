import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared breakpoints for compact, medium, and wide editor layouts.
class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double wide = 1200;

  const AppBreakpoints._();
}

/// Exposes common responsive width checks without duplicating magic numbers.
extension ResponsiveConstraints on BoxConstraints {
  bool get isCompact => maxWidth < AppBreakpoints.compact;
  bool get isMedium =>
      maxWidth >= AppBreakpoints.compact && maxWidth < AppBreakpoints.medium;
  bool get isWide => maxWidth >= AppBreakpoints.medium;
}

/// Provides a viewport-aware max size for dialogs.
BoxConstraints adaptiveDialogConstraints(
  BuildContext context, {
  double maxWidth = 720,
  double maxHeightFactor = 0.85,
}) {
  final size = MediaQuery.sizeOf(context);
  return BoxConstraints(
    maxWidth: math.min(maxWidth, size.width - 32),
    maxHeight: math.max(240, size.height * maxHeightFactor),
  );
}

/// Wraps horizontal controls once they no longer fit comfortably.
class OverflowSafeRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final CrossAxisAlignment crossAxisAlignment;

  const OverflowSafeRow({
    super.key,
    required this.children,
    this.spacing = 8,
    this.runSpacing = 8,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// Keeps dense status bars usable on narrow widths.
class ResponsiveStatusBar extends StatelessWidget {
  final List<Widget> leading;
  final List<Widget> trailing;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  const ResponsiveStatusBar({
    super.key,
    required this.leading,
    required this.trailing,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.minHeight = 35,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding,
      color: color,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < AppBreakpoints.compact;
          final content = <Widget>[
            ...leading,
            if (!isCompact) const Spacer(),
            ...trailing,
          ];

          if (isCompact) {
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [...leading, ...trailing],
            );
          }

          return Row(children: content);
        },
      ),
    );
  }
}
