/// Abstraction over a monotonic clock.
///
/// The stopwatch logic never reads the wall clock directly, which keeps it
/// deterministic and fully testable: tests inject a fake implementation and
/// advance time manually instead of sleeping.
abstract interface class TimeSource {
  /// A monotonically increasing timestamp. Only differences between two
  /// values are meaningful.
  Duration now();
}

/// Production [TimeSource] backed by [Stopwatch], which is monotonic and is
/// not affected by changes of the system clock (e.g. DST, manual changes).
class MonotonicTimeSource implements TimeSource {
  MonotonicTimeSource() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration now() => _stopwatch.elapsed;
}
