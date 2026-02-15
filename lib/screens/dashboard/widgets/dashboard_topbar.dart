import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/widgets/settings_dialog.dart';
import 'package:lore_keeper/utils/dashboard_search_delegate.dart';

class DashboardTopbar extends StatelessWidget {
  final double opacity;

  const DashboardTopbar({super.key, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: opacity == 0,
      child: Opacity(
        opacity: opacity,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ), // Fixed 5% approx
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Small Logo
                    Row(
                      children: [
                        SvgPicture.asset(
                          Theme.of(context).brightness == Brightness.dark
                              ? 'assets/svg/LOGOMARK_DARK.svg'
                              : 'assets/svg/LOGOMARK_LIGHT.svg',
                          height: 28,
                        ),
                        const SizedBox(width: 12),
                        SvgPicture.asset(
                          Theme.of(context).brightness == Brightness.dark
                              ? 'assets/svg/WORDMARK_DARK.svg'
                              : 'assets/svg/WORDMARK_LIGHT.svg',
                          height: 14, // 50% of 28
                        ),
                      ],
                    ),

                    // Settings Button & Search Bar
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            LucideIcons.settings,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  const SettingsDialog(moduleIndex: -1),
                            );
                          },
                          tooltip: 'Settings',
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 280,
                          height: 44, // WCAG AAA Target Size
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.bgPanel
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.15),
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              Icon(
                                LucideIcons.search,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.7),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    showSearch(
                                      context: context,
                                      delegate: DashboardSearchDelegate(),
                                    );
                                  },
                                  child: Container(
                                    height: 36, // Increased for AAA comfort
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.black.withValues(alpha: 0.2)
                                          : Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: AbsorbPointer(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          hintText: 'Search archives...',
                                          hintStyle: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.4),
                                            fontSize: 12,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
