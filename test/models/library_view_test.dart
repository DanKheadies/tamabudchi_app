import 'package:flutter_test/flutter_test.dart';
import 'package:tamabudchi_app/barrel.dart';

Sprite _sprite(
  String name, {
  Set<String> folders = const {},
  bool onDesktop = true,
  String? id,
}) => Sprite(
  id: id ?? name,
  name: name,
  gridSize: 3,
  frames: [
    <int>{0},
  ],
  folders: folders,
  onDesktop: onDesktop,
);

void main() {
  group('spriteInView', () {
    test('all shows everything', () {
      expect(spriteInView(_sprite('a', onDesktop: false), allView), isTrue);
    });

    test('desktop follows onDesktop', () {
      expect(spriteInView(_sprite('a'), desktopView), isTrue);
      expect(
        spriteInView(_sprite('a', onDesktop: false), desktopView),
        isFalse,
      );
    });

    test('unfiled means no folders, wherever it sits', () {
      expect(spriteInView(_sprite('a', onDesktop: false), unfiledView), isTrue);
      expect(
        spriteInView(_sprite('a', folders: {'Pets'}), unfiledView),
        isFalse,
      );
    });

    test('a folder view only shows that folder', () {
      final dog = _sprite('dog', folders: {'Pets'});
      expect(spriteInView(dog, folderView('Pets')), isTrue);
      expect(spriteInView(dog, folderView('Enemies')), isFalse);
    });

    test('views with the same scope and folder are equal', () {
      expect(folderView('Pets'), folderView('Pets'));
      expect(folderView('Pets'), isNot(folderView('Enemies')));
    });
  });

  group('viewLabel', () {
    test('names each view', () {
      expect(viewLabel(desktopView), 'Desktop');
      expect(viewLabel(allView), 'All');
      expect(viewLabel(unfiledView), 'Unfiled');
      expect(viewLabel(folderView('Pets')), 'Pets');
    });
  });

  group('search', () {
    test('tokens are lowercase words', () {
      expect(searchTokens('  Char   WALK '), ['char', 'walk']);
      expect(searchTokens('   '), isEmpty);
    });

    test('no words matches everything', () {
      expect(matchesSearch(_sprite('anything'), []), isTrue);
    });

    test('every word must appear, in any order, ignoring case', () {
      final walk = _sprite('CHAR_1_WALK');
      expect(matchesSearch(walk, searchTokens('char walk')), isTrue);
      expect(matchesSearch(walk, searchTokens('WALK char')), isTrue);
      expect(matchesSearch(walk, searchTokens('char dog')), isFalse);
    });

    test('folder names are searched too', () {
      final blob = _sprite('Blob', folders: {'Pets'});
      expect(matchesSearch(blob, searchTokens('pets')), isTrue);
      expect(matchesSearch(blob, searchTokens('blob pets')), isTrue);
    });
  });

  group('sortedByName', () {
    test('uses natural order', () {
      final sorted = sortedByName([
        _sprite('CHAR_10'),
        _sprite('char_2'),
        _sprite('Char_1'),
      ]);
      expect([for (final s in sorted) s.name], ['Char_1', 'char_2', 'CHAR_10']);
    });

    test('equal names fall back to id', () {
      final sorted = sortedByName([
        _sprite('Same', id: 'b'),
        _sprite('Same', id: 'a'),
      ]);
      expect([for (final s in sorted) s.id], ['a', 'b']);
    });

    test('leaves the input list alone', () {
      final input = [_sprite('b'), _sprite('a')];
      sortedByName(input);
      expect(input.first.name, 'b');
    });
  });
}
