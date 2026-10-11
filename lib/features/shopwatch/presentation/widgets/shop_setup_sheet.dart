import 'dart:async';
import 'package:flutter/material.dart';
import '../../shopwatch_strings.dart';

/// The gamer's choice from the setup sheet. [count] null means unlimited.
class ShopChoice {
  const ShopChoice(this.count);

  final int? count;
}

/// Resolves to null when the gamer cancels.
Future<ShopChoice?> showShopSetup(BuildContext context, {int maxItems = 99}) => showModalBottomSheet<ShopChoice>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: false,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      enableDrag: false,
      builder: (_) => ShopSetupSheet(maxItems: maxItems),
    );

class ShopSetupSheet extends StatefulWidget {
  const ShopSetupSheet({super.key, this.maxItems = 99, this.autoStartSeconds = 5});

  final int maxItems;
  final int autoStartSeconds;

  @override
  State<ShopSetupSheet> createState() => _ShopSetupSheetState();
}

class _ShopSetupSheetState extends State<ShopSetupSheet> {
  static const _unlimited = 'Unlimited';
  int? _count;
  bool _valid = true;
  late final List<String> _options = [
    _unlimited,
    for (var i = 1; i <= widget.maxItems; i++) '$i',
  ];
  final _actionsKey = GlobalKey();
  double? _actionsWidth;
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

  int? _parse(String text) {
    final v = text.trim();
    if (v.isEmpty || v.toLowerCase() == _unlimited.toLowerCase()) {
      _valid = true;
      return null;
    }
    final n = int.tryParse(v);
    _valid = n != null && n >= 1 && n <= widget.maxItems;
    return _valid ? n : _count;
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

  void _measureActions() {
    final width = _actionsKey.currentContext?.size?.width;
    if (mounted && width != null && width != _actionsWidth) {
      setState(() => _actionsWidth = width);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureActions());
    return SizedBox(
      width: double.infinity,
      child: Padding(
        // Lift the sheet above the on-screen keyboard.
        padding: const EdgeInsets.all(24) + EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _actionsWidth,
              child: Autocomplete<String>(
                key: ShopwatchKeys.itemsDropdown,
                initialValue: const TextEditingValue(text: _unlimited),
                optionsViewOpenDirection: OptionsViewOpenDirection.up,
                optionsBuilder: (value) {
                  final query = value.text.trim().toLowerCase();
                  return _options.where((o) => query.isEmpty || query == _unlimited.toLowerCase() || o.toLowerCase().startsWith(query));
                },
                onSelected: (value) {
                  _cancelCountdown();
                  setState(() => _count = _parse(value));
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Items',
                    helperText: 'Unlimited or 1-${widget.maxItems}',
                    errorText: _valid ? null : 'Enter 1-${widget.maxItems}',
                  ),
                  onTap: _cancelCountdown,
                  onChanged: (value) {
                    _cancelCountdown();
                    setState(() => _count = _parse(value));
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              key: _actionsKey,
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                FilledButton(
                  key: ShopwatchKeys.shopConfirm,
                  onPressed: _valid ? () => Navigator.of(context).pop(ShopChoice(_count)) : null,
                  child: Text(_timer == null ? ShopwatchStrings.shop : '${ShopwatchStrings.shop} ($_remaining)'),
                ),
                OutlinedButton(
                  key: ShopwatchKeys.shopCancel,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
