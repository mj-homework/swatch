import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../../core/formatting/duration_format.dart';
import '../../../../core/widgets/analog_clock.dart';
import '../../../../core/widgets/layout_breakpoints.dart';
import '../../data/leaderboard_repository.dart';
import '../../domain/game_config.dart';
import '../../domain/game_round.dart';
import '../../domain/shopwatch_game_cubit.dart';
import '../../shopwatch_dependencies.dart';
import '../../shopwatch_strings.dart';
import '../widgets/mood_line.dart';
import '../widgets/pos_terminal_sheet.dart';
import '../widgets/receipt_lap_list.dart';
import '../widgets/shop_setup_sheet.dart';
import '../widgets/shopping_controls.dart';

class ShopwatchPage extends StatefulWidget {
  const ShopwatchPage({super.key, required this.dependencies});
  final ShopwatchDependencies dependencies;
  @override
  State<ShopwatchPage> createState() => _ShopwatchPageState();
}

class _ShopwatchPageState extends State<ShopwatchPage> {
  late final _sound = widget.dependencies.soundFactory();
  final _elapsed = ValueNotifier(Duration.zero);
  final _gameRound = ValueNotifier<GameRound?>(null);
  final _controlsKey = GlobalKey<_ShopwatchControlsState>();
  bool _muted = false, _checkingOut = false;
  Future<bool> _pay(GameRound round) async {
    if (_checkingOut) {
      return false;
    }
    setState(() => _checkingOut = true);
    var paid = false;
    try {
      paid = await showCheckout(context,
          total: round.totalTime,
          receipt: ReceiptLapList(
            results: round.results,
            total: round.totalTime,
          ),
          sound: _sound,
          muted: _muted,
          haptic: widget.dependencies.haptic);
    } finally {
      if (mounted) {
        setState(() => _checkingOut = false);
      }
    }
    // Only a completed round is submitted to the leaderboard.
    if (paid && round.ownedNickname && round.status == RoundStatus.finished) {
      unawaited(_submit(round));
    }
    return paid;
  }

  Future<void> _submit(GameRound round) async {
    bool success;
    try {
      success = await widget.dependencies.repository
          .submit(round)
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      success = false;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Score saved'
              : 'Score not uploaded — local receipt retained'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _elapsed.dispose();
    _gameRound.dispose();
    unawaited(_sound.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Shopwatch'), actions: [
          // IconButton(
          //     key: ShopwatchKeys.mute,
          //     tooltip: _muted ? 'Unmute checkout' : 'Mute checkout',
          //     onPressed: () => setState(() => _muted = !_muted),
          //     icon: Icon(_muted ? Icons.volume_off : Icons.volume_up)),
        ]),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final controls = _ShopwatchControls(
                  key: _controlsKey,
                  elapsed: _elapsed,
                  checkingOut: _checkingOut,
                  dependencies: widget.dependencies,
                  onRoundChanged: (round) => _gameRound.value = round,
                  onPay: _pay,
                );

                final receipt = _ShopwatchReceipt(
                  gameRound: _gameRound,
                  checkingOut: _checkingOut,
                  onClear: () => _controlsKey.currentState?._emptyCart(),
                );

                if (constraints.maxWidth >= wideLayoutBreakpoint) {
                  return Row(
                    children: [
                      Expanded(flex: 3, child: controls),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: receipt),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(flex: 3, child: controls),
                    const SizedBox(height: 16),
                    Expanded(flex: 2, child: receipt),
                  ],
                );
              },
            ),
          ),
        ),
      );
}

class _ShopwatchControls extends StatefulWidget {
  const _ShopwatchControls({
    super.key,
    required this.elapsed,
    required this.checkingOut,
    required this.dependencies,
    required this.onRoundChanged,
    required this.onPay,
  });

  final ValueNotifier<Duration> elapsed;
  final bool checkingOut;
  final ShopwatchDependencies dependencies;
  final ValueChanged<GameRound?> onRoundChanged;
  final Future<bool> Function(GameRound) onPay;

  @override
  State<_ShopwatchControls> createState() => _ShopwatchControlsState();
}

class _ShopwatchControlsState extends State<_ShopwatchControls>
    with SingleTickerProviderStateMixin {
  late final _nickname = TextEditingController();
  final _policy = const NicknamePolicy();
  Timer? _debounce;
  late final Ticker _ticker;
  ShopwatchGameCubit? _game;
  StreamSubscription<GameRound>? _gameSubscription;
  int _generation = 0;
  int? _count; // null = unlimited
  // Difficulty selector is temporarily hidden; rounds always play on easy.
  final Difficulty _difficulty = Difficulty.easy;
  NicknameStatus _status = NicknameStatus.invalid;
  bool _starting = false;

  ValueNotifier<Duration> get elapsed => widget.elapsed;
  bool get checkingOut => widget.checkingOut;
  ShopwatchDependencies get dependencies => widget.dependencies;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final game = _game;
      if (game != null) elapsed.value = game.elapsed;
    });
  }

  @override
  void dispose() {
    ++_generation;
    _debounce?.cancel();
    _ticker.dispose();
    unawaited(_gameSubscription?.cancel());
    unawaited(_game?.close());
    _nickname.dispose();
    super.dispose();
  }

  void _onNicknameChanged(String value) {
    _debounce?.cancel();
    final generation = ++_generation;
    final valid = _policy.isValid(value);
    setState(() {
      _status = valid ? NicknameStatus.checking : NicknameStatus.invalid;
    });
    if (!valid) return;

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      NicknameStatus status;
      try {
        status = await widget.dependencies.repository
            .check(value)
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        status = NicknameStatus.offline;
      }
      if (mounted && generation == _generation) {
        setState(() => _status = status);
      }
    });
  }

  Future<void> _shop() async {
    final game = _game;
    if (_starting || checkingOut) return;
    if (game != null) {
      if (game.state.status == RoundStatus.ready) game.start();
      return;
    }
    final typed = _nickname.text.trim();
    if (typed.isNotEmpty && !_policy.isValid(typed)) {
      setState(() => _status = NicknameStatus.invalid);
      return;
    }

    final choice = await showShopSetup(context,
        maxItems: dependencies.config.items.length);
    if (choice == null || !mounted) return;
    _count = choice.count;

    _debounce?.cancel();
    ++_generation;
    final nickname = typed.isEmpty ? 'Guest' : typed;
    NicknameStatus reservation = NicknameStatus.offline;
    if (typed.isNotEmpty) {
      setState(() => _starting = true);
      try {
        reservation = await dependencies.repository
            .reserve(nickname)
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        reservation = NicknameStatus.offline;
      }
      if (!mounted) return;
      setState(() {
        _starting = false;
        _status = reservation;
      });
      if (reservation != NicknameStatus.available &&
          reservation != NicknameStatus.offline) {
        return;
      }
    }

    final round = ShopwatchGameCubit(
      config: dependencies.config,
      difficulty: _difficulty,
      itemCount: _count,
      nickname: nickname,
      roundId: dependencies.newRoundId(),
      random: dependencies.random,
      timeSource: dependencies.timeSource,
      ownedNickname: reservation == NicknameStatus.available,
    );
    _game = round;
    _gameSubscription = round.stream.listen((state) {
      elapsed.value = round.elapsed;
      widget.onRoundChanged(state);
      if (round.isRunning && !_ticker.isActive) _ticker.start();
      if (!round.isRunning && _ticker.isActive) _ticker.stop();
      if (mounted) setState(() {});
    });
    widget.onRoundChanged(round.state);
    setState(() {});
    round.start();
  }

  void _togglePause() {
    final game = _game;
    if (game == null) return;
    game.togglePause();
    elapsed.value = game.elapsed;
    if (game.isRunning && !_ticker.isActive) _ticker.start();
    if (!game.isRunning && _ticker.isActive) _ticker.stop();
    setState(() {});
  }

  Future<void> _checkoutGame() async {
    final game = _game;
    if (game == null) return;
    // Pay always pauses; continuing resumes only if it was running.
    final wasRunning = game.isRunning;
    if (wasRunning) _togglePause();
    var leave = false;
    if (game.state.results.isEmpty) {
      leave = await showNothingToPay(context);
    } else {
      leave = await widget.onPay(game.state);
    }
    if (!mounted) return;
    if (leave) {
      await _endRound();
    } else if (wasRunning && game.isPaused) {
      _togglePause();
    }
  }

  void _emptyCart() {
    final game = _game;
    if (game == null) return;
    game.emptyCart();
    elapsed.value = game.elapsed;
    if (game.isRunning && !_ticker.isActive) _ticker.start();
    setState(() {});
  }

  Future<void> _endRound() async {
    final game = _game;
    if (game == null) return;
    _ticker.stop();
    await _gameSubscription?.cancel();
    await game.close();
    _game = null;
    elapsed.value = Duration.zero;
    widget.onRoundChanged(null);
    setState(() {});
  }

  Future<void> _showLeaderboard() async {
    final board = dependencies.repository
        .top(_count ?? dependencies.config.items.length, _difficulty);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top 10 • lower total difference wins'),
        content: SizedBox(
          width: 360,
          child: FutureBuilder(
            future: board,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Text('Loading leaderboard…');
              }
              final entries = snapshot.data;
              if (entries == null) return const Text('Leaderboard offline');
              if (entries.isEmpty) return const Text('No scores yet');
              return ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < entries.length; i++)
                    ListTile(
                      title: Text('${i + 1}. ${entries[i].nickname}'),
                      trailing: Text('${entries[i].totalDiffMs} ms'),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Row(
                children: [
                  // SizedBox(
                  //   width: constraints.maxWidth < 380 ? 140 : 174,
                  //   child: _GameOptions(
                  //     nickname: _nickname,
                  //     status: _status,
                  //     starting: _starting || _game != null,
                  //     onNicknameChanged: _onNicknameChanged,
                  //     onShowLeaderboard: _showLeaderboard,
                  //   ),
                  // ),
                  // const SizedBox(width: 12),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 640,
                        maxHeight: 640,
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: AnalogClock(elapsed: elapsed),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_game?.state.currentItem case final item?) ...[
              const SizedBox(height: 8),
              Text(
                '${item.name.toUpperCase()} • goal ${formatElapsed(item.goal)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _game!.state.isEndless
                    ? 'Item ${_game!.state.results.length + 1}'
                    : 'Item ${_game!.state.results.length + 1} / ${_game!.state.itemCount}',
                textAlign: TextAlign.center,
              ),
            ],
            if (_game?.state.status == RoundStatus.finished)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Cart complete — pay to see your receipt.'),
              ),
            const SizedBox(height: 16),
            ValueListenableBuilder<Duration>(
              valueListenable: elapsed,
              builder: (_, value, __) {
                final round = _game?.state;
                final showTime = round == null ||
                    round.difficulty == Difficulty.easy ||
                    (round.difficulty == Difficulty.normal &&
                        value < round.config.normalHideAfter);
                return Column(
                  children: [
                    Text(
                      showTime ? formatElapsed(value) : '--:--.---',
                      key: ShopwatchKeys.time,
                      semanticsLabel: showTime
                          ? 'Item time ${formatElapsed(value)}'
                          : 'Item time hidden',
                      style: const TextStyle(
                        fontSize: 36,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShoppingControls(
                      start: !checkingOut &&
                              !_starting &&
                              _status != NicknameStatus.taken &&
                              (_nickname.text.trim().isEmpty ||
                                  _policy.isValid(_nickname.text)) &&
                              (round == null ||
                                  round.status == RoundStatus.ready)
                          ? _shop
                          : null,
                      pause:
                          !checkingOut && round?.status == RoundStatus.playing
                              ? _togglePause
                              : null,
                      paused: _game?.isPaused ?? false,
                      add: !checkingOut &&
                              round?.status == RoundStatus.playing &&
                              !(_game?.isPaused ?? false)
                          ? _game!.addToCart
                          : null,
                      pay: !checkingOut && _game != null ? _checkoutGame : null,
                    ),
                  ],
                );
              },
            ),
            // const SizedBox(height: 12),
            // MoodLine(elapsed: elapsed, paused: _game?.isPaused ?? false),
          ],
        ),
      );
}

// class _GameOptions extends StatelessWidget {
//   const _GameOptions({
//     required this.nickname,
//     required this.status,
//     required this.starting,
//     required this.onNicknameChanged,
//     required this.onShowLeaderboard,
//   });
//
//   final TextEditingController nickname;
//   final NicknameStatus status;
//   final bool starting;
//   final ValueChanged<String> onNicknameChanged;
//   final VoidCallback onShowLeaderboard;
//
//   @override
//   Widget build(BuildContext context) => Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Nickname is temporarily hidden.
//           // TextField(
//           //   key: ShopwatchKeys.nickname,
//           //   controller: nickname,
//           //   enabled: !starting,
//           //   onChanged: onNicknameChanged,
//           //   decoration: const InputDecoration(
//           //     labelText: 'Nickname',
//           //     helperText: '3–16 letters, digits or underscore',
//           //     isDense: true,
//           //   ),
//           // ),
//           // const SizedBox(height: 8),
//
//           // const SizedBox(height: 8),
//           // Nickname checking state is temporarily hidden.
//           // Text(
//           //   starting
//           //       ? 'Reserving nickname…'
//           //       : switch (status) {
//           //           NicknameStatus.invalid => nickname.text.trim().isEmpty
//           //               ? 'Optional — needed for the leaderboard.'
//           //               : 'Enter a valid nickname.',
//           //           NicknameStatus.checking => 'Checking…',
//           //           NicknameStatus.available => 'Available ✓',
//           //           NicknameStatus.taken => 'Taken ✗',
//           //           NicknameStatus.offline => ShopwatchStrings.offline,
//           //         },
//           //   semanticsLabel: 'Nickname ${status.name}',
//           //   style: Theme.of(context).textTheme.bodySmall,
//           // ),
//
//           // Top scores button is temporarily hidden.
//           // TextButton(
//           //   onPressed: onShowLeaderboard,
//           //   child: const Text('Top scores'),
//           // ),
//         ],
//       );
// }

class _ShopwatchReceipt extends StatelessWidget {
  const _ShopwatchReceipt({
    required this.gameRound,
    required this.checkingOut,
    required this.onClear,
  });

  final ValueListenable<GameRound?> gameRound;
  final bool checkingOut;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => ValueListenableBuilder<GameRound?>(
          valueListenable: gameRound,
          builder: (_, round, __) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: round == null
                  ? const ReceiptLapList(showClear: true)
                  : ReceiptLapList(
                      showClear: true,
                      onClear: !checkingOut && round.results.isNotEmpty
                          ? onClear
                          : null,
                      results: round.results,
                      total: round.totalTime,
                      showTotal: round.status == RoundStatus.finished,
                    ),
            ),
          ),
        ),
      );
}
