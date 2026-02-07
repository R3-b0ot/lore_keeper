import 'package:flutter/material.dart';

class MapViewerDemoScreen extends StatefulWidget {
  const MapViewerDemoScreen({super.key});

  @override
  State<MapViewerDemoScreen> createState() => _MapViewerDemoScreenState();
}

class _MapViewerDemoScreenState extends State<MapViewerDemoScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final MapVectorViewerController _svgController = MapVectorViewerController();
  final MapVectorViewerController _geoJsonController =
      MapVectorViewerController();

  // Sample SVG data
  final String _sampleSvg = '''
<svg width="400" height="400" viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#ff7e5f;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#feb47b;stop-opacity:1" />
    </linearGradient>
    <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
      <feOffset dx="2" dy="2" result="offsetblur"/>
      <feComponentTransfer>
        <feFuncA type="linear" slope="0.2"/>
      </feComponentTransfer>
      <feMerge> 
        <feMergeNode/>
        <feMergeNode in="SourceGraphic"/> 
      </feMerge>
    </filter>
  </defs>
  
  <!-- Background -->
  <rect width="400" height="400" fill="#f0f8ff"/>
  
  <!-- Map elements -->
  <g id="terrain">
    <rect x="50" y="300" width="300" height="80" fill="#8B4513" opacity="0.7"/>
    <ellipse cx="200" cy="280" rx="80" ry="40" fill="#228B22" opacity="0.6"/>
  </g>
  
  <g id="water">
    <path d="M 100 200 Q 200 150 300 200 T 300 250 Q 200 300 100 250 Z" 
          fill="#4682B4" opacity="0.7"/>
    <circle cx="150" cy="220" r="8" fill="#87CEEB"/>
    <circle cx="250" cy="230" r="6" fill="#87CEEB"/>
  </g>
  
  <g id="roads">
    <path d="M 50 350 L 350 350" stroke="#333" stroke-width="4" stroke-dasharray="5,5"/>
    <path d="M 200 50 L 200 380" stroke="#333" stroke-width="3" stroke-dasharray="5,5"/>
    <path d="M 100 150 Q 200 200 300 150" stroke="#666" stroke-width="2" fill="none"/>
  </g>
  
  <g id="buildings" filter="url(#shadow)">
    <rect x="80" y="120" width="60" height="80" fill="url(#grad1)" rx="5"/>
    <rect x="260" y="100" width="80" height="100" fill="url(#grad1)" rx="5"/>
    <rect x="170" y="160" width="40" height="60" fill="url(#grad1)" rx="5"/>
  </g>
  
  <g id="labels">
    <text x="110" y="110" font-family="Arial, sans-serif" font-size="12" fill="#333">City Hall</text>
    <text x="280" y="90" font-family="Arial, sans-serif" font-size="12" fill="#333">Library</text>
    <text x="175" y="150" font-family="Arial, sans-serif" font-size="10" fill="#333">Shop</text>
  </g>
</svg>
  ''';

  // Sample GeoJSON data
  final String _sampleGeoJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "name": "Central Park",
        "type": "park"
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [[
          [-74.0, 40.8],
          [-73.9, 40.8],
          [-73.9, 40.7],
          [-74.0, 40.7],
          [-74.0, 40.8]
        ]]
      }
    },
    {
      "type": "Feature",
      "properties": {
        "name": "Main Street",
        "type": "road"
      },
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [-74.05, 40.75],
          [-73.95, 40.75]
        ]
      }
    },
    {
      "type": "Feature",
      "properties": {
        "name": "City Hall",
        "type": "building"
      },
      "geometry": {
        "type": "Point",
        "coordinates": [-74.0, 40.75]
      }
    }
  ]
}
  ''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Vector Viewer Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'SVG Viewer', icon: Icon(Icons.image)),
            Tab(text: 'GeoJSON Viewer', icon: Icon(Icons.map)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSvgTab(), _buildGeoJsonTab()],
      ),
    );
  }

  Widget _buildSvgTab() {
    return Column(
      children: [
        // Controls
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _svgController.updateMapData(_sampleSvg, type: 'svg'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Load Sample SVG'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _svgController.clearMap(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ),
            ],
          ),
        ),
        // Map viewer
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.layers, size: 64),
                const SizedBox(height: 16),
                const Text('SVG Optimizer Demo'),
                const SizedBox(height: 8),
                const Text(
                  'WebView removed - Use Map Creator to import SVG files',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SVG Optimizer Active!')),
                    );
                  },
                  child: const Text('Test Optimization'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeoJsonTab() {
    return Column(
      children: [
        // Controls
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _geoJsonController.updateMapData(
                    _sampleGeoJson,
                    type: 'geojson',
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Load Sample GeoJSON'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _geoJsonController.clearMap(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ),
            ],
          ),
        ),
        // Map viewer
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map, size: 64),
                const SizedBox(height: 16),
                const Text('GeoJSON Support'),
                const SizedBox(height: 8),
                const Text('GeoJSON support coming in future update'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GeoJSON Coming Soon!')),
                    );
                  },
                  child: const Text('Coming Soon'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Simple controller class to manage MapVectorViewer instances
class MapVectorViewerController {
  void updateMapData(String data, {String type = 'svg'}) {
    // This would typically hold a reference to the MapVectorViewer
    // For demo purposes, this is a placeholder
  }

  void clearMap() {
    // This would typically hold a reference to the MapVectorViewer
    // For demo purposes, this is a placeholder
  }
}
