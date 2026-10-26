import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

// TODO: build out logic to control scenes & actions
class TamaGrid extends StatelessWidget {
  final List<Set<int>> frames;
  final PixelPlaybackController playback;

  const TamaGrid({super.key, required this.frames, required this.playback});

  @override
  Widget build(BuildContext context) {
    return PixelAnimation(controller: playback, frames: frames, gridSize: 3);
  }
}
