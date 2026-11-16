import 'package:flutter_test/flutter_test.dart';
import 'package:tamabudchi_app/models/sprite_model.dart';

void main() {
  group('Sprite JSON', () {
    test('round-trips through toJson and fromJson', () {
      final sprite = Sprite(
        id: 'a1',
        name: 'Blinky',
        gridSize: 4,
        frames: [
          {0, 5, 10},
          {1, 2},
        ],
        folders: {'Pets'},
        onDesktop: false,
        frameMs: 250,
      );

      final copy = Sprite.fromJson(sprite.toJson());

      expect(copy.toJson(), sprite.toJson());
    });

    test('old exports missing optional fields get defaults', () {
      final sprite = Sprite.fromJson({
        'id': 'x',
        'name': 'Old',
        'gridSize': 3,
        'frames': [
          [0, 1],
        ],
      });

      expect(sprite.frameMs, Sprite.defaultFrameMs);
      expect(sprite.folders, isEmpty);
      expect(sprite.onDesktop, isTrue);
    });

    test('pixels outside the grid are dropped on import', () {
      // A 3x3 grid has cells 0..8, so 9 and 40 don't exist.
      final sprite = Sprite.fromJson({
        'id': 'x',
        'name': 'Stray',
        'gridSize': 3,
        'frames': [
          [0, 8, 9, 40],
        ],
      });

      expect(sprite.frames.first, {0, 8});
    });

    test('toJson sorts pixels and folder names', () {
      final sprite = Sprite(
        id: 'x',
        name: 'Sorted',
        gridSize: 4,
        frames: [
          {5, 1, 3},
        ],
        folders: {'bravo', 'Alpha', 'charlie'},
      );

      final json = sprite.toJson();

      expect(json['frames'], [
        [1, 3, 5],
      ]);
      expect(json['folders'], ['Alpha', 'bravo', 'charlie']);
    });

    test('copyWith keeps id and gridSize', () {
      final sprite = Sprite(id: 'keep', name: 'One', gridSize: 8, frames: [{}]);

      final renamed = sprite.copyWith(name: 'Two');

      expect(renamed.id, 'keep');
      expect(renamed.gridSize, 8);
      expect(renamed.name, 'Two');
    });
  });

  group('compareNames', () {
    test('numbers compare as numbers', () {
      expect(compareNames('CHAR_2', 'CHAR_10'), isNegative);
    });

    test('ignores case', () {
      expect(compareNames('char_1', 'CHAR_1'), 0);
    });

    test('sorts a list naturally', () {
      final names = ['CHAR_10', 'char_2', 'Char_1']..sort(compareNames);
      expect(names, ['Char_1', 'char_2', 'CHAR_10']);
    });
  });

  group('jitterPercent', () {
    test('defaults to 0 for old exports', () {
      final sprite = Sprite.fromJson({
        'id': 'x',
        'name': 'Old',
        'gridSize': 3,
        'frames': [
          [0],
        ],
      });

      expect(sprite.jitterPercent, 0);
    });

    test('survives a round trip', () {
      final sprite = Sprite(
        id: 'x',
        name: 'Chaos',
        gridSize: 3,
        frames: [
          {0},
        ],
        jitterPercent: 35,
      );

      expect(Sprite.fromJson(sprite.toJson()).jitterPercent, 35);
    });

    test('out-of-range values are clamped on import', () {
      Sprite load(int value) => Sprite.fromJson({
        'id': 'x',
        'name': 'Clamp',
        'gridSize': 3,
        'frames': [
          [0],
        ],
        'jitterPercent': value,
      });

      expect(load(-40).jitterPercent, 0);
      expect(load(900).jitterPercent, Sprite.maxJitterPercent);
    });

    test('copyWith changes only jitter', () {
      final sprite = Sprite(
        id: 'x',
        name: 'Chaos',
        gridSize: 3,
        frames: [
          {0},
        ],
        frameMs: 300,
      );

      final changed = sprite.copyWith(jitterPercent: 50);

      expect(changed.jitterPercent, 50);
      expect(changed.frameMs, 300);
    });
  });
}
