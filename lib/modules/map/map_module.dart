import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lore_keeper/providers/map_provider.dart';

import 'map_editor_canvas.dart';
import 'map_toolbar.dart';
import 'map_layers_panel.dart';

class MapModule extends StatelessWidget {
  final int projectId;

  const MapModule({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapProvider(projectId),
      child: const MapModuleView(),
    );
  }
}

class MapModuleView extends StatelessWidget {
  const MapModuleView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapProvider>();

    if (provider.activeMap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          const MapToolbar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: ClipRect(
              child: Stack(
                children: [
                  const MapEditorCanvas(),
                  
                  // Top overlay (Layers panel toggle, etc.)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        provider.toggleLayersPanel();
                      },
                      tooltip: 'Layers',
                      child: const Icon(Icons.layers),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const MapLayersPanel(),
        ],
      ),
    );
  }
}
