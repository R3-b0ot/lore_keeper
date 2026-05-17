import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/widgets/settings_dialog.dart';
import 'package:lore_keeper/screens/dashboard/global_search_delegate.dart';
import 'package:lore_keeper/widgets/responsive_layout.dart';

class DashboardHero extends StatelessWidget {
  const DashboardHero({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < AppBreakpoints.compact;
        final heroHeight = isCompact ? 320.0 : 400.0;
        final logoSize = isCompact ? 96.0 : 160.0;
        final wordmarkHeight = isCompact ? 48.0 : 80.0;

        return Container(
          constraints: BoxConstraints(minHeight: heroHeight),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.dark
                ? AppColors.heroGradient
                : AppColors.heroGradientLight,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 72, 24, 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flex(
                        direction: isCompact ? Axis.vertical : Axis.horizontal,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.primary.withValues(
                                          alpha: 0.35,
                                        )
                                      : AppColors.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                  blurRadius: isCompact ? 40 : 80,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: SvgPicture.asset(
                              Theme.of(context).brightness == Brightness.dark
                                  ? 'assets/svg/LOGOMARK_DARK.svg'
                                  : 'assets/svg/LOGOMARK_LIGHT.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(
                            width: isCompact ? 0 : 40,
                            height: isCompact ? 16 : 0,
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SvgPicture.asset(
                              Theme.of(context).brightness == Brightness.dark
                                  ? 'assets/svg/WORDMARK_DARK.svg'
                                  : 'assets/svg/WORDMARK_LIGHT.svg',
                              height: wordmarkHeight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Text(
                          'Welcome back, Lorekeeper. What world shall we shape today?\nYour archives and manuscripts are ready for your touch.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.textMuted
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.normal,
                                height: 1.6,
                              ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 40,
                left: 24,
                child: IconButton(
                  icon: Icon(
                    LucideIcons.settings,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 28,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SettingsDialog(moduleIndex: -1),
                    );
                  },
                  tooltip: 'Settings',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HeroSearchBar extends StatelessWidget {
  const HeroSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgPanel
            : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 20),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Icon(
            LucideIcons.search,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
            semanticLabel: 'Search',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                showSearch(context: context, delegate: GlobalSearchDelegate());
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Search manuscripts, characters, or world lore...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
