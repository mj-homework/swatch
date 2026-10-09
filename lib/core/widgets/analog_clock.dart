import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'shopwatch_keys.dart';

/// Analog clock face showing the shopwatch's elapsed time.
///
/// * second hand: one revolution per minute
/// * minute hand: one revolution per hour
/// * hour hand:   one revolution per 12 hours
/// * outer ring:  progress within the current minute
///
/// Hand angles are computed from the elapsed time with sub-millisecond
/// precision on every frame, so the hands sweep smoothly instead of jumping.
/// The painter listens to [elapsed] directly (`repaint:`), so only this
/// canvas is repainted on each tick – no widget rebuilds.
class AnalogClock extends StatelessWidget {
  const AnalogClock({super.key, required this.elapsed});

  final ValueListenable<Duration> elapsed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Analog clock showing the elapsed time',
      child: RepaintBoundary(
        child: CustomPaint(
          key: StopwatchKeys.analogClock,
          painter: AnalogClockPainter(
            elapsed: elapsed,
            colors: Theme.of(context).colorScheme,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Hand angles in radians, measured clockwise from 12 o'clock.
@visibleForTesting
({double hour, double minute, double second}) handAngles(Duration elapsed) {
  const fullTurn = 2 * math.pi;
  final ms = elapsed.inMicroseconds / 1000.0;
  return (
    second: (ms % 60000) / 60000 * fullTurn,
    minute: (ms % 3600000) / 3600000 * fullTurn,
    hour: (ms % 43200000) / 43200000 * fullTurn,
  );
}

class AnalogClockPainter extends CustomPainter {
  AnalogClockPainter({required this.elapsed, required this.colors})
      : super(repaint: elapsed);

  final ValueListenable<Duration> elapsed;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final angles = handAngles(elapsed.value);

    _paintFace(canvas, center, radius);
    _paintTicks(canvas, center, radius);
    _paintProgressRing(canvas, center, radius, angles.second);

    _paintHand(
      canvas,
      center,
      angle: angles.hour,
      length: radius * 0.45,
      width: radius * 0.05,
      color: colors.onSurface,
    );
    _paintHand(
      canvas,
      center,
      angle: angles.minute,
      length: radius * 0.66,
      width: radius * 0.035,
      color: colors.onSurface,
    );
    _paintHand(
      canvas,
      center,
      angle: angles.second,
      length: radius * 0.78,
      tail: radius * 0.16,
      width: radius * 0.015,
      color: colors.primary,
    );

    canvas
      ..drawCircle(center, radius * 0.045, Paint()..color = colors.primary)
      ..drawCircle(center, radius * 0.018, Paint()..color = colors.surface);
  }

  void _paintFace(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius * 0.96,
      Paint()..color = colors.surfaceContainerHighest,
    );
    canvas.drawCircle(
      center,
      radius * 0.96,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.01
        ..color = colors.outlineVariant,
    );
  }

  void _paintTicks(Canvas canvas, Offset center, double radius) {
    final minor = Paint()
      ..color = colors.onSurfaceVariant.withValues(alpha: 0.5)
      ..strokeWidth = radius * 0.008
      ..strokeCap = StrokeCap.round;
    final major = Paint()
      ..color = colors.onSurface
      ..strokeWidth = radius * 0.022
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 60; i++) {
      final isMajor = i % 5 == 0;
      final angle = i / 60 * 2 * math.pi;
      final outer = radius * 0.84;
      final inner = isMajor ? radius * 0.72 : radius * 0.79;
      canvas.drawLine(
        _polar(center, angle, inner),
        _polar(center, angle, outer),
        isMajor ? major : minor,
      );
    }
  }

  void _paintProgressRing(
    Canvas canvas,
    Offset center,
    double radius,
    double secondAngle,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius * 0.90);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      secondAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.03
        ..strokeCap = StrokeCap.round
        ..color = colors.primary.withValues(alpha: 0.6),
    );
  }

  void _paintHand(
    Canvas canvas,
    Offset center, {
    required double angle,
    required double length,
    required double width,
    required Color color,
    double tail = 0,
  }) {
    canvas.drawLine(
      _polar(center, angle + math.pi, tail),
      _polar(center, angle, length),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Point at [distance] from [center], [angle] clockwise from 12 o'clock.
  static Offset _polar(Offset center, double angle, double distance) =>
      center + Offset(math.sin(angle), -math.cos(angle)) * distance;

  @override
  bool shouldRepaint(AnalogClockPainter oldDelegate) =>
      oldDelegate.elapsed != elapsed || oldDelegate.colors != colors;
}
