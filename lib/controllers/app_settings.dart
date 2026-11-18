import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamabudchi_app/barrel.dart';

/// Preferences about how the app looks and behaves (as opposed to the
/// sprites themselves, which live in [SpriteLibrary]).
class AppSettings extends ChangeNotifier {
  AppSettings({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const String barLayoutKey = 'bar_layout';
  static const String tileActionsKey = 'tile_actions';
  // These two were saved by SpriteLibrary before moving here. The key names
  // stay the same so values people already saved carry over.
  static const String lastGridSizeKey = 'last_grid_size';
  static const String sortKey = 'sprites_sort_az';

  final SharedPreferencesAsync _prefs;

  BarLayout _barLayout = BarLayout.split;
  TileActions _tileActions = TileActions.both;
  int _lastGridSize = Sprite.defaultGridSize;
  bool _sortAlphabetically = false;

  BarLayout get barLayout => _barLayout;
  TileActions get tileActions => _tileActions;
  int get lastGridSize => _lastGridSize;

  /// Whether the library screen shows sprites A–Z instead of in the order the
  /// person arranged them. The arranged order is kept and returns when this
  /// is turned off.
  bool get sortAlphabetically => _sortAlphabetically;

  Future<void> load() async {
    // Each read is separate, so one unreadable value can't block the others.
    final layout = await _read(
      'bar layout',
      () => _prefs.getString(barLayoutKey),
    );
    final tiles = await _read(
      'tile actions',
      () => _prefs.getString(tileActionsKey),
    );
    final gridSize = await _read(
      'grid size',
      () => _prefs.getInt(lastGridSizeKey),
    );
    final sort = await _read('sort order', () => _prefs.getBool(sortKey));

    // A stored name that no longer matches any case (say, after a rename)
    // quietly falls back to the default instead of crashing at launch.
    _barLayout = BarLayout.values.asNameMap()[layout] ?? BarLayout.split;
    _tileActions = TileActions.values.asNameMap()[tiles] ?? TileActions.both;
    _lastGridSize = (gridSize ?? Sprite.defaultGridSize).clamp(
      Sprite.minGridSize,
      Sprite.maxGridSize,
    );
    _sortAlphabetically = sort ?? false;
    notifyListeners();
  }

  Future<void> setBarLayout(BarLayout value) async {
    if (value == _barLayout) return;

    _barLayout = value;
    notifyListeners();
    await _write(
      'bar layout',
      () => _prefs.setString(barLayoutKey, value.name),
    );
  }

  Future<void> setTileActions(TileActions value) async {
    if (value == _tileActions) return;

    _tileActions = value;
    notifyListeners();
    await _write(
      'tile actions',
      () => _prefs.setString(tileActionsKey, value.name),
    );
  }

  /// Remember the grid size last used for a new sprite.
  Future<void> setLastGridSize(int size) async {
    final clamped = size.clamp(Sprite.minGridSize, Sprite.maxGridSize);
    if (clamped == _lastGridSize) return;

    _lastGridSize = clamped;
    notifyListeners();
    await _write('grid size', () => _prefs.setInt(lastGridSizeKey, clamped));
  }

  /// Switch between A–Z and your own order, and remember the choice.
  Future<void> setSortAlphabetically(bool value) async {
    if (value == _sortAlphabetically) return;

    _sortAlphabetically = value;
    notifyListeners();
    await _write('sort order', () => _prefs.setBool(sortKey, value));
  }

  Future<T?> _read<T>(String what, Future<T?> Function() read) async {
    try {
      return await read();
    } catch (e) {
      debugPrint('Could not read $what: $e');
      return null;
    }
  }

  Future<void> _write(String what, Future<void> Function() write) async {
    try {
      await write();
    } catch (e) {
      debugPrint('Could not save $what: $e');
    }
  }
}
