import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tamabudchi_app/barrel.dart';

/// Export text containing only [edited], as if it came from another device.
String _exportOf(SpriteLibrary library, Sprite edited) {
  final data =
      jsonDecode(library.exportJson(onlyId: edited.id)) as Map<String, dynamic>;
  data['sprites'] = [edited.toJson()];
  return jsonEncode(data);
}

void main() {
  late SpriteLibrary library;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    library = SpriteLibrary();
    await library.load(); // empty storage loads the starter sprites
  });

  group('importJson', () {
    test('importing what is already there adds nothing', () {
      final before = library.sprites.length;

      final result = library.importJson(library.exportJson());

      expect(result.added, 0);
      expect(result.duplicates, before);
      expect(library.sprites.length, before);
    });

    test('same id, different drawing: kept as a copy with its timing', () {
      final existing = library.sprites.first;
      final edited = existing.copyWith(
        frames: [
          {0, 1, 2},
        ],
        frameMs: 250,
        jitterPercent: 40,
      );

      final result = library.importJson(_exportOf(library, edited));

      expect(result.added, 1);
      final copy = library.sprites.last;
      expect(copy.name, '${existing.name} (imported)');
      expect(copy.id, isNot(existing.id));
      expect(copy.frameMs, 250);
      expect(copy.jitterPercent, 40);
    });

    test('a sprite that differs only in jitter is not a duplicate', () {
      final existing = library.sprites.first;
      final edited = existing.copyWith(jitterPercent: 30);

      final result = library.importJson(_exportOf(library, edited));

      expect(result.duplicates, 0);
      expect(result.added, 1);
    });

    test('text that is not an export is rejected', () {
      expect(() => library.importJson('hello'), throwsFormatException);
    });

    test('an export from a newer version is rejected', () {
      final data = jsonDecode(library.exportJson()) as Map<String, dynamic>;
      data['version'] = 999;

      expect(() => library.importJson(jsonEncode(data)), throwsFormatException);
    });
  });
}
