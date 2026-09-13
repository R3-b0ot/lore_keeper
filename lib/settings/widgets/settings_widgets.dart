import 'package:flutter/material.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/settings/app_scale.dart';

/// Vertical padding applied to a settings row derived from the active scale
/// tokens (so density changes affect control height globally).
EdgeInsets _rowPadding(BuildContext context) {
  final scale = context.scale;
  final densityPad = scale.densityControl;
  final base = 12.0 + densityPad;
  return EdgeInsets.symmetric(
    horizontal: scale.sp(16),
    vertical: base.clamp(6, 28),
  );
}

/// A single setting row: label + description on the left, a [control] on the
/// right. Encapsulates the inherited/overridden/value presentation so every
/// setting shares identical, consistent markup.
class SettingTile extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? control;
  final Widget? leading;
  final bool enabled;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool inherited;

  const SettingTile({
    super.key,
    required this.title,
    this.description,
    this.control,
    this.leading,
    this.enabled = true,
    this.onTap,
    this.tooltip,
    this.inherited = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scale = context.scale;
    final opacity = enabled ? 1.0 : 0.5;

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          Opacity(opacity: opacity, child: leading),
          SizedBox(width: scale.sp(12)),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (inherited) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_upward,
                      size: scale.icon(12),
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.3, inherit: false),
                ),
              ],
            ],
          ),
        ),
        if (control != null) ...[
          SizedBox(width: scale.sp(16)),
          Opacity(opacity: opacity, child: control),
        ],
      ],
    );

    if (tooltip != null) {
      content = Tooltip(message: tooltip!, child: content);
    }

    if (onTap != null) {
      return InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: _rowPadding(context),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.transparent,
          ),
          child: content,
        ),
      );
    }

    return Container(padding: _rowPadding(context), child: content);
  }
}

/// A labeled section card grouping several settings tiles.
class SettingSection extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;
  final Widget? trailing;

  const SettingSection({
    super.key,
    required this.title,
    this.description,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scale = context.scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: scale.sp(10)),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  inherit: false,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            children: List.generate(children.length, (i) {
              final child = children[i];
              if (i == 0) return child;
              return Column(
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: scale.sp(16),
                    endIndent: scale.sp(16),
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  child,
                ],
              );
            }),
          ),
        ),
        if (description != null) ...[
          SizedBox(height: scale.sp(8)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scale.sp(4)),
            child: Text(
              description!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(inherit: false),
            ),
          ),
        ],
        SizedBox(height: scale.sp(24)),
      ],
    );
  }
}

/// A toggle switch tile (Switch row).
class SettingSwitch extends StatelessWidget {
  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final String? tooltip;

  const SettingSwitch({
    super.key,
    required this.title,
    this.description,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SettingTile(
      title: title,
      description: description,
      tooltip: tooltip,
      onTap: enabled ? () => onChanged?.call(!value) : null,
      control: Switch.adaptive(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: colors.primary,
      ),
    );
  }
}

/// A slider tile.
class SettingSlider extends StatelessWidget {
  final String title;
  final String? description;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double)? labelFormatter;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;

  const SettingSlider({
    super.key,
    required this.title,
    this.description,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.labelFormatter,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SettingTile(
      title: title,
      description: description,
      control: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              labelFormatter?.call(value) ?? value.toStringAsFixed(0),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
                inherit: false,
              ),
            ),
            SizedBox(
              width: 220,
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                activeColor: colors.primary,
                onChanged: enabled ? onChanged : null,
                onChangeEnd: enabled ? onChangeEnd ?? onChanged : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dropdown tile.
class SettingDropdown<T> extends StatelessWidget {
  final String title;
  final String? description;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const SettingDropdown({
    super.key,
    required this.title,
    this.description,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SettingTile(
      title: title,
      description: description,
      control: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        dropdownColor: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        style: Theme.of(context).textTheme.bodyMedium,
        isDense: true,
      ),
    );
  }
}

/// A segmented control tile (Material-style radio group).
class SettingSegmentedControl<T> extends StatelessWidget {
  final String title;
  final String? description;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final IconData? Function(T)? iconOf;
  final ValueChanged<T> onChanged;
  final bool enabled;

  const SettingSegmentedControl({
    super.key,
    required this.title,
    this.description,
    required this.value,
    required this.options,
    required this.labelOf,
    this.iconOf,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      title: title,
      description: description,
      control: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SegmentedButton<T>(
          segments: [
            for (final option in options)
              ButtonSegment<T>(
                value: option,
                icon: iconOf == null ? null : Icon(iconOf!(option)),
                label: Text(labelOf(option)),
              ),
          ],
          selected: {value},
          onSelectionChanged: enabled
              ? (selection) => onChanged(selection.first)
              : null,
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}

/// A text field tile.
class SettingTextField extends StatefulWidget {
  final String title;
  final String? description;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final bool obscureText;
  final bool enabled;
  final bool monospace;

  const SettingTextField({
    super.key,
    required this.title,
    this.description,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.hintText,
    this.obscureText = false,
    this.enabled = true,
    this.monospace = false,
  });

  @override
  State<SettingTextField> createState() => _SettingTextFieldState();
}

class _SettingTextFieldState extends State<SettingTextField> {
  TextEditingController? _owned;

  TextEditingController get _controller =>
      widget.controller ??
      (_owned ??= TextEditingController(text: widget.initialValue ?? ''));

  @override
  void didUpdateWidget(covariant SettingTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep an owned controller in sync when the control is rebuilt with a new
    // external value while not externally managed (avoids stale text after
    // e.g. a "reset to defaults").
    if (_owned != null &&
        widget.controller == null &&
        widget.initialValue != null) {
      final text = _owned!.text;
      if (text != widget.initialValue && !_owned!.selection.isValid) {
        _owned!.text = widget.initialValue!;
      }
    }
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scale = context.scale;
    final field = TextField(
      controller: _controller,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      onChanged: widget.onChanged != null
          ? (v) {
              widget.onChanged!(v);
            }
          : null,
      style: widget.monospace
          ? Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              inherit: false,
            )
          : null,
      decoration: InputDecoration(
        hintText: widget.hintText,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: scale.sp(10),
          vertical: scale.sp(8),
        ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
      ),
    );
    return SettingTile(
      title: widget.title,
      description: widget.description,
      control: SizedBox(width: 280, child: field),
    );
  }
}

/// A scope badge ("Global" vs "Project") shown in the content header.
class SettingScopeBadge extends StatelessWidget {
  final bool isProject;
  final String? projectName;

  const SettingScopeBadge({
    super.key,
    required this.isProject,
    this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = isProject ? const Color(0xFF818CF8) : colors.primary;
    final bg = isProject
        ? const Color(0xFF6366F1).withValues(alpha: 0.12)
        : colors.primary.withValues(alpha: 0.12);
    final label = isProject
        ? 'Project Scope${projectName != null ? ': $projectName' : ''}'
        : 'Global Scope';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isProject ? Icons.folder_outlined : Icons.public,
            size: 13,
            color: accent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple info/notice row (used for warnings and explanatory notes).
class SettingInfo extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool warning;

  const SettingInfo({
    super.key,
    required this.text,
    required this.icon,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = warning
        ? AppColors.getError(context)
        : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color, inherit: false),
            ),
          ),
        ],
      ),
    );
  }
}
