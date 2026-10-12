/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:swatch/core/formatting/duration_format.dart';
import 'package:swatch/core/widgets/analog_clock.dart';
import 'package:swatch/core/widgets/layout_breakpoints.dart';
import 'package:swatch/app/router.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/domain/shopwatch_game_cubit.dart';
import 'package:swatch/features/shopwatch/services/sound_player.dart';
import 'package:swatch/features/shopwatch/shopwatch_dependencies.dart';
import 'package:swatch/features/shopwatch/shopwatch_strings.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/hint_overlay.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/pos_terminal_sheet.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/receipt_list.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/shop_setup_sheet.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/shopping_controls.dart';

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
  final _timerKey = GlobalKey();
  OverlayEntry? _hintsEntry;
  bool _muted = false, _checkingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_autoShowHints()));
  }

  Future<void> _autoShowHints() async {
    final seen = await widget.dependencies.hintsStore.isSeen();
    if (!seen && mounted) _showHints();
  }

  void _showHints() {
    if (_hintsEntry != null) return;
    final entry = OverlayEntry(
      builder: (_) => HintOverlay(
        onDismiss: _dismissHints,
        targets: [
          HintTarget(
            targetKey: _timerKey,
            icon: Icons.timer_outlined,
            title: ShopwatchStrings.classicHintTitle,
            text: ShopwatchStrings.classicHintText,
          ),
          const HintTarget(
            targetKey: ShopwatchKeys.start,
            preferAbove: true,
            icon: Icons.shopping_cart_outlined,
            title: ShopwatchStrings.shopHintTitle,
            text: ShopwatchStrings.shopHintText,
          ),
          const HintTarget(
            targetKey: ShopwatchKeys.pay,
            icon: Icons.contactless,
            title: ShopwatchStrings.payHintTitle,
            text: ShopwatchStrings.payHintText,
          ),
        ],
      ),
    );
    Overlay.of(context).insert(entry);
    setState(() => _hintsEntry = entry);
  }

  void _dismissHints() {
    final entry = _hintsEntry;
    if (entry == null) return;
    entry.remove();
    entry.dispose();
    setState(() => _hintsEntry = null);
    unawaited(widget.dependencies.hintsStore.markSeen());
  }

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
    return paid;
  }

  @override
  void dispose() {
    _hintsEntry?.remove();
    _hintsEntry?.dispose();
    _elapsed.dispose();
    _gameRound.dispose();
    _shopEnabled.dispose();
    unawaited(_sound.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _hintsEntry == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _dismissHints();
        },
        child: _buildScaffold(context),
      );

  Widget _buildScaffold(BuildContext context) => Scaffold(
        appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ValueListenableBuilder<bool>(
                valueListenable: _shopEnabled,
                builder: (context, enabled, _) => IconButton.filled(
                  key: _timerKey,
                  tooltip: ShopwatchStrings.classicHintTitle,
                  onPressed: enabled ? () => Navigator.of(context).pushNamed(AppRoutes.stopwatch) : null,
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
                        applicationLegalese: 'Copyright 2026 Juhász Mátyás (gatsby82)\n'
                            'Licensed under the MIT License.',
                        children: [
                          const SizedBox(height: 32),
                          FilledButton.icon(
                              icon: const Icon(Icons.help_outline),
                              onPressed: () {
                                _showHints();
                                Navigator.of(context).pop();
                              },
                              label: const Text('Show hints'))
                        ],
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

class _ShopwatchControlsState extends State<_ShopwatchControls> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  ShopwatchGameCubit? _game;
  StreamSubscription<GameRound>? _gameSubscription;
  int? _count; // null = unlimited
  // Difficulty selector is temporarily hidden; rounds always play on easy.
  final Difficulty _difficulty = Difficulty.easy;

  ValueNotifier<Duration> get elapsed => widget.elapsed;

  bool get checkingOut => widget.checkingOut;

  ShopwatchDependencies get dependencies => widget.dependencies;

  bool get canShop => !checkingOut && (_game == null || _game!.state.status == RoundStatus.ready);

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
    _ticker.dispose();
    unawaited(_gameSubscription?.cancel());
    unawaited(_game?.close());
    super.dispose();
  }

  Future<void> _shop({bool skipSetup = false}) async {
    final game = _game;
    if (checkingOut) return;
    if (game != null) {
      if (game.state.status == RoundStatus.ready) game.start();
      return;
    }

    if (!skipSetup) {
      final choice = await showShopSetup(context);
      if (choice == null || !mounted) return;
      _count = choice.count;
    }

    final round = ShopwatchGameCubit(
      config: dependencies.config,
      difficulty: _difficulty,
      itemCount: _count,
      roundId: dependencies.newRoundId(),
      random: dependencies.random,
      timeSource: dependencies.timeSource,
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
                        (round.difficulty == Difficulty.normal && value < round.config.normalHideAfter);
                    final text = showTime ? formatElapsed(value) : '--:--.---';
                    final colors = Theme.of(context).colorScheme;
                    return DecoratedBox(
                      decoration: ShapeDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: StadiumBorder(side: BorderSide(color: colors.outlineVariant)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(
                          text,
                          key: ShopwatchKeys.time,
                          semanticsLabel: showTime ? 'Item time $text' : 'Item time hidden',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: ShapeDecoration(
                  shape: StadiumBorder(
                    side: BorderSide(color: Theme.of(context).colorScheme.secondary),
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
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
                    onDoubleStart: canShop ? () => _shop(skipSetup: true) : null,
                    pause: !checkingOut && round?.status == RoundStatus.playing ? _togglePause : null,
                    paused: _game?.isPaused ?? false,
                    add: !checkingOut && round?.status == RoundStatus.playing && !(_game?.isPaused ?? false)
                        ? _addToCart
                        : null,
                    pay: !checkingOut && _game != null ? _checkoutGame : null,
                    onDoublePay: !checkingOut && _game != null ? () => unawaited(_endRound()) : null,
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
                  constraints: MediaQuery.sizeOf(context).width < wideLayoutBreakpoint
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
            final resultsCleared = _lastResultCount > 0 && resultCount == 0;

            void scrollToPosition(double position) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    position,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }

            if (resultsCleared) {
              scrollToPosition(_scrollController.position.minScrollExtent);
            } else if (round?.id == _lastRoundId && resultCount > _lastResultCount) {
              scrollToPosition(_scrollController.position.maxScrollExtent);
            }

            _lastRoundId = round?.id;
            _lastResultCount = resultCount;

            return SingleChildScrollView(
              controller: _scrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: round == null
                    ? const ReceiptList()
                    : ReceiptList(
                        showClear: round.results.isNotEmpty,
                        onClear: !widget.checkingOut && round.results.isNotEmpty ? widget.onClear : null,
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
