import 'package:flutter/material.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/widgets/calendar_init_wizard.dart';
import 'package:lore_keeper/widgets/calendar_main_panel.dart';

class CalendarModule extends StatelessWidget {
  final CalendarTreeProvider calendarProvider;

  const CalendarModule({super.key, required this.calendarProvider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgMain : AppColors.bgMainLight;

    return Container(
      color: bgColor,
      child: ListenableBuilder(
        listenable: calendarProvider,
        builder: (context, child) {
          if (!calendarProvider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final system = calendarProvider.selectedSystem;
          if (system == null) {
            return const Center(child: Text('No calendar system found.'));
          }

          if (!system.isConfigured) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: CalendarInitWizard(
                provider: calendarProvider,
                systemKey: system.key as int,
                initialName: system.name,
              ),
            );
          }

          return CalendarMainPanel(provider: calendarProvider);
        },
      ),
    );
  }
}
