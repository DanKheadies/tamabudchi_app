import 'package:flutter/foundation.dart';
import 'package:tamabudchi_app/barrel.dart';

/// Handles the [Sprite] being edited along with the [PixelPlaybackController]'s
/// active frame, i.e. controls the playback controller to keep frame count and
/// index aligned as well as managing disposal.
class SpriteEditor extends ChangeNotifier {
  final PixelPlaybackController playback;

  SpriteEditor({required Sprite sprite})
    : _sprite = sprite,
      playback = PixelPlaybackController(frameCount: sprite.frameCount);

  static const int _maxHistory = 100;

  Sprite _sprite;
  bool _editing = false;
  bool _onionSkin = false;

  final List<_Snapshot> _undoStack = [];
  final List<_Snapshot> _redoStack = [];
  bool _inStroke = false;
  _Snapshot? _strokeStart;

  bool get editing => _editing;
  bool get onionSkin => _onionSkin;
  Sprite get sprite => _sprite;
  int get gridSize => _sprite.gridSize;
  Set<int> get currentFrame => _sprite.frames[playback.frameIndex];

  /// Must be editing and paused to edit; editing and playing acts as a preview.
  bool get canEdit => _editing && !playback.playing;

  /// A sprite must have one frame.
  bool get canDeleteFrame => _sprite.frameCount > 1;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Ghost of prevoius frame, shown only during editing.
  bool get showOnionSkin => canEdit && _onionSkin;

  /// Listens for changes to the sprite, edits, or playback.
  late final Listenable changes = Listenable.merge([this, playback]);

  void toggleEditing() {
    _editing = !_editing;
    if (_editing) playback.pause();
    notifyListeners();
  }

  void toggleOnionSkin() {
    _onionSkin = !_onionSkin;
    notifyListeners();
  }

  /// Replace the sprite being edited via library load; history stays with the
  /// sprite and cleared on a new load.
  void load(Sprite sprite) {
    _sprite = sprite;
    _undoStack.clear();
    _redoStack.clear();
    endStroke();
    playback.frameCount = sprite.frameCount; // safety measure
    playback.jumpTo(0);
    notifyListeners();
  }

  // ---- history ------

  _Snapshot _snapshot() => _Snapshot(_sprite.frames, playback.frameIndex);

  void _record(_Snapshot before) {
    _undoStack.add(before);
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (!canUndo) return;
    endStroke();
    final _Snapshot step = _undoStack.removeLast();
    _redoStack.add(_Snapshot(_sprite.frames, step.index));
    _restore(step);
  }

  void redo() {
    if (!canRedo) return;
    endStroke();
    final _Snapshot step = _redoStack.removeLast();
    _undoStack.add(_Snapshot(_sprite.frames, step.index));
    _restore(step);
  }

  void _restore(_Snapshot step) {
    _sprite = _sprite.copyWith(frames: step.frames);
    playback.frameCount = step.frames.length;
    playback.jumpTo(step.index); // shows the frame that was changed
    notifyListeners();
  }

  /// A stroke (pointer down > pointer up) is one undo step (can be many pixels).
  /// Call [beginStroke] on pointer down and [endStroke] on pointer up / cancel.
  /// Strokes that change nothing leave no history.
  void beginStroke() {
    _inStroke = true;
    _strokeStart = _snapshot();
  }

  void endStroke() {
    _inStroke = false;
    _strokeStart = null;
  }

  // ---- pixels ------

  /// Turn one pixel of the current frame on or off.
  ///
  /// Copy-on-write: builds a new Set and a new frame list instead of mutating,
  /// so PixelGridPainter.shouldRepaint (which compares by identity) sees the
  /// change. Idempotent, so repeating a call for the same cell is harmless.
  void setCell(int cell, bool on) {
    if (cell < 0 || cell >= gridSize * gridSize) return;

    final index = playback.frameIndex;
    final current = _sprite.frames[index];
    if (current.contains(cell) == on) return;

    // First, real change of a stroke commits the pre-stroke snapshot.
    if (!_inStroke) {
      _record(_snapshot());
    } else {
      final start = _strokeStart;
      if (start != null) {
        _record(start);
        _strokeStart = null;
      }
    }

    final next = Set<int>.of(current);
    if (on) {
      next.add(cell);
    } else {
      next.remove(cell);
    }

    final frames = List<Set<int>>.of(_sprite.frames);
    frames[index] = next;
    _sprite = _sprite.copyWith(frames: frames);
    notifyListeners();
  }

  // ---- frames ------

  /// Look at a specific frame. Pauses playback so the frame stays put.
  void selectFrame(int index) {
    playback.pause();
    playback.jumpTo(index);
  }

  /// Insert a blank frame after the current one and select it.
  void addFrame() => _insertAfterCurrent(<int>{});

  /// Insert a copy of the current frame after it and select the copy.
  void duplicateFrame() => _insertAfterCurrent(Set<int>.of(currentFrame));

  void _insertAfterCurrent(Set<int> frame) {
    final at = playback.frameIndex + 1;
    final frames = List<Set<int>>.of(_sprite.frames)..insert(at, frame);
    _replaceFrames(frames, select: at);
  }

  /// Remove the current frame. The next frame slides into its place (or the
  /// previous frame is selected if the final one was removed).
  void deleteFrame() {
    if (!canDeleteFrame) return;

    final at = playback.frameIndex;
    final frames = List<Set<int>>.of(_sprite.frames)..removeAt(at);
    _replaceFrames(
      frames,
      select: at >= frames.length ? frames.length - 1 : at,
    );
  }

  /// Move the frame at [from] so it ends up at index [to] (the final index,
  /// after the move). The selection follows whichever frame was selected.
  void moveFrame(int from, int to) {
    if (from == to) return;

    final frames = List<Set<int>>.of(_sprite.frames);
    final moved = frames.removeAt(from);
    frames.insert(to, moved);

    final current = playback.frameIndex;
    var select = current;
    if (current == from) {
      select = to;
    } else if (from < current && current <= to) {
      select = current - 1;
    } else if (to <= current && current < from) {
      select = current + 1;
    }
    _replaceFrames(frames, select: select);
  }

  void _replaceFrames(List<Set<int>> frames, {required int select}) {
    _record(_snapshot()); // hold the pre-change state
    _sprite = _sprite.copyWith(frames: frames);
    playback.frameCount = frames.length; // keep playback in step with sprite
    playback.jumpTo(select);
    notifyListeners();
  }

  @override
  void dispose() {
    playback.dispose();
    super.dispose();
  }
}

/// A point-in-time edit history. The frames as they were & which frame was
/// selected. Frames are replaced (not mutated).
class _Snapshot {
  final int index;
  final List<Set<int>> frames;

  const _Snapshot(this.frames, this.index);
}
