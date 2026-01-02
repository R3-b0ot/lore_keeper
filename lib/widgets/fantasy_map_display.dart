import 'package:flutter/material.dart';
import 'package:lore_keeper/models/geometry.dart';

/// Fantasy Map Display - Renders the Fantasy Map Generator output
class FantasyMapDisplay extends StatefulWidget {
  final GeneratedMap mapData;

  const FantasyMapDisplay({super.key, required this.mapData});

  @override
  State<FantasyMapDisplay> createState() => _FantasyMapDisplayState();
}

class _FantasyMapDisplayState extends State<FantasyMapDisplay> {
  final double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _dragStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        color: Colors.blue.shade100, // Ocean background
        child: CustomPaint(
          painter: FantasyMapPainter(
            mapData: widget.mapData,
            scale: _scale,
            offset: _offset,
          ),
          child: Container(), // Full size container
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStart != null) {
      setState(() {
        _offset += details.delta;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStart = null;
  }
}

/// Custom painter for rendering the fantasy map
class FantasyMapPainter extends CustomPainter {
  final GeneratedMap mapData;
  final double scale;
  final Offset offset;

  FantasyMapPainter({
    required this.mapData,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Transform canvas for zoom and pan
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw cells
    for (final cell in mapData.cells) {
      _drawCell(canvas, cell);
    }

    // Draw cell borders
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 0.5 / scale
      ..style = PaintingStyle.stroke;

    for (final cell in mapData.cells) {
      _drawCellBorder(canvas, cell, borderPaint);
    }

    canvas.restore();
  }

  void _drawCell(Canvas canvas, Cell cell) {
    if (cell.vertices.isEmpty) return;

    final path = Path();
    path.moveTo(cell.vertices[0].x, cell.vertices[0].y);
    for (int i = 1; i < cell.vertices.length; i++) {
      path.lineTo(cell.vertices[i].x, cell.vertices[i].y);
    }
    path.close();

    final paint = Paint()
      ..color = _getBiomeColor(cell.biome)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawCellBorder(Canvas canvas, Cell cell, Paint borderPaint) {
    if (cell.vertices.isEmpty) return;

    final path = Path();
    path.moveTo(cell.vertices[0].x, cell.vertices[0].y);
    for (int i = 1; i < cell.vertices.length; i++) {
      path.lineTo(cell.vertices[i].x, cell.vertices[i].y);
    }
    path.close();

    canvas.drawPath(path, borderPaint);
  }

  Color _getBiomeColor(Biome biome) {
    switch (biome) {
      case Biome.ocean:
        return Colors.blue.shade600;
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
        return Colors.yellow.shade400;
      case Biome.grassland:
        return Colors.green.shade300;
      case Biome.forest:
        return Colors.green.shade600;
      case Biome.taiga:
        return Colors.green.shade800;
      case Biome.tundra:
        return Colors.grey.shade300;
      case Biome.mountain:
        return Colors.grey.shade700;
      case Biome.swamp:
        return Colors.green.shade900;
      case Biome.jungle:
        return Colors.green.shade800;
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
  bool shouldRepaint(FantasyMapPainter oldDelegate) {
    return oldDelegate.mapData != mapData ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }
}
