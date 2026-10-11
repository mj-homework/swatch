import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/formatting/duration_format.dart';
import '../../services/sound_player.dart';
import '../../shopwatch_strings.dart';

/// Resolves to true only when the gamer paid and closed the sheet with Done.
Future<bool> showCheckout(BuildContext context,
        {required Duration total,
        required Duration averageDiff,
        required bool isEndless,
        required Widget receipt,
        required SoundPlayer sound,
        required bool muted,
        required Future<void> Function() haptic}) =>
    showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => PosTerminalSheet(
            total: total,
            averageDiff: averageDiff,
            isEndless: isEndless,
            receipt: receipt,
            sound: sound,
            muted: muted,
            haptic: haptic))
        .then((paid) => paid ?? false);

/// Returns true when the gamer chooses to cancel shopping.
Future<bool> showNothingToPay(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Nothing to pay.',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          Wrap(spacing: 12, children: [
            FilledButton(
                key: ShopwatchKeys.cancelShopping,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancel anyway')),
            OutlinedButton(
                key: ShopwatchKeys.continueShopping,
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continue')),
          ]),
        ]),
      ),
    ) ??
    false;

class PosTerminalSheet extends StatefulWidget {
  const PosTerminalSheet(
      {super.key, required this.total, required this.averageDiff, required this.isEndless, required this.receipt, required this.sound, required this.muted, required this.haptic});

  final Duration total;
  final Duration averageDiff;
  final bool isEndless;
  final Widget receipt;
  final SoundPlayer sound;
  final bool muted;
  final Future<void> Function() haptic;

  @override
  State<PosTerminalSheet> createState() => _PosTerminalSheetState();
}

class _PosTerminalSheetState extends State<PosTerminalSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))
    ..repeat(reverse: true);
  bool _approved = false, _closing = false;

  Future<void> _effect(Future<void> Function() effect) async {
    try {
      await effect();
    } catch (_) {
      /* Effects are best effort. */
    }
  }

  void _approve() {
    if (!mounted || _closing || _approved) return;
    _pulse.stop();
    setState(() => _approved = true);
    if (!widget.muted) unawaited(_effect(widget.sound.playCheckoutBeep));
    unawaited(_effect(widget.haptic));
  }

  void _close([bool paid = false]) {
    if (_closing) return;
    _closing = true;
    _pulse.stop();
    Navigator.of(context).pop(paid);
  }

  @override
  void dispose() {
    _closing = true;
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) _closing = true;
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AVERAGE DIFF: ${formatElapsed(widget.averageDiff)}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 22)),
                if (!_approved) ...[
                  IconButton(
                    onPressed: _approve,
                    iconSize: 72,
                    icon: FadeTransition(
                      opacity: Tween(begin: .35, end: 1.0).animate(_pulse),
                      child: const Icon(Icons.contactless),
                    ),
                  ),
                  // const Text('Contactless'),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, children: [
                    // FilledButton(key: ShopwatchKeys.confirmPay, onPressed: _approve, child: const Text('Pay')),
                    OutlinedButton(
                      key: ShopwatchKeys.skip,
                      onPressed: _close,
                      child: Text(widget.isEndless ? 'Continue shopping' : 'Cancel'),
                    ),
                  ]),
                ] else ...[
                  // const SizedBox(height: 12),
                  // const Icon(Icons.check_circle, color: ShopwatchStyle.approved, size: 48),
                  // const Text(ShopwatchStrings.approved),
                  // const Text(ShopwatchStrings.finePrint),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(child: widget.receipt),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: ShopwatchKeys.dismiss,
                    onPressed: () => _close(true),
                    child: const Text('Bag it & go'),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
}
