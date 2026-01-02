import 'package:flutter/material.dart';
import 'package:lore_keeper/models/geometry.dart';

/// Interactive world display widget with zoom, pan, and layer controls
class WorldDisplay extends StatefulWidget {
  final GeneratedMap mapData;

  const WorldDisplay({super.key, required this.mapData});

  @override
  State<WorldDisplay> createState() => _WorldDisplayState();
}

class _WorldDisplayState extends State<WorldDisplay> {
  final TransformationController _transformationController =
      TransformationController();
  bool _showBiomes = true;
  bool _showRivers = true;
  bool _showCivilizations = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('World Map'),
        actions: [
          // Layer toggles
          Tooltip(
            message: 'Toggle Biomes',
            child: IconButton(
              icon: Icon(_showBiomes ? Icons.terrain : Icons.terrain_outlined),
              onPressed: () => setState(() => _showBiomes = !_showBiomes),
            ),
          ),
          Tooltip(
            message: 'Toggle Rivers',
            child: IconButton(
              icon: Icon(_showRivers ? Icons.waves : Icons.waves_outlined),
              onPressed: () => setState(() => _showRivers = !_showRivers),
            ),
          ),
          Tooltip(
            message: 'Toggle Civilizations',
            child: IconButton(
              icon: Icon(
                _showCivilizations
                    ? Icons.location_city
                    : Icons.location_city_outlined,
              ),
              onPressed: () =>
                  setState(() => _showCivilizations = !_showCivilizations),
            ),
          ),
          // Reset view
          Tooltip(
            message: 'Reset View',
            child: IconButton(
              icon: const Icon(Icons.center_focus_strong),
              onPressed: _resetView,
            ),
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.1,
        maxScale: 5.0,
        child: Container(
          width: 1000,
          height: 1000,
          color: Colors.blue.shade900, // Ocean background
          child: CustomPaint(
            painter: WorldPainter(
              mapData: widget.mapData,
              showBiomes: _showBiomes,
              showRivers: _showRivers,
              showCivilizations: _showCivilizations,
            ),
          ),
        ),
      ),
    );
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}

/// Custom painter for rendering the world map
class WorldPainter extends CustomPainter {
  final GeneratedMap mapData;
  final bool showBiomes;
  final bool showRivers;
  final bool showCivilizations;

  WorldPainter({
    required this.mapData,
    required this.showBiomes,
    required this.showRivers,
    required this.showCivilizations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw cells
    for (final cell in mapData.cells) {
      _drawCell(canvas, cell);
    }

    // Draw rivers
    if (showRivers && mapData.rivers != null) {
      for (final river in mapData.rivers!) {
        _drawRiver(canvas, river);
      }
    }

    // Draw civilizations
    if (showCivilizations && mapData.civilizations != null) {
      for (final civilization in mapData.civilizations!) {
        _drawCivilization(canvas, civilization);
      }
    }
  }

  void _drawCell(Canvas canvas, Cell cell) {
    if (cell.vertices.isEmpty) return;

    final path = Path();
    path.moveTo(cell.vertices[0].x, cell.vertices[0].y);
    for (int i = 1; i < cell.vertices.length; i++) {
      path.lineTo(cell.vertices[i].x, cell.vertices[i].y);
    }
    path.close();

    Color color;
    if (cell.height < 20) {
      // Water
      color = Colors.blue.shade600;
    } else if (showBiomes) {
      // Biome colors
      color = _getBiomeColor(cell.biome);
    } else {
      // Height-based colors
      final intensity = (cell.height / 100).clamp(0.0, 1.0);
      color = Color.lerp(
        Colors.green.shade200,
        Colors.brown.shade800,
        intensity,
      )!;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawPath(path, borderPaint);
  }

  void _drawRiver(Canvas canvas, Map<String, dynamic> river) {
    final cells = river['cells'] as List<int>;
    if (cells.length < 2) return;

    final path = Path();
    bool first = true;

    for (final cellIndex in cells) {
      if (cellIndex >= mapData.cells.length) continue;
      final cell = mapData.cells[cellIndex];
      final point = cell.site;

      if (first) {
        path.moveTo(point.x, point.y);
        first = false;
      } else {
        path.lineTo(point.x, point.y);
      }
    }

    final paint = Paint()
      ..color = Colors.blue.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  void _drawCivilization(Canvas canvas, Map<String, dynamic> civilization) {
    final x = civilization['x'] as double;
    final y = civilization['y'] as double;
    final size = civilization['size'] as String;

    double radius;
    Color color;

    switch (size) {
      case 'large':
        radius = 8.0;
        color = Colors.red.shade700;
        break;
      case 'medium':
        radius = 6.0;
        color = Colors.orange.shade700;
        break;
      case 'small':
        radius = 4.0;
        color = Colors.yellow.shade700;
        break;
      default: // tiny
        radius = 3.0;
        color = Colors.grey.shade600;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), radius, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(x, y), radius, borderPaint);
  }

  Color _getBiomeColor(Biome biome) {
    switch (biome) {
      case Biome.ocean:
        return Colors.blue.shade800;
      case Biome.lake:
        return Colors.blue.shade400;
      case Biome.freshwater:
        return Colors.blue.shade300;
      case Biome.salt:
        return Colors.blue.shade500;
      case Biome.frozen:
        return Colors.white;
      case Biome.dry:
        return Colors.yellow.shade200;
      case Biome.desert:
        return Colors.yellow.shade600;
      case Biome.grassland:
        return Colors.green.shade400;
      case Biome.forest:
        return Colors.green.shade700;
      case Biome.taiga:
        return Colors.green.shade800;
      case Biome.tundra:
        return Colors.grey.shade400;
      case Biome.mountain:
        return Colors.grey.shade600;
      case Biome.swamp:
        return Colors.green.shade300;
      case Biome.jungle:
        return Colors.green.shade900;
      case Biome.savanna:
        return Colors.orange.shade300;
      case Biome.steppe:
        return Colors.yellow.shade300;
      case Biome.badlands:
        return Colors.red.shade400;
      case Biome.volcanic:
        return Colors.black;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is WorldPainter) {
      return oldDelegate.showBiomes != showBiomes ||
          oldDelegate.showRivers != showRivers ||
          oldDelegate.showCivilizations != showCivilizations;
    }
    return true;
  }
}
