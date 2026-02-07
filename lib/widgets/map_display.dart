import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:lore_keeper/models/map_model.dart';

class MapDisplay extends StatefulWidget {
  final MapModel map;

  const MapDisplay({super.key, required this.map});

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  final TransformationController _transformationController =
      TransformationController();
  double _zoomLevel = 1.0;
  bool _showLayers = true; // For SVG layer toggle

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _zoomLevel = 1.0;
    });
  }

  void _onZoomChanged(double value) {
    setState(() {
      _zoomLevel = value;
    });
    // Apply zoom transformation
    final Matrix4 matrix = Matrix4.identity();
    matrix.scaleByVector3(Vector3(_zoomLevel, _zoomLevel, _zoomLevel));
    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar with map name
        Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                widget.map.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Layer toggle for SVG files
              if (widget.map.fileType.toLowerCase() == 'svg' ||
                  widget.map.fileType.toLowerCase() == 'eps')
                IconButton(
                  icon: Icon(_showLayers ? Icons.layers : Icons.layers_clear),
                  onPressed: () {
                    setState(() {
                      _showLayers = !_showLayers;
                    });
                  },
                  tooltip: _showLayers ? 'Hide Layers' : 'Show Layers',
                ),
            ],
          ),
        ),
        // Map display area
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.1,
            maxScale: 5.0,
            child: Center(child: _buildMapContent()),
          ),
        ),
        // Bottom bar with zoom controls
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  final newZoom = (_zoomLevel - 0.1).clamp(0.1, 5.0);
                  _onZoomChanged(newZoom);
                },
                tooltip: 'Zoom Out',
              ),
              Expanded(
                child: Slider(
                  value: _zoomLevel,
                  min: 0.1,
                  max: 5.0,
                  divisions: 49,
                  onChanged: _onZoomChanged,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  final newZoom = (_zoomLevel + 0.1).clamp(0.1, 5.0);
                  _onZoomChanged(newZoom);
                },
                tooltip: 'Zoom In',
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                onPressed: _resetZoom,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapContent() {
    final file = File(widget.map.filePath);

    if (!file.existsSync()) {
      return const Center(child: Text('Map file not found'));
    }

    switch (widget.map.fileType.toLowerCase()) {
      case 'jpeg':
      case 'jpg':
      case 'png':
        return Image.file(file);
      case 'svg':
        return _showLayers
            ? SvgPicture.file(file)
            : Container(
                color: Colors.grey[200],
                child: const Center(child: Text('Layers Hidden')),
              );
      case 'eps':
        // EPS files are complex, for now show a placeholder
        return Container(
          color: Colors.grey[200],
          child: const Center(child: Text('EPS file - Preview not available')),
        );
      default:
        return const Center(child: Text('Unsupported file type'));
    }
  }
}
