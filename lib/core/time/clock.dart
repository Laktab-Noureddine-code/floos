import 'package:floos/core/time/local_day.dart';

/// Injectable clock so time-dependent rules are testable.
class Clock {
  const Clock();

  DateTime now() => DateTime.now();

  LocalDay today() => LocalDay.fromDateTime(now());
}

/// Fixed clock for tests.
class FixedClock extends Clock {
  const FixedClock(this.fixed);

  final DateTime fixed;

  @override
  DateTime now() => fixed;
}
