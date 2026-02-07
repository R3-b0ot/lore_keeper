import 'package:flutter/material.dart';
import 'package:lore_keeper/models/country_data.dart';
import 'package:lore_keeper/theme/app_colors.dart';

/// Data models for the locations
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

/// The Selection Modal Dialog
class ModernCountrySelectionDialog extends StatefulWidget {
  final LocationData? initialSelection;
  final Function(LocationData) onSelected;
  const ModernCountrySelectionDialog({
    super.key,
    this.initialSelection,
    required this.onSelected,
  });

  @override
  State<ModernCountrySelectionDialog> createState() =>
      _ModernCountrySelectionDialogState();
}

class _ModernCountrySelectionDialogState
    extends State<ModernCountrySelectionDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  late List<LocationData> _countries;
  late List<LocationData> _fictional;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize Official Countries from CountryData
    _countries = CountryData.countries
        .map(
          (c) => LocationData(label: c.label, code: c.code, isOfficial: true),
        )
        .toList();

    // Initialize Fictional Places from CountryData
    _fictional = CountryData.fictionalPlaces
        .map(
          (f) => LocationData(
            label: f.label,
            region: f.region,
            type: f.type,
            color: f.color,
            icon: CountryData.getIconData(f.iconName),
            isOfficial: false,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedTextColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final borderColor = Theme.of(context).colorScheme.outline;

    return Container(
      width:
          600, // Fixed width for desktop/tablet, constrained by dialog on mobile
      height:
          MediaQuery.of(context).size.height *
          0.7, // Slightly smaller than before
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32), // All-around rounded corners
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Directory',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${_countries.length} UN States & ${_fictional.length} Fictional Worlds',
                      style: TextStyle(color: mutedTextColor, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.bgMain
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    foregroundColor: textColor,
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: isDark
                ? AppColors.bgMain
                : Theme.of(context).colorScheme.surfaceContainerLow,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: mutedTextColor,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.1,
              ),
              tabs: const [
                Tab(text: 'OFFICIAL REGISTRY'),
                Tab(text: 'USER CREATED'),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search locations...',
                hintStyle: TextStyle(
                  color: mutedTextColor.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
                prefixIcon: Icon(Icons.search, color: mutedTextColor),
                filled: true,
                fillColor: isDark
                    ? AppColors.bgMain
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_countries, textColor, mutedTextColor, borderColor),
                _buildList(_fictional, textColor, mutedTextColor, borderColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<LocationData> source,
    Color textColor,
    Color mutedTextColor,
    Color borderColor,
  ) {
    final filtered = source
        .where(
          (l) => l.label.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final isSelected = widget.initialSelection?.label == item.label;

        return GestureDetector(
          onTap: () {
            widget.onSelected(item);
            Navigator.pop(context);
          },
          child: LocationTile(
            item: item,
            isSelected: isSelected,
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            borderColor: borderColor,
          ),
        );
      },
    );
  }
}

/// Individual List Item with the Makeshift Flag background
class LocationTile extends StatelessWidget {
  final LocationData item;
  final bool isSelected;
  final Color textColor;
  final Color mutedTextColor;
  final Color borderColor;

  const LocationTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.textColor,
    required this.mutedTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                  ? const Color(0xFF0F172A)
                  : const Color(
                      0xFF0F172A,
                    )) // Keep selection dark for contrast with flag
            : (isDark
                  ? Colors.black45
                  : Theme.of(context).colorScheme.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: borderColor.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background "Flag"
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 180,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.transparent, Colors.white],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Opacity(
                opacity: 0.3,
                child: item.isOfficial && item.code != null
                    ? Image.network(
                        'https://flagcdn.com/w320/${item.code!.toLowerCase()}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            CustomPaint(
                              painter: MakeshiftFlagPainter(color: Colors.grey),
                            ),
                      )
                    : CustomPaint(
                        painter: MakeshiftFlagPainter(
                          color: item.color ?? Colors.grey,
                        ),
                      ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        item.color?.withValues(alpha: 0.2) ??
                        Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon ?? Icons.map,
                    color: isSelected ? AppColors.primaryLight : Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors
                            .white, // Text on flag background needs to be white/light
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      item.isOfficial
                          ? (item.code ?? 'UN')
                          : '${item.type} • ${item.region}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter to replicate the "Makeshift Flag" geometric pattern
class MakeshiftFlagPainter extends CustomPainter {
  final Color color;
  MakeshiftFlagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Fill base
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw Stripes (Pattern)
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
