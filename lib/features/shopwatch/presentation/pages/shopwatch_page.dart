/*
 *    Copyright (c) 2026 Juhász Mátyás. All rights reserved.
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../../core/formatting/duration_format.dart';
import '../../../../core/widgets/analog_clock.dart';
import '../../../../core/widgets/layout_breakpoints.dart';
import '../../../../app/router.dart';
import '../../data/leaderboard_repository.dart';
import '../../domain/game_config.dart';
import '../../domain/game_round.dart';
import '../../domain/shop_item.dart';
import '../../domain/shopwatch_game_cubit.dart';
import '../../services/sound_player.dart';
import '../../shopwatch_dependencies.dart';
import '../../shopwatch_strings.dart';
import '../widgets/pos_terminal_sheet.dart';
import '../widgets/receipt_list.dart';
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
  final _shopEnabled = ValueNotifier(true);
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
          averageDiff: round.averageError,
          isEndless: round.isEndless,
          receipt: ReceiptList(
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
    _shopEnabled.dispose();
    unawaited(_sound.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ValueListenableBuilder<bool>(
                valueListenable: _shopEnabled,
                builder: (context, enabled, _) => IconButton.filled(
                  onPressed: enabled
                      ? () =>
                          Navigator.of(context).pushNamed(AppRoutes.stopwatch)
                      : null,
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  icon: const Icon(Icons.timer_outlined),
                  // label: const Text(''),
                ),
              ),
            ),
            title: const Text('Shopwatch', textAlign: TextAlign.center),
            centerTitle: true,
            actions: [
              IconButton(
                  tooltip: 'About Shopwatch',
                  onPressed: () => showAboutDialog(
                    context: context,
                    applicationName: 'Shopwatch',
                    applicationLegalese:
                        'Copyright 2026 Juhász Mátyás (gatsby82)\n'
                        'Licensed under the MIT License.',
                  ),
                  icon: const Icon(Icons.info_outline)),
              IconButton(
                  key: ShopwatchKeys.mute,
                  tooltip: _muted ? 'Unmute sounds' : 'Mute sounds',
                  onPressed: () => setState(() => _muted = !_muted),
                  icon: Icon(_muted ? Icons.volume_off : Icons.volume_up)),
            ]),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final controls = _ShopwatchControls(
                  landscape: constraints.maxWidth > wideLayoutBreakpoint,
                  key: _controlsKey,
                  elapsed: _elapsed,
                  shopEnabled: _shopEnabled,
                  checkingOut: _checkingOut,
                  dependencies: widget.dependencies,
                  sound: _sound,
                  muted: _muted,
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
                    Expanded(flex: 5, child: controls),
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
    required this.landscape,
    required this.elapsed,
    required this.shopEnabled,
    required this.checkingOut,
    required this.dependencies,
    required this.sound,
    required this.muted,
    required this.onRoundChanged,
    required this.onPay,
  });

  final bool landscape;
  final ValueNotifier<Duration> elapsed;
  final ValueNotifier<bool> shopEnabled;
  final bool checkingOut;
  final ShopwatchDependencies dependencies;
  final SoundPlayer sound;
  final bool muted;
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

  bool get canShop =>
      !checkingOut &&
      !_starting &&
      _status != NicknameStatus.taken &&
      (_nickname.text.trim().isEmpty || _policy.isValid(_nickname.text)) &&
      (_game == null || _game!.state.status == RoundStatus.ready);

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

  // void _onNicknameChanged(String value) {
  //   _debounce?.cancel();
  //   final generation = ++_generation;
  //   final valid = _policy.isValid(value);
  //   setState(() {
  //     _status = valid ? NicknameStatus.checking : NicknameStatus.invalid;
  //   });
  //   if (!valid) return;
  //
  //   _debounce = Timer(const Duration(milliseconds: 400), () async {
  //     NicknameStatus status;
  //     try {
  //       status = await widget.dependencies.repository.check(value).timeout(const Duration(seconds: 6));
  //     } catch (_) {
  //       status = NicknameStatus.offline;
  //     }
  //     if (mounted && generation == _generation) {
  //       setState(() => _status = status);
  //     }
  //   });
  // }

  Future<void> _shop({bool skipSetup = false}) async {
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

    if (!skipSetup) {
      final choice = await showShopSetup(context);
      if (choice == null || !mounted) return;
      _count = choice.count;
    }

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

  void _addToCart() {
    final game = _game;
    if (game == null) return;
    final previousCount = game.state.results.length;
    game.addToCart();
    if (!widget.muted && game.state.results.length > previousCount) {
      unawaited(_playScan(game.state.results.last.accuracy));
    }
  }

  Future<void> _playScan(Accuracy accuracy) async {
    try {
      await widget.sound.playScan(accuracy);
    } catch (_) {
      // Audio must never block adding an item to the cart.
    }
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
        .top(_count ?? shopItemCombinationCount, _difficulty);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top 10 • lower average difference wins'),
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
                      trailing: Text(
                          '${entries[i].averageDiffMs.toStringAsFixed(1)} ms'),
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
        builder: (context, constraints) {
          final enabled = canShop;
          if (widget.shopEnabled.value != enabled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final currentEnabled = canShop;
              if (widget.shopEnabled.value != currentEnabled) {
                widget.shopEnabled.value = currentEnabled;
              }
            });
          }
          final item = _game?.state.currentItem;

          Widget clockFace() => AnalogClock(
                elapsed: elapsed,
                goalSec: _game?.state.currentItem?.goal,
                isRunning: _game?.isRunning ?? false,
                muted: widget.muted,
                digitalDisplay: ValueListenableBuilder<Duration>(
                  valueListenable: elapsed,
                  builder: (context, value, __) {
                    final round = _game?.state;
                    final showTime = round == null ||
                        round.difficulty == Difficulty.easy ||
                        (round.difficulty == Difficulty.normal &&
                            value < round.config.normalHideAfter);
                    final text = showTime ? formatElapsed(value) : '--:--.---';
                    final colors = Theme.of(context).colorScheme;
                    return DecoratedBox(
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: StadiumBorder(
                            side: BorderSide(color: colors.outlineVariant)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Text(
                          text,
                          key: ShopwatchKeys.time,
                          semanticsLabel:
                              showTime ? 'Item time $text' : 'Item time hidden',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );

          Widget goalBox() => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: ShapeDecoration(
                  shape: StadiumBorder(
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item == null)
                      Text(
                        'Add to cart at exactly the right millisecond!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Collect ${item.shopItem.receiptLabel} at',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatElapsed(item.goal),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    if (item != null && !_game!.state.isEndless)
                      Text(
                        'Item ${_game!.state.results.length + 1} / ${_game!.state.itemCount}',
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              );

          Widget finishedNote() => const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Cart complete — pay to see your receipt.'),
              );

          Widget buttons() => ValueListenableBuilder<Duration>(
                valueListenable: elapsed,
                builder: (_, __, ___) {
                  final round = _game?.state;
                  return ShoppingControls(
                    start: canShop ? _shop : null,
                    onDoubleStart:
                        canShop ? () => _shop(skipSetup: true) : null,
                    pause: !checkingOut && round?.status == RoundStatus.playing
                        ? _togglePause
                        : null,
                    paused: _game?.isPaused ?? false,
                    add: !checkingOut &&
                            round?.status == RoundStatus.playing &&
                            !(_game?.isPaused ?? false)
                        ? _addToCart
                        : null,
                    pay: !checkingOut && _game != null ? _checkoutGame : null,
                    onDoublePay: !checkingOut && _game != null
                        ? () => unawaited(_endRound())
                        : null,
                  );
                },
              );

          if (widget.landscape) {
            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      AspectRatio(aspectRatio: 1, child: clockFace()),
                      const SizedBox(width: 16),
                      Expanded(child: Center(child: buttons())),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                goalBox(),
                if (_game?.state.status == RoundStatus.finished) finishedNote(),
              ],
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints:
                      MediaQuery.sizeOf(context).width < wideLayoutBreakpoint
                          ? const BoxConstraints()
                          : const BoxConstraints(maxWidth: 640, maxHeight: 640),
                  child: AspectRatio(aspectRatio: 1, child: clockFace()),
                ),
              ),
              const SizedBox(height: 16),
              goalBox(),
              if (_game?.state.status == RoundStatus.finished) finishedNote(),
              const SizedBox(height: 16),
              const SizedBox(height: 8),
              buttons(),
              const SizedBox(height: 12),
            ],
          );
        },
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

class _ShopwatchReceipt extends StatefulWidget {
  const _ShopwatchReceipt({
    required this.gameRound,
    required this.checkingOut,
    required this.onClear,
  });

  final ValueListenable<GameRound?> gameRound;
  final bool checkingOut;
  final VoidCallback onClear;

  @override
  State<_ShopwatchReceipt> createState() => _ShopwatchReceiptState();
}

class _ShopwatchReceiptState extends State<_ShopwatchReceipt> {
  final _scrollController = ScrollController();
  String? _lastRoundId;
  int _lastResultCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => ValueListenableBuilder<GameRound?>(
          valueListenable: widget.gameRound,
          builder: (_, round, __) {
            final resultCount = round?.results.length ?? 0;
            if (round?.id == _lastRoundId && resultCount > _lastResultCount) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
            _lastRoundId = round?.id;
            _lastResultCount = resultCount;
            return SingleChildScrollView(
              controller: _scrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: round == null
                    ? const ReceiptList(showClear: true)
                    : ReceiptList(
                        showClear: true,
                        onClear: !widget.checkingOut && round.results.isNotEmpty
                            ? widget.onClear
                            : null,
                        results: round.results,
                        total: round.totalTime,
                        showTotal: round.status == RoundStatus.finished,
                      ),
              ),
            );
          },
        ),
      );
}
