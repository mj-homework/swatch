/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:swatch/core/services/layout_service.dart';

import 'package:swatch/core/swatch/swatch_controller.dart';
import 'package:swatch/core/swatch/time_source.dart';
import 'package:swatch/core/widgets/analog_clock.dart';
import 'package:swatch/features/stopwatch/presentation/pages/control_buttons.dart';
import 'package:swatch/features/stopwatch/presentation/pages/elapsed_time_display.dart';
import 'package:swatch/features/stopwatch/presentation/pages/lap_panel.dart';
import 'package:swatch/core/services/sound_player.dart';

/// Main screen. Owns the [SwatchController] and the frame [Ticker].
///
/// The controller only notifies on state changes. While running, a [Ticker]
/// (synchronized with the display refresh rate) pushes the current elapsed
/// time into [_elapsed]; only the pages listening to it repaint, the rest
/// of the tree is not rebuilt on every frame.
class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key, this.timeSource, required this.soundPlayer});

  final TimeSource? timeSource;
  final SoundPlayer? soundPlayer;

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> with SingleTickerProviderStateMixin {
  late final SwatchController _controller = SwatchController(timeSource: widget.timeSource);
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  late final Ticker _ticker;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _controller.addListener(_onControllerChanged);
  }

  void _onTick(Duration _) => _elapsed.value = _controller.elapsed;

  void _onControllerChanged() {
    _elapsed.value = _controller.elapsed;
    _syncTicking();
    if (_controller.isRunning && !_ticker.isActive) {
      _ticker.start();
    } else if (!_controller.isRunning && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _syncTicking() {
    if (_controller.isRunning && !_muted) {
      unawaited(widget.soundPlayer?.startTicking());
    } else {
      unawaited(widget.soundPlayer?.stopTicking());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _ticker.dispose();
    _controller.dispose();
    _elapsed.dispose();
    unawaited(widget.soundPlayer?.stopTicking());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classic swatch'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _muted ? 'Unmute sounds' : 'Mute sounds',
            onPressed: () {
              setState(() => _muted = !_muted);
              _syncTicking();
            },
            icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stopwatch = _StopwatchSection(
                controller: _controller,
                elapsed: _elapsed,
              );

              final laps = LapPanel(controller: _controller);

              if (LayoutService.isWide(constraints.maxWidth)) {
                return Row(
                  children: [
                    Expanded(flex: 3, child: stopwatch),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: laps),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(flex: 3, child: stopwatch),
                  const SizedBox(height: 16),
                  Expanded(flex: 2, child: laps),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StopwatchSection extends StatelessWidget {
  const _StopwatchSection({required this.controller, required this.elapsed});

  final SwatchController controller;
  final ValueListenable<Duration> elapsed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
            child: AspectRatio(
              aspectRatio: 1,
              child: ListenableBuilder(
                listenable: controller,
                builder: (_, __) => AnalogClock(
                  elapsed: elapsed,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElapsedTimeDisplay(elapsed: elapsed),
        const SizedBox(height: 16),
        ControlButtons(controller: controller),
      ],
    );
  }
}
