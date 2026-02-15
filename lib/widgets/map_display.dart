import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:url_launcher/url_launcher.dart';

class MapDisplay extends StatefulWidget {
  final MapModel map;

  const MapDisplay({super.key, required this.map});

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  double _zoomLevel = 1.0;
  InAppWebViewController? _webViewController;
  String? _windowsError;
  String? _inlineSvgMarkup;
  String? _inlineSvgError;
  bool _inlineSvgLoading = false;
  String? _webView2RuntimePath;
  final Uri _webView2DownloadUrl = Uri.parse(
    'https://go.microsoft.com/fwlink/p/?LinkId=2124703',
  );
  final TransformationController _nativeZoomController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _webView2RuntimePath = _findWebView2RuntimePath();
      _windowsError = _webView2RuntimePath == null
          ? 'WebView2 runtime was not detected.'
          : null;
    }
    _loadInlineSvgIfNeeded();
  }

  @override
  void didUpdateWidget(covariant MapDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.map.fileType != widget.map.fileType ||
        oldWidget.map.filePath != widget.map.filePath) {
      _loadInlineSvgIfNeeded(forceReload: true);
    }
  }

  @override
  void dispose() {
    _nativeZoomController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
    });
    _applyZoom();
  }

  void _onZoomChanged(double value) {
    setState(() {
      _zoomLevel = value;
    });
    _applyZoom();
  }

  void _applyZoom() {
    if (_useNativePreview()) {
      _nativeZoomController.value = Matrix4.identity()
        ..scaleByDouble(_zoomLevel, _zoomLevel, _zoomLevel, 1.0);
      return;
    }
    final controller = _webViewController;
    if (controller == null) return;
    controller.evaluateJavascript(
      source: 'setZoom(${_zoomLevel.toStringAsFixed(3)});',
    );
  }

  bool _useNativePreview() {
    return Platform.isWindows &&
        _webView2RuntimePath == null &&
        (_isSvgType(widget.map.fileType) || _isRasterType(widget.map.fileType));
  }

  String _cssColor(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }

  bool _isRasterType(String fileType) {
    final lower = fileType.toLowerCase();
    return const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(lower);
  }

  bool _isSvgType(String fileType) => fileType.toLowerCase() == 'svg';

  bool _isEpsType(String fileType) => fileType.toLowerCase() == 'eps';

  Future<void> _loadInlineSvgIfNeeded({bool forceReload = false}) async {
    if (!_isSvgType(widget.map.fileType)) {
      if (mounted) {
        setState(() {
          _inlineSvgMarkup = null;
          _inlineSvgError = null;
          _inlineSvgLoading = false;
        });
      }
      return;
    }
    if (_inlineSvgLoading && !forceReload) return;

    final file = File(widget.map.filePath);
    if (!file.existsSync()) {
      if (!mounted) return;
      setState(() {
        _inlineSvgMarkup = null;
        _inlineSvgError = 'Map file not found.';
        _inlineSvgLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _inlineSvgLoading = true;
      _inlineSvgError = null;
    });

    try {
      final raw = await file.readAsString();
      final sanitized = raw
          .replaceAll(RegExp(r'<\\?xml[^>]*\\?>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '');
      if (!mounted) return;
      setState(() {
        _inlineSvgMarkup = sanitized;
        _inlineSvgLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inlineSvgMarkup = null;
        _inlineSvgError = e.toString();
        _inlineSvgLoading = false;
      });
    }
  }

  Future<void> _openWebView2Installer() async {
    await launchUrl(_webView2DownloadUrl, mode: LaunchMode.externalApplication);
  }

  String? _findWebView2RuntimePath() {
    if (!Platform.isWindows) return null;

    final localAppData = Platform.environment['LOCALAPPDATA'];
    final candidates = <String>[
      r'C:\Program Files (x86)\Microsoft\EdgeWebView\Application',
      r'C:\Program Files\Microsoft\EdgeWebView\Application',
      if (localAppData != null && localAppData.isNotEmpty)
        '$localAppData\\Microsoft\\EdgeWebView\\Application',
    ];

    for (final root in candidates) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;

      final versionDirs =
          dir
              .listSync()
              .whereType<Directory>()
              .map((entry) => entry.path)
              .where(
                (path) => RegExp(r'\\d+\\.\\d+\\.\\d+\\.\\d+$').hasMatch(path),
              )
              .toList()
            ..sort(
              (a, b) => _compareVersionStrings(
                a.split(Platform.pathSeparator).last,
                b.split(Platform.pathSeparator).last,
              ),
            );

      for (final versionDir in versionDirs.reversed) {
        final exePath =
            '$versionDir${Platform.pathSeparator}msedgewebview2.exe';
        if (File(exePath).existsSync()) {
          return versionDir;
        }
      }
    }

    return null;
  }

  int _compareVersionStrings(String a, String b) {
    final aParts = a.split('.').map(int.tryParse).toList();
    final bParts = b.split('.').map(int.tryParse).toList();
    final length = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;

    for (var i = 0; i < length; i++) {
      final aValue = i < aParts.length ? (aParts[i] ?? 0) : 0;
      final bValue = i < bParts.length ? (bParts[i] ?? 0) : 0;
      if (aValue != bValue) {
        return aValue.compareTo(bValue);
      }
    }
    return 0;
  }

  String _buildMapHtml({
    required String fileUrl,
    required String fileType,
    required String backgroundColor,
    String? inlineSvgMarkup,
    String? inlineSvgError,
  }) {
    final lower = fileType.toLowerCase();
    final isRaster = _isRasterType(fileType);
    final isSvg = _isSvgType(fileType);
    final isEps = _isEpsType(fileType);

    final encodedFileUrl = jsonEncode(fileUrl);
    final encodedFileType = jsonEncode(lower);
    final encodedInlineSvg = inlineSvgMarkup != null
        ? jsonEncode(inlineSvgMarkup)
        : 'null';
    final encodedInlineError = inlineSvgError != null
        ? jsonEncode(inlineSvgError)
        : 'null';

    String content;
    if (isRaster || isSvg) {
      content = '<div id="map-host"></div>';
    } else if (isEps) {
      content =
          '''
<object id="map" data="$fileUrl" type="application/postscript">
  <div class="fallback">EPS preview may not be supported on this platform.</div>
</object>
''';
    } else {
      content =
          '''
<div class="fallback">Unsupported file type: $fileType</div>
''';
    }

    return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes" />
    <style>
      html, body {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        background: $backgroundColor;
        overflow: auto;
      }
      #wrap {
        width: 100%;
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
      }
      #map {
        width: 100%;
        height: 100%;
        max-width: 100%;
        max-height: 100%;
        object-fit: contain;
      }
      .fallback {
        font-family: sans-serif;
        color: #b3b3b3;
        padding: 16px;
        text-align: center;
      }
      #panel {
        position: absolute;
        top: 12px;
        right: 12px;
        width: 220px;
        max-height: calc(100% - 24px);
        background: rgba(20, 20, 20, 0.85);
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 12px;
        padding: 12px;
        color: #f0f0f0;
        font-family: sans-serif;
        display: none;
        overflow: hidden;
      }
      #panel.light {
        background: rgba(250, 250, 250, 0.95);
        color: #111;
        border-color: rgba(0, 0, 0, 0.08);
      }
      #panel h3 {
        margin: 0 0 8px 0;
        font-size: 13px;
        font-weight: 600;
      }
      #panel-list {
        overflow-y: auto;
        max-height: 220px;
        padding-right: 6px;
        margin-bottom: 8px;
      }
      #panel-list label {
        display: flex;
        gap: 8px;
        align-items: center;
        margin-bottom: 6px;
        font-size: 12px;
      }
      #panel-actions {
        display: flex;
        gap: 8px;
      }
      #panel-actions button {
        flex: 1;
        border: 1px solid rgba(255, 255, 255, 0.2);
        background: transparent;
        color: inherit;
        font-size: 11px;
        padding: 6px;
        border-radius: 6px;
        cursor: pointer;
      }
      #panel-empty {
        font-size: 12px;
        opacity: 0.7;
      }
      #map-host svg {
        width: 100%;
        height: 100%;
        max-width: 100%;
        max-height: 100%;
      }
      #map-host img {
        width: 100%;
        height: 100%;
        object-fit: contain;
      }
    </style>
  </head>
  <body>
    <div id="wrap">
      $content
    </div>
    <div id="panel">
      <h3>Map Objects</h3>
      <div id="panel-list"></div>
      <div id="panel-empty">No named SVG objects.</div>
      <div id="panel-actions">
        <button id="show-all">Show all</button>
        <button id="hide-all">Hide all</button>
      </div>
    </div>
    <script>
      const fileUrl = $encodedFileUrl;
      const fileType = $encodedFileType;
      const inlineSvg = $encodedInlineSvg;
      const inlineSvgError = $encodedInlineError;
      const panel = document.getElementById('panel');
      const panelList = document.getElementById('panel-list');
      const panelEmpty = document.getElementById('panel-empty');
      const showAllButton = document.getElementById('show-all');
      const hideAllButton = document.getElementById('hide-all');
      const mapHost = document.getElementById('map-host');
      const isLight = window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches;
      if (isLight) panel.classList.add('light');

      const objectMap = new Map();
      const checkboxMap = new Map();

      function setZoom(z) { document.body.style.zoom = z; }

      function clearPanel() {
        panelList.innerHTML = '';
        panelEmpty.style.display = 'block';
        objectMap.clear();
        checkboxMap.clear();
      }

      function setObjectVisible(id, visible) {
        const target = objectMap.get(id);
        if (!target) return;
        target.style.display = visible ? '' : 'none';
      }

      function bindPanelActions() {
        showAllButton.onclick = () => {
          checkboxMap.forEach((checkbox, id) => {
            checkbox.checked = true;
            setObjectVisible(id, true);
          });
        };
        hideAllButton.onclick = () => {
          checkboxMap.forEach((checkbox, id) => {
            checkbox.checked = false;
            setObjectVisible(id, false);
          });
        };
      }

      function buildPanel(svgRoot) {
        clearPanel();
        if (!svgRoot) {
          panelEmpty.textContent = 'No SVG content found.';
          return;
        }

        const candidates = Array.from(svgRoot.querySelectorAll('[id]'))
          .filter(el => el.id && el.tagName.toLowerCase() !== 'defs' && !el.closest('defs'));

        const unique = new Map();
        for (const el of candidates) {
          if (!unique.has(el.id)) unique.set(el.id, el);
        }

        if (unique.size === 0) {
          panelEmpty.textContent = 'No named SVG objects.';
          return;
        }

        panelEmpty.style.display = 'none';
        panel.style.display = 'block';

        unique.forEach((el, id) => {
          objectMap.set(id, el);
          const label = document.createElement('label');
          const checkbox = document.createElement('input');
          checkbox.type = 'checkbox';
          checkbox.checked = true;
          checkbox.onchange = () => setObjectVisible(id, checkbox.checked);
          checkboxMap.set(id, checkbox);
          const text = document.createElement('span');
          text.textContent = id;
          label.appendChild(checkbox);
          label.appendChild(text);
          panelList.appendChild(label);
        });

        bindPanelActions();
      }

      function showFallback(message) {
        mapHost.innerHTML = `<div class="fallback">\${message}</div>`;
      }

      if (fileType === 'svg') {
        if (inlineSvgError) {
          showFallback(inlineSvgError);
        } else if (!inlineSvg) {
          showFallback('Loading SVG...');
        } else {
          mapHost.innerHTML = inlineSvg;
          const svgRoot = mapHost.querySelector('svg');
          if (svgRoot) {
            svgRoot.setAttribute('id', 'map');
            svgRoot.setAttribute('preserveAspectRatio', 'xMidYMid meet');
          }
          buildPanel(svgRoot);
        }
      } else if (${isRaster ? 'true' : 'false'}) {
        mapHost.innerHTML = `<img id="map" src="\${fileUrl}" alt="map" />`;
      } else if (fileType === 'eps') {
        panel.style.display = 'block';
        panelEmpty.textContent = 'EPS layers cannot be toggled.';
      }
    </script>
  </body>
</html>
''';
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
            ],
          ),
        ),
        // Map display area
        Expanded(child: _buildMapContent()),
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
                icon: const Icon(LucideIcons.zoomOut),
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
                icon: const Icon(LucideIcons.zoomIn),
                onPressed: () {
                  final newZoom = (_zoomLevel + 0.1).clamp(0.1, 5.0);
                  _onZoomChanged(newZoom);
                },
                tooltip: 'Zoom In',
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                icon: const Icon(LucideIcons.refreshCw),
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

    if (_isSvgType(widget.map.fileType)) {
      if (_inlineSvgLoading && _inlineSvgMarkup == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_inlineSvgMarkup == null && _inlineSvgError != null) {
        return Center(child: Text(_inlineSvgError!));
      }
    }

    if (_useNativePreview()) {
      return _buildNativePreview(file);
    }
    if (Platform.isWindows && _webView2RuntimePath == null) {
      return _buildWindowsMissingWebView2();
    }

    final fileUrl = Uri.file(widget.map.filePath).toString();
    final dirUrl = Uri.file(
      file.parent.path.endsWith(Platform.pathSeparator)
          ? file.parent.path
          : '${file.parent.path}${Platform.pathSeparator}',
    );
    final background = _cssColor(Theme.of(context).colorScheme.surface);
    final html = _buildMapHtml(
      fileUrl: fileUrl,
      fileType: widget.map.fileType,
      backgroundColor: background,
      inlineSvgMarkup: _inlineSvgMarkup,
      inlineSvgError: _inlineSvgError,
    );

    return InAppWebView(
      key: ValueKey(widget.map.filePath),
      initialData: InAppWebViewInitialData(
        data: html,
        baseUrl: WebUri.uri(dirUrl),
        mimeType: 'text/html',
        encoding: 'utf-8',
      ),
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
        allowFileAccess: true,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        supportZoom: true,
        builtInZoomControls: true,
        displayZoomControls: false,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStop: (controller, url) {
        _applyZoom();
      },
    );
  }

  Widget _buildWindowsMissingWebView2() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circleAlert, size: 28),
            const SizedBox(height: 12),
            const Text(
              'Map preview is unavailable on this device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _windowsError ?? 'WebView2 runtime is missing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (_webView2RuntimePath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Detected WebView2 at:\n$_webView2RuntimePath',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'WebView2 is required to preview SVG and EPS on Windows.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openWebView2Installer,
              icon: Icon(LucideIcons.download),
              label: Text('Download WebView2'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativePreview(File file) {
    final Widget content = _isSvgType(widget.map.fileType)
        ? SvgPicture.file(file, fit: BoxFit.contain)
        : Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Text('Unable to load map image.'));
            },
          );

    return InteractiveViewer(
      transformationController: _nativeZoomController,
      minScale: 0.1,
      maxScale: 5.0,
      panEnabled: true,
      scaleEnabled: true,
      child: Center(child: content),
    );
  }
}
