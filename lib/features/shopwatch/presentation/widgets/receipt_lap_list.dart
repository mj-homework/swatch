import 'package:flutter/material.dart';
import '../../../../core/formatting/duration_format.dart';
import '../../../../core/stopwatch/lap.dart';
import '../../domain/game_config.dart';
import '../../domain/game_round.dart';
import '../../shopwatch_strings.dart';

class ReceiptLapList extends StatelessWidget {
  const ReceiptLapList({super.key, this.laps = const [], this.results,
    this.total = Duration.zero, this.showTotal = true});
  final List<Lap> laps;
  final List<ItemResult>? results;
  final Duration total;
  final bool showTotal;
  @override
  Widget build(BuildContext context) {
    int? fastest, slowest;
    if (laps.length >= 3) {
      fastest = 0; slowest = 0;
      for (var i = 1; i < laps.length; i++) {
        if (laps[i].lapTime < laps[fastest!].lapTime) fastest = i;
        if (laps[i].lapTime > laps[slowest!].lapTime) slowest = i;
      }
      // Earliest wins ties. All-equal receipts have only a BEST DEAL.
      if (fastest == slowest) slowest = null;
    }
    final game = results;
    return ClipPath(
      clipper: _TornEdge(),
      child: ColoredBox(color: ShopwatchStyle.paper, child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: DefaultTextStyle(style: ShopwatchStyle.receipt, child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('SHOPWATCH • RECEIPT', textAlign: TextAlign.center),
            const _DashedRule(),
            if ((game ?? laps).isEmpty) const Text(ShopwatchStrings.empty),
            if (game == null) for (var i = 0; i < laps.length; i++) Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text('ITEM ${laps[i].number.toString().padLeft(2, '0')} · ${formatElapsed(laps[i].lapTime)}'
                '${i == fastest ? '  BEST DEAL' : ''}${i == slowest ? '  OVERPRICED' : ''}'
                '\n  running total ${formatElapsed(laps[i].splitTime)}'),
            ),
            if (game != null) for (final result in game) Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('${result.item.name.toUpperCase()}\ngoal ${formatElapsed(result.item.goal)}'
                '\ngot  ${formatElapsed(result.actual)}  ${result.difference.isNegative ? '−' : '+'}${formatElapsed(result.difference.abs())}'
                '\n${result.accuracy.name.toUpperCase()}',
                style: TextStyle(color: switch (result.accuracy) {
                  Accuracy.perfect => const Color(0xFF126A36), Accuracy.close => const Color(0xFF407221),
                  Accuracy.fair => const Color(0xFF8C5800), Accuracy.missed => const Color(0xFFB32121),
                })),
            ),
            const _DashedRule(),
            Text('${game?.length ?? laps.length} items'),
            if (game != null) Text('TOTAL DIFF ${formatElapsed(game.fold(Duration.zero, (sum, r) => sum + r.difference.abs()))}'),
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
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 10),
    child: LayoutBuilder(builder: (_, c) => Text('-' * (c.maxWidth / 9).floor(), maxLines: 1)));
}
class _TornEdge extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(size.width, 0)..lineTo(size.width, size.height - 7);
    for (var x = size.width; x > 0; x -= 12) {
      path..lineTo(x - 6, size.height)..lineTo(x - 12, size.height - 7);
    }
    return path..close();
  }
  @override
  bool shouldReclip(_TornEdge oldClipper) => false;
}
