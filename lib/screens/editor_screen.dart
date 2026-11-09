import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

class EditorScreen extends StatefulWidget {
  final bool startEditing;
  final Sprite sprite;
  final SpriteLibrary library;

  const EditorScreen({
    super.key,
    required this.library,
    required this.sprite,
    this.startEditing = false,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver {
  static const double _barSize = 60;

  // late PixelPlaybackController playback;
  late final SpriteEditor editor;

  // Tracks the last sprite handed to the library to avoid unnecessary saves,
  // i.e. edit-mode / onion-skin toggles.
  late Sprite _lastSaved;

  @override
  void initState() {
    super.initState();

    editor = SpriteEditor(sprite: widget.sprite);
    _lastSaved = widget.sprite;
    editor.addListener(_autosave);
    WidgetsBinding.instance.addObserver(this);

    if (widget.startEditing) editor.toggleEditing();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A phone can kill a backgrounded app at any time, so don't leave recent
    // edits waiting on the library's save delay.
    if (state != AppLifecycleState.resumed) {
      unawaited(widget.library.flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    editor.removeListener(_autosave);
    unawaited(widget.library.flush()); // save anything still pending
    editor.dispose(); // disposes editor.playback too

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

  void _autosave() {
    if (identical(editor.sprite, _lastSaved)) return;

    _lastSaved = editor.sprite;
    widget.library.update(editor.sprite);
  }

  Widget _framesBar({
    required bool horizontal,
    bool floating = false,
    double limen = 0,
  }) {
    return FramesBar(
      barSize: _barSize,
      editor: editor,
      isFloating: floating,
      isHorizontal: horizontal,
      limen: limen,
      onOpenLibrary: () => Navigator.of(context).maybePop(),
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
