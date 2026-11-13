import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

class SequenceBar extends StatelessWidget {
  final bool isHorizontal;
  final bool? isFloating;
  final double barSize;
  final double? limen;
  final SpriteEditor editor;

  const SequenceBar({
    super.key,
    required this.barSize,
    required this.editor,
    required this.isHorizontal,
    this.isFloating = false,
    this.limen = 0,
  });

  PixelPlaybackController get playback => editor.playback;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: editor.changes,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isFloating! ? 15 : 0),
            color: Colors.green.shade100,
          ),
          height: isHorizontal
              ? barSize
              : isFloating!
              ? limen! - limen! / 50
              : double.infinity,
          margin: isHorizontal
              ? EdgeInsets.only(bottom: barSize / 4)
              : EdgeInsets.only(right: barSize / 4),
          width: !isHorizontal
              ? barSize
              : isFloating!
              ? limen! - limen! / 50
              : double.infinity,
          child: Flex(
            direction: isHorizontal ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [...historyButtons(), ...sequenceButtons(context)],
          ),
        );
      },
    );
  }

  List<Widget> historyButtons() {
    if (!editor.editing) return const [];

    final bool canEdit = editor.canEdit;
    return [
      IconButton(
        visualDensity: VisualDensity.compact,
        color: Colors.deepPurple,
        disabledColor: Colors.black26,
        tooltip: 'Undo',
        icon: Icon(Icons.undo),
        onPressed: canEdit && editor.canUndo ? editor.undo : null,
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        color: Colors.deepPurple,
        disabledColor: Colors.black26,
        tooltip: 'Redo',
        icon: Icon(Icons.redo),
        onPressed: canEdit && editor.canRedo ? editor.redo : null,
      ),
    ];
  }

  List<Widget> sequenceButtons(BuildContext context) {
    // Tighter while editing, when undo / redo share the bar.
    final density = editor.editing ? VisualDensity.compact : null;

    return [
      IconButton(
        color: Colors.deepPurple,
        icon: const Icon(Icons.skip_previous),
        onPressed: () => playback.step(-1),
        visualDensity: density,
      ),
      IconButton(
        color: Colors.deepPurple,
        icon: Icon(playback.playing ? Icons.pause : Icons.play_arrow),
        onPressed: playback.toggle,
        visualDensity: density,
      ),
      IconButton(
        color: Colors.deepPurple,
        icon: Icon(Icons.skip_next),
        onPressed: playback.step,
        visualDensity: density,
      ),
      IconButton(
        color: Colors.deepPurple,
        icon: Icon(Icons.fast_rewind),
        onPressed: editor.slowDown,
        tooltip: 'Slower',
        visualDensity: density,
      ),
      Tooltip(
        message: 'Time per frame. Tap to type an exact value.',
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.deepPurple,
            minimumSize: const Size(44, 40),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => _typeSpeed(context),
          child: Text('${editor.frameMs}ms'),
        ),
      ),

      IconButton(
        color: Colors.deepPurple,
        icon: Icon(Icons.fast_forward),
        onPressed: editor.speedUp,
        tooltip: 'Faster',
        visualDensity: density,
      ),
    ];
  }

  Future<void> _typeSpeed(BuildContext context) async {
    final ms = await showFrameTimeDialog(context, editor.frameMs);
    if (ms != null) editor.setFrameMs(ms);
  }
}
