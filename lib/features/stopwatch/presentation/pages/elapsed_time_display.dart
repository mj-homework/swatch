/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:swatch/core/formatting/duration_format.dart';
import 'package:swatch/core/widgets/swatch_keys.dart';

/// Digital `MM:SS.mmm` readout.
class ElapsedTimeDisplay extends StatelessWidget {
  const ElapsedTimeDisplay({super.key, required this.elapsed});

  final ValueListenable<Duration> elapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w300,
      color: theme.colorScheme.onSurface,
      // Equal-width digits so the text does not jitter while counting.
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ValueListenableBuilder<Duration>(
        valueListenable: elapsed,
        builder: (context, value, _) {
          final text = formatElapsed(value);
          return Semantics(
            label: 'Elapsed time',
            value: text,
            child: ExcludeSemantics(
              child: Text(text, key: SwatchKeys.elapsedText, style: style),
            ),
          );
        },
      ),
    );
  }
}
