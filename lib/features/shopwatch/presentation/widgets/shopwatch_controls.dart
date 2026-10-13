/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swatch/core/widgets/analog_clock.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/domain/shopwatch_session_cubit.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/goal_box.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/item_time_display.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/pos_terminal_sheet.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/shop_setup_sheet.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/shopping_buttons.dart';

/// Clock, goal box and shopping buttons. Drives the [ShopwatchSessionCubit]
/// found in the context; owns only UI concerns (frame ticker, quick-start
/// lockout, setup dialog).
class ShopwatchControls extends StatefulWidget {
  const ShopwatchControls({
    super.key,
    required this.isWide,
    required this.checkingOut,
    required this.onPay,
  });

  final bool isWide;
  final bool checkingOut;

  /// Shows the checkout for a round with items; resolves to true when paid.
  final Future<bool> Function(GameRound) onPay;

  @override
  State<ShopwatchControls> createState() => _ShopwatchControlsState();
}

class _ShopwatchControlsState extends State<ShopwatchControls> with SingleTickerProviderStateMixin {
  late final ShopwatchSessionCubit _session = context.read<ShopwatchSessionCubit>();
  final _elapsed = ValueNotifier(Duration.zero);
  late final Ticker _ticker;
  // Add to cart sits where Shop! was, so block it briefly after a long-press start.
  static const _quickStartLockout = Duration(milliseconds: 555);
  Timer? _addLockout;
  int? _count; // null = unlimited
  // Difficulty selector is temporarily hidden; rounds always play on easy.
  final Difficulty _difficulty = Difficulty.easy;

  bool get checkingOut => widget.checkingOut;

  bool get canShop => !checkingOut && !_session.state.inGame;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _elapsed.value = _session.elapsed);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    _addLockout?.cancel();
    super.dispose();
  }

  /// Keeps the readout and the frame ticker in step with the session.
  void _onSessionChanged(BuildContext context, ShopwatchSession session) {
    _elapsed.value = _session.elapsed;
    if (session.isRunning && !_ticker.isActive) _ticker.start();
    if (!session.isRunning && _ticker.isActive) _ticker.stop();
    if (!session.inGame && _addLockout != null) {
      _addLockout!.cancel();
      setState(() => _addLockout = null);
    }
  }

  Future<void> _shop({bool skipSetup = false}) async {
    if (!canShop) return;

    if (!skipSetup) {
      final choice = await showShopSetup(context);
      if (choice == null || !mounted) return;
      _count = choice.count;
    }

    _session.start(itemCount: _count, difficulty: _difficulty);
  }

  void _quickStart() {
    _addLockout?.cancel();
    _addLockout = Timer(_quickStartLockout, () {
      if (mounted) setState(() => _addLockout = null);
    });
    unawaited(_shop(skipSetup: true));
  }

  Future<void> _checkoutGame() async {
    final round = _session.state.round;
    if (round == null) return;
    // Pay always pauses; continuing resumes only if it was running.
    final wasRunning = _session.state.isRunning;
    if (wasRunning) _session.togglePause();
    final leave = round.results.isEmpty ? await showNothingToPay(context) : await widget.onPay(_session.state.round!);
    // The round may have ended while the sheet was open.
    if (!mounted || _session.state.round?.id != round.id) return;
    if (leave) {
      await _session.endRound();
    } else if (wasRunning && _session.state.isPaused) {
      _session.togglePause();
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ShopwatchSessionCubit, ShopwatchSession>(
        listener: _onSessionChanged,
        builder: (context, session) {
          final round = session.round;

          clockFace() => AnalogClock(
                elapsed: _elapsed,
                goalSec: round?.currentItem?.goal,
                digitalDisplay: ItemTimeDisplay(elapsed: _elapsed, round: round),
              );

          final buttons = ShoppingButtons(
            landscape: widget.isWide,
            inGame: session.inGame,
            onStart: canShop ? _shop : null,
            onLongStart: canShop ? _quickStart : null,
            onPause: !checkingOut && round?.status == RoundStatus.playing ? _session.togglePause : null,
            paused: session.isPaused,
            onAdd: !checkingOut && _addLockout == null && round?.status == RoundStatus.playing && !session.isPaused
                ? _session.addToCart
                : null,
            onPay: !checkingOut && session.inGame ? _checkoutGame : null,
            onLongPay: !checkingOut && session.inGame ? () => unawaited(_session.endRound()) : null,
          );

          if (widget.isWide) {
            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      AspectRatio(aspectRatio: 1, child: clockFace()),
                      const SizedBox(width: 16),
                      Expanded(child: Center(child: buttons)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GoalBox(round: round),
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
              GoalBox(round: round),
              const SizedBox(height: 8),
              buttons,
            ],
          );
        },
      );
}
