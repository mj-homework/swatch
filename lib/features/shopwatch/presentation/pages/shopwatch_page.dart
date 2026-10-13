/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:swatch/core/widgets/analog_clock.dart';
import 'package:swatch/app/router.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/domain/shopwatch_game_cubit.dart';
import 'package:swatch/core/services/layout_service.dart';
import 'package:swatch/core/services/sound_player.dart';
import 'package:swatch/features/shopwatch/presentation/scan_cue.dart';
import 'package:swatch/app/app_dependencies.dart';
import 'package:swatch/features/shopwatch/presentation/shopwatch_keys.dart';
import 'package:swatch/features/shopwatch/presentation/shopwatch_strings.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/goal_box.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/hint_overlay.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/item_time_display.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/pos_terminal_sheet.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/receipt_panel.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/shop_setup_sheet.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/shopping_buttons.dart';

class ShopwatchPage extends StatefulWidget {
  const ShopwatchPage({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<ShopwatchPage> createState() => _ShopwatchPageState();
}

class _ShopwatchPageState extends State<ShopwatchPage> {
  SoundPlayer get _sound => widget.dependencies.sound;
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
      paid =
          await showCheckout(context, round: round, sound: _sound, muted: _muted, haptic: widget.dependencies.haptic);
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
    unawaited(_sound.stopTicking());
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
                  isWide: LayoutService.isWide(constraints.maxWidth),
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

                final receipt = ReceiptPanel(
                  gameRound: _gameRound,
                  checkingOut: _checkingOut,
                  onClear: () => _controlsKey.currentState?._emptyCart(),
                );

                if (LayoutService.isWide(constraints.maxWidth)) {
                  return Row(
                    children: [
                      Expanded(flex: 2, child: receipt),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: controls),
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
    required this.isWide,
    required this.elapsed,
    required this.shopEnabled,
    required this.checkingOut,
    required this.dependencies,
    required this.sound,
    required this.muted,
    required this.onRoundChanged,
    required this.onPay,
  });

  final bool isWide;
  final ValueNotifier<Duration> elapsed;
  final ValueNotifier<bool> shopEnabled;
  final bool checkingOut;
  final AppDependencies dependencies;
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
  // Add to cart sits where Shop! was, so block it briefly after a long-press start.
  static const _quickStartLockout = Duration(milliseconds: 555);
  Timer? _addLockout;
  int? _count; // null = unlimited
  // Difficulty selector is temporarily hidden; rounds always play on easy.
  final Difficulty _difficulty = Difficulty.easy;

  ValueNotifier<Duration> get elapsed => widget.elapsed;

  bool get checkingOut => widget.checkingOut;

  AppDependencies get dependencies => widget.dependencies;

  bool get canShop => !checkingOut && _game == null;

  @override
  void didUpdateWidget(_ShopwatchControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muted != widget.muted) _syncTicking();
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final game = _game;
      if (game != null) elapsed.value = game.elapsed;
    });
  }

  void _syncTicking() {
    if (_game?.isRunning == true && !widget.muted) {
      unawaited(widget.sound.startTicking());
    } else {
      unawaited(widget.sound.stopTicking());
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _addLockout?.cancel();
    unawaited(_gameSubscription?.cancel());
    unawaited(_game?.close());
    super.dispose();
  }

  Future<void> _shop({bool skipSetup = false}) async {
    final game = _game;
    if (checkingOut) return;
    if (game != null) return;

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
      _syncTicking();
      if (mounted) setState(() {});
    });
    widget.onRoundChanged(round.state);
    setState(() {});
    round.start();
    _syncTicking();
  }

  void _quickStart() {
    _addLockout?.cancel();
    _addLockout = Timer(_quickStartLockout, () {
      if (mounted) setState(() => _addLockout = null);
    });
    unawaited(_shop(skipSetup: true));
  }

  void _togglePause() {
    final game = _game;
    if (game == null) return;
    game.togglePause();
    elapsed.value = game.elapsed;
    if (game.isRunning && !_ticker.isActive) _ticker.start();
    if (!game.isRunning && _ticker.isActive) _ticker.stop();
    _syncTicking();
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
      await widget.sound.play(scanCueForAccuracy(accuracy));
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
    _syncTicking();
    setState(() {});
  }

  Future<void> _endRound() async {
    final game = _game;
    if (game == null) return;
    final subscription = _gameSubscription;
    // Reset the UI first: awaiting the cleanup below must not delay it, and
    // clearing _game keeps dispose() from closing the round a second time.
    _ticker.stop();
    _game = null;
    _gameSubscription = null;
    _addLockout?.cancel();
    _addLockout = null;
    elapsed.value = Duration.zero;
    widget.onRoundChanged(null);
    setState(() {});
    await widget.sound.stopTicking();
    await subscription?.cancel();
    await game.close();
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
          final round = _game?.state;

          clockFace() => AnalogClock(
                elapsed: elapsed,
                goalSec: round?.currentItem?.goal,
                digitalDisplay: ItemTimeDisplay(elapsed: elapsed, round: round),
              );

          goalBox() => GoalBox(round: round);

          buttons() {
            return ShoppingButtons(
              landscape: widget.isWide,
              inGame: _game != null,
              onStart: canShop ? _shop : null,
              onLongStart: canShop ? _quickStart : null,
              onPause: !checkingOut && round?.status == RoundStatus.playing ? _togglePause : null,
              paused: _game?.isPaused ?? false,
              onAdd: !checkingOut &&
                      _addLockout == null &&
                      round?.status == RoundStatus.playing &&
                      !(_game?.isPaused ?? false)
                  ? _addToCart
                  : null,
              onPay: !checkingOut && _game != null ? _checkoutGame : null,
              onLongPay: !checkingOut && _game != null ? () => unawaited(_endRound()) : null,
            );
          }

          if (widget.isWide) {
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
                const SizedBox(height: 8),
                goalBox(),
              ],
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: AspectRatio(aspectRatio: 1, child: clockFace()),
              ),
              const SizedBox(height: 8),
              goalBox(),
              const SizedBox(height: 8),
              buttons(),
            ],
          );
        },
      );
}
