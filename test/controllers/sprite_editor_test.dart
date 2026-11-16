import 'package:flutter_test/flutter_test.dart';
import 'package:tamabudchi_app/barrel.dart';

SpriteEditor _makeEditor() {
  final editor = SpriteEditor(
    sprite: Sprite(
      id: 'x',
      name: 'Test',
      gridSize: 3,
      frames: [
        {0},
      ],
    ),
  );
  addTearDown(editor.dispose); // cleans up after each test
  return editor;
}

void main() {
  group('setJitterPercent', () {
    test('clamps to 0..max', () {
      final editor = _makeEditor();

      editor.setJitterPercent(500);
      expect(editor.jitterPercent, Sprite.maxJitterPercent);

      editor.setJitterPercent(-5);
      expect(editor.jitterPercent, 0);
    });

    test('is not an undo step', () {
      final editor = _makeEditor();
      editor.setJitterPercent(20);
      expect(editor.canUndo, isFalse);
    });

    test('notifies only on a real change', () {
      final editor = _makeEditor();
      var calls = 0;
      editor.addListener(() => calls++);

      editor.setJitterPercent(20);
      editor.setJitterPercent(20); // same value, nothing should happen

      expect(calls, 1);
    });
  });
}
