/*
 *    Copyright (c) 2026 Juhász Mátyás. All rights reserved.
 */

/// Formats a duration as `MM:SS.mmm` (minutes, seconds, milliseconds).
///
/// Minutes are not wrapped at 60, so 75 minutes is shown as `75:00.000`.
/// Negative durations are clamped to zero.
String formatElapsed(Duration duration) {
  final d = duration.isNegative ? Duration.zero : duration;
  final minutes = d.inMinutes.toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  final millis = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
  return '$minutes:$seconds.$millis';
}
