import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/formatting/duration_format.dart';
import '../../services/sound_player.dart';
import '../../shopwatch_strings.dart';

/// Inputs are frozen by the caller. Closing by any route completes checkout.
Future<void> showCheckout(BuildContext context, {required Duration total,
  required Widget receipt, required SoundPlayer sound, required bool muted,
  required Future<void> Function() haptic}) => showModalBottomSheet<void>(
    context: context, isScrollControlled: true, useSafeArea: true,
    builder: (_) => PosTerminalSheet(total: total, receipt: receipt, sound: sound, muted: muted, haptic: haptic));

class PosTerminalSheet extends StatefulWidget {
  const PosTerminalSheet({super.key, required this.total, required this.receipt,
    required this.sound, required this.muted, required this.haptic});
  final Duration total;
  final Widget receipt;
  final SoundPlayer sound;
  final bool muted;
  final Future<void> Function() haptic;
  @override
  State<PosTerminalSheet> createState() => _PosTerminalSheetState();
}
class _PosTerminalSheetState extends State<PosTerminalSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..repeat(reverse: true);
  Timer? _timer;
  bool _approved = false, _closing = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 1), _approve);
  }
  Future<void> _effect(Future<void> Function() effect) async {
    try { await effect(); } catch (_) { /* Effects are best effort. */ }
  }
  void _approve() {
    if (!mounted || _closing || _approved) return;
    _pulse.stop();
    setState(() => _approved = true);
    if (!widget.muted) unawaited(_effect(widget.sound.playCheckoutBeep));
    unawaited(_effect(widget.haptic));
  }
  void _close() {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    _pulse.stop();
    Navigator.of(context).pop();
  }
  @override
  void dispose() { _closing = true; _timer?.cancel(); _pulse.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, _) { if (didPop) { _closing = true; _timer?.cancel(); } },
    child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('TOTAL: ${formatElapsed(widget.total)}', style: const TextStyle(fontFamily: 'monospace', fontSize: 22)),
        if (!_approved) ...[
          FadeTransition(opacity: Tween(begin: .35, end: 1.0).animate(_pulse), child: const Icon(Icons.contactless, size: 72)),
          const Text('Contactless'),
          TextButton(key: ShopwatchKeys.skip, onPressed: _close, child: const Text('Tap to skip • reset now')),
        ] else ...[
          const Icon(Icons.check_circle, color: ShopwatchStyle.approved, size: 48),
          const Text(ShopwatchStrings.approved),
          const Text(ShopwatchStrings.finePrint),
          const SizedBox(height: 12), widget.receipt,
          FilledButton(key: ShopwatchKeys.dismiss, onPressed: _close, child: const Text('Done • reset')),
        ],
      ])),
    ),
  );
}
