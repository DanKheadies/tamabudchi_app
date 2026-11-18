import 'package:flutter_test/flutter_test.dart';
import 'package:tamabudchi_app/barrel.dart';

void main() {
  group('TileActions', () {
    test('menu shows only the menu', () {
      expect(TileActions.menu.showsMenu, isTrue);
      expect(TileActions.menu.showsSwipe, isFalse);
    });

    test('swipe shows only swipe', () {
      expect(TileActions.swipe.showsMenu, isFalse);
      expect(TileActions.swipe.showsSwipe, isTrue);
    });

    test('both shows both', () {
      expect(TileActions.both.showsMenu, isTrue);
      expect(TileActions.both.showsSwipe, isTrue);
    });

    test('every mode leaves at least one way to reach the actions', () {
      for (final mode in TileActions.values) {
        expect(mode.showsMenu || mode.showsSwipe, isTrue, reason: mode.name);
      }
    });
  });
}
