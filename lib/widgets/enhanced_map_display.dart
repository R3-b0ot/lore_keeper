import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:xml/xml.dart' as xml;
import 'package:lore_keeper/widgets/vector_optimized_viewer.dart';

class EnhancedMapDisplay extends StatefulWidget {
  final MapModel map;
  final bool useWebView;

  const EnhancedMapDisplay({
    super.key,
    required this.map,
    this.useWebView = false,
  });

  @override
  State<EnhancedMapDisplay> createState() => _EnhancedMapDisplayState();
}

class _EnhancedMapDisplayState extends State<EnhancedMapDisplay> {
  final TransformationController _transformationController =
      TransformationController();
  double _zoomLevel = 1.0;
  Offset? _lastFocalPoint;
  Map<String, bool> _layerVisibility = {};
  final GlobalKey _layerButtonKey = GlobalKey();
  bool _useWebView = false;

  @override
  void initState() {
    super.initState();
    _useWebView = widget.useWebView || _shouldUseWebView();
    _transformationController.addListener(_onTransformationChanged);
    _initializeLayerVisibility();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  bool _shouldUseWebView() {
    // Use WebView for complex SVGs or when GeoJSON support is needed
    final fileType = widget.map.fileType.toLowerCase();
    return fileType == 'svg' && _isComplexSvg();
  }

  bool _isComplexSvg() {
    try {
      final file = File(widget.map.filePath);
      if (!file.existsSync()) return false;

      final svgContent = file.readAsStringSync();
      final document = xml.XmlDocument.parse(svgContent);

      // Check for complex features that benefit from WebView rendering
      final hasFilters = document.findAllElements('filter').isNotEmpty;
      final hasGradients =
          document.findAllElements('linearGradient').isNotEmpty ||
          document.findAllElements('radialGradient').isNotEmpty;
      final hasMasks = document.findAllElements('mask').isNotEmpty;
      final hasComplexPaths = document.findAllElements('path').length > 50;

      return hasFilters || hasGradients || hasMasks || hasComplexPaths;
    } catch (e) {
      return false;
    }
  }

  void _initializeLayerVisibility() {
    final fileType = widget.map.fileType.toLowerCase();
    if (fileType == 'jpeg' || fileType == 'jpg' || fileType == 'png') {
      _layerVisibility = {'Background': true};
    } else if (fileType == 'svg') {
      _initializeSvgLayers();
    } else if (fileType == 'geojson') {
      _layerVisibility = {'GeoJSON': true};
    } else {
      _layerVisibility = {'All Layers': true};
    }
  }

  void _onTransformationChanged() {
    final vm.Matrix4 matrix = _transformationController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    if (scale != _zoomLevel) {
      setState(() {
        _zoomLevel = scale;
      });
    }
  }

  void _resetZoom() {
    _transformationController.value = vm.Matrix4.identity();
    _lastFocalPoint = null;
    setState(() {
      _zoomLevel = 1.0;
    });
  }

  void _onZoomChanged(double value) {
    final vm.Matrix4 currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();
    final double scaleFactor = value / currentScale;

    if (_lastFocalPoint != null) {
      final vm.Matrix4 newMatrix = currentMatrix.clone();
      newMatrix.translateByDouble(
        _lastFocalPoint!.dx,
        _lastFocalPoint!.dy,
        0,
        1,
      );
      newMatrix.scaleByDouble(scaleFactor, scaleFactor, scaleFactor, 1);
      newMatrix.translateByDouble(
        -_lastFocalPoint!.dx,
        -_lastFocalPoint!.dy,
        0,
        1,
      );
      _transformationController.value = newMatrix;
    } else {
      final vm.Matrix4 newMatrix = currentMatrix.clone();
      newMatrix.scaleByDouble(scaleFactor, scaleFactor, scaleFactor, 1);
      _transformationController.value = newMatrix;
    }

    setState(() {
      _zoomLevel = value;
    });
  }

  void _onScrollWheel(PointerScrollEvent event) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);

    final delta = event.scrollDelta.dy > 0 ? -0.10 : 0.10;
    final vm.Matrix4 currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();
    final double newScale = (currentScale + delta).clamp(0.1, 5.0);

    if (newScale == currentScale) return;

    final vm.Matrix4 invertedMatrix = vm.Matrix4.copy(currentMatrix);
    invertedMatrix.invert();
    final vm.Vector4 transformedPoint4 = invertedMatrix.transform(
      vm.Vector4(localPosition.dx, localPosition.dy, 0, 1),
    );
    final Offset focalPoint = Offset(transformedPoint4.x, transformedPoint4.y);

    _lastFocalPoint = focalPoint;

    final vm.Matrix4 newMatrix = currentMatrix.clone();
    newMatrix.translateByDouble(focalPoint.dx, focalPoint.dy, 0, 1);
    newMatrix.scaleByDouble(
      newScale / currentScale,
      newScale / currentScale,
      newScale / currentScale,
      1,
    );
    newMatrix.translateByDouble(-focalPoint.dx, -focalPoint.dy, 0, 1);

    _transformationController.value = newMatrix;

    setState(() {
      _zoomLevel = newScale;
    });
  }

  void _toggleLayer(String layerName, bool value) {
    setState(() {
      _layerVisibility[layerName] = value;
    });
  }

  void _initializeSvgLayers() {
    try {
      final file = File(widget.map.filePath);
      if (!file.existsSync()) {
        _layerVisibility = {'All Layers': true};
        return;
      }

      final svgContent = file.readAsStringSync();
      final document = xml.XmlDocument.parse(svgContent);

      final layerElements = document
          .findAllElements('g')
          .where(
            (element) =>
                element.getAttribute('id') != null &&
                element.getAttribute('id')!.isNotEmpty,
          );

      if (layerElements.isEmpty) {
        _layerVisibility = {'All Layers': true};
      } else {
        _layerVisibility = {};
        for (final element in layerElements) {
          final id = element.getAttribute('id')!;
          _layerVisibility[id] = true;
        }
      }
    } catch (e) {
      _layerVisibility = {'All Layers': true};
    }
  }

  void _toggleRenderer() {
    setState(() {
      _useWebView = !_useWebView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar with map name and renderer toggle
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
              // Renderer toggle for SVG files
              if (widget.map.fileType.toLowerCase() == 'svg')
                PopupMenuButton<String>(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_useWebView ? Icons.web : Icons.image),
                      const SizedBox(width: 4),
                      Text(_useWebView ? 'WebView' : 'Native'),
                    ],
                  ),
                  onSelected: (value) {
                    if (value == 'toggle') {
                      _toggleRenderer();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz),
                          SizedBox(width: 8),
                          Text('Switch Renderer'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // Map display area
        Expanded(child: _buildMapContent()),
        // Bottom bar with zoom controls
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildMapContent() {
    final file = File(widget.map.filePath);

    if (!file.existsSync()) {
      return const Center(child: Text('Map file not found'));
    }

    final fileType = widget.map.fileType.toLowerCase();

    // Use WebView for SVG when enabled or for GeoJSON
    if ((_useWebView && fileType == 'svg') || fileType == 'geojson') {
      return _buildWebViewContent(file, fileType);
    }

    // Use native Flutter rendering
    if (_useWebView) {
      return GestureDetector(
        onScaleStart: (details) {},
        onScaleUpdate: (details) {
          if (details.scale != 1.0) {
            final delta = details.scale > 1.0 ? 0.10 : -0.10;
            final currentScale = _transformationController.value
                .getMaxScaleOnAxis();
            final newScale = (currentScale + delta).clamp(0.1, 5.0);
            if (newScale != currentScale) {
              final scaleFactor = newScale / currentScale;
              final newMatrix = _transformationController.value.clone();
              newMatrix.scaleByDouble(scaleFactor, scaleFactor, scaleFactor, 1);
              _transformationController.value = newMatrix;
              setState(() {
                _zoomLevel = newScale;
              });
            }
          } else {
            final translation = details.focalPointDelta;
            final newMatrix = _transformationController.value.clone();
            newMatrix.translateByDouble(translation.dx, translation.dy, 0, 1);
            _transformationController.value = newMatrix;
          }
        },
        child: Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              _onScrollWheel(pointerSignal);
            }
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            scaleEnabled: false,
            panEnabled: false,
            minScale: 0.1,
            maxScale: 5.0,
            child: Center(child: _buildNativeMapContent(file)),
          ),
        ),
      );
    }

    // Default native rendering with full interaction
    return GestureDetector(
      onScaleStart: (details) {},
      onScaleUpdate: (details) {
        if (details.scale != 1.0) {
          final delta = details.scale > 1.0 ? 0.10 : -0.10;
          final currentScale = _transformationController.value
              .getMaxScaleOnAxis();
          final newScale = (currentScale + delta).clamp(0.1, 5.0);
          if (newScale != currentScale) {
            final scaleFactor = newScale / currentScale;
            final newMatrix = _transformationController.value.clone();
            newMatrix.scaleByDouble(scaleFactor, scaleFactor, scaleFactor, 1);
            _transformationController.value = newMatrix;
            setState(() {
              _zoomLevel = newScale;
            });
          }
        } else {
          final translation = details.focalPointDelta;
          final newMatrix = _transformationController.value.clone();
          newMatrix.translateByDouble(translation.dx, translation.dy, 0, 1);
          _transformationController.value = newMatrix;
        }
      },
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            _onScrollWheel(pointerSignal);
          }
        },
        child: InteractiveViewer(
          transformationController: _transformationController,
          scaleEnabled: false,
          panEnabled: false,
          minScale: 0.1,
          maxScale: 5.0,
          child: Center(child: _buildNativeMapContent(file)),
        ),
      ),
    );
  }

  Widget _buildWebViewContent(File file, String fileType) {
    if (fileType == 'geojson') {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64),
            SizedBox(height: 16),
            Text('GeoJSON support coming soon'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        VectorOptimizedViewer(
          map: widget.map,
          onLoadComplete: () {
            debugPrint('SVG optimized map ready');
          },
          onError: () {
            debugPrint('SVG optimized map error');
          },
        ),
        // Native zoom controls overlay
        if (!_useWebView)
          Positioned(bottom: 80, right: 16, child: _buildZoomControls()),
      ],
    );
  }

  Widget _buildNativeMapContent(File file) {
    switch (widget.map.fileType.toLowerCase()) {
      case 'jpeg':
      case 'jpg':
      case 'png':
        return _layerVisibility['Background'] == true
            ? Image.file(file)
            : Container(
                color: Colors.grey[200],
                child: const Center(child: Text('Background Hidden')),
              );
      case 'svg':
        return _buildSvgContent(file);
      case 'eps':
        return _layerVisibility['All Layers'] == true
            ? Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Text('EPS file - Preview not available'),
                ),
              )
            : Container(
                color: Colors.grey[200],
                child: const Center(child: Text('Layers Hidden')),
              );
      default:
        return const Center(child: Text('Unsupported file type'));
    }
  }

  Widget _buildSvgContent(File file) {
    try {
      final svgContent = file.readAsStringSync();
      final document = xml.XmlDocument.parse(svgContent);

      final layerElements = document
          .findAllElements('g')
          .where(
            (element) =>
                element.getAttribute('id') != null &&
                element.getAttribute('id')!.isNotEmpty,
          );

      if (layerElements.isEmpty ||
          _layerVisibility.values.every((visible) => visible)) {
        return SvgPicture.string(svgContent);
      }

      for (final element in layerElements) {
        final id = element.getAttribute('id')!;
        if (_layerVisibility[id] == false) {
          element.setAttribute('style', 'display:none;');
        }
      }

      final modifiedSvg = document.toXmlString();
      return SvgPicture.string(modifiedSvg);
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Text('Error loading SVG')),
      );
    }
  }

  Widget _buildBottomControls() {
    return Container(
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
          // Zoom percentage
          Text(
            '${(_zoomLevel * 100).round()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          // Zoom slider
          SizedBox(
            width: 120,
            child: Slider(
              value: _zoomLevel,
              min: 0.1,
              max: 5.0,
              divisions: 49,
              onChanged: _onZoomChanged,
            ),
          ),
          const SizedBox(width: 8),
          // Zoom out button
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              final newZoom = (_zoomLevel - 0.05).clamp(0.1, 5.0);
              _onZoomChanged(newZoom);
            },
            tooltip: 'Zoom Out',
          ),
          // Zoom in button
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              final newZoom = (_zoomLevel + 0.05).clamp(0.1, 5.0);
              _onZoomChanged(newZoom);
            },
            tooltip: 'Zoom In',
          ),
          const Spacer(),
          // Layers button
          if (_layerVisibility.length > 1)
            TextButton.icon(
              key: _layerButtonKey,
              icon: const Icon(Icons.layers),
              label: const Text('Layers'),
              onPressed: () {
                final RenderBox renderBox =
                    _layerButtonKey.currentContext!.findRenderObject()
                        as RenderBox;
                final Offset offset = renderBox.localToGlobal(Offset.zero);
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    offset.dx,
                    offset.dy + renderBox.size.height,
                    offset.dx + renderBox.size.width,
                    offset.dy + renderBox.size.height,
                  ),
                  items: _layerVisibility.entries.map((entry) {
                    return PopupMenuItem(
                      child: Row(
                        children: [
                          Checkbox(
                            value: entry.value,
                            onChanged: (bool? value) {
                              if (value != null) {
                                _toggleLayer(entry.key, value);
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: entry.key == 'Background'
                                ? const TextStyle(fontStyle: FontStyle.italic)
                                : null,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          // Reset button
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
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              final newZoom = (_zoomLevel + 0.1).clamp(0.1, 5.0);
              _onZoomChanged(newZoom);
            },
            tooltip: 'Zoom In',
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              final newZoom = (_zoomLevel - 0.1).clamp(0.1, 5.0);
              _onZoomChanged(newZoom);
            },
            tooltip: 'Zoom Out',
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetZoom,
            tooltip: 'Reset Zoom',
          ),
        ],
      ),
    );
  }
}
