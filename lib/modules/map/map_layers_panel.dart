import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lore_keeper/providers/map_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MapLayersPanel extends StatelessWidget {
  const MapLayersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapProvider>();
    final mapData = provider.activeMap;

    if (!provider.isLayersPanelVisible || mapData == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Layers', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(LucideIcons.plus, size: 20),
                  tooltip: 'New Layer',
                  onPressed: () => provider.addLayer('New Layer'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: mapData.layers.length,
              onReorder: (oldIndex, newIndex) {
                provider.reorderLayers(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final layer = mapData.layers[index];
                final isActive = provider.activeLayerIndex == index;

                return Material(
                  key: ValueKey(layer.id),
                  color: isActive
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        LucideIcons.gripVertical,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      layer.name,
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () => provider.setActiveLayer(index),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            layer.isLocked
                                ? LucideIcons.lock
                                : LucideIcons.lockOpen,
                            size: 18,
                          ),
                          onPressed: () => provider.toggleLayerLock(index),
                          tooltip: layer.isLocked ? 'Unlock' : 'Lock',
                        ),
                        IconButton(
                          icon: Icon(
                            layer.isVisible
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            size: 18,
                          ),
                          onPressed: () =>
                              provider.toggleLayerVisibility(index),
                          tooltip: layer.isVisible ? 'Hide' : 'Show',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
