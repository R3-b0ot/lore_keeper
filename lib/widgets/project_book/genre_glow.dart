// lib/widgets/project_book/genre_glow.dart
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A fully data-driven description of how a project's genre lights up its
/// book: the cover palette, the escaping light and the particle sparks.
///
/// Every painter in this feature consumes a single [GenreGlowStyle] so a new
/// genre is purely data — no rendering code needs to change to support it.
class GenreGlowStyle {
  const GenreGlowStyle({
    required this.coverColors,
    required this.core,
    required this.mid,
    required this.edge,
    required this.accent,
    required this.particleColor,
    required this.svgType,
    this.particles = const [],
    this.icon = LucideIcons.bookOpen,
    this.isSmoke = false,
    this.intensity = 1.0,
  });

  /// The SVG symbol type from the prototype (e.g. 'sword', 'sparkle')
  final String svgType;

  /// The exact RGB color mapped from the prototype for particles and glow
  final Color particleColor;

  /// Diagonal gradient painted across the cover board.
  final List<Color> coverColors;

  /// Brightest hue of the escaping light (innermost ring of the glow).
  final Color core;

  /// Mid-tone of the escaping light.
  final Color mid;

  /// Outer fade of the escaping light.
  final Color edge;

  /// Metallic accent used for the cover ring, tag and icon tint.
  final Color accent;

  /// Spark colors used by the particle field; falls back to
  /// `[core, accent]` when empty.
  final List<Color> particles;

  /// Genre glyph stamped on the cover.
  final IconData icon;

  /// When true the glow reads as smoke drifting from the opening (noir)
  /// rather than as hot light.
  final bool isSmoke;

  /// Global strength multiplier applied on top of derived intensities.
  final double intensity;

  /// Returns a copy with only [intensity] replaced.
  GenreGlowStyle copyWith({double? intensity}) => GenreGlowStyle(
    coverColors: coverColors,
    core: core,
    mid: mid,
    edge: edge,
    accent: accent,
    particleColor: particleColor,
    svgType: svgType,
    particles: particles,
    icon: icon,
    isSmoke: isSmoke,
    intensity: intensity ?? this.intensity,
  );
}

/// A registry mapping project genre strings to [GenreGlowStyle]s.
///
/// Matching is fuzzy (case-insensitive substring) so full dialog labels such
/// as "Science Fiction" or "Crime and Mystery" resolve to their palettes, and
/// any unregistered genre falls back to the gilded default. New genres can be
/// plugged in at runtime via [GenreGlowRegistry.register] — exact matches win
/// over keyword matching.
class GenreGlowRegistry {
  GenreGlowRegistry._();

  static const GenreGlowStyle _default = GenreGlowStyle(
    coverColors: [Color(0xFFbfa054), Color(0xFF4a4231)],
    core: Color(0xFFE8D392),
    mid: Color(0xFFB08F4A),
    edge: Color(0xFF2A2418),
    accent: Color(0xFFE8D392),
    particleColor: Color.fromARGB(255, 200, 200, 200),
    svgType: 'star',
    icon: LucideIcons.bookOpen,
  );

  static const GenreGlowStyle _action = GenreGlowStyle(
    coverColors: [Color(0xFFC2410C), Color(0xFF2A0A03)],
    core: Color(0xFFFDBA74),
    mid: Color(0xFFEA580C),
    edge: Color(0xFF431407),
    accent: Color(0xFFFED7AA),
    particleColor: Color.fromARGB(255, 255, 215, 0),
    svgType: 'sword',
    icon: LucideIcons.sword,
  );

  static const GenreGlowStyle _classic = GenreGlowStyle(
    coverColors: [Color(0xFFbfa054), Color(0xFF4a4231)],
    core: Color(0xFFF0F0E6),
    mid: Color(0xFFDCDCCA),
    edge: Color(0xFF333330),
    accent: Color(0xFFF0F0E6),
    particleColor: Color.fromARGB(255, 240, 240, 230),
    svgType: 'quill',
    icon: LucideIcons.feather,
  );

  static const GenreGlowStyle _contemporary = GenreGlowStyle(
    coverColors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
    core: Color(0xFF64C8FF),
    mid: Color(0xFF3BA4E6),
    edge: Color(0xFF0F2D4A),
    accent: Color(0xFF64C8FF),
    particleColor: Color.fromARGB(255, 100, 200, 255),
    svgType: 'star',
    icon: LucideIcons.star,
  );

  static const GenreGlowStyle _crime = GenreGlowStyle(
    coverColors: [Color(0xFF4F46E5), Color(0xFF171044)],
    core: Color(0xFFDC1414),
    mid: Color(0xFFB01010),
    edge: Color(0xFF2A0505),
    accent: Color(0xFFDC1414),
    particleColor: Color.fromARGB(255, 220, 20, 20),
    svgType: 'magnifier',
    icon: LucideIcons.search,
  );

  static const GenreGlowStyle _dystopian = GenreGlowStyle(
    coverColors: [Color(0xFF4B5563), Color(0xFF111827)],
    core: Color(0xFF969696),
    mid: Color(0xFF707070),
    edge: Color(0xFF202020),
    accent: Color(0xFF969696),
    particleColor: Color.fromARGB(255, 150, 150, 150),
    svgType: 'gear',
    icon: LucideIcons.settings,
  );

  static const GenreGlowStyle _fantasy = GenreGlowStyle(
    coverColors: [Color(0xFF6D28D9), Color(0xFF1E1B4B)],
    core: Color(0xFF0096FF),
    mid: Color(0xFF0070CC),
    edge: Color(0xFF001E4A),
    accent: Color(0xFF0096FF),
    particleColor: Color.fromARGB(255, 0, 150, 255),
    svgType: 'sparkle',
    icon: LucideIcons.sparkles,
  );

  static const GenreGlowStyle _graphicNovel = GenreGlowStyle(
    coverColors: [Color(0xFFDB2777), Color(0xFF4C0519)],
    core: Color(0xFFFF3296),
    mid: Color(0xFFCC2878),
    edge: Color(0xFF330A1E),
    accent: Color(0xFFFF3296),
    particleColor: Color.fromARGB(255, 255, 50, 150),
    svgType: 'star',
    icon: LucideIcons.image,
  );

  static const GenreGlowStyle _historical = GenreGlowStyle(
    coverColors: [Color(0xFF92400E), Color(0xFF241102)],
    core: Color(0xFF8B4513),
    mid: Color(0xFF6B360F),
    edge: Color(0xFF201005),
    accent: Color(0xFF8B4513),
    particleColor: Color.fromARGB(255, 139, 69, 19),
    svgType: 'scroll',
    icon: LucideIcons.landmark,
  );

  static const GenreGlowStyle _horror = GenreGlowStyle(
    coverColors: [Color(0xFF7F1D1D), Color(0xFF1A0404)],
    core: Color(0xFF7800B4),
    mid: Color(0xFF5E008C),
    edge: Color(0xFF1E0032),
    accent: Color(0xFF7800B4),
    particleColor: Color.fromARGB(255, 120, 0, 180),
    svgType: 'skull',
    icon: LucideIcons.ghost,
  );

  static const GenreGlowStyle _literary = GenreGlowStyle(
    coverColors: [Color(0xFFbfa054), Color(0xFF4a4231)],
    core: Color(0xFFC8B48C),
    mid: Color(0xFFA09070),
    edge: Color(0xFF2A261D),
    accent: Color(0xFFC8B48C),
    particleColor: Color.fromARGB(255, 200, 180, 140),
    svgType: 'quill',
    icon: LucideIcons.penTool,
  );

  static const GenreGlowStyle _romance = GenreGlowStyle(
    coverColors: [Color(0xFFBE185D), Color(0xFF300A24)],
    core: Color(0xFFFF69B4),
    mid: Color(0xFFCC5490),
    edge: Color(0xFF331524),
    accent: Color(0xFFFF69B4),
    particleColor: Color.fromARGB(255, 255, 105, 180),
    svgType: 'heart',
    icon: LucideIcons.heart,
  );

  static const GenreGlowStyle _scifi = GenreGlowStyle(
    coverColors: [Color(0xFF0E7490), Color(0xFF06202E)],
    core: Color(0xFF00FF64),
    mid: Color(0xFF00CC50),
    edge: Color(0xFF003314),
    accent: Color(0xFF00FF64),
    particleColor: Color.fromARGB(255, 0, 255, 100),
    svgType: 'atom',
    icon: LucideIcons.rocket,
  );

  static const GenreGlowStyle _thriller = GenreGlowStyle(
    coverColors: [Color(0xFF1F2937), Color(0xFF09090B)],
    core: Color(0xFFFFFFFF),
    mid: Color(0xFFCCCCCC),
    edge: Color(0xFF333333),
    accent: Color(0xFFFFFFFF),
    particleColor: Color.fromARGB(255, 255, 255, 255),
    svgType: 'lightning',
    icon: LucideIcons.zap,
  );

  static const GenreGlowStyle _ya = GenreGlowStyle(
    coverColors: [Color(0xFF7C3AED), Color(0xFF2E1065)],
    core: Color(0xFFB464FF),
    mid: Color(0xFF9050CC),
    edge: Color(0xFF241433),
    accent: Color(0xFFB464FF),
    particleColor: Color.fromARGB(255, 180, 100, 255),
    svgType: 'sparkle',
    icon: LucideIcons.star,
  );

  static const GenreGlowStyle _memoir = GenreGlowStyle(
    coverColors: [Color(0xFFD97706), Color(0xFF451A03)],
    core: Color(0xFFFFC864),
    mid: Color(0xFFCCA050),
    edge: Color(0xFF332814),
    accent: Color(0xFFFFC864),
    particleColor: Color.fromARGB(255, 255, 200, 100),
    svgType: 'quill',
    icon: LucideIcons.book,
  );

  static const GenreGlowStyle _biography = GenreGlowStyle(
    coverColors: [Color(0xFF2563EB), Color(0xFF172554)],
    core: Color(0xFF6496FF),
    mid: Color(0xFF5078CC),
    edge: Color(0xFF141E33),
    accent: Color(0xFF6496FF),
    particleColor: Color.fromARGB(255, 100, 150, 255),
    svgType: 'scroll',
    icon: LucideIcons.user,
  );

  static const GenreGlowStyle _cookbooks = GenreGlowStyle(
    coverColors: [Color(0xFFEA580C), Color(0xFF431407)],
    core: Color(0xFFFF9632),
    mid: Color(0xFFCC7828),
    edge: Color(0xFF331E0A),
    accent: Color(0xFFFF9632),
    particleColor: Color.fromARGB(255, 255, 150, 50),
    svgType: 'fire',
    icon: LucideIcons.flame,
  );

  static const GenreGlowStyle _historicalNonfiction = GenreGlowStyle(
    coverColors: [Color(0xFF92400E), Color(0xFF241102)],
    core: Color(0xFFA06E3C),
    mid: Color(0xFF805830),
    edge: Color(0xFF20160C),
    accent: Color(0xFFA06E3C),
    particleColor: Color.fromARGB(255, 160, 110, 60),
    svgType: 'scroll',
    icon: LucideIcons.landmark,
  );

  static const GenreGlowStyle _howto = GenreGlowStyle(
    coverColors: [Color(0xFFFFAA7A), Color(0xFF022C22)],
    core: Color(0xFF32FF32),
    mid: Color(0xFF28CC28),
    edge: Color(0xFF0A330A),
    accent: Color(0xFF32FF32),
    particleColor: Color.fromARGB(255, 50, 255, 50),
    svgType: 'gear',
    icon: LucideIcons.wrench,
  );

  static const GenreGlowStyle _humor = GenreGlowStyle(
    coverColors: [Color(0xFFF59E0B), Color(0xFF451A03)],
    core: Color(0xFFFFDC00),
    mid: Color(0xFFCCB000),
    edge: Color(0xFF332C00),
    accent: Color(0xFFFFDC00),
    particleColor: Color.fromARGB(255, 255, 220, 0),
    svgType: 'sparkle',
    icon: LucideIcons.smile,
  );

  static const GenreGlowStyle _selfHelp = GenreGlowStyle(
    coverColors: [Color(0xFF059669), Color(0xFF022C22)],
    core: Color(0xFF64FFC8),
    mid: Color(0xFF50CCA0),
    edge: Color(0xFF143328),
    accent: Color(0xFF64FFC8),
    particleColor: Color.fromARGB(255, 100, 255, 200),
    svgType: 'star',
    icon: LucideIcons.heartHandshake,
  );

  static const GenreGlowStyle _trueCrime = GenreGlowStyle(
    coverColors: [Color(0xFF7F1D1D), Color(0xFF1A0404)],
    core: Color(0xFF8B0000),
    mid: Color(0xFF6E0000),
    edge: Color(0xFF1A0000),
    accent: Color(0xFF8B0000),
    particleColor: Color.fromARGB(255, 139, 0, 0),
    svgType: 'magnifier',
    icon: LucideIcons.shieldAlert,
  );

  static const GenreGlowStyle _travel = GenreGlowStyle(
    coverColors: [Color(0xFF0D9488), Color(0xFF042F2E)],
    core: Color(0xFF32C896),
    mid: Color(0xFF28A078),
    edge: Color(0xFF0A281E),
    accent: Color(0xFF32C896),
    particleColor: Color.fromARGB(255, 50, 200, 150),
    svgType: 'compass',
    icon: LucideIcons.map,
  );

  static const Map<String, GenreGlowStyle> _keywords = {
    'action': _action,
    'adventure': _action,
    'classic': _classic,
    'contemporary': _contemporary,
    'crime': _crime,
    'mystery': _crime,
    'dystopian': _dystopian,
    'fantasy': _fantasy,
    'graphic novel': _graphicNovel,
    'historical fiction': _historical,
    'horror': _horror,
    'literary fiction': _literary,
    'romance': _romance,
    'science fiction': _scifi,
    'sci-fi': _scifi,
    'thriller': _thriller,
    'young adult': _ya,
    'ya': _ya,
    'autobiography': _memoir,
    'memoir': _memoir,
    'biography': _biography,
    'cookbook': _cookbooks,
    'historical nonfiction': _historicalNonfiction,
    'how-to': _howto,
    'diy': _howto,
    'humor': _humor,
    'self-help': _selfHelp,
    'travel': _travel,
    'true crime': _trueCrime,
  };

  static final Map<String, GenreGlowStyle> _registered = {};

  /// Resolves the glow style for a project genre string.
  static GenreGlowStyle styleFor(String? genre) {
    final key = (genre ?? '').trim().toLowerCase();
    if (key.isEmpty) return _default;
    final exact = _registered[key];
    if (exact != null) return exact;
    for (final MapEntry(key: word, value: style) in _keywords.entries) {
      if (key.contains(word)) return style;
    }
    return _default;
  }

  /// Registers a custom glow style under a concrete genre label.
  static void register(String genre, GenreGlowStyle style) {
    _registered[genre.trim().toLowerCase()] = style;
  }
}
