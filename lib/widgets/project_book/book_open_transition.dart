// lib/widgets/project_book/book_open_transition.dart
import 'dart:math' as math;
import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:lore_keeper/models/project.dart';
import 'project_book_view.dart';

/// Builds the route that opens a book and zooms the camera into its pages.
///
/// The overlay renders a second [ProjectBookView] from the same [BookViewInfo]
/// as the tapped card, positioned over the card's screen rect. Two animations
/// run simultaneously with the same cinematic `cubic-bezier(0.7, 0, 0.3, 1)`:
///   A. cover opening — independent rotation around the LEFT hinge, resuming
///      from the hover angle (~-38° mirrored) to fully open (+175°), ~1.0s.
///   B. scene zoom — the whole book wrapper scales 1 → 8 toward the viewer,
///      holds fully visible until ~1.0s, then dissolves to opacity 0 by ~1.2s.
/// Only after the book has dissolved is the destination workspace revealed
/// underneath (built once, so heavy project UI never blocks the animation).
///
/// Timeline (t = route animation 0→1 over 1200ms):
///   0.0s    cover ≈ hover angle, scale 1,        opacity 1
///   ~1.0s   cover fully open,      scale ≈ 6-8,  opacity ≈ 1
///   ~1.2s   cover fully open,      scale 8,      opacity 0
/// Reverse navigation replays the sequence backwards: the book closes as the
/// camera pulls back to the card.
/// Stage 1 target: the cover swings to `+175deg` (the depth-mirror of the
/// prototype's CSS `swingCoverOpen` `-175deg`), past fully-open so the inner
/// spine shows while the camera dives in.
const double _swingTargetAngle = 175.0 * math.pi / 180.0;

Route<void> buildBookOpenRoute({
  required Project project,
  required BookViewInfo info,
  required Rect originRect,
  required double initialOpenAngle,
  required WidgetBuilder destinationBuilder,
}) {
  return PageRouteBuilder<void>(
    settings: RouteSettings(name: 'book-open://${project.key}'),
    transitionDuration: const Duration(milliseconds: 1200),
    reverseTransitionDuration: const Duration(milliseconds: 800),
    // Non-opaque so the previous screen stays visible under the scrim and the
    // book appears to zoom out of the live card.
    opaque: false,
    // Tapping the barrier must not dismiss: `ModalBarrier` pops the route on
    // tap by default, so a second click during the dive would cancel the zoom
    // it just started. The dive is one-way; back navigation returns to the
    // card.
    barrierDismissible: false,
    // The destination page is deferred: it stays an empty placeholder until
    // the book transition completes (see [_DeferredDestination]), then builds
    // the real workspace exactly once.
    pageBuilder: (context, animation, secondaryAnimation) =>
        _DeferredDestination(animation: animation, builder: destinationBuilder),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        _BookZoomOverlay(
          animation: animation,
          originRect: originRect,
          initialOpenAngle: initialOpenAngle,
          info: info,
          child: child,
        ),
  );
}

/// Keeps the route's page empty while the book-open animation runs, then
/// builds the [builder] destination exactly once — after the transition.
///
/// This is the lifecycle fix for a possible freeze: `ProjectEditorScreen` (and
/// friends) construct several providers in `initState`, so building them at
/// push time would block the main thread mid-animation. By deferring the build
/// until the book has fully dissolved (animation completed), the heavy UI can
/// never stall the cover swing or the zoom.
///
/// The gate is driven by the animation listener, NOT by a value snapshot in
/// [State.initState]: the `HeroController` installed by `MaterialApp` parks a
/// freshly pushed route offstage for its first frame (swapping the route
/// animation proxy to a constant "completed" animation), so reading the value
/// at mount would build the destination on frame one and defeat the deferral.
///
/// Two extra guards keep the heavy build off the animation's critical path:
///  1. It waits for [AnimationStatus.completed], not merely value ≥ 0.95 —
///     the frames between 0.95 and 1.0 are still playing.
///  2. The build itself is scheduled in a post-frame callback, so it runs on a
///     frame AFTER the fully-dissolved book has painted, never on an animation
///     frame.
class _DeferredDestination extends StatefulWidget {
  const _DeferredDestination({required this.animation, required this.builder});

  final Animation<double> animation;
  final WidgetBuilder builder;

  @override
  State<_DeferredDestination> createState() => _DeferredDestinationState();
}

class _DeferredDestinationState extends State<_DeferredDestination> {
  bool _built = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_maybeBuild);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_maybeBuild);
    super.dispose();
  }

  void _maybeBuild() {
    if (_built || _scheduled) return;
    if (widget.animation.status != AnimationStatus.completed) return;
    if (widget.animation.value < 0.95) return;
    _scheduled = true;
    // Build on the frame AFTER this one paints the fully-dissolved book, so
    // the destination's first (heavy) build never lands on an animation frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _built = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_built) return const SizedBox.shrink();
    return widget.builder(context);
  }
}

class _BookZoomOverlay extends StatefulWidget {
  const _BookZoomOverlay({
    required this.animation,
    required this.child,
    required this.originRect,
    required this.initialOpenAngle,
    required this.info,
  });

  final Animation<double> animation;
  final Widget child;
  final Rect originRect;
  final double initialOpenAngle;
  final BookViewInfo info;

  @override
  State<_BookZoomOverlay> createState() => _BookZoomOverlayState();
}

class _BookZoomOverlayState extends State<_BookZoomOverlay> {
  // Seeded to the click-flow start pose rather than snapshot from the
  // animation: the HeroController parked this route offstage for its first
  // frame, swapping the route animation proxy to a constant "completed"
  // animation (value 1.0). Reading it at mount would render the book as
  // already dissolved — and the jump-target — on frame one. The listener below
  // only receives genuine controller ticks after the offstage park is lifted.
  double _t = 0.0;

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_onAnimationTick);
    super.dispose();
  }

  void _onAnimationTick() {
    setState(() => _t = widget.animation.value);
  }

  @override
  Widget build(BuildContext context) {
    final animation = widget.animation;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = constraints.biggest;
        final reversing = animation.status == AnimationStatus.reverse;
        final t = _t;
        // Only absorb taps while the zoom animation is in flight (t < 1.0).
        // Without this conditional the overlay stays pointer-absorbent after
        // the book has fully dissolved, making the destination appear frozen.
        return AbsorbPointer(
          absorbing: t < 1.0,
          child: Builder(
            builder: (context) {
              // Use cubic-bezier(0.7, 0, 0.3, 1) equivalent
              const curve = Cubic(0.7, 0.0, 0.3, 1.0);

              // Cover opening finishes slightly before zoom (1.0s vs 1.2s)
              final swingT = curve.transform((t * 1.2).clamp(0.0, 1.0));
              final openAngle =
                  widget.initialOpenAngle +
                  (_swingTargetAngle - widget.initialOpenAngle) * swingT;

              // Zoom scale and translate
              final zoomT = curve.transform(t);
              final scale = 1.0 + (7.0 * zoomT); // scale(8) max

              // Center offset - moves book to center, then translates 30px
              // right in the book's local coordinate space (which is scaled).
              final overlayCenter = Offset(
                screenSize.width / 2,
                screenSize.height / 2,
              );
              final centerOffset = widget.originRect.center - overlayCenter;
              final currentCenterOffset = Offset.lerp(
                centerOffset,
                Offset.zero,
                zoomT,
              )!;

              // Apply prototype's `scale(8) translateX(30px)` — translate is
              // local space so it is multiplied by the zoom scale; CSS positive
              // X shifts the book to the RIGHT.
              final panX = 30.0 * zoomT * scale;

              // Fade out the book only at the very end: it stays fully visible
              // until ~1.0s (t 0.85), then dissolves to 0 by ~1.2s (t 0.95),
              // matching the prototype's opacity curve.
              final bookOpacity = reversing
                  ? ((t - 0.1) / 0.2).clamp(0.0, 1.0)
                  : 1.0 - ((t - 0.85) / 0.1).clamp(0.0, 1.0);

              // Fade in the destination exactly as the book dissolves — it is
              // only built once the transition completes, so this reveal never
              // races ahead of the animation.
              final destOpacity = ((t - 0.95) / 0.05).clamp(0.0, 1.0);

              // Scrim isolates the moment early on, clearing as the book fades.
              final scrim =
                  0.9 *
                  Curves.easeOut.transform((t / 0.3).clamp(0.0, 1.0)) *
                  (1.0 -
                      Curves.easeIn.transform(
                        ((t - 0.8) / 0.2).clamp(0.0, 1.0),
                      ));

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Destination workspace — no IgnorePointer: once the
                  // AbsorbPointer above releases (t ≥ 1.0) this must be
                  // tappable immediately.
                  Opacity(opacity: destOpacity, child: widget.child),

                  // Scrim isolating the moment — IgnorePointer so it never
                  // blocks taps even while transparent (a ColoredBox with
                  // alpha = 0 is still hit-testable by default).
                  IgnorePointer(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: scrim),
                    ),
                  ),

                  // Ambient glow (expands and fades)
                  Positioned(
                    top: (screenSize.height / 2) - 300,
                    left: (screenSize.width / 2) - 300,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity:
                            (1.0 - destOpacity) * zoomT.clamp(0.0, 1.0) * 0.8,
                        child: Container(
                          width: 600,
                          height: 600,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.info.glow.particleColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          child: BackdropFilter(
                            filter: dart_ui.ImageFilter.blur(
                              sigmaX: 100,
                              sigmaY: 100,
                            ),
                            child: const SizedBox(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // The book itself, zooming and opening. After it dissolves
                  // (bookOpacity ≈ 0) it must stop intercepting hit tests;
                  // Opacity(0) is still hit-testable, so IgnorePointer
                  // prevents the invisible scaled-up book from stealing
                  // taps that belong to the destination underneath.
                  IgnorePointer(
                    ignoring: bookOpacity <= 0,
                    child: Opacity(
                      opacity: bookOpacity,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translateByDouble(
                            currentCenterOffset.dx + panX,
                            currentCenterOffset.dy,
                            0.0,
                            1.0,
                          )
                          ..scaleByDouble(scale, scale, 1.0, 1.0)
                          ..setEntry(3, 2, bookPerspectiveFactor),
                        child: SizedBox(
                          width: 240, // strict 3D dimensions
                          height: 340,
                          child: ProjectBookView(
                            info: widget.info,
                            openAngle: openAngle,
                            showMeta:
                                openAngle.abs() <
                                1.5, // fade text when mostly open
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
