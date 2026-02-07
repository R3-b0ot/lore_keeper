import 'package:flutter/material.dart';

/// Data model for location selection
class LocationData {
  final String label;
  final String? code; // For countries
  final String? region; // For fictional
  final String? type; // For fictional
  final Color? color; // For fictional
  final IconData? icon;
  final bool isOfficial;

  LocationData({
    required this.label,
    this.code,
    this.region,
    this.type,
    this.color,
    this.icon,
    this.isOfficial = true,
  });
}

/// Country/Fictional Location Selector Dialog
class CountryLocationSelector extends StatefulWidget {
  final String? initialLocation;
  final Function(LocationData) onSelected;

  const CountryLocationSelector({
    super.key,
    this.initialLocation,
    required this.onSelected,
  });

  @override
  State<CountryLocationSelector> createState() =>
      _CountryLocationSelectorState();
}

class _CountryLocationSelectorState extends State<CountryLocationSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Sample data - replace with your actual data
  final List<LocationData> _countries = [
    LocationData(label: 'United States', code: 'US'),
    LocationData(label: 'United Kingdom', code: 'GB'),
    LocationData(label: 'Canada', code: 'CA'),
    LocationData(label: 'France', code: 'FR'),
    LocationData(label: 'Germany', code: 'DE'),
    LocationData(label: 'Japan', code: 'JP'),
    LocationData(label: 'Australia', code: 'AU'),
    LocationData(label: 'Brazil', code: 'BR'),
    LocationData(label: 'India', code: 'IN'),
  ];

  final List<LocationData> _fictional = [
    LocationData(
      label: 'Atlantis',
      region: 'Atlantic',
      type: 'Mythical',
      color: Colors.cyan,
      icon: Icons.anchor,
      isOfficial: false,
    ),
    LocationData(
      label: 'Wakanda',
      region: 'Africa',
      type: 'Hidden',
      color: Colors.purple,
      icon: Icons.bolt,
      isOfficial: false,
    ),
    LocationData(
      label: 'Gotham City',
      region: 'USA',
      type: 'Metropolis',
      color: Colors.blueGrey,
      icon: Icons.business,
      isOfficial: false,
    ),
    LocationData(
      label: 'Middle-earth',
      region: 'Arda',
      type: 'Continent',
      color: Colors.green,
      icon: Icons.forest,
      isOfficial: false,
    ),
    LocationData(
      label: 'Tatooine',
      region: 'Outer Rim',
      type: 'Planet',
      color: Colors.orange,
      icon: Icons.wb_sunny,
      isOfficial: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxWidth: 448,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Global Directory',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '195 UN States & Fictional Worlds',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),

            // Tab switcher
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
                tabs: const [
                  Tab(text: 'Official Registry'),
                  Tab(text: 'User Created'),
                ],
              ),
            ),

            // Search bar
            Container(
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: _tabController.index == 0
                      ? 'Search countries...'
                      : 'Search lore...',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(48, 20, 16, 20),
                ),
              ),
            ),

            // List content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildList(_countries), _buildList(_fictional)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<LocationData> source) {
    final filtered = source
        .where(
          (l) => l.label.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No territories found',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final isSelected = widget.initialLocation == item.label;

        return GestureDetector(
          onTap: () {
            widget.onSelected(item);
            Navigator.of(context).pop();
          },
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.black87
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          item.color?.withValues(alpha: 0.2) ??
                          Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon ?? Icons.public,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          item.isOfficial
                              ? item.code!
                              : '${item.type} • ${item.region}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.grey.shade400
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
