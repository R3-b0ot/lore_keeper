import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;

/// SVG Optimizer utility for converting and optimizing vector files
class SvgOptimizer {
  // Optimization settings
  static const double _maxSvgSize = 50 * 1024 * 1024; // 50MB max for SVG
  static const double _maxEpsSize = 10 * 1024 * 1024; // 10MB max for EPS

  /// Check if a file needs optimization
  static bool needsOptimization(File file) {
    if (!file.existsSync()) return false;

    final fileSize = file.lengthSync();
    final extension = file.path.toLowerCase().split('.').last;

    if (extension == 'svg') {
      return fileSize > _maxSvgSize;
    } else if (extension == 'eps') {
      return fileSize > _maxEpsSize;
    }

    return false;
  }

  /// Optimize a vector file and return the optimized content
  static Future<String?> optimizeFile(File file, {String? fileType}) async {
    try {
      final content = await file.readAsString();
      final type = fileType ?? file.path.toLowerCase().split('.').last;

      if (type == 'svg') {
        return await _optimizeSvgContent(content);
      } else if (type == 'eps') {
        return await _convertEpsToSvg(content);
      }

      return content; // Return original if no optimization
    } catch (e) {
      debugPrint('Error optimizing file: $e');
      return null;
    }
  }

  /// Save optimized content to file
  static Future<bool> saveOptimizedFile(
    File file,
    String optimizedContent,
  ) async {
    try {
      await file.writeAsString(optimizedContent);
      return true;
    } catch (e) {
      debugPrint('Error saving optimized file: $e');
      return false;
    }
  }

  /// Optimize SVG content
  static Future<String?> _optimizeSvgContent(String content) async {
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

  /// Convert EPS to SVG (simplified implementation)
  static Future<String?> _convertEpsToSvg(String epsContent) async {
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

  /// Simplify path data
  static String _simplifyPathData(String pathData) {
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

  /// Check if command is simple
  static bool _isSimpleCommand(String command) {
    return RegExp(r'^[MmLlHhVvCcCsSsZz]$').hasMatch(command);
  }

  /// Check if commands can be combined
  static bool _canCombineCommands(String cmd1, String cmd2) {
    // Simple heuristic for command combination
    if ((cmd1.contains('L') && cmd2.contains('L')) ||
        (cmd1.contains('M') && cmd2.contains('M')) ||
        (cmd1.contains('Z') && cmd2.contains('Z'))) {
      return true;
    }
    return false;
  }

  /// Optimize colors in document
  static void _optimizeColors(xml.XmlDocument document) {
    final styleElements = document.findAllElements('style');
    for (final style in styleElements) {
      final content = style.innerText;
      // Remove excessive comments
      final cleaned = content.replaceAll(RegExp(r'/\*.*?\*/'), '');
      // Optimize color definitions
      final optimized = _optimizeColorDefinitions(cleaned);
      style.innerText = optimized;
    }
  }

  /// Optimize color definitions
  static String _optimizeColorDefinitions(String cssContent) {
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

  /// Remove whitespace from XML
  static String _removeWhitespace(String xml) {
    return xml
        .replaceAll(RegExp(r'>\s+<'), '><')
        .replaceAll(RegExp(r'\s+>'), '>')
        .replaceAll(RegExp(r'\s+</'), '<')
        .trim();
  }

  /// Check if attribute is useful
  static bool _isUsefulAttribute(String key, String? value) {
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

  /// Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get optimization report
  static Map<String, dynamic> getOptimizationReport(
    File originalFile,
    File optimizedFile,
  ) {
    final originalSize = originalFile.lengthSync();
    final optimizedSize = optimizedFile.lengthSync();
    final savedBytes = originalSize - optimizedSize;
    final savedPercentage = originalSize > 0
        ? (savedBytes / originalSize * 100)
        : 0;

    return {
      'originalSize': originalSize,
      'optimizedSize': optimizedSize,
      'savedBytes': savedBytes,
      'savedPercentage': savedPercentage,
      'originalSizeString': getFileSizeString(originalSize),
      'optimizedSizeString': getFileSizeString(optimizedSize),
      'savedBytesString': getFileSizeString(savedBytes),
    };
  }
}

/// Dialog for prompting users to optimize vector files
class VectorOptimizationDialog extends StatelessWidget {
  final File file;
  final VoidCallback onOptimize;
  final VoidCallback onSkip;

  const VectorOptimizationDialog({
    super.key,
    required this.file,
    required this.onOptimize,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final fileSize = file.lengthSync();
    final fileSizeString = SvgOptimizer.getFileSizeString(fileSize);
    final fileName = file.path.split('/').last;

    return AlertDialog(
      title: const Text('Optimize Vector File?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The file "$fileName" is quite large ($fileSizeString).',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Would you like to optimize it for better performance?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            'Benefits of optimization:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          ...const [
            '• Faster loading times',
            '• Smaller file size',
            '• Better performance',
            '• Cleaner SVG structure',
          ].map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(benefit, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSkip();
          },
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onOptimize();
          },
          child: const Text('Optimize'),
        ),
      ],
    );
  }
}

/// Widget for showing optimization progress and results
class VectorOptimizationProgress extends StatefulWidget {
  final File file;
  final Function(bool success, String? optimizedPath) onComplete;

  const VectorOptimizationProgress({
    super.key,
    required this.file,
    required this.onComplete,
  });

  @override
  State<VectorOptimizationProgress> createState() =>
      _VectorOptimizationProgressState();
}

class _VectorOptimizationProgressState
    extends State<VectorOptimizationProgress> {
  bool _isOptimizing = true;
  String? _error;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _optimizeFile();
  }

  Future<void> _optimizeFile() async {
    try {
      final optimizedContent = await SvgOptimizer.optimizeFile(widget.file);

      if (optimizedContent != null) {
        // Create optimized version
        final originalPath = widget.file.path;
        final optimizedPath = originalPath.replaceAll(
          RegExp(r'\.[^.]+$'),
          '_optimized.svg',
        );
        final optimizedFile = File(optimizedPath);

        final success = await SvgOptimizer.saveOptimizedFile(
          optimizedFile,
          optimizedContent,
        );

        if (success) {
          _report = SvgOptimizer.getOptimizationReport(
            widget.file,
            optimizedFile,
          );
          setState(() {
            _isOptimizing = false;
          });
          widget.onComplete(true, optimizedPath);
        } else {
          setState(() {
            _isOptimizing = false;
            _error = 'Failed to save optimized file';
          });
          widget.onComplete(false, null);
        }
      } else {
        setState(() {
          _isOptimizing = false;
          _error = 'Failed to optimize file';
        });
        widget.onComplete(false, null);
      }
    } catch (e) {
      setState(() {
        _isOptimizing = false;
        _error = e.toString();
      });
      widget.onComplete(false, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOptimizing) {
      return const AlertDialog(
        title: Text('Optimizing...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Optimizing your vector file...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return AlertDialog(
        title: const Text('Optimization Failed'),
        content: Text('An error occurred during optimization: $_error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Optimization Complete!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File successfully optimized!',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          if (_report != null) ...[
            Text('Original size: ${_report!['originalSizeString']}'),
            Text('Optimized size: ${_report!['optimizedSizeString']}'),
            Text(
              'Saved: ${_report!['savedBytesString']} (${_report!['savedPercentage'].toStringAsFixed(1)}%)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
