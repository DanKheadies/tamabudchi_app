import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

class PixelAnimation extends StatefulWidget {
  final Duration frameDuration;
  final int gridSize;
  final List<Set<int>> frames;

  const PixelAnimation({
    super.key,
    required this.frames,
    required this.gridSize,
    this.frameDuration = const Duration(milliseconds: 400),
  });

  @override
  State<PixelAnimation> createState() => _PixelAnimationState();
}

class _PixelAnimationState extends State<PixelAnimation> {
  int frame = 0;

  late final Timer timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(widget.frameDuration, (_) {
      setState(() {
        frame = (frame + 1) % widget.frames.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: PixelGridPainter(
          frame: widget.frames[frame],
          gridSize: widget.gridSize,
        ),
      ),
    );
  }
}
