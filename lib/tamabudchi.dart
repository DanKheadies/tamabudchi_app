import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

class Tamabudchi extends StatefulWidget {
  const Tamabudchi({super.key});

  @override
  State<Tamabudchi> createState() => _TamabudchiState();
}

class _TamabudchiState extends State<Tamabudchi> {
  static const double _barSize = 60;

  final List<Sprite> _sprites = [
    Sprite(
      id: 'simple',
      name: 'Simple',
      gridSize: 3,
      frames: [
        {0, 2, 4, 6, 8},
        {0, 1, 2, 4, 6, 7, 8},
        {4},
      ],
    ),
    Sprite(
      id: 'spiral',
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

  int _spriteIndex = 0;

  // late PixelPlaybackController playback;
  late final SpriteEditor editor;

  @override
  void initState() {
    super.initState();

    editor = SpriteEditor(sprite: _sprites.first);
  }

  @override
  void dispose() {
    // playback.dispose();
    editor.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Standard')),
      body: SafeArea(
        // Build a responsive shell to maintain a center, square of pixels with
        // actions in horizontal & vertical spaces.
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth >= constraints.maxHeight;
            // Limiting-dimension
            double limen = isWide
                ? constraints.maxHeight
                : constraints.maxWidth;
            double limenAndBars = limen + (_barSize * 2) + (_barSize / 2);
            // Bars sit beside the grid when there's room, else float over it.
            final barsInline =
                (isWide ? constraints.maxWidth : constraints.maxHeight) >
                limenAndBars;

            return Stack(
              children: [
                Center(
                  child: Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (barsInline) _sequenceBar(horizontal: !isWide),
                      TamaGrid(editor: editor),
                      if (barsInline) _framesBar(horizontal: !isWide),
                    ],
                  ),
                ),
                if (!barsInline) ...[
                  // Sequence bar
                  Positioned(
                    top: limen / 100,
                    left: limen / 100,
                    child: Opacity(
                      opacity: 0.75,
                      child: _sequenceBar(
                        horizontal: !isWide,
                        floating: true,
                        limen: limen,
                      ),
                    ),
                  ),
                  // Frames bar
                  Positioned(
                    top: isWide ? limen / 100 : null,
                    bottom: isWide ? null : limen / 100,
                    left: isWide ? null : limen / 100,
                    right: isWide ? limen / 100 : null,
                    child: Opacity(
                      opacity: 0.75,
                      child: _framesBar(
                        horizontal: !isWide,
                        floating: true,
                        limen: limen,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void cycleSprite() {
    // Save any edits to the current sprite before cycling.
    _sprites[_spriteIndex] = editor.sprite;
    _spriteIndex = (_spriteIndex + 1) % _sprites.length;
    editor.load(_sprites[_spriteIndex]);
  }

  Widget _framesBar({
    required bool horizontal,
    bool floating = false,
    double limen = 0,
  }) {
    return FramesBar(
      barSize: _barSize,
      cycleFrameSet: cycleSprite,
      editor: editor,
      isFloating: floating,
      isHorizontal: horizontal,
      limen: limen,
    );
  }

  Widget _sequenceBar({
    required bool horizontal,
    bool floating = false,
    double limen = 0,
  }) {
    return SequenceBar(
      barSize: _barSize,
      editor: editor,
      isFloating: floating,
      isHorizontal: horizontal,
      limen: limen,
    );
  }
}
