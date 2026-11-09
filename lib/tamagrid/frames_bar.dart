import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

class FramesBar extends StatelessWidget {
  final bool isHorizontal;
  final bool? isFloating;
  final double barSize;
  final double? limen;
  final Function() onOpenLibrary;
  final SpriteEditor editor;

  const FramesBar({
    super.key,
    required this.barSize,
    required this.editor,
    required this.isHorizontal,
    required this.onOpenLibrary,
    this.isFloating = false,
    this.limen = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: editor.changes,
      builder: (context, _) {
        final bool canEdit = editor.canEdit;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isFloating! ? 15 : 0),
            color: Colors.yellow.shade100,
          ),
          height: isHorizontal
              ? barSize
              : isFloating!
              ? limen! - limen! / 50
              : double.infinity,
          margin: isHorizontal
              ? EdgeInsets.only(top: barSize / 4)
              : EdgeInsets.only(left: barSize / 4),
          width: !isHorizontal
              ? barSize
              : isFloating!
              ? limen! - limen! / 50
              : double.infinity,
          child: Flex(
            direction: isHorizontal ? Axis.horizontal : Axis.vertical,
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (editor.editing)
                IconButton(
                  color: editor.onionSkin ? Colors.purple : Colors.deepPurple,
                  icon: Icon(
                    editor.onionSkin ? Icons.layers : Icons.layers_outlined,
                  ),
                  onPressed: editor.toggleOnionSkin,
                  tooltip: 'Onion skin (ghost of previous frame)',
                )
              else
                IconButton(
                  color: Colors.deepPurple,
                  icon: Icon(Icons.arrow_back),
                  onPressed: onOpenLibrary,
                  tooltip: 'Back to library',
                ),
              IconButton(
                color: editor.editing ? Colors.purple : Colors.deepPurple,
                icon: Icon(editor.editing ? Icons.edit_off : Icons.edit),
                onPressed: editor.toggleEditing,
                tooltip: 'Toggle editing',
              ),
              Expanded(
                child: FrameStrip(editor: editor, isHorizontal: isHorizontal),
              ),
              if (editor.editing) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  color: Colors.deepPurple,
                  disabledColor: Colors.black26,
                  icon: Icon(Icons.add_box_outlined),
                  onPressed: canEdit ? editor.addFrame : null,
                  tooltip: 'Add blank frame',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  color: Colors.deepPurple,
                  disabledColor: Colors.black26,
                  icon: Icon(Icons.copy),
                  onPressed: canEdit ? editor.duplicateFrame : null,
                  tooltip: 'Duplicate frame',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  color: Colors.deepPurple,
                  disabledColor: Colors.black26,
                  icon: Icon(Icons.delete_outline),
                  onPressed: canEdit && editor.canDeleteFrame
                      ? editor.deleteFrame
                      : null,
                  tooltip: 'Delete frame',
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
