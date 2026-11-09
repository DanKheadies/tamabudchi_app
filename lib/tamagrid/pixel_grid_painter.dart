import 'package:flutter/material.dart';

class PixelGridPainter extends CustomPainter {
  final Color ghostColor;
  final Color onColor;
  final Color offColor;
  final double gap;
  final int gridSize;
  final Set<int> frame;
  final Set<int>? ghost;

  PixelGridPainter({
    required this.frame,
    required this.gridSize,
    this.gap = 0.08,
    this.ghost,
    this.ghostColor = const Color(0x40000000), // black @ 25%
    this.offColor = const Color(0xFFC7D3B0),
    this.onColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / gridSize;
    final inset = cell * gap / 2;

    canvas.drawRect(Offset.zero & size, Paint()..color = offColor);

    void drawCells(Set<int> cells, Color color) {
      final paint = Paint()..color = color;
      for (final i in cells) {
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

    final ghostCells = ghost;
    if (ghostCells != null) drawCells(ghostCells, ghostColor);
    drawCells(frame, onColor);
  }

  @override
  bool shouldRepaint(PixelGridPainter old) =>
      old.frame != frame ||
      old.ghost != ghost ||
      old.ghostColor != ghostColor ||
      old.gridSize != gridSize ||
      old.onColor != onColor ||
      old.offColor != offColor;
}
