import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../../core/formatting/duration_format.dart';
import '../../../../core/stopwatch/stopwatch_controller.dart';
import '../../shopwatch_dependencies.dart';
import '../../shopwatch_strings.dart';
import '../widgets/mood_line.dart';
import '../widgets/pos_terminal_sheet.dart';
import '../widgets/price_tag_clock.dart';
import '../widgets/receipt_lap_list.dart';
import '../widgets/shopping_controls.dart';

class ShopwatchPage extends StatefulWidget {
  const ShopwatchPage({super.key, required this.dependencies});
  final ShopwatchDependencies dependencies;
  @override
  State<ShopwatchPage> createState() => _ShopwatchPageState();
}
class _ShopwatchPageState extends State<ShopwatchPage> with SingleTickerProviderStateMixin {
  late final _controller = StopwatchController(timeSource: widget.dependencies.timeSource);
  late final _sound = widget.dependencies.soundFactory();
  final _elapsed = ValueNotifier(Duration.zero);
  late final Ticker _ticker;
  bool _muted = false, _checkingOut = false;
  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _elapsed.value = _controller.elapsed);
    _controller.addListener(_changed);
  }
  void _changed() {
    _elapsed.value = _controller.elapsed;
    if (_controller.isRunning && !_ticker.isActive) _ticker.start();
    if (!_controller.isRunning && _ticker.isActive) _ticker.stop();
    setState(() {});
  }
  Future<void> _pay() async {
    if (_checkingOut || (_controller.elapsed == Duration.zero && _controller.laps.isEmpty)) return;
    setState(() => _checkingOut = true);
    _controller.pause();
    final total = _controller.elapsed;
    final laps = _controller.laps.toList();
    try {
      await showCheckout(context, total: total, receipt: ReceiptLapList(laps: laps, total: total),
        sound: _sound, muted: _muted, haptic: widget.dependencies.haptic);
    } finally {
      if (mounted) { _controller.reset(); setState(() => _checkingOut = false); }
    }
  }
  @override
  void dispose() {
    _controller.removeListener(_changed); _ticker.dispose(); _controller.dispose(); _elapsed.dispose();
    unawaited(_sound.dispose()); super.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Shopwatch'), actions: [
      IconButton(key: ShopwatchKeys.mute, tooltip: _muted ? 'Unmute checkout' : 'Mute checkout',
        onPressed: () => setState(() => _muted = !_muted), icon: Icon(_muted ? Icons.volume_off : Icons.volume_up)),
    ]),
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(children: [
        FilledButton.tonalIcon(onPressed: () => Navigator.pushNamed(context, '/shopwatch/game'),
          icon: const Icon(Icons.sports_esports), label: const Text('Time is money • Game & leaderboard')),
        PriceTagClock(elapsed: _elapsed),
        ValueListenableBuilder(valueListenable: _elapsed, builder: (_, value, __) => Column(children: [
          Text(formatElapsed(value), key: ShopwatchKeys.time, style: const TextStyle(fontSize: 36, fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(height: 8),
          ShoppingControls(start: !_checkingOut && _controller.isIdle ? _controller.start : null,
            pause: !_checkingOut && !_controller.isIdle ? _controller.togglePause : null,
            paused: _controller.isPaused,
            add: !_checkingOut && _controller.isRunning ? _controller.lap : null,
            clear: !_checkingOut && _controller.laps.isNotEmpty ? _controller.clearLaps : null,
            pay: !_checkingOut && (value > Duration.zero || _controller.laps.isNotEmpty) ? _pay : null),
        ])),
        const SizedBox(height: 12), MoodLine(elapsed: _elapsed, paused: _controller.isPaused),
        const SizedBox(height: 16),
        ValueListenableBuilder(valueListenable: _elapsed, builder: (_, value, __) => ReceiptLapList(laps: _controller.laps, total: value)),
      ])),
    ))),
  );
}
