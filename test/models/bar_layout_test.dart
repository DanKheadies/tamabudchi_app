import 'package:flutter_test/flutter_test.dart';
import 'package:tamabudchi_app/barrel.dart';

void main() {
  group('BarLayout.placement', () {
    test('every layout shows each bar exactly once', () {
      for (final layout in BarLayout.values) {
        final all = [...layout.placement.before, ...layout.placement.after];
        expect(all, unorderedEquals(BarKind.values), reason: layout.name);
      }
    });

    test('swapped trades the sides of split', () {
      expect(BarLayout.split.placement.before, [BarKind.sequence]);
      expect(BarLayout.swapped.placement.before, [BarKind.frames]);
      expect(BarLayout.swapped.placement.after, [BarKind.sequence]);
    });

    test('stacked layouts keep both bars on one side', () {
      expect(BarLayout.stackedStart.placement.after, isEmpty);
      expect(BarLayout.stackedEnd.placement.before, isEmpty);
    });

    test('stackedEnd mirrors stackedStart', () {
      expect(
        BarLayout.stackedEnd.placement.after,
        BarLayout.stackedStart.placement.before.reversed.toList(),
      );
    });
  });
}
