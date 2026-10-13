/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swatch/app/router.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/domain/shopwatch_session_cubit.dart';
import 'package:swatch/core/services/layout_service.dart';
import 'package:swatch/core/services/sound_player.dart';
import 'package:swatch/features/shopwatch/presentation/scan_cue.dart';
import 'package:swatch/app/app_dependencies.dart';
import 'package:swatch/features/shopwatch/presentation/shopwatch_keys.dart';
import 'package:swatch/features/shopwatch/presentation/shopwatch_strings.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/hint_overlay.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/pos_terminal_sheet.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/receipt_panel.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/shopwatch_controls.dart';

class ShopwatchPage extends StatefulWidget {
  const ShopwatchPage({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<ShopwatchPage> createState() => _ShopwatchPageState();
}

class _ShopwatchPageState extends State<ShopwatchPage> {
  SoundPlayer get _sound => widget.dependencies.sound;
  late final _session = ShopwatchSessionCubit(
    config: widget.dependencies.config,
    random: widget.dependencies.random,
    newRoundId: widget.dependencies.newRoundId,
    timeSource: widget.dependencies.timeSource,
  );
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

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _syncTicking();
  }

  /// The tick loop plays while the round's clock runs and sound is on.
  void _syncTicking() {
    if (_session.state.isRunning && !_muted) {
      unawaited(_sound.startTicking());
    } else {
      unawaited(_sound.stopTicking());
    }
  }

  Future<void> _playScan(Accuracy accuracy) async {
    try {
      await _sound.play(scanCueForAccuracy(accuracy));
    } catch (_) {
      // Audio must never block adding an item to the cart.
    }
  }

  @override
  void dispose() {
    _hintsEntry?.remove();
    _hintsEntry?.dispose();
    unawaited(_session.close());
    unawaited(_sound.stopTicking());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _session,
        child: MultiBlocListener(
          listeners: [
            BlocListener<ShopwatchSessionCubit, ShopwatchSession>(
              listenWhen: (previous, current) => previous.isRunning != current.isRunning,
              listener: (_, __) => _syncTicking(),
            ),
            BlocListener<ShopwatchSessionCubit, ShopwatchSession>(
              // A new result in the same round means an item was just scanned.
              listenWhen: (previous, current) =>
                  previous.round?.id == current.round?.id &&
                  (current.round?.results.length ?? 0) > (previous.round?.results.length ?? 0),
              listener: (_, session) {
                if (!_muted) unawaited(_playScan(session.round!.results.last.accuracy));
              },
            ),
          ],
          child: PopScope(
            canPop: _hintsEntry == null,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _dismissHints();
            },
            child: _buildScaffold(context),
          ),
        ),
      );

  Widget _buildScaffold(BuildContext context) => Scaffold(
        appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: BlocSelector<ShopwatchSessionCubit, ShopwatchSession, bool>(
                selector: (session) => session.inGame,
                builder: (context, inGame) => IconButton.filled(
                  key: _timerKey,
                  tooltip: ShopwatchStrings.classicHintTitle,
                  onPressed:
                      !inGame && !_checkingOut ? () => Navigator.of(context).pushNamed(AppRoutes.stopwatch) : null,
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
                  onPressed: _toggleMute,
                  icon: Icon(_muted ? Icons.volume_off : Icons.volume_up)),
            ]),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = LayoutService.isWide(constraints.maxWidth);
                final controls = ShopwatchControls(
                  isWide: isWide,
                  checkingOut: _checkingOut,
                  onPay: _pay,
                );

                final receipt = BlocSelector<ShopwatchSessionCubit, ShopwatchSession, GameRound?>(
                  selector: (session) => session.round,
                  builder: (_, round) => ReceiptPanel(
                    round: round,
                    checkingOut: _checkingOut,
                    onClear: _session.emptyCart,
                  ),
                );

                if (isWide) {
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
