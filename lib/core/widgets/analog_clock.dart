import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'swatch_keys.dart';

/// Analog clock face showing the shopwatch's elapsed time.
///
/// * second hand: one revolution per minute
/// * minute hand: one revolution per hour
/// * hour hand:   one revolution per 12 hours
/// * outer ring:  progress within the current minute
///
/// The painter listens to [elapsed] directly (`repaint:`), avoiding widget
/// rebuilds for the analog hands.
class AnalogClock extends StatefulWidget {
  const AnalogClock({
    super.key,
    required this.elapsed,
    this.goalSec,
    this.digitalDisplay,
    this.isRunning = false,
    this.muted = false,
  });

  final ValueListenable<Duration> elapsed;

  /// Whether the clock should play its ticking sound.
  final bool isRunning;

  /// Whether the ticking sound should be muted.
  final bool muted;

  /// Optional target time, marked as a red tick on the seconds scale.
  final Duration? goalSec;

  /// Optional digital readout rendered over the lower half of the clock face.
  final Widget? digitalDisplay;

  @override
  State<AnalogClock> createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  AudioPlayer? _player;
  int _playbackRequest = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isRunning && !widget.muted) unawaited(_syncTicking());
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRunning != widget.isRunning ||
        oldWidget.muted != widget.muted) {
      unawaited(_syncTicking());
    }
  }

  Future<void> _syncTicking() async {
    final request = ++_playbackRequest;
    final player = _player;
    if (!widget.isRunning || widget.muted) {
      if (player != null) {
        try {
          await player.stop();
        } catch (_) {
          // Audio must never interfere with the clock.
        }
      }
      return;
    }

    final activePlayer = _player ??= AudioPlayer();
    try {
      // Low-latency mode (SoundPool on Android) loops sample-accurately;
      // the default MediaPlayer mode inserts a gap at every loop restart.
      // The 1 s loop clip is small enough for SoundPool's size limit.
      await activePlayer.setPlayerMode(PlayerMode.lowLatency);
      await activePlayer.setReleaseMode(ReleaseMode.loop);
      await activePlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.assistanceSonification,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ));
      if (!mounted ||
          request != _playbackRequest ||
          !widget.isRunning ||
          widget.muted) {
        return;
      }
      await activePlayer.play(
        AssetSource('sounds/tick_loop_10.wav'),
        volume: 0.2,
      );
    } catch (_) {
      // Audio must never interfere with the clock.
    }
  }

  @override
  void dispose() {
    ++_playbackRequest;
    final player = _player;
    if (player != null) unawaited(_disposePlayer(player));
    super.dispose();
  }

  Future<void> _disposePlayer(AudioPlayer player) async {
    try {
      await player.dispose();
    } catch (_) {
      // Audio must never interfere with the clock.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Analog clock showing the elapsed time',
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              key: SwatchKeys.analogClock,
              painter: AnalogClockPainter(
                elapsed: widget.elapsed,
                colors: Theme.of(context).colorScheme,
                goalSec: widget.goalSec == null
                    ? null
                    : widget.goalSec!.inMicroseconds / 1e6,
              ),
              size: Size.infinite,
            ),
            if (widget.digitalDisplay != null)
              IgnorePointer(
                child: Align(
                  alignment: const Alignment(0, 0.42),
                  child: FractionallySizedBox(
                    widthFactor: 0.9,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: widget.digitalDisplay,
                    ),
                  ),
                ),
              ),
          ],
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
  AnalogClockPainter(
      {required this.elapsed, required this.colors, this.goalSec})
      : super(repaint: elapsed);

  final ValueListenable<Duration> elapsed;
  final ColorScheme colors;
  final double? goalSec;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final angles = handAngles(elapsed.value);

    _paintFace(canvas, center, radius);
    _paintTicks(canvas, center, radius);

    if (goalSec != null) {
      _paintGoalTick(canvas, center, radius, goalSec!);
    }

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

  void _paintGoalTick(
      Canvas canvas, Offset center, double radius, double goalSec) {
    final goal = Paint()
      ..color = colors.secondary
      ..strokeWidth = radius * 0.015
      ..strokeCap = StrokeCap.round;

    // The goal is an absolute time on the running clock; the face shows seconds.
    final angle = (goalSec % 60) / 60 * 2 * math.pi;
    final outer = radius * 0.84;
    final inner = radius * 0.66;
    canvas.drawLine(
      _polar(center, angle, inner),
      _polar(center, angle, outer),
      goal,
    );
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
      oldDelegate.elapsed != elapsed ||
      oldDelegate.colors != colors ||
      oldDelegate.goalSec != goalSec;
}
