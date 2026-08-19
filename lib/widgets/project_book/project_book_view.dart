// lib/widgets/project_book/project_book_view.dart
import 'package:flutter/material.dart';
import 'genre_glow.dart';

/// CSS `perspective: 1400px` mapped to Matrix4's (3,2) entry. Flutter applies
/// perspective as a w-divisor (z / distance), so the entry equals 1 / 1400 —
/// not the 1/1000 ≈ 0.001 a `setEntry(3, 2, 0.001)` call would imply.
const double bookPerspectiveFactor = 1.0 / 1400.0;

class BookViewInfo {
  const BookViewInfo({
    required this.title,
    required this.genre,
    required this.wordCount,
    required this.time,
    required this.glow,
    required this.seed,
  });

  final String title;
  final String genre;
  final String wordCount;
  final String time;
  final GenreGlowStyle glow;
  final double seed;
}

/// Renders the physical layers of the prototype book, back to front:
/// 1. [inner page] — full-size white page with ruled lines
/// 2. [front cover] — full-size genre cover hinged on its LEFT edge
///
/// There is no `.book-spine` layer (edge-on it leaked as a dark line outside
/// the left edge) and no `.book-pages-right` block (it projected as a white
/// strip outside the right edge). The front cover sits directly in front of the
/// white page, so the opening effect is the cover swinging away from the page.
class ProjectBookView extends StatelessWidget {
  const ProjectBookView({
    super.key,
    required this.info,
    required this.openAngle,
    this.showMeta = true,
  });

  final BookViewInfo info;

  /// The open angle in radians for the cover around the Y axis.
  /// 0 = closed; positive values swing the free edge TOWARD the viewer, which
  /// is the depth-mirror of the prototype's CSS `rotateY(-deg)` (e.g. +38 deg
  /// on hover, +175 deg fully open). Flutter's +z points away from the viewer,
  /// opposite of CSS, hence the sign flip.
  final double openAngle;

  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    // The prototype assumes a strict 240x340 box for the 3D transforms.
    // We provide a fixed size container, and rely on the parent (ProjectBook)
    // to scale it to fit via FittedBox if necessary, preserving the aspect ratio.
    return SizedBox(
      width: 240,
      height: 340,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Inner First Page — z-index 2 (100% x 100%). The white page sits
          // recessed behind the cover and is only revealed as the cover opens.
          Transform(
            transform: Matrix4.translationValues(0.0, 0.0, 19.0),
            child: const _BookFirstPage(),
          ),

          // Front Cover (hinged on the left) — z-index 6
          Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.translationValues(0.0, 0.0, 20.0)
              ..rotateY(openAngle),
            child: _BookFront(info: info, showMeta: showMeta),
          ),
        ],
      ),
    );
  }
}

class _BookFirstPage extends StatelessWidget {
  const _BookFirstPage();

  @override
  Widget build(BuildContext context) {
    // Mirrors CSS .book-first-page: full-bleed #FDFBF7, inset shadow
    // `12px 0 25px rgba(0,0,0,0.06)`, 2px #E0E0E0 right border, ruled lines.
    return Container(
      width: 240,
      height: 340,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        border: const Border(
          right: BorderSide(color: Color(0xFFE0E0E0), width: 2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000), // rgba(0,0,0,0.06) inset
            offset: Offset(12, 0),
            blurRadius: 25,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: CustomPaint(painter: const _RuledLinesPainter()),
    );
  }
}

class _RuledLinesPainter extends CustomPainter {
  const _RuledLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // CSS: repeating-linear-gradient 26px pitch, first line at 16px.
    final paint = Paint()..color = const Color(0xFFEAEAEA);
    for (double y = 16; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BookFront extends StatelessWidget {
  const _BookFront({required this.info, required this.showMeta});

  final BookViewInfo info;
  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    final glow = info.glow;

    // Inner (back) face of the cover — dark lining visible when the cover has
    // swung past ~90° (same as CSS .book-front::after with backface-visibility).
    if (!showMeta) {
      return Container(
        width: 240,
        height: 340,
        decoration: const BoxDecoration(
          color: Color(0xFF2a2a2c),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(4),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            // Heavy shadow on the binding edge, visible when the cover is open.
            BoxShadow(
              color: Color(0xCC000000), // 0.8 opacity
              blurRadius: 15,
              offset: Offset(-5, 0),
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
      );
    }

    return Container(
      width: 240,
      height: 340,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: glow.coverColors,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: const [
          // CSS .book-front: `6px 10px 30px rgba(0,0,0,0.5)` drop shadow.
          BoxShadow(
            color: Color(0x80000000), // 0.5 opacity
            offset: Offset(6, 10),
            blurRadius: 30,
          ),
          // Dark inner shadow on the binding edge (page-side depth).
          BoxShadow(
            color: Color(0x4D000000), // 0.3 opacity
            offset: Offset(4, 0),
            blurRadius: 10,
            blurStyle: BlurStyle.inner,
          ),
          // CSS inset: `2px 0 6px rgba(255,255,255,0.2)` edge highlight.
          BoxShadow(
            color: Color(0x33FFFFFF), // 0.2 opacity
            offset: Offset(2, 0),
            blurRadius: 6,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Genre icon centred in the upper portion of the cover.
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Icon(
                glow.icon,
                size: 60,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),

            // Title + last-modified date at the bottom of the cover.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  info.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF3F4F6),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.time, // ← uses real elapsed time, not hardcoded string
                  style: TextStyle(
                    color: const Color(0xFFD1D5DB).withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
