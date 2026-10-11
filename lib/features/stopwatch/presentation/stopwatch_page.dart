import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/stopwatch/stopwatch_controller.dart';
import '../../../core/stopwatch/time_source.dart';
import '../../../core/widgets/analog_clock.dart';
import '../../../core/widgets/layout_breakpoints.dart';
import 'widgets/control_buttons.dart';
import 'widgets/elapsed_time_display.dart';
import 'widgets/lap_panel.dart';

/// Main screen. Owns the [StopwatchController] and the frame [Ticker].
///
/// The controller only notifies on state changes. While running, a [Ticker]
/// (synchronized with the display refresh rate) pushes the current elapsed
/// time into [_elapsed]; only the widgets listening to it repaint, the rest
/// of the tree is not rebuilt on every frame.
class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key, this.timeSource});

  final TimeSource? timeSource;

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage>
    with SingleTickerProviderStateMixin {
  late final StopwatchController _controller =
      StopwatchController(timeSource: widget.timeSource);
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  late final Ticker _ticker;
  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _controller.addListener(_onControllerChanged);
  }

  void _onTick(Duration _) => _elapsed.value = _controller.elapsed;

  void _onControllerChanged() {
    _elapsed.value = _controller.elapsed;
    if (_controller.isRunning && !_ticker.isActive) {
      _ticker.start();
    } else if (!_controller.isRunning && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _ticker.dispose();
    _controller.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stopwatch'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shopwatch = _ShopwatchSection(
                controller: _controller,
                elapsed: _elapsed,
              );
              final laps = LapPanel(controller: _controller);

              if (constraints.maxWidth >= wideLayoutBreakpoint) {
                return Row(
                  children: [
                    Expanded(flex: 3, child: shopwatch),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: laps),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(flex: 3, child: shopwatch),
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

class _ShopwatchSection extends StatelessWidget {
  const _ShopwatchSection({required this.controller, required this.elapsed});

  final StopwatchController controller;
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
              child: AnalogClock(elapsed: elapsed),
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
