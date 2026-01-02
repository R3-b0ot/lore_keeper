import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lore_keeper/models/geometry.dart' as geo;
import 'package:lore_keeper/providers/map_display_provider.dart';

class MapDisplay extends ConsumerStatefulWidget {
  final geo.GeneratedMap mapData;

  const MapDisplay({super.key, required this.mapData});

  @override
  ConsumerState<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends ConsumerState<MapDisplay> {
  @override
  Widget build(BuildContext context) {
    final displayState = ref.watch(mapDisplayProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: CustomPaint(
            painter: MapPainter(
              mapData: widget.mapData,
              displayState: displayState,
            ),
          ),
        );
      },
    );
  }
}

class MapPainter extends CustomPainter {
  final geo.GeneratedMap mapData;
  final MapDisplayState displayState;

  MapPainter({required this.mapData, required this.displayState});

  @override
  void paint(Canvas canvas, Size size) {
    if (mapData.cells.isEmpty) return;

    // Calculate bounds of all cells
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final cell in mapData.cells) {
      for (final vertex in cell.vertices) {
        minX = min(minX, vertex.x);
        minY = min(minY, vertex.y);
        maxX = max(maxX, vertex.x);
        maxY = max(maxY, vertex.y);
      }
    }

    final mapWidth = maxX - minX;
    final mapHeight = maxY - minY;

    // Scale to fit the canvas while maintaining aspect ratio
    final scaleX = size.width / mapWidth;
    final scaleY = size.height / mapHeight;
    final scale = min(scaleX, scaleY);

    final offsetX = (size.width - mapWidth * scale) / 2 - minX * scale;
    final offsetY = (size.height - mapHeight * scale) / 2 - minY * scale;

    // Draw each cell
    for (final cell in mapData.cells) {
      if (cell.vertices.isEmpty) continue;

      final path = Path();
      final scaledVertices = cell.vertices
          .map((v) => Offset(v.x * scale + offsetX, v.y * scale + offsetY))
          .toList();

      path.addPolygon(scaledVertices, true);

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _getCellColor(cell);

      canvas.drawPath(path, paint);

      // Draw borders if enabled
      if (displayState.showBorders) {
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black.withValues(alpha: 0.3)
          ..strokeWidth = 0.5;
        canvas.drawPath(path, borderPaint);
      }
    }
  }

  Color _getCellColor(geo.Cell cell) {
    if (displayState.showBiomes) {
      return _getBiomeColor(cell.biome);
    } else if (displayState.showElevation) {
      return _getElevationColor(cell.height);
    } else if (displayState.showTemperature) {
      return _getTemperatureColor(cell.temperature);
    } else if (displayState.showPrecipitation) {
      return _getPrecipitationColor(cell.precipitation);
    }

    // Default to biome colors
    return _getBiomeColor(cell.biome);
  }

  Color _getBiomeColor(geo.Biome biome) {
    switch (biome) {
      case geo.Biome.ocean:
        return const Color(0xFF1e3a8a); // Deep blue
      case geo.Biome.lake:
        return const Color(0xFF3b82f6); // Blue
      case geo.Biome.freshwater:
        return const Color(0xFF60a5fa); // Light blue
      case geo.Biome.salt:
        return const Color(0xFF1e40af); // Dark blue
      case geo.Biome.frozen:
        return const Color(0xFFf8fafc); // White
      case geo.Biome.dry:
        return const Color(0xFFd97706); // Orange
      case geo.Biome.desert:
        return const Color(0xFFf59e0b); // Yellow
      case geo.Biome.grassland:
        return const Color(0xFF16a34a); // Green
      case geo.Biome.forest:
        return const Color(0xFF15803d); // Dark green
      case geo.Biome.taiga:
        return const Color(0xFF166534); // Dark green
      case geo.Biome.tundra:
        return const Color(0xFFa3a3a3); // Gray
      case geo.Biome.mountain:
        return const Color(0xFF78716c); // Brown
      case geo.Biome.swamp:
        return const Color(0xFF365314); // Dark green
      case geo.Biome.jungle:
        return const Color(0xFF14532d); // Very dark green
      case geo.Biome.savanna:
        return const Color(0xFF65a30d); // Light green
      case geo.Biome.steppe:
        return const Color(0xFF84cc16); // Yellow green
      case geo.Biome.badlands:
        return const Color(0xFFdc2626); // Red
      case geo.Biome.volcanic:
        return const Color(0xFF7c2d12); // Dark red
    }
  }

  Color _getElevationColor(int height) {
    // Height ranges from 0-100, sea level at 20
    if (height < 20) {
      // Water
      final intensity = (height / 20).clamp(0.0, 1.0);
      return Color.lerp(
        const Color(0xFF1e3a8a),
        const Color(0xFF3b82f6),
        intensity,
      )!;
    } else {
      // Land
      final landHeight = (height - 20) / 80.0; // 0-1 scale for land
      return Color.lerp(
        const Color(0xFF16a34a),
        const Color(0xFF78716c),
        landHeight.clamp(0.0, 1.0),
      )!;
    }
  }

  Color _getTemperatureColor(int temperature) {
    // Temperature from -128 to 127
    final normalizedTemp = (temperature + 128) / 255.0; // 0-1 scale
    return Color.lerp(Colors.blue, Colors.red, normalizedTemp.clamp(0.0, 1.0))!;
  }

  Color _getPrecipitationColor(double precipitation) {
    // Precipitation from 0-255
    final normalizedPrec = precipitation / 255.0;
    return Color.lerp(
      Colors.yellow,
      Colors.blue,
      normalizedPrec.clamp(0.0, 1.0),
    )!;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for now
  }
}

class _LocationCreationDialog extends StatefulWidget {
  final geo.Cell cell;

  const _LocationCreationDialog({required this.cell});

  @override
  State<_LocationCreationDialog> createState() =>
      _LocationCreationDialogState();
}

class _LocationCreationDialogState extends State<_LocationCreationDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with suggested name and description
    _nameController.text = 'Location ${widget.cell.index}';
    _descriptionController.text =
        'A ${widget.cell.biome.toString().split('.').last} region '
        'in ${widget.cell.state != 0 ? "state ${widget.cell.state}" : "the wilderness"}.';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Location Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Text('Biome: ${widget.cell.biome.toString().split('.').last}'),
          Text(
            'Culture: ${widget.cell.culture != 0 ? "Culture ${widget.cell.culture}" : "Unknown"}',
          ),
          Text(
            'State: ${widget.cell.state != 0 ? "State ${widget.cell.state}" : "Independent"}',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location "${_nameController.text}" created!'),
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
