import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rings spreading out from the button. [t] runs 0→1 and repeats; each ring
/// starts a third of the way after the last. [level] (0–1) pushes them
/// further and brighter while listening; at rest they only breathe.
class RipplesPainter extends CustomPainter {
  const RipplesPainter({
    required this.t,
    required this.level,
    required this.color,
    required this.listening,
    required this.innerRadius,
  });

  final double t;
  final double level;
  final Color color;
  final bool listening;
  final double innerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    if (!listening) {
      // A slow breath: one soft halo growing and shrinking.
      final breath = 0.5 - 0.5 * math.cos(2 * math.pi * t);
      final radius = innerRadius + 10 + 14 * breath;
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = color.withValues(alpha: 0.10 + 0.06 * breath),
      );
      return;
    }
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1;
      final reach =
          innerRadius + (outer - innerRadius) * p * (0.65 + 0.35 * level);
      final fade = (1 - p) * (0.18 + 0.32 * level);
      canvas.drawCircle(
        center,
        reach,
        Paint()..color = color.withValues(alpha: fade * 0.5),
      );
      canvas.drawCircle(
        center,
        reach,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(RipplesPainter old) =>
      old.t != t ||
      old.level != level ||
      old.listening != listening ||
      old.color != color;
}

/// A ring around the button filling over the listening time, with a tick
/// where each identification try happens.
class ListenArcPainter extends CustomPainter {
  const ListenArcPainter({
    required this.fraction,
    required this.marks,
    required this.color,
    required this.track,
    required this.radius,
  });

  final double fraction;
  final List<double> marks;
  final Color color;
  final Color track;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, stroke..color = track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      stroke..color = color,
    );
    for (final m in marks) {
      final a = -math.pi / 2 + 2 * math.pi * m;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawCircle(
        center + dir * radius,
        m <= fraction ? 4.5 : 3,
        Paint()..color = m <= fraction ? color : track,
      );
    }
  }

  @override
  bool shouldRepaint(ListenArcPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}

/// Five equalizer bars that dance with [level]; [t] (repeating 0→1) keeps
/// them moving a little even in quiet moments.
class LevelBars extends StatelessWidget {
  const LevelBars({
    super.key,
    required this.t,
    required this.level,
    required this.color,
  });

  final double t;
  final double level;
  final Color color;

  static const _weights = [0.55, 0.85, 1.0, 0.8, 0.6];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < _weights.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Container(
              width: 8,
              height:
                  12 +
                  52 *
                      (_weights[i] *
                                  level *
                                  (0.75 +
                                      0.25 *
                                          math.sin(
                                            2 * math.pi * (t * 3 + i * 0.37),
                                          )) +
                              0.08 *
                                  (1 +
                                      math.sin(
                                        2 * math.pi * (t * 2 + i * 0.21),
                                      )))
                          .clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A one-off burst of dots flying out from the center as [t] goes 0→1.
class BurstPainter extends CustomPainter {
  const BurstPainter({
    required this.t,
    required this.colors,
    required this.from,
    required this.ring,
  });

  final double t;
  final List<Color> colors;

  /// Radius the dots start at.
  final double from;

  /// Color of the ring that flashes outward first.
  final Color ring;

  static final _dots = () {
    final random = math.Random(9);
    return [
      for (var i = 0; i < 18; i++)
        (
          angle: 2 * math.pi * i / 18 + random.nextDouble() * 0.3,
          reach: 0.65 + random.nextDouble() * 0.35,
          size: 3.0 + random.nextDouble() * 4,
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final eased = Curves.easeOutCubic.transform(t);
    final flash = (t / 0.5).clamp(0.0, 1.0);
    if (flash < 1) {
      canvas.drawCircle(
        center,
        from * 0.7 + (outer - from * 0.7) * Curves.easeOut.transform(flash),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * (1 - flash) + 1
          ..color = ring.withValues(alpha: 0.6 * (1 - flash)),
      );
    }
    for (var i = 0; i < _dots.length; i++) {
      final dot = _dots[i];
      final distance =
          from * 0.85 + (outer + 20 - from * 0.85) * dot.reach * eased;
      final position =
          center + Offset(math.cos(dot.angle), math.sin(dot.angle)) * distance;
      canvas.drawCircle(
        position,
        dot.size * (1 - t * 0.6),
        Paint()..color = colors[i % colors.length].withValues(alpha: 1 - t),
      );
    }
  }

  @override
  bool shouldRepaint(BurstPainter old) => old.t != t;
}
