import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lore_keeper/models/map_model.dart';

class MapViewer extends StatefulWidget {
  final MapModel map;

  const MapViewer({super.key, required this.map});

  @override
  State<MapViewer> createState() => _MapViewerState();
}

class _MapViewerState extends State<MapViewer> {
  bool _showLayers = true;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        children: [
          // Toolbar for SVG controls
          if (widget.map.fileType.toLowerCase() == 'svg' ||
              widget.map.fileType.toLowerCase() == 'eps')
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  const Text(
                    'Layers:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Show All'),
                    selected: _showLayers,
                    onSelected: (selected) {
                      setState(() {
                        _showLayers = selected;
                      });
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    onPressed: () {
                      // Zoom in functionality would be implemented here
                      // For now, just reset to fit
                      _transformationController.value = Matrix4.identity();
                    },
                    tooltip: 'Fit to Screen',
                  ),
                ],
              ),
            ),
          // Main viewer area
          Expanded(
            child: Center(
              child: widget.map.filePath.isNotEmpty
                  ? _buildMapContent()
                  : const Text('No map image available'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    final fileType = widget.map.fileType.toLowerCase();

    if (fileType == 'svg' || fileType == 'eps') {
      // SVG/EPS viewer with layer controls
      return InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(20.0),
        minScale: 0.1,
        maxScale: 5.0,
        child: SvgPicture.file(
          File(widget.map.filePath),
          fit: BoxFit.contain,
          placeholderBuilder: (BuildContext context) => Container(
            padding: const EdgeInsets.all(30.0),
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    } else if (fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png') {
      // Flat image viewer with zoom
      return InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(20.0),
        minScale: 0.1,
        maxScale: 5.0,
        child: Image.file(
          File(widget.map.filePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Error loading map image');
          },
        ),
      );
    } else {
      return const Text('Unsupported file type');
    }
  }
}
