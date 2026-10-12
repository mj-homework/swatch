/*
 *    Copyright (c) 2026 Juhász Mátyás. All rights reserved.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../shopwatch_strings.dart';

class MoodLine extends StatefulWidget {
  const MoodLine({super.key, required this.elapsed, required this.paused});
  final ValueListenable<Duration> elapsed;
  final bool paused;
  @override
  State<MoodLine> createState() => _MoodLineState();
}

class _MoodLineState extends State<MoodLine> {
  late String _text;
  @override
  void initState() {
    super.initState();
    _text = ShopwatchStrings.mood(widget.elapsed.value, widget.paused);
    widget.elapsed.addListener(_update);
  }

  void _update() {
    final text = ShopwatchStrings.mood(widget.elapsed.value, widget.paused);
    if (text != _text) setState(() => _text = text);
  }

  @override
  void didUpdateWidget(MoodLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elapsed != widget.elapsed) {
      oldWidget.elapsed.removeListener(_update);
      widget.elapsed.addListener(_update);
    }
    _text = ShopwatchStrings.mood(widget.elapsed.value, widget.paused);
  }

  @override
  void dispose() {
    widget.elapsed.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text(_text, textAlign: TextAlign.center);
}
