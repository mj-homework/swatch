import 'package:flutter/material.dart';
import '../../../../core/formatting/duration_format.dart';
import '../../../../core/stopwatch/lap.dart';
import '../../domain/game_config.dart';
import '../../domain/game_round.dart';
import '../../shopwatch_strings.dart';

class ReceiptList extends StatelessWidget {
  const ReceiptList(
      {super.key,
      this.laps = const [],
      this.results,
      this.total = Duration.zero,
      this.showTotal = true,
      this.showClear = false,
      this.onClear});

  final List<Lap> laps;
  final List<ItemResult>? results;
  final Duration total;
  final bool showTotal;

  /// Shows the Clear button in the header (disabled while [onClear] is null).
  final bool showClear;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    int? fastest, slowest;
    if (laps.length >= 3) {
      fastest = 0;
      slowest = 0;
      for (var i = 1; i < laps.length; i++) {
        if (laps[i].lapTime < laps[fastest!].lapTime) fastest = i;
        if (laps[i].lapTime > laps[slowest!].lapTime) slowest = i;
      }
      // Earliest wins ties. All-equal receipts have only a BEST DEAL.
      if (fastest == slowest) slowest = null;
    }
    final game = results;
    final averageDiff = game == null || game.isEmpty
        ? null
        : Duration(
            microseconds: game
                    .fold(Duration.zero, (sum, r) => sum + r.difference.abs())
                    .inMicroseconds ~/
                game.length);
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('RECEIPT'),
                        if (showClear)
                          TextButton.icon(
                            key: ShopwatchKeys.clear,
                            onPressed: onClear,
                            icon: const Icon(Icons.delete_sweep_outlined),
                            label: const Text('Put it all back'),
                          ),
                      ],
                    ),
                    const _DashedRule(),
                    if ((game ?? laps).isEmpty)
                      const Text(ShopwatchStrings.empty),
                    // if (game == null)
                    //   for (var i = 0; i < laps.length; i++)
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(vertical: 5),
                    //       child: Text('ITEM ${laps[i].number.toString().padLeft(2, '0')} · ${formatElapsed(laps[i].lapTime)}'
                    //           '${i == fastest ? '  BEST DEAL' : ''}${i == slowest ? '  OVERPRICED' : ''}'
                    //           '\n  running total ${formatElapsed(laps[i].splitTime)}'),
                    //     ),
                    if (game != null)
                      for (final result in game)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: DefaultTextStyle.merge(
                            style: TextStyle(
                                color: switch (result.accuracy) {
                              Accuracy.perfect => const Color(0xFF126A36),
                              Accuracy.close => const Color(0xFF407221),
                              Accuracy.fair => const Color(0xFF8C5800),
                              Accuracy.missed => const Color(0xFFB32121),
                            }),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(result.item.shopItem.receiptLabel),
                                    Text(result.accuracy.name.toUpperCase()),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'goal ${formatElapsed(result.item.goal)}'),
                                    Text(
                                        '${result.difference.isNegative ? '−' : '+'}${formatElapsed(result.difference.abs())}'),
                                  ],
                                ),
                                Text('got  ${formatElapsed(result.actual)}'),
                              ],
                            ),
                          ),
                        ),
                    const _DashedRule(),
                    Text('${game?.length ?? laps.length} items'),
                    if (averageDiff != null)
                      Text('AVERAGE DIFF ${formatElapsed(averageDiff)}'),
                    if (showTotal) Text('TOTAL TIME ${formatElapsed(total)}'),
                  ],
                )),
          )),
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: LayoutBuilder(
          builder: (_, c) =>
              Text('-' * (c.maxWidth / 9).floor(), maxLines: 1)));
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
