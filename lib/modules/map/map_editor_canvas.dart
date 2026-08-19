import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lore_keeper/providers/map_provider.dart';
import 'package:lore_keeper/models/map_data.dart';
import 'package:lore_keeper/services/resource_manager.dart';
import 'package:uuid/uuid.dart';

class MapEditorCanvas extends StatefulWidget {
  const MapEditorCanvas({super.key});

  @override
  State<MapEditorCanvas> createState() => _MapEditorCanvasState();
}

class _MapEditorCanvasState extends State<MapEditorCanvas> {
  final TransformationController _transformationController =
      TransformationController();

  List<Offset> _currentDrawingPath = [];
  String _activeDragType = 'none'; // 'move', 'scale', 'rotate', 'none'
  Offset? _dragStartPos;
  double _initialScale = 1.0;
  double _initialRotation = 0.0;

  void _handlePanStart(DragStartDetails details) {
    final provider = context.read<MapProvider>();
    if (provider.currentTool == MapTool.pan) return;

    final localPosition = _getLocalPosition(details.globalPosition);

    if (provider.currentTool == MapTool.select) {
      // Find selected stamp
      final stampId = provider.selectedStampId;
      if (stampId != null) {
        // Find stamp data
        MapStamp? activeStamp;
        for (var l in provider.activeMap!.layers) {
          try {
            activeStamp = l.stamps.firstWhere((s) => s.id == stampId);
            break;
          } catch (_) {}
        }

        if (activeStamp != null) {
          // Check handle hitboxes (simplified)
          final dx = localPosition.dx - activeStamp.x;
          final dy = localPosition.dy - activeStamp.y;
          final dist = dx * dx + dy * dy;

          if (dist < 400) {
            // Clicked center (move)
            _activeDragType = 'move';
            _dragStartPos = localPosition;
            return;
          } else if (dx > 30 && dy > 30 && dx < 70 && dy < 70) {
            // Bottom right approx (scale)
            _activeDragType = 'scale';
            _dragStartPos = localPosition;
            _initialScale = activeStamp.scale;
            return;
          } else if (dx > -20 && dx < 20 && dy < -40 && dy > -80) {
            // Top center approx (rotate)
            _activeDragType = 'rotate';
            _dragStartPos = localPosition;
            _initialRotation = activeStamp.rotation;
            return;
          }
        }
      }
      _activeDragType = 'none';
      return;
    }

    if (provider.currentTool == MapTool.eraser) {
      provider.removeAssetAt(localPosition);
      return;
    }

    if (provider.currentTool == MapTool.path ||
        provider.currentTool == MapTool.brush) {
      setState(() {
        _currentDrawingPath = [localPosition];
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final provider = context.read<MapProvider>();
    if (provider.currentTool == MapTool.pan) return;

    final localPosition = _getLocalPosition(details.globalPosition);

    if (provider.currentTool == MapTool.select &&
        _activeDragType != 'none' &&
        _dragStartPos != null) {
      final stampId = provider.selectedStampId;
      if (stampId != null) {
        MapStamp? activeStamp;
        for (var l in provider.activeMap!.layers) {
          try {
            activeStamp = l.stamps.firstWhere((s) => s.id == stampId);
            break;
          } catch (_) {}
        }

        if (activeStamp != null) {
          if (_activeDragType == 'move') {
            final delta = localPosition - _dragStartPos!;
            final newPos = Offset(
              activeStamp.x + delta.dx,
              activeStamp.y + delta.dy,
            );
            provider.updateSelectedStamp(position: newPos);
            _dragStartPos = localPosition;
          } else if (_activeDragType == 'scale') {
            final deltaY = localPosition.dy - _dragStartPos!.dy;
            final newScale = (_initialScale + (deltaY / 100)).clamp(0.1, 10.0);
            provider.updateSelectedStamp(scale: newScale);
          } else if (_activeDragType == 'rotate') {
            final deltaX = localPosition.dx - _dragStartPos!.dx;
            final newRotation = _initialRotation + (deltaX / 50);
            provider.updateSelectedStamp(rotation: newRotation);
          }
        }
      }
      return;
    }

    if (provider.currentTool == MapTool.path ||
        provider.currentTool == MapTool.brush) {
      setState(() {
        _currentDrawingPath.add(localPosition);
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final provider = context.read<MapProvider>();

    if (_currentDrawingPath.length > 1) {
      if (provider.currentTool == MapTool.path) {
        provider.addPath(
          MapPath(
            id: const Uuid().v4(),
            controlPoints: _currentDrawingPath
                .map((o) => OffsetData.fromOffset(o))
                .toList(),
          ),
        );
      } else if (provider.currentTool == MapTool.brush) {
        provider.addPolygon(
          MapPolygon(
            id: const Uuid().v4(),
            points: _currentDrawingPath
                .map((o) => OffsetData.fromOffset(o))
                .toList(),
            textureAssetPath: '', // Will implement texture later
          ),
        );
      }
    }

    _activeDragType = 'none';
    _dragStartPos = null;

    setState(() {
      _currentDrawingPath = [];
    });
  }

  void _handleTapDown(TapDownDetails details) {
    final provider = context.read<MapProvider>();
    final localPosition = _getLocalPosition(details.globalPosition);

    if (provider.currentTool == MapTool.select) {
      if (provider.activeMap == null) return;
      for (int i = provider.activeMap!.layers.length - 1; i >= 0; i--) {
        var layer = provider.activeMap!.layers[i];
        if (layer.isLocked || !layer.isVisible) continue;
        for (int j = layer.stamps.length - 1; j >= 0; j--) {
          var stamp = layer.stamps[j];
          if ((localPosition.dx - stamp.x).abs() < 50 &&
              (localPosition.dy - stamp.y).abs() < 50) {
            provider.selectStamp(stamp.id);
            provider.setActiveLayer(i);
            return;
          }
        }
      }
      provider.selectStamp(null);
      return;
    }

    if (provider.currentTool == MapTool.stamp) {
      provider.addStamp(
        MapStamp(
          id: const Uuid().v4(),
          assetPath: 'default', // Placeholder
          x: localPosition.dx,
          y: localPosition.dy,
        ),
      );
    } else if (provider.currentTool == MapTool.eraser) {
      provider.removeAssetAt(localPosition);
    }
  }

  Offset _getLocalPosition(Offset globalPosition) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(globalPosition);
    // Apply inverse transformation to get coordinates on the map canvas
    final Matrix4 inverseMatrix = Matrix4.inverted(
      _transformationController.value,
    );
    final Offset transformedPosition = MatrixUtils.transformPoint(
      inverseMatrix,
      localPosition,
    );
    return transformedPosition;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapProvider>();
    final mapData = provider.activeMap;

    if (mapData == null) return const SizedBox.shrink();

    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTapDown: _handleTapDown,
      child: InteractiveViewer(
        transformationController: _transformationController,
        panEnabled: provider.currentTool == MapTool.pan,
        scaleEnabled:
            provider.currentTool == MapTool.pan ||
            provider.currentTool == MapTool.select,
        minScale: 0.1,
        maxScale: 5.0,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        child: SizedBox(
          width: mapData.width,
          height: mapData.height,
          child: CustomPaint(
            painter: MapPainter(
              mapData: mapData,
              currentDrawingPath: _currentDrawingPath,
              currentTool: provider.currentTool,
              selectedStampId: provider.selectedStampId,
              onAssetLoaded: () {
                if (mounted) setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final MapData mapData;
  final List<Offset> currentDrawingPath;
  final MapTool currentTool;
  final VoidCallback onAssetLoaded;
  final String? selectedStampId;

  MapPainter({
    required this.mapData,
    required this.currentDrawingPath,
    required this.currentTool,
    required this.onAssetLoaded,
    this.selectedStampId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background
    final bgPaint = Paint()..color = const Color(0xFFE3D6C1); // Parchment color
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw Layers
    for (var layer in mapData.layers) {
      if (!layer.isVisible) continue;

      // Draw Polygons (Landmasses)
      final polyPaint = Paint()
        ..color =
            const Color(0xFF6B8E23) // Olive drab land
        ..style = PaintingStyle.fill;

      for (var poly in layer.polygons) {
        if (poly.points.isEmpty) continue;
        final path = Path();
        path.moveTo(poly.points.first.dx, poly.points.first.dy);
        for (int i = 1; i < poly.points.length; i++) {
          path.lineTo(poly.points[i].dx, poly.points[i].dy);
        }
        path.close();
        canvas.drawPath(path, polyPaint);
      }

      // Draw Paths (Rivers/Roads)
      for (var mapPath in layer.paths) {
        if (mapPath.controlPoints.length < 2) continue;

        final pathPaint = Paint()
          ..color = Color(mapPath.colorValue).withValues(alpha: 1.0)
          ..strokeWidth = mapPath.strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        final path = Path();
        path.moveTo(
          mapPath.controlPoints.first.dx,
          mapPath.controlPoints.first.dy,
        );

        for (int i = 1; i < mapPath.controlPoints.length - 1; i++) {
          final p1 = mapPath.controlPoints[i];
          final p2 = mapPath.controlPoints[i + 1];
          final xc = (p1.dx + p2.dx) / 2;
          final yc = (p1.dy + p2.dy) / 2;
          path.quadraticBezierTo(p1.dx, p1.dy, xc, yc);
        }
        path.lineTo(
          mapPath.controlPoints.last.dx,
          mapPath.controlPoints.last.dy,
        );

        canvas.drawPath(path, pathPaint);
      }

      // Draw Stamps
      final stampPaint = Paint()..color = Colors.black54;
      for (var stamp in layer.stamps) {
        canvas.save();
        canvas.translate(stamp.x, stamp.y);
        canvas.scale(stamp.scale);
        canvas.rotate(stamp.rotation);

        final picInfo = ResourceManager().getSvgPictureSync(stamp.assetPath);
        if (picInfo != null) {
          // Center the SVG based on its size
          canvas.translate(-picInfo.size.width / 2, -picInfo.size.height / 2);
          canvas.drawPicture(picInfo.picture);
        } else {
          // Trigger async load, then notify to repaint
          ResourceManager().getSvgPicture(stamp.assetPath).then((_) {
            onAssetLoaded();
          });
          // Draw placeholder
          canvas.drawCircle(Offset.zero, 15, stampPaint);
        }
        canvas.restore();
      }
    }

    // 3. Draw active drawing path
    if (currentDrawingPath.isNotEmpty) {
      final activePaint = Paint()
        ..color = currentTool == MapTool.brush
            ? Colors.green.withValues(alpha: 0.5)
            : Colors.blue
        ..strokeWidth = currentTool == MapTool.brush ? 30.0 : 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(currentDrawingPath.first.dx, currentDrawingPath.first.dy);

      for (int i = 1; i < currentDrawingPath.length - 1; i++) {
        final p1 = currentDrawingPath[i];
        final p2 = currentDrawingPath[i + 1];
        final xc = (p1.dx + p2.dx) / 2;
        final yc = (p1.dy + p2.dy) / 2;
        path.quadraticBezierTo(p1.dx, p1.dy, xc, yc);
      }
      path.lineTo(currentDrawingPath.last.dx, currentDrawingPath.last.dy);

      canvas.drawPath(path, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    // In a real app, optimize this by checking deep equality or tracking a tick counter
    return true;
  }
}
