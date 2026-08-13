import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lore_keeper/providers/map_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lore_keeper/services/resource_manager.dart';
import 'package:lore_keeper/models/map_data.dart';
import 'package:uuid/uuid.dart';

class MapToolbar extends StatelessWidget {
  const MapToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapProvider>();
    final currentTool = provider.currentTool;

    return Container(
      width: 60,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _ToolButton(
            icon: LucideIcons.mousePointer2,
            tooltip: 'Select / Move',
            isSelected: currentTool == MapTool.select,
            onPressed: () => provider.setTool(MapTool.select),
          ),
          _ToolButton(
            icon: LucideIcons.hand,
            tooltip: 'Pan View',
            isSelected: currentTool == MapTool.pan,
            onPressed: () => provider.setTool(MapTool.pan),
          ),
          _ToolButton(
            icon: LucideIcons.paintbrush,
            tooltip: 'Paint Landmass (Texture)',
            isSelected: currentTool == MapTool.brush,
            onPressed: () => provider.setTool(MapTool.brush),
          ),
          _ToolButton(
            icon: LucideIcons.spline,
            tooltip: 'Draw Path (River/Road)',
            isSelected: currentTool == MapTool.path,
            onPressed: () => provider.setTool(MapTool.path),
          ),
          _ToolButton(
            icon: LucideIcons.stamp,
            tooltip: 'Place Stamp (Object)',
            isSelected: currentTool == MapTool.stamp,
            onPressed: () => provider.setTool(MapTool.stamp),
          ),
          _ToolButton(
            icon: LucideIcons.eraser,
            tooltip: 'Eraser',
            isSelected: currentTool == MapTool.eraser,
            onPressed: () => provider.setTool(MapTool.eraser),
          ),
          const Spacer(),
          const Divider(),
          _ToolButton(
            icon: LucideIcons.upload,
            tooltip: 'Import Custom Asset',
            isSelected: false,
            onPressed: () => _importAsset(context, provider),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _importAsset(BuildContext context, MapProvider provider) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg', 'png', 'jpg', 'jpeg'],
      );
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String assetPath = await ResourceManager().importCustomAsset(file);
        
        await provider.addStamp(MapStamp(
          id: const Uuid().v4(),
          assetPath: assetPath,
          x: 2000, // roughly center of 4096 map for now
          y: 2000,
          isCustom: true,
        ));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asset imported successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing asset: $e')),
        );
      }
    }
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
