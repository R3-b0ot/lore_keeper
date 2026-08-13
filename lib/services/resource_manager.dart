import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ResourceManager {
  static final ResourceManager _instance = ResourceManager._internal();
  factory ResourceManager() => _instance;
  ResourceManager._internal();

  String? _appSupportDir;
  final Map<String, PictureInfo> _svgCache = {};

  Future<void> initialize() async {
    final dir = await getApplicationSupportDirectory();
    _appSupportDir = dir.path;
    await _ensureCustomAssetsDirectory();
  }

  Future<void> _ensureCustomAssetsDirectory() async {
    if (_appSupportDir == null) return;
    final customDir = Directory(p.join(_appSupportDir!, 'custom_assets'));
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }
  }

  /// Copies an external file into the app's custom assets directory
  /// Returns the relative path within the app's support directory.
  Future<String> importCustomAsset(File sourceFile) async {
    if (_appSupportDir == null) await initialize();
    
    final extension = p.extension(sourceFile.path);
    final fileName = '${const Uuid().v4()}$extension';
    final targetPath = p.join(_appSupportDir!, 'custom_assets', fileName);
    
    await sourceFile.copy(targetPath);
    return 'custom_assets/$fileName';
  }

  /// Resolves an asset path to a usable File object or bundle path
  /// Returns an absolute file path or an asset path.
  Future<String> resolveAssetPath(String path) async {
    if (path.startsWith('custom_assets/')) {
      if (_appSupportDir == null) await initialize();
      return p.join(_appSupportDir!, path);
    }
    // Otherwise assume it's a bundled asset
    return path;
  }

  /// Loads an SVG into a dart:ui PictureInfo for fast canvas rendering.
  Future<PictureInfo?> getSvgPicture(String assetPath) async {
    if (_svgCache.containsKey(assetPath)) {
      return _svgCache[assetPath];
    }
    try {
      final absolutePath = await resolveAssetPath(assetPath);
      PictureInfo pictureInfo;
      if (absolutePath.startsWith('assets/')) {
        pictureInfo = await vg.loadPicture(SvgAssetLoader(absolutePath), null);
      } else {
        pictureInfo = await vg.loadPicture(SvgFileLoader(File(absolutePath)), null);
      }
      _svgCache[assetPath] = pictureInfo;
      return pictureInfo;
    } catch (e) {
      debugPrint('Error loading SVG: $e');
      return null;
    }
  }

  /// Returns the cached SVG picture if it's already loaded, otherwise null.
  PictureInfo? getSvgPictureSync(String assetPath) {
    return _svgCache[assetPath];
  }

  void clearCache() {
    for (final info in _svgCache.values) {
      info.picture.dispose();
    }
    _svgCache.clear();
  }
}
