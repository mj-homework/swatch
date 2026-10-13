/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

import 'package:swatch/core/swatch/lap.dart';
import 'package:swatch/core/swatch/swatch_controller.dart';
import 'package:swatch/core/formatting/duration_format.dart';
import 'package:swatch/core/widgets/swatch_keys.dart';

/// Card with the recorded laps (newest on top) and a Clear button.
///
/// With at least three laps the fastest and slowest are highlighted.
class LapPanel extends StatelessWidget {
  const LapPanel({super.key, required this.controller});

  final SwatchController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final laps = controller.laps;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        laps.isEmpty ? 'Laps' : 'Laps (${laps.length})',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      key: SwatchKeys.clearLapsButton,
                      onPressed: laps.isEmpty ? null : controller.clearLaps,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              const _LapHeader(),
              const Divider(height: 1),
              Expanded(
                child: laps.isEmpty
                    ? Center(
                        child: Text(
                          'No laps yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : _LapList(laps: laps),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LapHeader extends StatelessWidget {
  const _LapHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('Lap', style: style)),
          Expanded(
            child: Text('Lap time', style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            child: Text('Total', style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _LapList extends StatelessWidget {
  const _LapList({required this.laps});

  final List<Lap> laps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Duration? fastest;
    Duration? slowest;
    if (laps.length >= 3) {
      fastest = laps.map((l) => l.lapTime).reduce((a, b) => a < b ? a : b);
      slowest = laps.map((l) => l.lapTime).reduce((a, b) => a > b ? a : b);
    }

    return ListView.separated(
      key: SwatchKeys.lapList,
      itemCount: laps.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        // Newest lap on top.
        final lap = laps[laps.length - 1 - index];
        Color? highlight;
        if (fastest != null && lap.lapTime == fastest) {
          highlight = colors.primary;
        } else if (slowest != null && lap.lapTime == slowest) {
          highlight = colors.error;
        }
        return _LapRow(key: ValueKey(lap), lap: lap, highlight: highlight);
      },
    );
  }
}

class _LapRow extends StatelessWidget {
  const _LapRow({super.key, required this.lap, this.highlight});

  final Lap lap;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      color: highlight,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text('Lap ${lap.number}', style: base)),
          Expanded(
            child: Text(
              formatElapsed(lap.lapTime),
              style: base?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            child: Text(
              formatElapsed(lap.splitTime),
              style: base,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
