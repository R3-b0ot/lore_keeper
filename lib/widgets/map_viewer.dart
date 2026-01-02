import 'package:flutter/material.dart';

class MapViewer extends StatelessWidget {
  final Map<String, dynamic> mapData;

  const MapViewer({super.key, required this.mapData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mapData['name'] ?? 'Map Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => _showMapInfo(context),
            tooltip: 'Map Information',
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 800,
          height: 600,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.lightBlue[50],
          ),
          child: Stack(children: _buildLayers()),
        ),
      ),
    );
  }

  List<Widget> _buildLayers() {
    final layers = mapData['layers'] as List<dynamic>? ?? [];
    return layers.map((layer) {
      final layerMap = layer as Map<String, dynamic>;
      if (!layerMap['visible']) return const SizedBox.shrink();
      return Opacity(
        opacity: layerMap['opacity'] ?? 1.0,
        child: _buildLayerContent(layerMap),
      );
    }).toList();
  }

  Widget _buildLayerContent(Map<String, dynamic> layer) {
    switch (layer['type']) {
      case 'texture':
        return Container(color: Colors.blue[100]);
      case 'grid':
        return CustomPaint(
          painter: GridPainter(
            gridType: layer['gridType'] ?? 'square',
            columns: layer['columns'] ?? 20,
            rows: layer['rows'] ?? 20,
            lineWidth: layer['lineWidth'] ?? 1.0,
            color: layer['color'] ?? Colors.grey,
          ),
        );
      case 'objects':
        return const SizedBox();
      default:
        return const SizedBox();
    }
  }

  void _showMapInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${mapData['name'] ?? 'Unknown'}'),
            Text('Style: ${mapData['style'] ?? 'Unknown'}'),
            Text('Resolution: ${mapData['resolution'] ?? 'Unknown'}'),
            Text('Aspect Ratio: ${mapData['aspectRatio'] ?? 'Unknown'}'),
            Text('Layers: ${(mapData['layers'] as List?)?.length ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final String gridType;
  final int columns;
  final int rows;
  final double lineWidth;
  final dynamic color;

  GridPainter({
    required this.gridType,
    required this.columns,
    required this.rows,
    required this.lineWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color is Color ? color : Colors.grey
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    final columnWidth = size.width / columns;
    final rowHeight = size.height / rows;

    // Draw vertical lines
    for (int i = 0; i <= columns; i++) {
      final x = i * columnWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 0; i <= rows; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
