/*
 *    Copyright (c) 2026 Juhász Mátyás. All rights reserved.
 */

import 'package:flutter/material.dart';

import '../../../../core/stopwatch/stopwatch_controller.dart';
import '../../../../core/widgets/swatch_keys.dart';

/// Start / Pause(Resume) / Lap / Reset buttons.
///
/// A button is disabled whenever its action would be a no-op in the current
/// state, so the user always sees what is possible.
class ControlButtons extends StatelessWidget {
  const ControlButtons({super.key, required this.controller});

  final StopwatchController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final running = controller.isRunning;
        final paused = controller.isPaused;
        final hasSomethingToReset = !controller.isIdle ||
            controller.elapsed > Duration.zero ||
            controller.laps.isNotEmpty;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: SwatchKeys.startButton,
              onPressed: running ? null : controller.start,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start'),
            ),
            FilledButton.tonalIcon(
              key: SwatchKeys.pauseButton,
              onPressed: running || paused ? controller.togglePause : null,
              icon: Icon(
                paused ? Icons.play_circle_outline_rounded : Icons.pause_rounded,
              ),
              label: Text(paused ? 'Resume' : 'Pause'),
            ),
            OutlinedButton.icon(
              key: SwatchKeys.lapButton,
              onPressed: running ? controller.lap : null,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Lap'),
            ),
            OutlinedButton.icon(
              key: SwatchKeys.resetButton,
              onPressed: hasSomethingToReset ? controller.reset : null,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
