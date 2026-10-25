import 'package:flutter/material.dart';

class PixelGridPainter extends CustomPainter {
  final Color onColor;
  final Color offColor;
  final double gap;
  final int gridSize;
  final Set<int> frame;

  PixelGridPainter({
    required this.frame,
    required this.gridSize,
    this.gap = 0.08,
    this.offColor = const Color(0xFFC7D3B0),
    this.onColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / gridSize;
    final inset = cell * gap / 2;

    canvas.drawRect(Offset.zero & size, Paint()..color = offColor);

    final paint = Paint()..color = onColor;
    for (final i in frame) {
      final row = i ~/ gridSize;
      final col = i % gridSize;

      canvas.drawRect(
        Rect.fromLTWH(
          col * cell + inset,
          row * cell + inset,
          cell - inset * 2,
          cell - inset * 2,
        ),
        paint,
      );
    }
  }

  @override
  // bool shouldRepaint(covariant CustomPainter oldDelegate) =>
  bool shouldRepaint(PixelGridPainter old) =>
      old.frame != frame ||
      old.gridSize != gridSize ||
      old.onColor != onColor ||
      old.offColor != offColor;
}
