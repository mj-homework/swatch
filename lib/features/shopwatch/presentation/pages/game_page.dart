import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/formatting/duration_format.dart';
import '../../../../core/widgets/analog_clock.dart';
import '../../domain/game_config.dart';
import '../../domain/game_round.dart';
import '../../domain/shopwatch_game_cubit.dart';
import '../../shopwatch_dependencies.dart';
import '../../shopwatch_strings.dart';
import '../widgets/pos_terminal_sheet.dart';
import '../widgets/receipt_lap_list.dart';
import '../widgets/shopping_controls.dart';
import 'game_arguments.dart';

class GamePage extends StatefulWidget {
  const GamePage(
      {super.key, required this.dependencies, required this.arguments});

  final ShopwatchDependencies dependencies;
  final GameArguments arguments;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  late final _game = ShopwatchGameCubit(
      config: widget.dependencies.config,
      difficulty: widget.arguments.difficulty,
      itemCount: widget.arguments.count,
      nickname: widget.arguments.nickname,
      roundId: widget.dependencies.newRoundId(),
      random: widget.dependencies.random,
      timeSource: widget.dependencies.timeSource,
      ownedNickname: widget.arguments.owned);
  late final _sound = widget.dependencies.soundFactory();
  final _elapsed = ValueNotifier(Duration.zero);
  late final Ticker _ticker;
  late final StreamSubscription<GameRound> _subscription;
  bool _muted = false, _checkingOut = false, _submitted = false;
  String _upload = '';

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _elapsed.value = _game.elapsed);
    _subscription = _game.stream.listen((round) {
      _elapsed.value = _game.elapsed;
      if (_game.isRunning && !_ticker.isActive) _ticker.start();
      if (!_game.isRunning && _ticker.isActive) _ticker.stop();
    });
  }

  Future<void> _submit(GameRound snapshot) async {
    if (_submitted) return;
    _submitted = true;
    bool success;
    try {
      success = await widget.dependencies.repository
          .submit(snapshot)
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      success = false;
    }
    if (mounted) {
      setState(() => _upload = success
          ? 'Score saved'
          : 'Score not uploaded — local receipt retained');
    }
  }

  Future<void> _pay() async {
    if (_checkingOut || _game.state.status != RoundStatus.finished) return;
    setState(() => _checkingOut = true);
    final snapshot = _game.state;
    if (snapshot.ownedNickname) unawaited(_submit(snapshot));
    await showCheckout(context,
        total: snapshot.totalTime,
        receipt: ReceiptLapList(
            results: snapshot.results, total: snapshot.totalTime),
        sound: _sound,
        muted: _muted,
        haptic: widget.dependencies.haptic);
    if (mounted) {
      _game.reset();
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    unawaited(_subscription.cancel());
    unawaited(_game.close());
    _elapsed.dispose();
    unawaited(_sound.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text('Shopwatch • ${widget.arguments.nickname}'),
            actions: [
              IconButton(
                  key: ShopwatchKeys.mute,
                  tooltip: _muted ? 'Unmute checkout' : 'Mute checkout',
                  onPressed: () => setState(() => _muted = !_muted),
                  icon: Icon(_muted ? Icons.volume_off : Icons.volume_up)),
            ]),
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: BlocBuilder<ShopwatchGameCubit, GameRound>(
                        bloc: _game,
                        builder: (_, round) => Column(children: [
                          if (!round.ownedNickname)
                            const Text(ShopwatchStrings.offline),
                          if (round.currentItem case final item?) ...[
                            const SizedBox(height: 16),
                            Container(
                                padding: const EdgeInsets.all(16),
                                color: ShopwatchStyle.tag,
                                child: Text(
                                    '${item.name.toUpperCase()} — ${(item.goal.inMilliseconds / 1000).toStringAsFixed(3).replaceAll('.', ',')}',
                                    style: const TextStyle(
                                        color: ShopwatchStyle.ink,
                                        fontSize: 24))),
                            Text(
                                'Item ${round.results.length + 1} / ${round.itemCount} • goal in seconds'),
                          ] else
                            const Text('Cart complete! Ready to Pay.'),
                          if (round.difficulty != Difficulty.hard &&
                              round.status != RoundStatus.finished)
                            SizedBox.square(
                              dimension: 230,
                              child: AnalogClock(elapsed: _elapsed),
                            ),
                          ValueListenableBuilder(
                              valueListenable: _elapsed,
                              builder: (_, elapsed, __) {
                                final visible = round.difficulty ==
                                        Difficulty.easy ||
                                    (round.difficulty == Difficulty.normal &&
                                        elapsed < round.config.normalHideAfter);
                                return Text(
                                    visible
                                        ? formatElapsed(elapsed)
                                        : '--:--.---',
                                    key: ShopwatchKeys.time,
                                    semanticsLabel: visible
                                        ? 'Item time ${formatElapsed(elapsed)}'
                                        : 'Item time hidden',
                                    style: const TextStyle(fontSize: 32));
                              }),
                          ShoppingControls(
                              start: round.status == RoundStatus.ready
                                  ? _game.start
                                  : null,
                              add: round.status == RoundStatus.playing
                                  ? _game.addToCart
                                  : null,
                              pay: !_checkingOut &&
                                      round.status == RoundStatus.finished
                                  ? _pay
                                  : null),
                          if (_upload.isNotEmpty) Text(_upload),
                          const SizedBox(height: 16),
                          ReceiptLapList(
                              results: round.results,
                              total: round.totalTime,
                              showTotal: round.status == RoundStatus.finished),
                        ]),
                      )),
                ))),
      );
}
