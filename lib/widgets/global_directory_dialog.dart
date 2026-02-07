import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

class GlobalDirectoryDialog extends StatefulWidget {
  final Function(String) onSelected;

  const GlobalDirectoryDialog({super.key, required this.onSelected});

  static Future<void> show(
    BuildContext context, {
    required Function(String) onSelected,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 100),
      pageBuilder: (context, anim1, anim2) =>
          GlobalDirectoryDialog(onSelected: onSelected),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12 * anim1.value,
            sigmaY: 12 * anim1.value,
          ),
          child: Transform.scale(
            scale: 0.95 + (0.05 * anim1.value),
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: anim1,
                curve: const Interval(0, 1, curve: Curves.easeOut),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<GlobalDirectoryDialog> createState() => _GlobalDirectoryDialogState();
}

class _GlobalDirectoryDialogState extends State<GlobalDirectoryDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Theme accessors
  Color _primaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  Color _surfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  Color _onSurfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  Color _onSurfaceVariant(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  Color _containerColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;
  Color _containerColorHigh(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHigh;

  List<dynamic> _countries = [];
  List<dynamic> _filteredCountries = [];
  final List<Map<String, String>> _fictionalPlaces = [
    {
      'label': 'Atlantis',
      'region': 'Atlantic Ocean',
      'type': 'Mythical',
      'icon': 'anchor',
      'color': 'cyan', // mapped to Tailwind colors below
    },
    {
      'label': 'Eldorado',
      'region': 'South America',
      'type': 'Mythical',
      'icon': 'sparkles',
      'color': 'yellow',
    },
    {
      'label': 'Shangri-La',
      'region': 'Himalayas',
      'type': 'Utopian',
      'icon': 'mountain',
      'color': 'emerald',
    },
    {
      'label': 'Neverland',
      'region': 'Second Star',
      'type': 'Fantasy',
      'icon': 'moon',
      'color': 'indigo',
    },
    {
      'label': 'Wakanda',
      'region': 'East Africa',
      'type': 'Hidden City',
      'icon': 'zap',
      'color': 'purple',
    },
    {
      'label': 'Camelot',
      'region': 'Great Britain',
      'type': 'Legendary',
      'icon': 'sword',
      'color': 'red',
    },
    {
      'label': 'Narnia',
      'region': 'Wardrobe',
      'type': 'Parallel World',
      'icon': 'castle',
      'color': 'blue',
    },
    {
      'label': 'Gotham City',
      'region': 'United States',
      'type': 'Metropolis',
      'icon': 'building',
      'color': 'slate',
    },
    {
      'label': 'Westeros',
      'region': 'Known World',
      'type': 'Continent',
      'icon': 'ghost',
      'color': 'zinc',
    },
    {
      'label': 'Middle-earth',
      'region': 'Arda',
      'type': 'Continent',
      'icon': 'trees',
      'color': 'green',
    },
    {
      'label': 'Hogwarts',
      'region': 'Scotland',
      'type': 'Academy',
      'icon': 'castle',
      'color': 'amber',
    },
    {
      'label': 'Tatooine',
      'region': 'Outer Rim',
      'type': 'Planet',
      'icon': 'compass',
      'color': 'orange',
    },
  ];
  List<Map<String, String>> _filteredFictional = [];
  final ScrollController _officialController = ScrollController();
  final ScrollController _fictionalController = ScrollController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredFictional = List.from(_fictionalPlaces);
    _fetchCountries();
    _searchController.addListener(_onSearch);
  }

  Future<void> _fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse('https://restcountries.com/v3.1/all?fields=name,cca2'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        data.sort(
          (a, b) => (a['name']['common'] as String).compareTo(
            b['name']['common'] as String,
          ),
        );
        if (mounted) {
          setState(() {
            _countries = data;
            _filteredCountries = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (_tabController.index == 0) {
        _filteredCountries = _countries.where((c) {
          return (c['name']['common'] as String).toLowerCase().contains(query);
        }).toList();
      } else {
        _filteredFictional = _fictionalPlaces.where((p) {
          return p['label']!.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _officialController.dispose();
    _fictionalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 85% screen height
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 448, // max-w-md
          constraints: BoxConstraints(maxHeight: maxHeight),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceColor(context),
            borderRadius: BorderRadius.circular(24), // rounded-3xl
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25), // shadow-2xl
                blurRadius: 50,
                offset: const Offset(0, 25),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias, // overflow-hidden
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Global Directory',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20, // text-xl
                            fontWeight: FontWeight.w900, // font-black
                            color: _onSurfaceColor(context),
                            letterSpacing: -0.5, // tracking-tight
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '195 UN States & Fictional Worlds',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12, // text-xs
                            fontWeight: FontWeight.w500, // font-medium
                            color: _onSurfaceVariant(context),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          _onSurfaceVariant(context),
                          BlendMode.srcIn,
                        ),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _containerColor(context),
                        highlightColor: _containerColorHigh(context),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainer.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTabButton('Official Registry', 0)),
                    Expanded(child: _buildTabButton('User Created', 1)),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _containerColorHigh(context), // bg-slate-100
                    borderRadius: BorderRadius.circular(16), // rounded-2xl
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>',
                          width: 16,
                          height: 16,
                          colorFilter: ColorFilter.mode(
                            _onSurfaceVariant(context),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      hintText: _tabController.index == 0
                          ? 'Search countries...'
                          : 'Search lore...',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        color: _onSurfaceVariant(
                          context,
                        ).withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: _onSurfaceColor(context), // text-slate-800
                    ),
                  ),
                ),
              ),

              // List Content
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildCountryList(), _buildFictionalList()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.index = index;
          _onSearch();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? _primaryColor(context) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12, // text-xs
            fontWeight: FontWeight.w900, // font-black
            letterSpacing: 2.0, // tracking-widest
            color: isActive
                ? _primaryColor(context)
                : _onSurfaceVariant(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredCountries.isEmpty) return _buildEmptyState();

    return Scrollbar(
      controller: _officialController,
      thumbVisibility: true,
      thickness: 4,
      radius: const Radius.circular(10),
      child: ListView.separated(
        controller: _officialController,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: _filteredCountries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final country = _filteredCountries[index];
          final name = country['name']['common'] as String;
          final code = (country['cca2'] as String).toLowerCase();

          return _buildListItem(
            label: name,
            subtitle: code.toUpperCase(),
            isOfficial: true,
            code: code,
            onTap: () => widget.onSelected(name),
          );
        },
      ),
    );
  }

  Widget _buildFictionalList() {
    if (_filteredFictional.isEmpty) return _buildEmptyState();

    return Scrollbar(
      controller: _fictionalController,
      thumbVisibility: true,
      thickness: 4,
      radius: const Radius.circular(10),
      child: ListView.separated(
        controller: _fictionalController,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: _filteredFictional.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final place = _filteredFictional[index];

          return _buildListItem(
            label: place['label']!,
            subtitle: '${place['type']} • ${place['region']}',
            isOfficial: false,
            iconData: place['icon'],
            color: place['color'],
            onTap: () => widget.onSelected(place['label']!),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: 0.2,
          child: SvgPicture.string(
            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>',
            width: 48,
            height: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No territories found',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildListItem({
    required String label,
    required String subtitle,
    required bool isOfficial,
    String? code,
    String? iconData,
    String? color,
    required VoidCallback onTap,
  }) {
    // Color mapping from Tailwind names to Color values
    Color getColor(String? name) {
      switch (name) {
        case 'cyan':
          return Colors.cyan[500]!;
        case 'yellow':
          return Colors.yellow[500]!;
        case 'emerald':
          return Colors.green[500]!; // closest Material
        case 'indigo':
          return Colors.indigo[500]!;
        case 'purple':
          return Colors.purple[600]!;
        case 'red':
          return Colors.red[500]!;
        case 'blue':
          return Colors.blue[400]!;
        case 'slate':
          return const Color(0xFF334155); // slate-700
        case 'zinc':
          return const Color(0xFF71717A); // zinc-500
        case 'green':
          return const Color(0xFF15803D); // green-700
        case 'amber':
          return const Color(0xFF92400E); // amber-800
        case 'orange':
          return Colors.orange[400]!;
        default:
          return Colors.blue;
      }
    }

    final accentColor = isOfficial ? Colors.transparent : getColor(color);

    return _TerritoryListItem(
      label: label,
      subtitle: subtitle,
      isOfficial: isOfficial,
      code: code,
      iconData: iconData,
      accentColor: accentColor,
      onTap: onTap,
    );
  }
}

class _TerritoryListItem extends StatefulWidget {
  final String label;
  final String subtitle;
  final bool isOfficial;
  final String? code;
  final String? iconData;
  final Color accentColor;
  final VoidCallback onTap;

  const _TerritoryListItem({
    required this.label,
    required this.subtitle,
    required this.isOfficial,
    this.code,
    this.iconData,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_TerritoryListItem> createState() => _TerritoryListItemState();
}

class _TerritoryListItemState extends State<_TerritoryListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final containerColor = Theme.of(context).colorScheme.surfaceContainer;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 80),
          scale: _isHovered ? 1.01 : 1.0,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            constraints: const BoxConstraints(minHeight: 100),
            decoration: BoxDecoration(
              color: _isHovered ? Colors.black : containerColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isHovered ? 0.2 : 0.1),
                  blurRadius: _isHovered ? 8 : 4,
                  offset: Offset(0, _isHovered ? 4 : 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Full-height Background Overlay (Fixed width viewport)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 240, // Consistent viewport width reduces over-zoom
                  child: widget.isOfficial && widget.code != null
                      ? SvgPicture.network(
                          'https://flagcdn.com/${widget.code}.svg',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          placeholderBuilder: (context) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            child: Icon(
                              Icons.public,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 32,
                            ),
                          ),
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                child: Icon(
                                  Icons.flag,
                                  color: widget.accentColor.withValues(
                                    alpha: 0.7,
                                  ),
                                  size: 32,
                                ),
                              ),
                        )
                      : CustomPaint(
                          size: Size.infinite,
                          painter: StripedPainter(color: widget.accentColor),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Icon Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isOfficial
                              ? Colors.white.withValues(alpha: 0.15)
                              : widget.accentColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: widget.isOfficial ? 0.05 : 0.1,
                            ),
                          ),
                        ),
                        child: SvgPicture.string(
                          _getSvgPath(widget.iconData ?? 'mapPin'),
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.label,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: onSurfaceVariant.withValues(alpha: 0.8),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSvgPath(String name) {
    switch (name) {
      case 'anchor':
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22V8m0 0 5 5m-5-5-5 5M5 12a7 7 0 0 0 14 0"/></svg>';
      case 'sparkles':
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 3 1.912 5.813a2 2 0 0 0 1.275 1.275L21 12l-5.813 1.912a2 2 0 0 0-1.275 1.275L12 21l-1.912-5.813a2 2 0 0 0-1.275-1.275L3 12l5.813-1.912a2 2 0 0 0 1.275-1.275L12 3Z"/></svg>';
      case 'mountain':
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m8 3 4 8 5-5 5 15H2L8 3z"/></svg>';
      case 'moon':
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/></svg>';
      case 'zap':
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2 L3 14 L12 14 L11 22 L21 10 L12 10 Z"/></svg>';
      case 'sword':
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="14.5 17.5 3 6 3 3 6 3 17.5 14.5"/><line x1="13" y1="19" x2="19" y2="13"/><line x1="16" y1="16" x2="20" y2="20"/><line x1="19" y1="21" x2="21" y2="19"/></svg>';
      case 'castle':
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 20v-9H2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2Z"/><path d="M18 11V4H6v7"/><path d="M15 11h-2a2 2 0 0 1-2-2V4"/><path d="M11 11h-2a2 2 0 0 0-2-2V4"/><path d="M15 22v-4a3 3 0 0 0-6 0v4"/></svg>';
      case 'building':
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="20" x="4" y="2" rx="2" ry="2"/><path d="M9 22v-4h6v4"/><path d="M8 6h.01"/><path d="M16 6h.01"/><path d="M8 10h.01"/><path d="M16 10h.01"/><path d="M8 14h.01"/><path d="M16 14h.01"/></svg>';
      case 'ghost':
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 10h.01"/><path d="M15 10h.01"/><path d="M12 2a8 8 0 0 0-8 8v12l3-3 2.5 2.5L12 19l2.5 2.5L17 19l3 3V10a8 8 0 0 0-8-8z"/></svg>';
      case 'trees':
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 10v7a3 3 0 0 1-3 3H4"/><path d="M14 10v7a3 3 0 0 0 3 3h3"/><path d="M12 2v18"/><path d="M12 8l-5-2"/><path d="M12 12l5-2"/><path d="M12 16l-5-2"/></svg>';
      case 'compass':
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/></svg>';
      default:
        return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>';
    }
  }
}

// Custom Painter for the "Makeshift flag" pattern defined in CSS
// repeating-linear-gradient(45deg, rgba(255,255,255,0.1) 0px, ... 10px, transparent 10px, ... 20px)
class StripedPainter extends CustomPainter {
  final Color color;

  StripedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = color,
    );

    // Draw stripes
    // Simplified Stripe Drawing logic:
    // Draw diagonal lines or polygons
    // To match 45deg repeating pattern:
    const double stripeWidth = 10;
    const double gap = 10;

    // We can use a shader or simple loop drawing for 1:1 match
    final path = Path();
    // Logic: calculate number of stripes needed to cover diag
    for (double i = -size.height; i < size.width; i += (stripeWidth + gap)) {
      // Draw a 45 degree stripe
      // Points: (i, 0), (i+w, 0), (i+w-h, h), (i-h, h)
      // Actually simply:
      path.moveTo(i, 0);
      path.lineTo(i + stripeWidth, 0);
      path.lineTo(i + stripeWidth - size.height, size.height);
      path.lineTo(i - size.height, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
