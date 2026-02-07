import 'package:flutter/material.dart';
import 'package:lore_keeper/theme/app_colors.dart';

class ActionCard extends StatefulWidget {
  final String icon;
  final String title;
  final String description;
  final bool isPrimary;
  final VoidCallback? onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Removed internal Expanded as it's typically used in a Row/Column by the parent
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          height: 220,
          transform: _isHovered
              ? Matrix4.translationValues(0.0, -8.0, 0.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.primaryCardGradient
                      : AppColors.primaryCardGradientAAA)
                : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.actionCardGradient
                      : AppColors.actionCardGradientLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.outline,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.shadow
                        : AppColors.shadowLight),
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: widget.isPrimary
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.isPrimary
                      ? Colors.white.withValues(alpha: 0.9)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
