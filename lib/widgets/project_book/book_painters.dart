// lib/widgets/project_book/book_painters.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'genre_glow.dart';

class Particle {
  double x = 0;
  double y = 0;
  double life = 0;
  double maxLife = 100;
  double vx = 0;
  double vy = 0;
  double size = 10;
  double rotation = 0;
  double rotSpeed = 0;

  /// Spawns at the prototype's emit column: the HTML computes
  /// `rightEdgeX = windowCenterX + 60`; in this widget's box-local space the
  /// cover is centred at x=120, so the column is 120 + 60 = 180.
  void reset(double rightEdgeX, double centerY) {
    final rng = math.Random();
    x = rightEdgeX + (rng.nextDouble() * 15);
    y = centerY + (rng.nextDouble() * 260 - 130);
    life = 0;
    maxLife = rng.nextDouble() * 50 + 35;
    vx = (rng.nextDouble() * 3.5) + 1.2;
    vy = (rng.nextDouble() - 0.5) * 3.5;
    size = rng.nextDouble() * 8 + 6;
    rotation = rng.nextDouble() * math.pi * 2;
    rotSpeed = (rng.nextDouble() - 0.5) * 0.04;
  }

  void update() {
    x += vx;
    y += vy;
    rotation += rotSpeed;
    life++;
  }
}

class ParticlePainter extends CustomPainter {
  ParticlePainter({required this.particles, required this.style});

  final List<Particle> particles;
  final GenreGlowStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.life >= p.maxLife) continue;

      double opacity = (1.0 - (p.life / p.maxLife));
      if (p.life < 8) opacity = (p.life / 8.0);
      if (style.svgType == 'skull') opacity *= 0.6;

      _drawSVGElement(
        canvas,
        style.svgType,
        p.x,
        p.y,
        p.size,
        style.particleColor,
        opacity,
        p.rotation,
      );
    }
  }

  void _drawSVGElement(
    Canvas canvas,
    String type,
    double x,
    double y,
    double size,
    Color color,
    double opacity,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);

    final strokeColor = color.withValues(alpha: opacity.clamp(0.0, 1.0));
    final fillColor = color.withValues(alpha: (opacity * 0.7).clamp(0.0, 1.0));

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final s = size * 0.8;
    final path = Path();

    switch (type) {
      case 'sword':
        path.moveTo(-s, s);
        path.lineTo(s, -s);
        path.moveTo(-s * 0.5, s * 0.8);
        path.lineTo(-s * 0.8, s * 0.5);
        canvas.drawPath(path, strokePaint);
        break;
      case 'quill':
        path.moveTo(-s, s);
        path.cubicTo(-s, -s, s, -s, s, s);
        path.cubicTo(0, s * 0.5, -s * 0.5, s, -s, s);
        canvas.drawPath(path, strokePaint);
        break;
      case 'star':
        for (int i = 0; i < 5; i++) {
          double outerAngle = (18 + i * 72) * math.pi / 180;
          double innerAngle = (54 + i * 72) * math.pi / 180;
          if (i == 0) {
            path.moveTo(math.cos(outerAngle) * s, -math.sin(outerAngle) * s);
          } else {
            path.lineTo(math.cos(outerAngle) * s, -math.sin(outerAngle) * s);
          }
          path.lineTo(
            math.cos(innerAngle) * (s * 0.5),
            -math.sin(innerAngle) * (s * 0.5),
          );
        }
        path.close();
        canvas.drawPath(path, fillPaint);
        break;
      case 'magnifier':
        path.addArc(
          Rect.fromCircle(center: Offset(-s * 0.3, -s * 0.3), radius: s * 0.6),
          0,
          math.pi * 2,
        );
        path.moveTo(s * 0.2, s * 0.2);
        path.lineTo(s, s);
        canvas.drawPath(path, strokePaint);
        break;
      case 'gear':
        path.addArc(
          Rect.fromCircle(center: Offset.zero, radius: s * 0.6),
          0,
          math.pi * 2,
        );
        canvas.drawPath(path, strokePaint);
        break;
      case 'sparkle':
        path.moveTo(0, -s);
        path.lineTo(0, s);
        path.moveTo(-s, 0);
        path.lineTo(s, 0);
        path.moveTo(-s * 0.6, -s * 0.6);
        path.lineTo(s * 0.6, s * 0.6);
        canvas.drawPath(path, strokePaint);
        break;
      case 'scroll':
        path.addRect(Rect.fromLTRB(-s, -s * 0.6, s, s * 0.6));
        canvas.drawPath(path, strokePaint);
        break;
      case 'skull':
        path.addArc(
          Rect.fromCircle(center: Offset(0, -s * 0.2), radius: s * 0.7),
          0,
          math.pi * 2,
        );
        path.addRect(Rect.fromLTRB(-s * 0.4, s * 0.3, s * 0.4, s * 0.8));
        canvas.drawPath(path, fillPaint);
        break;
      case 'heart':
        path.moveTo(0, s * 0.4);
        path.cubicTo(-s, -s * 0.2, -s * 0.8, -s, 0, -s * 0.3);
        path.cubicTo(s * 0.8, -s, s, -s * 0.2, 0, s * 0.4);
        canvas.drawPath(path, fillPaint);
        break;
      case 'atom':
        path.addArc(
          Rect.fromCircle(center: Offset.zero, radius: s * 0.3),
          0,
          math.pi * 2,
        );
        // Add ellipse by scaling the canvas slightly for the stroke
        canvas.save();
        canvas.rotate(math.pi / 4);
        canvas.scale(1.0, 0.4);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: s),
          0,
          math.pi * 2,
          false,
          strokePaint,
        );
        canvas.restore();
        canvas.drawPath(path, strokePaint);
        break;
      case 'lightning':
        path.moveTo(s * 0.2, -s);
        path.lineTo(-s * 0.5, 0);
        path.lineTo(0, 0);
        path.lineTo(-s * 0.2, s);
        path.lineTo(s * 0.5, 0);
        path.lineTo(0, 0);
        path.close();
        canvas.drawPath(path, fillPaint);
        break;
      case 'fire':
        path.moveTo(0, s);
        path.quadraticBezierTo(-s, 0, 0, -s);
        path.quadraticBezierTo(s, 0, 0, s);
        canvas.drawPath(path, fillPaint);
        break;
      case 'compass':
        path.addArc(
          Rect.fromCircle(center: Offset.zero, radius: s * 0.8),
          0,
          math.pi * 2,
        );
        path.moveTo(0, -s * 0.8);
        path.lineTo(0, s * 0.8);
        canvas.drawPath(path, strokePaint);
        break;
      default:
        path.addArc(
          Rect.fromCircle(center: Offset.zero, radius: s * 0.5),
          0,
          math.pi * 2,
        );
        canvas.drawPath(path, fillPaint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return true; // We animate continuously, so always repaint
  }
}
