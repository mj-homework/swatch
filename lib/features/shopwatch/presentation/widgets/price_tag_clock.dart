import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/analog_clock.dart';
import '../../shopwatch_strings.dart';

class PriceTagClock extends StatelessWidget {
  const PriceTagClock({super.key, required this.elapsed});
  final ValueListenable<Duration> elapsed;
  @override
  Widget build(BuildContext context) => Semantics(label: 'Price tag clock',
    child: RepaintBoundary(child: CustomPaint(size: const Size(230, 250), painter: _TagPainter(elapsed))));
}
class _TagPainter extends CustomPainter {
  _TagPainter(this.elapsed) : super(repaint: elapsed);
  final ValueListenable<Duration> elapsed;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height - 30) / 2 - 8;
    canvas.drawCircle(center, radius, Paint()..color = ShopwatchStyle.tag);
    final ink = Paint()..color = ShopwatchStyle.ink..strokeWidth = 2..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 12, 0), Offset(center.dx, center.dy - radius + 12), ink);
    canvas.drawCircle(Offset(center.dx, center.dy - radius + 12), 4, ink);
    Offset polar(double angle, double length) => center + Offset(math.sin(angle), -math.cos(angle)) * length;
    for (var i = 0; i < 60; i++) {
      final angle = i * math.pi / 30;
      canvas.drawLine(polar(angle, radius * (i % 5 == 0 ? .77 : .83)), polar(angle, radius * .87), ink..strokeWidth = i % 5 == 0 ? 2 : 1);
    }
    final angles = handAngles(elapsed.value);
    canvas.drawLine(center, polar(angles.hour, radius * .44), ink..strokeWidth = 5);
    canvas.drawLine(center, polar(angles.minute, radius * .64), ink..strokeWidth = 3);
    canvas.drawLine(polar(angles.second + math.pi, radius * .12), polar(angles.second, radius * .73),
      Paint()..color = ShopwatchStyle.approved..strokeWidth = 2);
    final bar = Rect.fromLTWH(12, size.height - 8, size.width - 24, 5);
    canvas.drawRect(bar, Paint()..color = ShopwatchStyle.paper);
    canvas.drawRect(Rect.fromLTWH(bar.left, bar.top, bar.width * (elapsed.value.inMicroseconds % 60000000) / 60000000, bar.height), Paint()..color = ShopwatchStyle.approved);
  }
  @override
  bool shouldRepaint(_TagPainter oldDelegate) => elapsed != oldDelegate.elapsed;
}
