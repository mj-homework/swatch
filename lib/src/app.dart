import 'package:flutter/material.dart';

import 'stopwatch/time_source.dart';
import 'ui/stopwatch_page.dart';

/// Root widget of the application.
///
/// [timeSource] can be injected so the whole app can be driven by a fake
/// clock in widget tests.
class StopwatchApp extends StatelessWidget {
  const StopwatchApp({super.key, this.timeSource});

  final TimeSource? timeSource;

  static const _seedColor = Color(0xFF52AE30);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stopwatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: StopwatchPage(timeSource: timeSource),
    );
  }
}
