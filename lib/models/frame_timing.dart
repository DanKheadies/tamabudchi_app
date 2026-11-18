import 'dart:math';

import 'sprite_model.dart';

/// A random multiplier within ±[jitterPercent] of 1.0 (e.g. 30 -> 0.7 to 1.3).
double jitterFactor(int jitterPercent, Random random) {
  final spread = jitterPercent / 100;
  return 1 + (random.nextDouble() * 2 - 1) * spread;
}

/// How long to hold a frame: base time scaled by [factor], never below the
/// sprite minimum so a big jitter can't produce a zero-length frame.
Duration holdDuration(Duration base, double factor) {
  final ms = (base.inMilliseconds * factor).round();
  return Duration(milliseconds: max(Sprite.minFrameMs, ms));
}
