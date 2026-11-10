import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamabudchi_app/barrel.dart';

/// What happens during an import (lets the UI report it honestly).
typedef ImportResult = ({int added, int duplicates, int unreadable});

/// The user's collection of sprites, saved to local storage as one JSON list
/// under a single key.
///
/// Two kinds of changes:
///  - structure (create / rename / delete): listeners are told right away and
///    the save happens immediately.
///  - [update] (autosave from the editor): the in-memory sprite is replaced
///    right away, but saving waits for a pause in editing, so a drag doesn't
///    write to disk dozens of times.
class SpriteLibrary extends ChangeNotifier {
  SpriteLibrary({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const int minGridSize = 3;
  static const int maxGridSize = 16;

  static const int _exportVersion = 1;
  static const int _hardMaxGridSize = 64;
  static const Duration _saveDelay = Duration(milliseconds: 600);
  static const String _exportApp = 'tamabudchi';
  static const String _storageKey = 'sprites_v1';

  final SharedPreferencesAsync _prefs;

  bool _dirty = false;
  int _idSeq = 0;
  List<Sprite> _sprites = [];
  Timer? _saveTimer;

  List<Sprite> get sprites => List.unmodifiable(_sprites);

  // ---- loading ------

  Future<void> load() async {
    final raw = await _prefs.getString(_storageKey);

    if (raw == null) {
      _sprites = _starterSprites();
      await _save();
    } else {
      try {
        _sprites = [
          for (final item in jsonDecode(raw) as List) ?_parseSprite(item),
        ];
      } catch (e) {
        // Keep the unreadable data around instead of silently overwriting it.
        debugPrint('Could not read saved sprites: $e');
        await _prefs.setString('${_storageKey}_unreadable', raw);
        _sprites = [];
      }
    }
    notifyListeners();
  }

  /// Turn stored/imported JSON into a safe Sprite (or null if unusable).
  /// Fixes what can be fixed: out-of-range pixels, missing frame(s), no name.
  Sprite? _parseSprite(Object? item) {
    try {
      final Sprite sprite = Sprite.fromJson(item as Map<String, dynamic>);
      final size = sprite.gridSize;
      if (size < 1 || size > _hardMaxGridSize) return null;

      final frames = [
        for (final frame in sprite.frames)
          {
            for (final cell in frame)
              if (cell >= 0 && cell < size * size) cell,
          },
      ];
      final name = sprite.name.trim();

      return sprite.copyWith(
        name: name.isEmpty ? 'Untitled' : name,
        frames: frames.isEmpty ? [<int>{}] : frames,
      );
    } catch (e) {
      debugPrint('Skipping an unreadable sprite: $e');
      return null;
    }
  }

  // ---- structure changes ------

  /// Make a new blank sprite (one empty frame) and return it.
  Sprite create({required String name, required int gridSize}) {
    final Sprite sprite = Sprite(
      id: _newId(),
      name: name.trim(),
      gridSize: gridSize.clamp(minGridSize, maxGridSize),
      frames: [<int>{}],
    );
    _sprites = [..._sprites, sprite];
    _structureChanged();
    return sprite;
  }

  void rename(String id, String name) {
    final trimmed = name.trim();
    final i = _sprites.indexWhere((s) => s.id == id);
    if (trimmed.isEmpty || i == -1) return;

    _sprites = List.of(_sprites)..[i] = _sprites[i].copyWith(name: trimmed);
    _structureChanged();
  }

  void delete(String id) {
    _sprites = _sprites.where((s) => s.id != id).toList();
    _structureChanged();
  }

  void _structureChanged() {
    _dirty = true;
    notifyListeners();
    unawaited(flush());
  }

  // ---- export / import ------

  /// All sprites (or indicated via id) as one JSON string, ready to copy.
  /// Reads the in-memory sprites, so it includes edits still waiting to save.
  String exportJson({String? onlyId}) {
    final Iterable<Sprite> chosen = onlyId == null
        ? _sprites
        : _sprites.where((s) => s.id == onlyId);

    return jsonEncode({
      'app': _exportApp,
      'version': _exportVersion,
      'sprites': [for (final s in chosen) s.toJson()],
    });
  }

  /// Add the sprites in [text] (output of [exportJson]) to the library.
  ///
  /// Never overwrites anything:
  ///  - a sprite that's already here, unchanged, is skipped;
  ///  - a sprite with a known id but different content is added as a copy.
  ///
  /// Throws a [FormatException] with a readable message if [text] isn't
  /// valid export data.
  ImportResult importJson(String text) {
    Object? data;
    try {
      data = jsonDecode(text.trim());
    } catch (_) {
      data = null;
    }

    if (data is! Map<String, dynamic> ||
        data['app'] != _exportApp ||
        data['sprites'] is! List) {
      throw const FormatException(
        "That doesn't look like exported Tamabudchi sprites. "
        'Copy the whole export and try again.',
      );
    }
    final version = data['version'];
    if (version is! int || version > _exportVersion) {
      throw const FormatException(
        'This export comes from a newer version of the app.',
      );
    }

    var added = 0;
    var duplicates = 0;
    var unreadable = 0;
    final next = List.of(_sprites);
    final known = {for (final s in next) s.id: s};

    for (final item in data['sprites'] as List) {
      final sprite = _parseSprite(item);
      if (sprite == null) {
        unreadable++;
        continue;
      }

      final existing = known[sprite.id];
      if (existing == null) {
        next.add(sprite);
        known[sprite.id] = sprite;
        added++;
      } else if (jsonEncode(existing.toJson()) == jsonEncode(sprite.toJson())) {
        duplicates++; // same sprite, nothing to do
      } else {
        // Same id but different content (edited on another device): keep
        // both rather than overwrite either.
        final copy = Sprite(
          id: _newId(),
          name: '${sprite.name} (imported)',
          gridSize: sprite.gridSize,
          frames: sprite.frames,
        );
        next.add(copy);
        known[copy.id] = copy;
        added++;
      }
    }

    if (added > 0) {
      _sprites = next;
      _structureChanged();
    }
    return (added: added, duplicates: duplicates, unreadable: unreadable);
  }

  // ---- autosave from the editor ------

  /// Replace a sprite with an edited version (matched by id). Saved after a
  /// short pause; call [flush] to save right now.
  void update(Sprite sprite) {
    final i = _sprites.indexWhere((s) => s.id == sprite.id);
    if (i == -1) return;

    _sprites = List.of(_sprites)..[i] = sprite;
    _dirty = true;

    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, () => unawaited(flush()));
  }

  /// Save any pending changes now, then tell listeners (so the library screen
  /// can refresh thumbnails and frame counts).
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (!_dirty) return;

    _dirty = false;
    await _save();
    notifyListeners();
  }

  // ---- storage ------

  Future<void> _save() async {
    final json = jsonEncode([for (final s in _sprites) s.toJson()]);
    try {
      await _prefs.setString(_storageKey, json);
    } catch (e) {
      debugPrint('Could not save sprites: $e');
      _dirty = true; // try again on the next change or flush
    }
  }

  String _newId() {
    final String time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$time${(_idSeq++).toRadixString(36)}';
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  // ---- demo content ------

  static List<Sprite> _starterSprites() => [
    Sprite(
      id: 'starter-simple',
      name: 'Simple',
      gridSize: 3,
      frames: [
        {0, 2, 4, 6, 8},
        {0, 1, 2, 4, 6, 7, 8},
        {4},
      ],
    ),
    Sprite(
      id: 'starter-spiral',
      name: 'Spiral',
      gridSize: 3,
      frames: [
        {4},
        {1},
        {2},
        {5},
        {8},
        {7},
        {6},
        {3},
        {0},
        {},
        {4},
        {4, 1},
        {4, 1, 2},
        {4, 1, 2, 5},
        {4, 1, 2, 5, 8},
        {4, 1, 2, 5, 8, 7},
        {4, 1, 2, 5, 8, 7, 6},
        {4, 1, 2, 5, 8, 7, 6, 3},
        {4, 1, 2, 5, 8, 7, 6, 3, 0},
        {},
      ],
    ),
  ];
}
