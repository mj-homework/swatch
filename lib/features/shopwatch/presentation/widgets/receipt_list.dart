/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';
import 'package:swatch/core/formatting/duration_format.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/presentation/shopwatch_keys.dart';
import 'package:swatch/features/shopwatch/presentation/shopwatch_strings.dart';
import 'package:swatch/features/shopwatch/presentation/shopwatch_style.dart';

class ReceiptList extends StatelessWidget {
  const ReceiptList({super.key, this.round, this.showTotal = true, this.showClear = false, this.onClear});

  /// Round to print; null prints an empty receipt.
  final GameRound? round;
  final bool showTotal;

  /// Shows the Clear button in the header (disabled while [onClear] is null).
  final bool showClear;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final results = round?.results ?? const <ItemResult>[];

    // Side by side when the receipt is wide enough, stacked when it is not.
    lastRow() => Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          children: [
            Text('${results.length} items'),
            if (results.isNotEmpty) Text('AVERAGE DIFF: ${formatElapsed(round!.averageError)}'),
          ],
        );

    return ClipPath(
      clipper: _TornEdge(),
      child: ColoredBox(
          color: ShopwatchStyle.paper,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 23, 16, 28),
            child: DefaultTextStyle(
                style: ShopwatchStyle.receipt,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('RECEIPT'),
                    const _DashedRule(),
                    if (results.isEmpty) const Text(ShopwatchStrings.empty),
                    for (final result in results)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: DefaultTextStyle.merge(
                          style: TextStyle(color: ShopwatchStyle.accuracy(result.accuracy)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      result.item.shopItem.receiptLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(result.accuracy.name.toUpperCase()),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('goal ${formatElapsed(result.item.goal)}'),
                                  Text('${result.difference.isNegative ? '−' : '+'}'
                                      '${formatElapsed(result.difference.abs())}'),
                                ],
                              ),
                              Text('got  ${formatElapsed(result.actual)}'),
                            ],
                          ),
                        ),
                      ),
                    const _DashedRule(),
                    lastRow(),
                    if (showTotal) Text('TOTAL TIME ${formatElapsed(round?.totalTime ?? Duration.zero)}'),
                    if (showClear)
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            key: ShopwatchKeys.clear,
                            onPressed: onClear,
                            icon: const Icon(Icons.delete_sweep_outlined),
                            label: const Text(ShopwatchStrings.clear),
                          ),
                        ],
                      ),
                  ],
                )),
          )),
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (_, c) => Text('-' * (c.maxWidth / 9).floor(), maxLines: 1));
}

class _TornEdge extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, 7);
    for (var x = 0.0; x < size.width; x += 12) {
      path
        ..lineTo(x + 6, 0)
        ..lineTo(x + 12, 7);
    }
    path
      ..lineTo(size.width, 7)
      ..lineTo(size.width, size.height - 7);
    for (var x = size.width; x > 0; x -= 12) {
      path
        ..lineTo(x - 6, size.height)
        ..lineTo(x - 12, size.height - 7);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_TornEdge oldClipper) => false;
}
