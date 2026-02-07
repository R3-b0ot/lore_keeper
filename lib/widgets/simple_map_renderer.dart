import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lore_keeper/models/map_model.dart';

/// Simple image/SVG renderer as fallback for WebView issues
class SimpleMapRenderer extends StatefulWidget {
  final MapModel map;
  final VoidCallback? onLoadComplete;
  final VoidCallback? onError;

  const SimpleMapRenderer({
    super.key,
    required this.map,
    this.onLoadComplete,
    this.onError,
  });

  @override
  State<SimpleMapRenderer> createState() => _SimpleMapRendererState();
}

class _SimpleMapRendererState extends State<SimpleMapRenderer> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  Future<void> _loadMap() async {
    try {
      final file = io.File(widget.map.filePath);

      if (!file.existsSync()) {
        _setError('Map file not found');
        return;
      }

      final fileType = widget.map.fileType.toLowerCase();

      if (fileType == 'svg') {
        // Validate SVG
        final content = await file.readAsString();
        if (!content.contains('<svg')) {
          _setError('Invalid SVG file');
          return;
        }
      } else if (!['jpg', 'jpeg', 'png'].contains(fileType)) {
        _setError('Unsupported file type: $fileType');
        return;
      }

      setState(() {
        _isLoading = false;
      });

      widget.onLoadComplete?.call();
    } catch (e) {
      _setError('Failed to load map: $e');
    }
  }

  void _setError(String error) {
    setState(() {
      _errorMessage = error;
      _isLoading = false;
    });
    widget.onError?.call();
  }

  Widget _buildMapContent() {
    final file = io.File(widget.map.filePath);
    final fileType = widget.map.fileType.toLowerCase();

    if (fileType == 'svg') {
      return SvgPicture.string(
        file.readAsStringSync(),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      );
    } else if (['jpg', 'jpeg', 'png'].contains(fileType)) {
      return Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Failed to load image'),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.help_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text('Unsupported file type: $fileType'),
              const SizedBox(height: 8),
              const Text('Supported: SVG, JPG, JPEG, PNG'),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading map',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading map...'),
            ],
          ),
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.1,
      maxScale: 5.0,
      child: _buildMapContent(),
    );
  }
}
