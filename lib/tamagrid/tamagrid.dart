import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

// TODO: build out logic to control scenes & actions
class TamaGrid extends StatelessWidget {
  const TamaGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return PixelAnimation(
      frames: [
        {0, 2, 4, 6, 8},
        {0, 1, 2, 4, 6, 7, 8},
        {4},
      ],
      gridSize: 3,
    );
  }
}
