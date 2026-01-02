import 'package:flutter/material.dart';

class MapCreationResult {
  final String name;
  final String style;
  final String resolution;
  final String aspectRatio;
  final String gridType;

  MapCreationResult({
    required this.name,
    required this.style,
    required this.resolution,
    required this.aspectRatio,
    required this.gridType,
  });
}

class MapCreatorDialog extends StatefulWidget {
  const MapCreatorDialog({super.key});

  @override
  State<MapCreatorDialog> createState() => _MapCreatorDialogState();
}

class _MapCreatorDialogState extends State<MapCreatorDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _mapName = '';
  String? _selectedStyle;
  String? _selectedResolution;
  String? _selectedAspectRatio;
  String? _selectedGridType;

  final List<Map<String, String>> _styles = [
    {
      'name': 'Fantasy',
      'description': 'Medieval fantasy world with castles, dragons, and magic.',
    },
    {
      'name': 'SciFi',
      'description':
          'Futuristic sci-fi universe with spaceships, aliens, and technology.',
    },
    {
      'name': 'Mercator',
      'description': 'Traditional world map projection style.',
    },
    {
      'name': 'Isometric',
      'description': '3D-like isometric view for detailed landscapes.',
    },
    {
      'name': 'Topographic',
      'description': 'Elevation-focused map with contour lines.',
    },
  ];

  final List<String> _resolutions = [
    '1K (Low)',
    '2K (Medium)',
    '3K (High)',
    '4K (Ultra)',
  ];
  final List<String> _aspectRatios = [
    '1:1',
    '2:1',
    '3:2',
    '16:9',
    '4:3',
    '1:2',
  ];
  final List<String> _gridTypes = [
    'Square',
    'Hex',
    'Flat Head Hex',
    'Trapezoid',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Map Creator',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Step 1: Choose Style'),
                Tab(text: 'Step 2: Scene Settings'),
                Tab(text: 'Step 3: Preview'),
                Tab(text: 'Step 4: Create'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStyleSelection(),
                  _buildSceneSettings(),
                  _buildPreview(),
                  _buildCreate(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _canCreate ? _createMap : null,
                  child: const Text('Create Map'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleSelection() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: _styles.length,
            itemBuilder: (context, index) {
              final style = _styles[index];
              final isSelected = _selectedStyle == style['name'];
              return ListTile(
                title: Text(style['name']!),
                selected: isSelected,
                onTap: () => setState(() => _selectedStyle = style['name']),
              );
            },
          ),
        ),
        const VerticalDivider(),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Map Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Enter map name...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _mapName = value),
                ),
                const SizedBox(height: 24),
                if (_selectedStyle != null) ...[
                  Text(
                    _selectedStyle!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _styles.firstWhere(
                      (s) => s['name'] == _selectedStyle,
                    )['description']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ] else
                  const Center(child: Text('Select a style to view details')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSceneSettings() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resolution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _resolutions.map((res) {
              return ChoiceChip(
                label: Text(res),
                selected: _selectedResolution == res,
                onSelected: (selected) =>
                    setState(() => _selectedResolution = selected ? res : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aspect Ratio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _aspectRatios.map((ratio) {
              return ChoiceChip(
                label: Text(ratio),
                selected: _selectedAspectRatio == ratio,
                onSelected: (selected) => setState(
                  () => _selectedAspectRatio = selected ? ratio : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Grid Type',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _gridTypes.map((gridType) {
              return ChoiceChip(
                label: Text(gridType),
                selected: _selectedGridType == gridType,
                onSelected: (selected) => setState(
                  () => _selectedGridType = selected ? gridType : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return const Center(child: Text('Preview functionality coming soon...'));
  }

  Widget _buildCreate() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Ready to create your map!'),
          const SizedBox(height: 16),
          if (_mapName.isNotEmpty) Text('Name: $_mapName'),
          if (_selectedStyle != null) Text('Style: $_selectedStyle'),
          if (_selectedResolution != null)
            Text('Resolution: $_selectedResolution'),
          if (_selectedAspectRatio != null)
            Text('Aspect Ratio: $_selectedAspectRatio'),
          if (_selectedGridType != null) Text('Grid Type: $_selectedGridType'),
        ],
      ),
    );
  }

  bool get _canCreate =>
      _mapName.isNotEmpty &&
      _selectedStyle != null &&
      _selectedResolution != null &&
      _selectedAspectRatio != null &&
      _selectedGridType != null;

  void _createMap() {
    final result = MapCreationResult(
      name: _mapName,
      style: _selectedStyle!,
      resolution: _selectedResolution!,
      aspectRatio: _selectedAspectRatio!,
      gridType: _selectedGridType!,
    );
    Navigator.of(context).pop(result);
  }
}
