import 'package:flutter/material.dart';

class MapEditor extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final List<Map<String, dynamic>> maps;
  final Function(Map<String, dynamic>) onMapSelected;
  final Function(Map<String, dynamic>) onMapCreated;

  const MapEditor({
    super.key,
    required this.mapData,
    required this.maps,
    required this.onMapSelected,
    required this.onMapCreated,
  });

  @override
  State<MapEditor> createState() => _MapEditorState();
}

class _MapEditorState extends State<MapEditor> {
  String _selectedTool = 'select';
  double _zoomLevel = 1.0;
  bool _autoSave = true;
  Map<String, dynamic>? _selectedMap;

  final List<Map<String, dynamic>> _layers = [
    {
      'id': 'ocean',
      'name': 'Ocean Base',
      'type': 'texture',
      'visible': true,
      'opacity': 1.0,
      'color': Colors.blue.shade600,
    },
    {
      'id': 'elevation',
      'name': 'Elevation',
      'type': 'elevation',
      'visible': true,
      'opacity': 0.8,
      'data': <String, dynamic>{}, // Will store height data
    },
    {
      'id': 'biome',
      'name': 'Biome',
      'type': 'biome',
      'visible': true,
      'opacity': 1.0,
      'data': <String, dynamic>{}, // Will store biome data
    },
    {
      'id': 'terrain',
      'name': 'Terrain Features',
      'type': 'terrain',
      'visible': true,
      'opacity': 1.0,
      'data': <String, dynamic>{}, // Will store natural features
    },
    {
      'id': 'settlements',
      'name': 'Settlements',
      'type': 'settlements',
      'visible': true,
      'opacity': 1.0,
      'data': <String, dynamic>{}, // Will store man-made features
    },
    {
      'id': 'grid',
      'name': 'Grid',
      'type': 'grid',
      'visible': true,
      'opacity': 0.5,
      'gridType': 'square',
      'columns': 20,
      'rows': 20,
      'lineWidth': 1.0,
      'color': Colors.grey,
    },
    {
      'id': 'objects',
      'name': 'Objects',
      'type': 'objects',
      'visible': true,
      'opacity': 1.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedMap = widget.mapData;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Bar (without AppBar wrapper since we're in a module)
        _buildTopBarContent(),
        // Main Content
        Expanded(
          child: Row(
            children: [
              // Left Toolbar
              _buildLeftToolbar(),
              // Main Canvas Area
              Expanded(
                child: Column(
                  children: [
                    // Main Canvas
                    Expanded(child: _buildMainCanvas()),
                    // Bottom Bar
                    _buildBottomBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBarContent() {
    return Container(
      height: 56,
      color:
          Theme.of(context).appBarTheme.backgroundColor ??
          Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text(
            _selectedMap?['name'] ?? 'Map Editor',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              // TODO: Implement undo
            },
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () {
              // TODO: Implement redo
            },
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showMapInfo,
            tooltip: 'Map Information',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMap,
            tooltip: 'Save Map',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportMap,
            tooltip: 'Export to SVG',
          ),
        ],
      ),
    );
  }

  Widget _buildLeftToolbar() {
    return Container(
      width: 60,
      color: Colors.grey[100],
      child: Column(
        children: [
          _buildToolButton('select', Icons.touch_app, 'Select Tool'),
          _buildToolButton('brush', Icons.brush, 'Brush Tool'),
          _buildToolButton('stamp', Icons.stars, 'Stamp Tool'),
          _buildToolButton('line', Icons.show_chart, 'Line Tool'),
          _buildToolButton('shape', Icons.category, 'Shape Tool'),
          _buildToolButton('text', Icons.text_fields, 'Text Tool'),
          _buildToolButton('note', Icons.note, 'Note Tool'),
          const Divider(),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showLayerPanel,
            tooltip: 'Layers',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addLayer,
            tooltip: 'Add Layer',
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(String toolId, IconData icon, String tooltip) {
    final isSelected = _selectedTool == toolId;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: IconButton(
        icon: Icon(icon),
        onPressed: () => setState(() => _selectedTool = toolId),
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : null,
          foregroundColor: isSelected ? Colors.white : null,
        ),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildMainCanvas() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Transform.scale(
          scale: _zoomLevel,
          child: GestureDetector(
            onPanStart: _onCanvasPanStart,
            onPanUpdate: _onCanvasPanUpdate,
            onPanEnd: _onCanvasPanEnd,
            onTapDown: _onCanvasTapDown,
            child: Container(
              width: 800,
              height: 600,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.lightBlue[50], // Ocean base
              ),
              child: Stack(
                children: _layers.map((layer) {
                  if (!layer['visible']) return const SizedBox.shrink();
                  return Opacity(
                    opacity: layer['opacity'],
                    child: _buildLayerContent(layer),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerContent(Map<String, dynamic> layer) {
    switch (layer['type']) {
      case 'texture':
        return Container(
          color: layer['color'] ?? Colors.blue.shade600, // Ocean texture
        );
      case 'elevation':
        return CustomPaint(
          painter: ElevationPainter(
            heightData: layer['data'] ?? {},
            opacity: layer['opacity'],
          ),
        );
      case 'biome':
        return CustomPaint(
          painter: BiomePainter(
            biomeData: layer['data'] ?? {},
            opacity: layer['opacity'],
          ),
        );
      case 'terrain':
        return CustomPaint(
          painter: TerrainPainter(
            terrainData: layer['data'] ?? {},
            opacity: layer['opacity'],
          ),
        );
      case 'settlements':
        return CustomPaint(
          painter: SettlementsPainter(
            settlementData: layer['data'] ?? {},
            opacity: layer['opacity'],
          ),
        );
      case 'grid':
        return CustomPaint(
          painter: GridPainter(
            gridType: layer['gridType'],
            columns: layer['columns'],
            rows: layer['rows'],
            lineWidth: layer['lineWidth'],
            color: layer['color'],
          ),
        );
      case 'objects':
        return const SizedBox(); // Objects layer - will contain pins/text
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomBar() {
    return Container(
      height: 40,
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text('Zoom: ${(_zoomLevel * 100).round()}%'),
          Expanded(
            child: Slider(
              value: _zoomLevel,
              min: 0.1,
              max: 3.0,
              onChanged: (value) => setState(() => _zoomLevel = value),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () =>
                setState(() => _zoomLevel = (_zoomLevel * 1.2).clamp(0.1, 3.0)),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () =>
                setState(() => _zoomLevel = (_zoomLevel / 1.2).clamp(0.1, 3.0)),
          ),
          const VerticalDivider(),
          Row(
            children: [
              const Text('Auto-save'),
              Switch(
                value: _autoSave,
                onChanged: (value) => setState(() => _autoSave = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMapInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_selectedMap?['name'] ?? 'Unknown'}'),
            Text('Style: ${_selectedMap?['style'] ?? 'Unknown'}'),
            Text('Resolution: ${_selectedMap?['resolution'] ?? 'Unknown'}'),
            Text('Aspect Ratio: ${_selectedMap?['aspectRatio'] ?? 'Unknown'}'),
            Text('Layers: ${_layers.length}'),
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

  void _saveMap() {
    // TODO: Implement save functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Map saved successfully')));
  }

  void _exportMap() {
    // TODO: Implement SVG export
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('SVG export coming soon')));
  }

  void _showLayerPanel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Layers'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView.builder(
            itemCount: _layers.length,
            itemBuilder: (context, index) {
              final layer = _layers[index];
              return ListTile(
                leading: IconButton(
                  icon: Icon(
                    layer['visible'] ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => layer['visible'] = !layer['visible']),
                ),
                title: Text(layer['name']),
                subtitle: Text(layer['type']),
                trailing: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _editLayer(layer),
                ),
              );
            },
          ),
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

  void _addLayer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Layer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Object Layer'),
              onTap: () => _createLayer('objects', 'New Objects Layer'),
            ),
            ListTile(
              title: const Text('Grid Layer'),
              onTap: () => _createLayer('grid', 'New Grid Layer'),
            ),
            ListTile(
              title: const Text('Brush Layer'),
              onTap: () => _createLayer('brush', 'New Brush Layer'),
            ),
            ListTile(
              title: const Text('Filter Layer'),
              onTap: () => _createLayer('filter', 'New Filter Layer'),
            ),
          ],
        ),
      ),
    );
  }

  void _createLayer(String type, String name) {
    setState(() {
      _layers.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'type': type,
        'visible': true,
        'opacity': 1.0,
      });
    });
    Navigator.of(context).pop();
  }

  void _editLayer(Map<String, dynamic> layer) {
    // TODO: Implement layer editing dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${layer['name']} coming soon')),
    );
  }

  void _onCanvasPanStart(DragStartDetails details) {
    if (_selectedTool == 'brush') {
      _applyBrush(details.localPosition);
    }
  }

  void _onCanvasPanUpdate(DragUpdateDetails details) {
    if (_selectedTool == 'brush') {
      _applyBrush(details.localPosition);
    }
  }

  void _onCanvasPanEnd(DragEndDetails details) {
    // Handle brush end if needed
  }

  void _onCanvasTapDown(TapDownDetails details) {
    if (_selectedTool == 'stamp') {
      _applyStamp(details.localPosition);
    }
  }

  void _applyBrush(Offset position) {
    // Find the biome layer and add brush stroke data
    final biomeLayer = _layers.firstWhere(
      (layer) => layer['type'] == 'biome',
      orElse: () => {},
    );

    if (biomeLayer.isNotEmpty) {
      final data = biomeLayer['data'] as Map<String, dynamic>;
      final brushStrokes = data['brushStrokes'] ?? <Offset>[];
      brushStrokes.add(position);
      data['brushStrokes'] = brushStrokes;

      setState(() {});
    }
  }

  void _applyStamp(Offset position) {
    // Find the settlements layer and add stamp data
    final settlementsLayer = _layers.firstWhere(
      (layer) => layer['type'] == 'settlements',
      orElse: () => {},
    );

    if (settlementsLayer.isNotEmpty) {
      final data = settlementsLayer['data'] as Map<String, dynamic>;
      final stamps = data['stamps'] ?? <Map<String, dynamic>>[];
      stamps.add({
        'position': position,
        'type': 'town', // Default stamp type
        'size': 20.0,
      });
      data['stamps'] = stamps;

      setState(() {});
    }
  }
}

class GridPainter extends CustomPainter {
  final String gridType;
  final int columns;
  final int rows;
  final double lineWidth;
  final Color color;

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
      ..color = color
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

class ElevationPainter extends CustomPainter {
  final Map<String, dynamic> heightData;
  final double opacity;

  ElevationPainter({required this.heightData, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: Implement elevation rendering based on height data
    // For now, show a placeholder gradient
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.brown.shade200.withValues(alpha: opacity),
          Colors.brown.shade600.withValues(alpha: opacity),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BiomePainter extends CustomPainter {
  final Map<String, dynamic> biomeData;
  final double opacity;

  BiomePainter({required this.biomeData, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw brush strokes
    final brushStrokes = biomeData['brushStrokes'] as List<Offset>? ?? [];
    if (brushStrokes.isNotEmpty) {
      final brushPaint = Paint()
        ..color = Colors.green.shade400.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      for (final stroke in brushStrokes) {
        canvas.drawCircle(stroke, 5.0, brushPaint);
      }
    }

    // TODO: Implement additional biome rendering based on biome data
    // For now, show a placeholder pattern if no brush strokes
    if (brushStrokes.isEmpty) {
      final paint = Paint()
        ..color = Colors.green.shade300.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TerrainPainter extends CustomPainter {
  final Map<String, dynamic> terrainData;
  final double opacity;

  TerrainPainter({required this.terrainData, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: Implement terrain feature rendering (mountains, forests, etc.)
    // For now, show placeholder shapes
    final paint = Paint()
      ..color = Colors.grey.shade700.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Draw some mountain-like shapes
    final path = Path();
    path.moveTo(100, 400);
    path.lineTo(150, 300);
    path.lineTo(200, 350);
    path.lineTo(250, 250);
    path.lineTo(300, 320);
    path.lineTo(350, 400);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SettlementsPainter extends CustomPainter {
  final Map<String, dynamic> settlementData;
  final double opacity;

  SettlementsPainter({required this.settlementData, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw stamps
    final stamps =
        settlementData['stamps'] as List<Map<String, dynamic>>? ?? [];
    if (stamps.isNotEmpty) {
      final stampPaint = Paint()
        ..color = Colors.brown.shade800.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      for (final stamp in stamps) {
        final position = stamp['position'] as Offset;
        final size = stamp['size'] as double? ?? 20.0;
        final type = stamp['type'] as String? ?? 'town';

        // Draw different shapes based on stamp type
        switch (type) {
          case 'town':
            // Draw a simple building shape
            canvas.drawRect(
              Rect.fromCenter(
                center: position,
                width: size,
                height: size * 1.5,
              ),
              stampPaint,
            );
            break;
          case 'castle':
            // Draw a castle-like shape
            canvas.drawRect(
              Rect.fromCenter(
                center: position,
                width: size * 1.2,
                height: size,
              ),
              stampPaint,
            );
            // Add towers
            canvas.drawRect(
              Rect.fromCenter(
                center: position.translate(-size * 0.4, -size * 0.3),
                width: size * 0.3,
                height: size * 0.6,
              ),
              stampPaint,
            );
            canvas.drawRect(
              Rect.fromCenter(
                center: position.translate(size * 0.4, -size * 0.3),
                width: size * 0.3,
                height: size * 0.6,
              ),
              stampPaint,
            );
            break;
          default:
            // Default to town
            canvas.drawRect(
              Rect.fromCenter(
                center: position,
                width: size,
                height: size * 1.5,
              ),
              stampPaint,
            );
        }
      }
    }

    // TODO: Implement additional settlement rendering based on settlement data
    // For now, show placeholder buildings if no stamps
    if (stamps.isEmpty) {
      final paint = Paint()
        ..color = Colors.brown.shade800.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Draw some building-like rectangles
      canvas.drawRect(const Rect.fromLTWH(150, 200, 20, 30), paint);
      canvas.drawRect(const Rect.fromLTWH(180, 210, 15, 25), paint);
      canvas.drawRect(const Rect.fromLTWH(200, 190, 25, 35), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
