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
  static const String _sortKey = 'sprites_sort_az';
  static const String _storageKey = 'sprites_v1';

  final SharedPreferencesAsync _prefs;

  bool _dirty = false;
  bool _sortAlphabetically = false;
  int _idSeq = 0;
  List<Sprite> _sprites = [];
  Timer? _saveTimer;

  /// Whether the library screen shows sprites A–Z instead of in the order the
  /// person arranged them. The arranged order is kept and returns when this
  /// is turned off.
  bool get sortAlphabetically => _sortAlphabetically;

  List<Sprite> get sprites => List.unmodifiable(_sprites);
  List<String> get folders {
    final names = {for (final s in _sprites) ...s.folders};
    return names.toList()..sort(compareFolderNames);
  }

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
    _sortAlphabetically = await _prefs.getBool(_sortKey) ?? false;
    notifyListeners();
  }

  /// Turn stored/imported JSON into a safe Sprite (or null if unusable).
  /// Fixes what can be fixed: out-of-range pixels, missing frame(s), no name,
  /// blank folder names.
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
        folders: {
          for (final f in sprite.folders)
            if (f.trim().isNotEmpty) f.trim(),
        },
      );
    } catch (e) {
      debugPrint('Skipping an unreadable sprite: $e');
      return null;
    }
  }

  // ---- structure changes ------

  /// Switch between A–Z and your own order, and remember the choice.
  Future<void> setSortAlphabetically(bool value) async {
    _sortAlphabetically = value;
    notifyListeners();
    try {
      await _prefs.setBool(_sortKey, value);
    } catch (e) {
      debugPrint('Could not save the sort setting: $e');
    }
  }

  /// Make a new blank sprite (one empty frame) and return it.
  /// Made while looking inside a folder? Pass it as [folder] and the sprite is
  /// filed there. Otherwise it starts on the desktop in no folder.
  Sprite create({required String name, required int gridSize, String? folder}) {
    final Sprite sprite = Sprite(
      id: _newId(),
      name: name.trim(),
      gridSize: gridSize.clamp(minGridSize, maxGridSize),
      frames: [<int>{}],
      folders: folder == null ? const {} : {folder},
      onDesktop: folder == null,
    );
    _sprites = [..._sprites, sprite];
    _structureChanged();
    return sprite;
  }

  /// Rename a folder everywhere it's used. If another folder already has the
  /// new name (ignoring case) the two merge, keeping that folder's spelling.
  /// Returns the name the folder ended up with.
  String renameFolder(String from, String to) {
    final target = to.trim();
    if (target.isEmpty || target == from) return from;

    final lower = target.toLowerCase();
    final other = folders.where((f) => f != from && f.toLowerCase() == lower);
    final name = other.isEmpty ? target : other.first;

    _sprites = [
      for (final s in _sprites)
        if (!s.folders.contains(from))
          s
        else
          s.copyWith(
            folders: {for (final f in s.folders) f == from ? name : f},
          ),
    ];
    _structureChanged();
    return name;
  }

  /// Delete a sprite.
  void delete(String id) {
    _sprites = _sprites.where((s) => s.id != id).toList();
    _structureChanged();
  }

  /// Remove a folder from every sprite. The sprites themselves are kept.
  void deleteFolder(String name) {
    _sprites = [
      for (final s in _sprites)
        if (!s.folders.contains(name))
          s
        else
          s.copyWith(
            folders: {...s.folders}..remove(name),
            // Never leave a sprite nowhere: with no folder left, it goes
            // back to the desktop.
            onDesktop: s.onDesktop || s.folders.length == 1,
          ),
    ];
    _structureChanged();
  }

  /// Move a sprite within a filtered view, keeping ONE order for the whole
  /// library. [visibleIds] are the sprites showing, in display order; [from]
  /// and [to] are positions in that list ([to] is the final position).
  /// Sprites that aren't in the view stay exactly where they are: the visible
  /// ones just rearrange themselves among the slots they already occupy.
  void moveWithin(List<String> visibleIds, int from, int to) {
    if (from == to) return;

    final byId = {for (final s in _sprites) s.id: s};
    final slots = [
      for (final id in visibleIds) _sprites.indexWhere((s) => s.id == id),
    ];
    if (slots.contains(-1)) return;
    slots.sort();

    final order = List.of(visibleIds);
    order.insert(to, order.removeAt(from));

    final next = List.of(_sprites);
    for (var i = 0; i < slots.length; i++) {
      next[slots[i]] = byId[order[i]]!;
    }
    _sprites = next;
    _structureChanged();
  }

  /// Rename a sprite.
  void rename(String id, String name) {
    final trimmed = name.trim();
    final i = _sprites.indexWhere((s) => s.id == id);
    if (trimmed.isEmpty || i == -1) return;

    _sprites = List.of(_sprites)..[i] = _sprites[i].copyWith(name: trimmed);
    _structureChanged();
  }

  /// Set which folders a sprite is in and whether it's on the desktop i.e.
  /// "leaves the desktop when first filed."
  void setOrganization(
    String id, {
    required Set<String> folders,
    required bool onDesktop,
  }) {
    final i = _sprites.indexWhere((s) => s.id == id);
    if (i == -1) return;

    _sprites = List.of(_sprites)
      ..[i] = _sprites[i].copyWith(folders: folders, onDesktop: onDesktop);
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

  /// What makes two sprites "the same drawing": name, size, and frames.
  /// Folders and desktop are organization, not content, so they're ignored.
  String _drawingKey(Sprite s) => jsonEncode({
    'name': s.name,
    'gridSize': s.gridSize,
    'frames': [for (final f in s.frames) f.toList()..sort()],
  });

  /// Add the sprites in [text] (output of [exportJson]) to the library.
  ///
  /// Never overwrites anything:
  ///  - a sprite that's already here with the same drawing is skipped (the
  ///    folders on this device win);
  ///  - a sprite with a known id but a different drawing is added as a copy.
  ///
  /// Imported folder names are matched to existing ones ignoring case.
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
    final spelling = {for (final f in folders) f.toLowerCase(): f};

    for (final item in data['sprites'] as List) {
      final parsed = _parseSprite(item);
      if (parsed == null) {
        unreadable++;
        continue;
      }
      final sprite = parsed.copyWith(
        folders: {
          for (final f in parsed.folders)
            spelling.putIfAbsent(f.toLowerCase(), () => f),
        },
      );

      final existing = known[sprite.id];
      if (existing == null) {
        next.add(sprite);
        known[sprite.id] = sprite;
        added++;
      } else if (_drawingKey(existing) == _drawingKey(sprite)) {
        duplicates++; // same drawing, nothing to do
      } else {
        // Same id but different content (edited on another device): keep
        // both rather than overwrite either.
        final copy = Sprite(
          id: _newId(),
          name: '${sprite.name} (imported)',
          gridSize: sprite.gridSize,
          frames: sprite.frames,
          folders: sprite.folders,
          onDesktop: sprite.onDesktop,
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
