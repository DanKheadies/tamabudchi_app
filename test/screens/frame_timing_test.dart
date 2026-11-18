import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamabudchi_app/barrel.dart';

/// A "random" that always returns the same value, so results are predictable.
class _FixedRandom implements Random {
  final double value;
  _FixedRandom(this.value);

  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

void main() {
  group('jitterFactor', () {
    test('zero jitter is always exactly 1.0', () {
      expect(jitterFactor(0, _FixedRandom(0.9)), 1.0);
    });

    test('spans 1 - j to 1 + j', () {
      expect(jitterFactor(50, _FixedRandom(0.0)), closeTo(0.5, 0.0001));
      expect(jitterFactor(50, _FixedRandom(0.5)), closeTo(1.0, 0.0001));
      expect(jitterFactor(50, _FixedRandom(1.0)), closeTo(1.5, 0.0001));
    });

    test('real random stays inside the range', () {
      final random = Random(1);
      for (var i = 0; i < 500; i++) {
        final f = jitterFactor(30, random);
        expect(f, inInclusiveRange(0.7, 1.3));
      }
    });
  });

  group('holdDuration', () {
    test('scales the base time', () {
      expect(
        holdDuration(const Duration(milliseconds: 400), 1.5),
        const Duration(milliseconds: 600),
      );
    });

    test('never drops below the minimum frame time', () {
      expect(
        holdDuration(const Duration(milliseconds: 100), 0.01),
        const Duration(milliseconds: Sprite.minFrameMs),
      );
    });
  });
}
