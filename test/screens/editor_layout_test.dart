import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tamabudchi_app/barrel.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  const sizes = <String, Size>{
    'portrait phone': Size(390, 844),
    'landscape phone': Size(844, 390),
    'near-square window': Size(700, 640),
    'short landscape window': Size(700, 320),
  };

  for (final layout in BarLayout.values) {
    for (final entry in sizes.entries) {
      testWidgets('${layout.name} fits a ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final settings = AppSettings();
        await settings.setBarLayout(layout);

        await tester.pumpWidget(
          MaterialApp(
            home: EditorScreen(
              library: SpriteLibrary(),
              settings: settings,
              startEditing: true, // edit mode has the most buttons
              sprite: Sprite(
                id: 'x',
                name: 'Test',
                gridSize: 8,
                frames: [
                  {0},
                  {1},
                ],
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // A layout overflow is reported as an exception.
        expect(tester.takeException(), isNull);
      });
    }
  }
}
