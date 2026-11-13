import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

// TODO: build out logic to control scenes & actions
class TamaGrid extends StatelessWidget {
  final SpriteEditor editor;

  const TamaGrid({super.key, required this.editor});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: editor.changes,
      builder: (context, _) {
        return Stack(
          children: [
            PixelAnimation(
              controller: editor.playback,
              frames: editor.sprite.frames,
              gridSize: editor.gridSize,
              onionSkin: editor.showOnionSkin,
              baseFrameDuration: Duration(milliseconds: editor.frameMs),
            ),
            if (editor.canEdit) ...[
              Positioned.fill(
                child: PixelEditOverlay(
                  gridSize: editor.gridSize,
                  isOn: (cell) => editor.currentFrame.contains(cell),
                  onSetCell: editor.setCell,
                  onStrokeBegin: editor.beginStroke,
                  onStrokeEnd: editor.endStroke,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
