import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

class EditorScreen extends StatefulWidget {
  final AppSettings settings;
  final bool startEditing;
  final Sprite sprite;
  final SpriteLibrary library;

  const EditorScreen({
    super.key,
    required this.library,
    required this.settings,
    required this.sprite,
    this.startEditing = false,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver {
  static const double _barGap = _barSize / 4;
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

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     // appBar: AppBar(title: Text('Standard')),
  //     body: SafeArea(
  //       // Build a responsive shell to maintain a center, square of pixels with
  //       // actions in horizontal & vertical spaces.
  //       child: LayoutBuilder(
  //         builder: (context, constraints) {
  //           bool isWide = constraints.maxWidth >= constraints.maxHeight;
  //           // Limiting-dimension
  //           double limen = isWide
  //               ? constraints.maxHeight
  //               : constraints.maxWidth;
  //           double limenAndBars = limen + (_barSize * 2) + (_barSize / 2);
  //           // Bars sit beside the grid when there's room, else float over it.
  //           final barsInline =
  //               (isWide ? constraints.maxWidth : constraints.maxHeight) >
  //               limenAndBars;

  //           return Stack(
  //             children: [
  //               Center(
  //                 child: Flex(
  //                   direction: isWide ? Axis.horizontal : Axis.vertical,
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     if (barsInline) _sequenceBar(horizontal: !isWide),
  //                     TamaGrid(editor: editor),
  //                     if (barsInline) _framesBar(horizontal: !isWide),
  //                   ],
  //                 ),
  //               ),
  //               if (!barsInline) ...[
  //                 // Sequence bar
  //                 Positioned(
  //                   top: limen / 100,
  //                   left: limen / 100,
  //                   child: Opacity(
  //                     opacity: 0.75,
  //                     child: _sequenceBar(
  //                       horizontal: !isWide,
  //                       floating: true,
  //                       limen: limen,
  //                     ),
  //                   ),
  //                 ),
  //                 // Frames bar
  //                 Positioned(
  //                   top: isWide ? limen / 100 : null,
  //                   bottom: isWide ? null : limen / 100,
  //                   left: isWide ? null : limen / 100,
  //                   right: isWide ? limen / 100 : null,
  //                   child: Opacity(
  //                     opacity: 0.75,
  //                     child: _framesBar(
  //                       horizontal: !isWide,
  //                       floating: true,
  //                       limen: limen,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ],
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Rebuild when the bar layout setting changes.
        child: ListenableBuilder(
          listenable: widget.settings,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final placement = widget.settings.barLayout.placement;
              final isWide = constraints.maxWidth >= constraints.maxHeight;
              // Limiting-dimension
              final limen = isWide
                  ? constraints.maxHeight
                  : constraints.maxWidth;
              // Two bars and two gaps, in every layout.
              final limenAndBars = limen + (_barSize * 2) + (_barSize / 2);
              // Bars sit beside the grid when there's room, else float over it.
              final barsInline =
                  (isWide ? constraints.maxWidth : constraints.maxHeight) >
                  limenAndBars;

              final gap = SizedBox(
                width: isWide ? _barGap : 0,
                height: isWide ? 0 : _barGap,
              );

              return Stack(
                children: [
                  Center(
                    child: Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (barsInline)
                          for (final kind in placement.before) ...[
                            _bar(kind, horizontal: !isWide),
                            gap,
                          ],
                        TamaGrid(editor: editor),
                        if (barsInline)
                          for (final kind in placement.after) ...[
                            gap,
                            _bar(kind, horizontal: !isWide),
                          ],
                      ],
                    ),
                  ),
                  if (!barsInline) ...[
                    for (final (i, kind) in placement.before.indexed)
                      _floatingBar(
                        kind,
                        isWide: isWide,
                        limen: limen,
                        atStart: true,
                        fromEdge: i,
                      ),
                    for (final (i, kind) in placement.after.indexed)
                      _floatingBar(
                        kind,
                        isWide: isWide,
                        limen: limen,
                        atStart: false,
                        fromEdge: placement.after.length - 1 - i,
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _autosave() {
    if (identical(editor.sprite, _lastSaved)) return;

    _lastSaved = editor.sprite;
    widget.library.update(editor.sprite);
  }

  Widget _bar(
    BarKind kind, {
    required bool horizontal,
    bool floating = false,
    double limen = 0,
  }) {
    return switch (kind) {
      BarKind.sequence => _sequenceBar(
        horizontal: horizontal,
        floating: floating,
        limen: limen,
      ),
      BarKind.frames => _framesBar(
        horizontal: horizontal,
        floating: floating,
        limen: limen,
      ),
    };
  }

  /// A bar floating over the grid, pinned to the start or end edge. [fromEdge]
  /// is how many bars sit between this one and that edge (0 = outermost).
  Widget _floatingBar(
    BarKind kind, {
    required bool isWide,
    required double limen,
    required bool atStart,
    required int fromEdge,
  }) {
    final cross = limen / 100;
    final inset = cross + fromEdge * (_barSize + _barGap);

    return Positioned(
      top: isWide ? cross : (atStart ? inset : null),
      bottom: isWide || atStart ? null : inset,
      left: isWide ? (atStart ? inset : null) : cross,
      right: isWide && !atStart ? inset : null,
      child: Opacity(
        opacity: 0.75,
        child: _bar(kind, horizontal: !isWide, floating: true, limen: limen),
      ),
    );
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
