// Copyright (c) 2026 Juhász Mátyás
// SPDX-License-Identifier: MIT

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:swatch/features/shopwatch/shopwatch_strings.dart';

class HintTarget {
  const HintTarget({
    required this.targetKey,
    required this.title,
    required this.text,
    this.icon,
    this.preferAbove = false,
  });

  final Key targetKey;
  final String title;
  final String text;
  final IconData? icon;
  final bool preferAbove;

  /// Render box of the widget carrying [targetKey], or null when it is not built.
  /// Non-global keys (e.g. [ShopwatchKeys.start]) are found by walking the element tree.
  RenderBox? findRenderBox() {
    final key = targetKey;
    if (key is GlobalKey) return key.currentContext?.findRenderObject() as RenderBox?;
    RenderBox? result;
    void visit(Element element) {
      if (result != null) return;
      if (element.widget.key == key) {
        result = element.findRenderObject() as RenderBox?;
        return;
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return result;
  }
}

class HintOverlay extends StatefulWidget {
  const HintOverlay({super.key, required this.targets, required this.onDismiss});

  final List<HintTarget> targets;
  final VoidCallback onDismiss;

  @override
  State<HintOverlay> createState() => _HintOverlayState();
}

class _HintOverlayState extends State<HintOverlay> with WidgetsBindingObserver {
  static const double _margin = 16;
  static const double _gap = 28;
  static const double _maxBubbleWidth = 280;

  final _bubbleKeys = <int, GlobalKey>{};
  Map<int, Rect> _rects = const {};
  Map<int, Size> _sizes = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(HintOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMeasure();
  }

  @override
  void didChangeMetrics() => _scheduleMeasure();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleMeasure() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final (rects, sizes) = _measure();
      if (!mapEquals(rects, _rects) || !mapEquals(sizes, _sizes)) {
        setState(() {
          _rects = rects;
          _sizes = sizes;
        });
        // Bubbles are only built after the targets are located, so measure again to get their sizes.
        _scheduleMeasure();
      }
    });
  }

  (Map<int, Rect>, Map<int, Size>) _measure() {
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.attached || !overlayBox.hasSize) return (const {}, const {});
    final screen = Offset.zero & overlayBox.size;
    final rects = <int, Rect>{};
    final sizes = <int, Size>{};
    for (var i = 0; i < widget.targets.length; i++) {
      final box = widget.targets[i].findRenderBox();
      if (box == null || !box.attached || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
      if (!rect.overlaps(screen)) continue;
      rects[i] = rect;
      final bubble = _bubbleKeys[i]?.currentContext?.findRenderObject() as RenderBox?;
      if (bubble != null && bubble.attached && bubble.hasSize) sizes[i] = bubble.size;
    }
    return (rects, sizes);
  }

  ({Rect rect, Offset from, Offset to}) _place(Rect target, Size size, Size screen, {bool preferAbove = false}) {
    final spot = target.inflate(_SpotlightPainter.padding);
    final fitsBelow = spot.bottom + _gap + size.height + _margin <= screen.height;
    final fitsAbove = spot.top - _gap - size.height >= _margin;
    final below = preferAbove ? !fitsAbove && fitsBelow : fitsBelow;
    final left = spot.center.dx - size.width / 2;
    final top = below ? spot.bottom + _gap : spot.top - _gap - size.height;
    final rect = Rect.fromLTWH(
      left.clamp(_margin, max(_margin, screen.width - _margin - size.width)),
      top.clamp(_margin, max(_margin, screen.height - _margin - size.height)),
      size.width,
      size.height,
    );
    final x = spot.center.dx.clamp(rect.left + _margin, rect.right - _margin);
    final toX = x.clamp(spot.left, spot.right);
    return (
      rect: rect,
      from: Offset(x, below ? rect.top : rect.bottom),
      to: Offset(toX, below ? spot.bottom : spot.top),
    );
  }

  Widget _bubble(BuildContext context, int index, double width) {
    final target = widget.targets[index];
    final theme = Theme.of(context);
    return Material(
      key: _bubbleKeys.putIfAbsent(index, GlobalKey.new),
      color: theme.colorScheme.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (target.icon != null) ...[
                Icon(target.icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(target.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(target.text, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: '${ShopwatchStrings.hintsLabel}: ${widget.targets.map((t) => '${t.title}. ${t.text}').join(' ')}',
        child: Material(
          key: ShopwatchKeys.hintsOverlay,
          type: MaterialType.transparency,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screen = constraints.biggest;
              final width = min(_maxBubbleWidth, screen.width - 2 * _margin);
              final arrows = <(Offset, Offset)>[];
              final bubbles = <Widget>[];
              var measured = true;
              for (final entry in _rects.entries) {
                final size = _sizes[entry.key];
                if (size == null) measured = false;
                final placed = _place(
                  entry.value,
                  size ?? Size(width, 0),
                  screen,
                  preferAbove: widget.targets[entry.key].preferAbove,
                );
                if (size != null) arrows.add((placed.from, placed.to));
                bubbles.add(Positioned(
                  left: placed.rect.left,
                  top: placed.rect.top,
                  child: _bubble(context, entry.key, width),
                ));
              }
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onDismiss,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ExcludeSemantics(
                      child: CustomPaint(
                        painter: _SpotlightPainter(_rects.values.toList(), measured ? arrows : const []),
                      ),
                    ),
                    ExcludeSemantics(
                      child: Opacity(opacity: measured ? 1 : 0, child: Stack(children: bubbles)),
                    ),
                    SafeArea(
                      minimum: const EdgeInsets.all(_margin),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: FilledButton(
                              key: ShopwatchKeys.hintsGotIt,
                              onPressed: widget.onDismiss,
                              child: const Text(ShopwatchStrings.gotIt),
                            ),
                          ),
                          const SizedBox(
                            height: 32,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.rects, this.arrows);

  static const double padding = 8;
  static const double radius = 12;
  static const double _headLength = 10;

  final List<Rect> rects;
  final List<(Offset, Offset)> arrows;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    for (final rect in rects) {
      path.addRRect(RRect.fromRectAndRadius(rect.inflate(padding), const Radius.circular(radius)));
    }
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.7));

    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final head = Paint()..color = Colors.white;
    for (final (from, to) in arrows) {
      final delta = to - from;
      if (delta.distance == 0) continue;
      final dir = delta / delta.distance;
      final normal = Offset(-dir.dy, dir.dx);
      final base = to - dir * _headLength;
      canvas.drawLine(from, base, line);
      canvas.drawPath(
        Path()
          ..moveTo(to.dx, to.dy)
          ..lineTo(base.dx + normal.dx * _headLength / 2, base.dy + normal.dy * _headLength / 2)
          ..lineTo(base.dx - normal.dx * _headLength / 2, base.dy - normal.dy * _headLength / 2)
          ..close(),
        head,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      !listEquals(oldDelegate.rects, rects) || !listEquals(oldDelegate.arrows, arrows);
}
