import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamabudchi_app/barrel.dart';

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

  static const String _storageKey = 'sprites_v1';
  static const Duration _saveDelay = Duration(milliseconds: 600);

  final SharedPreferencesAsync _prefs;

  List<Sprite> _sprites = [];
  Timer? _saveTimer;
  bool _dirty = false;

  List<Sprite> get sprites => List.unmodifiable(_sprites);

  // ---- loading ------

  Future<void> load() async {
    final raw = await _prefs.getString(_storageKey);

    if (raw == null) {
      _sprites = _starterSprites();
      await _save();
    } else {
      try {
        _sprites = _decode(raw);
      } catch (e) {
        // Keep the unreadable data around instead of silently overwriting it.
        debugPrint('Could not read saved sprites: $e');
        await _prefs.setString('${_storageKey}_unreadable', raw);
        _sprites = [];
      }
    }
    notifyListeners();
  }

  List<Sprite> _decode(String raw) {
    final sprites = <Sprite>[];
    for (final item in jsonDecode(raw) as List) {
      try {
        final Sprite sprite = Sprite.fromJson(item as Map<String, dynamic>);
        // A sprite always needs at least one frame.
        sprites.add(
          sprite.frames.isEmpty ? sprite.copyWith(frames: [<int>{}]) : sprite,
        );
      } catch (e) {
        debugPrint('Skipping an unreadable sprite: $e');
      }
    }
    return sprites;
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

  String _newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

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
