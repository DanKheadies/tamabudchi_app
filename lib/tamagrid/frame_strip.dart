import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

/// Scrollable strip of frame thumbnails. Tap to select a frame; while editing,
/// long-press and drag to reorder. Scrolls to keep the current frame in view.
class FrameStrip extends StatefulWidget {
  final bool isHorizontal;
  final SpriteEditor editor;

  const FrameStrip({
    super.key,
    required this.editor,
    required this.isHorizontal,
  });

  @override
  State<FrameStrip> createState() => _FrameStripState();
}

class _FrameStripState extends State<FrameStrip> {
  static const double _thumb = 44;
  static const double _extent = _thumb + 8; // thumbnail + spacing

  final ScrollController _scroll = ScrollController();
  int _lastIndex = -1;

  SpriteEditor get editor => widget.editor;

  @override
  void initState() {
    super.initState();
    editor.playback.addListener(_followCurrent);
  }

  @override
  void dispose() {
    editor.playback.removeListener(_followCurrent);
    _scroll.dispose();
    super.dispose();
  }

  void _followCurrent() {
    final index = editor.playback.frameIndex;
    if (index == _lastIndex) return;
    _lastIndex = index;

    // Wait for layout so a just-added frame is already part of the extent.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      final double target =
          (index * _extent - (position.viewportDimension - _extent) / 2).clamp(
            0.0,
            position.maxScrollExtent,
          );
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: editor.changes,
      builder: (context, _) {
        final frames = editor.sprite.frames;
        final current = editor.playback.frameIndex;

        return ReorderableListView.builder(
          scrollController: _scroll,
          scrollDirection: widget.isHorizontal
              ? Axis.horizontal
              : Axis.vertical,
          buildDefaultDragHandles: false,
          itemExtent: _extent,
          itemCount: frames.length,
          onReorderItem: editor.moveFrame,
          itemBuilder: (context, i) {
            return ReorderableDelayedDragStartListener(
              key: ValueKey(i),
              index: i,
              enabled: editor.canEdit,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => editor.selectFrame(i),
                child: Center(child: _thumbnail(frames[i], i == current)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _thumbnail(Set<int> frame, bool selected) {
    return Container(
      width: _thumb,
      height: _thumb,
      foregroundDecoration: BoxDecoration(
        border: Border.all(
          color: selected ? Colors.deepPurple : Colors.black26,
          width: selected ? 3 : 1,
        ),
      ),
      child: CustomPaint(
        painter: PixelGridPainter(frame: frame, gridSize: editor.gridSize),
      ),
    );
  }
}
