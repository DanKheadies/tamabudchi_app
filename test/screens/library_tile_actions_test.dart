import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tamabudchi_app/barrel.dart';

Future<AppSettings> _pumpLibrary(WidgetTester tester, TileActions mode) async {
  final library = SpriteLibrary();
  await library.load(); // empty storage loads the starter sprites
  final settings = AppSettings();
  await settings.setTileActions(mode);

  await tester.pumpWidget(
    MaterialApp(
      home: LibraryScreen(library: library, settings: settings),
    ),
  );
  return settings;
}

/// The menu button inside each sprite tile (not the one in the app bar).
Finder get _tileMenus => find.descendant(
  of: find.byType(ListTile),
  matching: find.byTooltip('Show menu'),
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  for (final mode in TileActions.values) {
    testWidgets('${mode.name}: menu button and swiping match the setting', (
      tester,
    ) async {
      await _pumpLibrary(tester, mode);

      final tiles = find.byType(ListTile).evaluate().length;
      expect(tiles, greaterThan(0));
      expect(_tileMenus, mode.showsMenu ? findsNWidgets(tiles) : findsNothing);

      final slidable = tester.widget<Slidable>(find.byType(Slidable).first);
      expect(slidable.enabled, mode.showsSwipe);
    });
  }

  testWidgets('swiping a tile reveals its actions', (tester) async {
    await _pumpLibrary(tester, TileActions.both);

    await tester.drag(find.byType(ListTile).first, const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('changing the setting updates the open screen', (tester) async {
    final settings = await _pumpLibrary(tester, TileActions.both);
    expect(_tileMenus, findsWidgets);

    await settings.setTileActions(TileActions.swipe);
    await tester.pump();

    expect(_tileMenus, findsNothing);
  });

  testWidgets('opening a second tile closes the first', (tester) async {
    await _pumpLibrary(tester, TileActions.both);
    double left(int i) => tester.getTopLeft(find.byType(ListTile).at(i)).dx;

    await tester.drag(
      find.byType(ListTile).at(0),
      const Offset(300, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(left(0), greaterThan(100)); // first tile is open

    await tester.drag(
      find.byType(ListTile).at(1),
      const Offset(300, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(left(1), greaterThan(100)); // second is open
    expect(left(0), closeTo(0, 1)); // first closed itself
  });
}
