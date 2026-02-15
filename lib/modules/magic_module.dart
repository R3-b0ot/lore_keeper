import 'package:flutter/material.dart';
import 'package:lore_keeper/providers/magic_tree_provider.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/widgets/magic_init_wizard.dart';
import 'package:lore_keeper/widgets/magic_main_panel.dart';

class MagicModule extends StatelessWidget {
  final MagicTreeProvider magicProvider;

  const MagicModule({super.key, required this.magicProvider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgMain : AppColors.bgMainLight;

    return Container(
      color: bgColor,
      child: ListenableBuilder(
        listenable: magicProvider,
        builder: (context, child) {
          if (!magicProvider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final system = magicProvider.selectedSystem;
          if (system == null) {
            return const Center(child: Text('No magic system found.'));
          }

          if (!system.isConfigured) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: MagicInitWizard(
                provider: magicProvider,
                systemKey: system.key as int,
                initialName: system.name,
              ),
            );
          }

          return MagicMainPanel(provider: magicProvider);
        },
      ),
    );
  }
}
