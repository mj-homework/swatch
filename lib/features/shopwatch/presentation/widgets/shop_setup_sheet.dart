import 'dart:async';
import 'package:flutter/material.dart';
import '../../shopwatch_strings.dart';

/// The gamer's choice from the setup sheet. [count] null means unlimited.
class ShopChoice {
  const ShopChoice(this.count);
  final int? count;
}

/// Resolves to null when the gamer cancels.
Future<ShopChoice?> showShopSetup(BuildContext context,
        {required int maxItems}) =>
    showModalBottomSheet<ShopChoice>(
      context: context,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => ShopSetupSheet(maxItems: maxItems),
    );

class ShopSetupSheet extends StatefulWidget {
  const ShopSetupSheet(
      {super.key, required this.maxItems, this.autoStartSeconds = 3});
  final int maxItems;
  final int autoStartSeconds;

  @override
  State<ShopSetupSheet> createState() => _ShopSetupSheetState();
}

class _ShopSetupSheetState extends State<ShopSetupSheet> {
  int? _count;
  Timer? _timer;
  late int _remaining = widget.autoStartSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        Navigator.of(context).pop(ShopChoice(_count));
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _cancelCountdown() {
    if (_timer == null) return;
    _timer!.cancel();
    _timer = null;
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int?>(
              key: ShopwatchKeys.itemsDropdown,
              initialValue: _count,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Items'),
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('Unlimited')),
                for (var i = 1; i <= widget.maxItems; i++)
                  DropdownMenuItem<int?>(value: i, child: Text('$i')),
              ],
              onTap: _cancelCountdown,
              onChanged: (value) {
                _cancelCountdown();
                setState(() => _count = value);
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                FilledButton(
                  key: ShopwatchKeys.shopConfirm,
                  onPressed: () =>
                      Navigator.of(context).pop(ShopChoice(_count)),
                  child: Text(_timer == null
                      ? ShopwatchStrings.shop
                      : '${ShopwatchStrings.shop} ($_remaining)'),
                ),
                OutlinedButton(
                  key: ShopwatchKeys.shopCancel,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      );
}
