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
            children: [...historyButtons(), ...sequenceButtons()],
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

  List<Widget> sequenceButtons() {
    return [
      IconButton(
        color: Colors.deepPurple,
        onPressed: () => editor.playback.step(-1),
        icon: const Icon(Icons.skip_previous),
      ),
      IconButton(
        color: Colors.deepPurple,
        onPressed: editor.playback.toggle,
        icon: Icon(editor.playback.playing ? Icons.pause : Icons.play_arrow),
      ),
      IconButton(
        color: Colors.deepPurple,
        onPressed: editor.playback.step,
        icon: Icon(Icons.skip_next),
      ),
      IconButton(
        color: Colors.deepPurple,
        onPressed: editor.playback.slowDown,
        icon: Icon(Icons.fast_rewind),
      ),
      IconButton(
        color: Colors.deepPurple,
        onPressed: editor.playback.speedUp,
        icon: Icon(Icons.fast_forward),
      ),
    ];
  }
}
