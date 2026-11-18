import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tamabudchi_app/barrel.dart';

void main() {
  setUp(() {
    // A fresh, empty fake store before every test.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('AppSettings bar layout', () {
    test('defaults to split when nothing is stored', () async {
      final settings = AppSettings();
      await settings.load();
      expect(settings.barLayout, BarLayout.split);
    });

    test('a saved choice survives a reload', () async {
      final first = AppSettings();
      await first.setBarLayout(BarLayout.stackedEnd);

      final second = AppSettings(); // like relaunching the app
      await second.load();

      expect(second.barLayout, BarLayout.stackedEnd);
    });

    test('an unknown stored value falls back to split', () async {
      await SharedPreferencesAsync().setString(
        AppSettings.barLayoutKey,
        'diagonal',
      );

      final settings = AppSettings();
      await settings.load();

      expect(settings.barLayout, BarLayout.split);
    });

    test('notifies only on a real change', () async {
      final settings = AppSettings();
      var calls = 0;
      settings.addListener(() => calls++);

      await settings.setBarLayout(BarLayout.swapped);
      await settings.setBarLayout(BarLayout.swapped);

      expect(calls, 1);
    });
  });

  group('AppSettings tile actions', () {
    test('defaults to both', () async {
      final settings = AppSettings();
      await settings.load();
      expect(settings.tileActions, TileActions.both);
    });

    test('a saved choice survives a reload', () async {
      await AppSettings().setTileActions(TileActions.menu);

      final reloaded = AppSettings();
      await reloaded.load();

      expect(reloaded.tileActions, TileActions.menu);
    });

    test('an unknown stored value falls back to both', () async {
      await SharedPreferencesAsync().setString(
        AppSettings.tileActionsKey,
        'telepathy',
      );

      final settings = AppSettings();
      await settings.load();

      expect(settings.tileActions, TileActions.both);
    });

    test('the two settings are stored independently', () async {
      await AppSettings().setTileActions(TileActions.swipe);

      final reloaded = AppSettings();
      await reloaded.load();

      expect(reloaded.tileActions, TileActions.swipe);
      expect(reloaded.barLayout, BarLayout.split); // untouched
    });
  });

  group('AppSettings preferences moved from the library', () {
    test('defaults', () async {
      final settings = AppSettings();
      await settings.load();

      expect(settings.lastGridSize, Sprite.defaultGridSize);
      expect(settings.sortAlphabetically, isFalse);
    });

    test('values saved under the old library keys still load', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('last_grid_size', 12);
      await prefs.setBool('sprites_sort_az', true);

      final settings = AppSettings();
      await settings.load();

      expect(settings.lastGridSize, 12);
      expect(settings.sortAlphabetically, isTrue);
    });

    test('an out-of-range stored grid size is clamped on load', () async {
      await SharedPreferencesAsync().setInt('last_grid_size', 99);

      final settings = AppSettings();
      await settings.load();

      expect(settings.lastGridSize, Sprite.maxGridSize);
    });

    test('setLastGridSize clamps, saves and reloads', () async {
      final first = AppSettings();
      await first.setLastGridSize(99);
      expect(first.lastGridSize, Sprite.maxGridSize);

      final second = AppSettings();
      await second.load();
      expect(second.lastGridSize, Sprite.maxGridSize);
    });

    test('the sort choice saves and reloads', () async {
      await AppSettings().setSortAlphabetically(true);

      final reloaded = AppSettings();
      await reloaded.load();

      expect(reloaded.sortAlphabetically, isTrue);
    });
  });
}
