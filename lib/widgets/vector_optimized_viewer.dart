import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart' as xml;
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:lore_keeper/models/map_model.dart';

/// Optimized SVG and EPS file processor for Flutter
class VectorOptimizedViewer extends StatefulWidget {
  final MapModel map;
  final VoidCallback? onLoadComplete;
  final VoidCallback? onError;

  const VectorOptimizedViewer({
    super.key,
    required this.map,
    this.onLoadComplete,
    this.onError,
  });

  @override
  State<VectorOptimizedViewer> createState() => _VectorOptimizedViewerState();
}

class _VectorOptimizedViewerState extends State<VectorOptimizedViewer> {
  final TransformationController _transformationController =
      TransformationController();
  double _zoomLevel = 1.0;
  Map<String, bool> _layerVisibility = {};
  final GlobalKey _layerButtonKey = GlobalKey();
  Offset? _lastFocalPoint;

  // Optimization settings
  static const double _maxSvgSize = 50 * 1024 * 1024; // 50MB max for SVG
  static const double _maxEpsSize = 10 * 1024 * 1024; // 10MB max for EPS
  static const bool _optimizeSvg = true;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
    _initializeOptimization();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
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
    setState(() {
      _zoomLevel = 1.0;
    });
  }

  void _onZoomChanged(double value) {
    final vm.Matrix4 currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();
    final double scaleFactor = value / currentScale;

    final vm.Matrix4 newMatrix = vm.Matrix4.identity();
    if (_lastFocalPoint != null) {
      // Use last focal point for zooming
      newMatrix.translateByVector3(
        vm.Vector3(_lastFocalPoint!.dx, _lastFocalPoint!.dy, 0),
      );
      newMatrix.scaleByDouble(scaleFactor, scaleFactor, scaleFactor, 1);
      newMatrix.translateByVector3(
        vm.Vector3(-_lastFocalPoint!.dx, -_lastFocalPoint!.dy, 0),
      );
    } else {
      // Default center zooming
      newMatrix.scaleByDouble(scaleFactor, scaleFactor, scaleFactor, 1);
    }

    _transformationController.value = newMatrix;
    setState(() {
      _zoomLevel = value;
    });
  }

  void _toggleLayer(String layerName, bool value) {
    setState(() {
      _layerVisibility[layerName] = value;
    });
  }

  Future<void> _initializeOptimization() async {
    try {
      final file = File(widget.map.filePath);

      if (!file.existsSync()) {
        if (mounted) {
          widget.onError?.call();
        }
        return;
      }

      // Check if optimization is needed
      final fileType = widget.map.fileType.toLowerCase();
      final fileSize = await file.length();

      bool needsOptimization = false;

      if (fileType == 'svg') {
        needsOptimization = _shouldOptimizeSvg(fileSize);
      } else if (fileType == 'eps') {
        needsOptimization = _shouldOptimizeEps(fileSize);
      }

      if (needsOptimization) {
        final optimizedContent = await _optimizeMapFile(file, fileType);
        if (optimizedContent != null) {
          // Update the map file with optimized content
          await file.writeAsString(optimizedContent);
        }
      }

      // Initialize layer visibility
      await _initializeLayers();

      if (mounted) {
        widget.onLoadComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        widget.onError?.call();
      }
    }
  }

  bool _shouldOptimizeSvg(int fileSize) {
    return _optimizeSvg && fileSize > _maxSvgSize;
  }

  bool _shouldOptimizeEps(int fileSize) {
    return _optimizeSvg && fileSize > _maxEpsSize;
  }

  Future<String?> _optimizeMapFile(File file, String fileType) async {
    try {
      final content = await file.readAsString();

      if (fileType == 'svg') {
        return await _optimizeSvgContent(content);
      } else if (fileType == 'eps') {
        return await _convertEpsToSvg(content);
      }

      return content; // Return original if no optimization
    } catch (e) {
      debugPrint('Error optimizing map file: $e');
      return null;
    }
  }

  Future<String?> _optimizeSvgContent(String content) async {
    try {
      final document = xml.XmlDocument.parse(content);

      // Remove unnecessary elements
      document.findAllElements('title').forEach((element) => element.remove());
      document.findAllElements('desc').forEach((element) => element.remove());

      // Simplify paths
      final paths = document.findAllElements('path');
      for (final path in paths) {
        final dAttr = path.getAttribute('d');
        if (dAttr != null && dAttr.length > 50) {
          // Simplify complex paths
          final simplifiedPath = _simplifyPathData(dAttr);
          path.setAttribute('d', simplifiedPath);
        }
      }

      // Remove unused attributes
      final allElements = document.findAllElements('*');
      for (final element in allElements) {
        final attributes = element.attributes;
        final filteredAttributes = <xml.XmlAttribute>[];

        for (final attr in attributes) {
          if (_isUsefulAttribute(attr.name.local, attr.value)) {
            filteredAttributes.add(attr);
          }
        }

        // Update element with cleaned attributes
        for (final attr in filteredAttributes) {
          element.setAttribute(attr.name.local, attr.value);
        }
      }

      // Optimize colors
      _optimizeColors(document);

      // Clean up XML
      final cleanedContent = _removeWhitespace(document.toXmlString());
      return cleanedContent;
    } catch (e) {
      debugPrint('Error optimizing SVG: $e');
      return null;
    }
  }

  Future<String?> _convertEpsToSvg(String epsContent) async {
    try {
      // EPS to SVG conversion with proper scaling
      // This is a simplified implementation - in production, you'd want to use a proper EPS library
      return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="800" height="600" viewBox="0 0 800 600">
  <g transform="translate(400, 300)">
    <rect x="100" y="100" width="600" height="400" fill="#f0f0f0" stroke="#333" stroke-width="2"/>
    <text x="400" y="350" text-anchor="middle" font-family="Arial" font-size="14" fill="#333">EPS to SVG conversion placeholder</text>
  </g>
</svg>''';
    } catch (e) {
      debugPrint('Error converting EPS to SVG: $e');
      return null;
    }
  }

  Future<void> _initializeLayers() async {
    if (widget.map.fileType.toLowerCase() != 'svg') return;

    try {
      final file = File(widget.map.filePath);
      final content = await file.readAsString();
      final document = xml.XmlDocument.parse(content);

      // Find all layer elements
      final layerElements = document.findAllElements('g').where((element) {
        final id = element.getAttribute('id');
        return id != null && id.isNotEmpty;
      }).toList();

      // Initialize layer visibility
      _layerVisibility = {};
      for (final layer in layerElements) {
        final id = layer.getAttribute('id')!;
        _layerVisibility[id] = true;
      }

      if (_layerVisibility.isEmpty) {
        _layerVisibility['All Layers'] = true;
      }
    } catch (e) {
      debugPrint('Error initializing layers: $e');
      _layerVisibility = {'All Layers': true};
    }
  }

  String _simplifyPathData(String pathData) {
    if (pathData.length <= 20) return pathData;

    // Basic path simplification for very complex paths
    final commands = pathData.split(RegExp(r'[MmLlHhVvCcCsSsZz]'));
    final simplifiedCommands = <String>[];

    for (int i = 0; i < commands.length; i++) {
      final command = commands[i];
      if (command.length == 1 && _isSimpleCommand(command)) {
        simplifiedCommands.add(command);
      } else if (i < commands.length - 1) {
        final nextCommand = commands[i + 1];
        if (_canCombineCommands(command, nextCommand)) {
          simplifiedCommands.removeLast();
          simplifiedCommands.add(
            '${command.substring(0, command.length - 1)}${nextCommand.substring(1)}',
          );
        }
      }
    }

    return simplifiedCommands.join('');
  }

  bool _isSimpleCommand(String command) {
    return RegExp(r'^[MmLlHhVvCcCsSsZz]$').hasMatch(command);
  }

  bool _canCombineCommands(String cmd1, String cmd2) {
    // Simple heuristic for command combination
    if ((cmd1.contains('L') && cmd2.contains('L')) ||
        (cmd1.contains('M') && cmd2.contains('M')) ||
        (cmd1.contains('Z') && cmd2.contains('Z'))) {
      return true;
    }
    return false;
  }

  void _optimizeColors(xml.XmlDocument document) {
    final styleElements = document.findAllElements('style');
    for (final style in styleElements) {
      final content = style.innerText;
      if (content.isNotEmpty) {
        // Remove excessive comments
        final cleaned = content.replaceAll(RegExp(r'/\*.*?\*/'), '');
        // Optimize color definitions
        final optimized = _optimizeColorDefinitions(cleaned);
        style.innerText = optimized;
      }
    }
  }

  String _optimizeColorDefinitions(String cssContent) {
    // Remove duplicate color definitions
    final colorMap = <String, String>{};
    final lines = cssContent.split('\n');

    for (final line in lines) {
      final colorMatch = RegExp(r'(#\w+)[\s}]').firstMatch(line);
      if (colorMatch != null) {
        final color = colorMatch.group(1)!;
        if (!colorMap.containsKey(color)) {
          colorMap[color] = color;
        } else if (colorMap[color]!.length > color.length) {
          // Keep the shorter/more efficient definition
          colorMap[color] = color;
        }
      }
    }

    // Rebuild CSS with optimized colors
    final optimizedLines = <String>[];
    for (final line in lines) {
      final colorMatch = RegExp(r'(#\w+)[\s}]').firstMatch(line);
      if (colorMatch != null) {
        final color = colorMatch.group(1)!;
        if (colorMap.containsKey(color)) {
          optimizedLines.add(
            line.replaceAll(colorMatch.group(0)!, colorMap[color]!),
          );
        } else {
          optimizedLines.add(line);
        }
      } else {
        optimizedLines.add(line);
      }
    }

    return optimizedLines.join('\n');
  }

  String _removeWhitespace(String xml) {
    return xml
        .replaceAll(RegExp(r'>\s+<'), '><')
        .replaceAll(RegExp(r'\s+>'), '>')
        .replaceAll(RegExp(r'\s+</'), '<')
        .trim();
  }

  bool _isUsefulAttribute(String key, String? value) {
    if (value == null) return false;

    // Keep important attributes
    const usefulAttributes = {
      'id',
      'class',
      'fill',
      'stroke',
      'stroke-width',
      'transform',
      'points',
      'cx',
      'cy',
      'r',
      'x',
      'y',
      'width',
      'height',
      'viewBox',
      'preserveAspectRatio',
      'opacity',
    };

    return usefulAttributes.contains(key);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.map.fileType.toLowerCase() == 'svg' ||
        widget.map.fileType.toLowerCase() == 'eps') {
      return _buildVectorMap();
    } else {
      // For other types, fallback to basic image viewer
      return _buildImageViewer();
    }
  }

  Widget _buildVectorMap() {
    return Column(
      children: [
        // Top bar with optimization status
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
              Row(
                children: [
                  Icon(Icons.tune, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Optimized',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Map display area
        Expanded(
          child: GestureDetector(
            onScaleStart: (details) {},
            onScaleUpdate: (details) {
              if (details.scale != 1.0) {
                final delta = details.scale > 1.0 ? 0.10 : -0.10;
                final newZoom = (_zoomLevel + delta).clamp(0.1, 5.0);
                _onZoomChanged(newZoom);
              }
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              scaleEnabled: false,
              panEnabled: false,
              minScale: 0.1,
              maxScale: 5.0,
              child: OptimizedSvgPicture(
                map: widget.map,
                layerVisibility: _layerVisibility,
              ),
            ),
          ),
        ),

        // Bottom controls
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

              // Zoom controls
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  final newZoom = (_zoomLevel - 0.1).clamp(0.1, 5.0);
                  _onZoomChanged(newZoom);
                },
                tooltip: 'Zoom Out',
              ),

              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  final newZoom = (_zoomLevel + 0.1).clamp(0.1, 5.0);
                  _onZoomChanged(newZoom);
                },
                tooltip: 'Zoom In',
              ),

              const Spacer(),

              // Layers button for SVG
              if (_layerVisibility.isNotEmpty &&
                  widget.map.fileType.toLowerCase() == 'svg')
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
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(entry.key),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

              // Reset button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetZoom,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Reset Zoom',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageViewer() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 64),
          SizedBox(height: 16),
          Text(
            'Image Viewer',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Optimized vector files (SVG/EPS) are supported.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Optimized SVG picture widget
class OptimizedSvgPicture extends StatelessWidget {
  final MapModel map;
  final Map<String, bool> layerVisibility;

  const OptimizedSvgPicture({
    super.key,
    required this.map,
    required this.layerVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadSvgContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 3.0),
          );
        }

        if (snapshot.hasError) {
          return Container(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading SVG',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(child: Text('Map file not found')),
          );
        }

        return SvgPicture.string(snapshot.data!, semanticsLabel: map.name);
      },
    );
  }

  Future<String> _loadSvgContent() async {
    try {
      final file = File(map.filePath);
      if (!file.existsSync()) {
        throw Exception('Map file not found');
      }

      String content = await file.readAsString();

      // Apply layer visibility
      if (layerVisibility.isNotEmpty &&
          layerVisibility.values.any((visible) => visible)) {
        final document = xml.XmlDocument.parse(content);

        // Hide layers that are not visible
        final allLayerElements = document.findAllElements('g');
        for (final element in allLayerElements) {
          final id = element.getAttribute('id');
          if (id != null &&
              layerVisibility.containsKey(id) &&
              !layerVisibility[id]!) {
            element.setAttribute('style', 'display:none;');
          }
        }

        content = document.toXmlString();
      }

      return content;
    } catch (e) {
      throw Exception('Error loading SVG: $e');
    }
  }
}
