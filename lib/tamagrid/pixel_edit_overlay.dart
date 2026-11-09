import 'dart:math';

import 'package:flutter/material.dart';

/// Transparent layer that sits on top of the pixel grid while editing.
/// Draws faint cell lines and turns touch / mouse input into cell edits.
///
/// Uses raw pointer events so a pixel changes the instant a finger lands, and
/// drags paint continuously.
class PixelEditOverlay extends StatefulWidget {
  final int gridSize;
  final bool Function(int cell) isOn;
  final void Function(int cell, bool on) onSetCell;
  final VoidCallback onStrokeBegin;
  final VoidCallback onStrokeEnd;

  const PixelEditOverlay({
    super.key,
    required this.gridSize,
    required this.isOn,
    required this.onSetCell,
    required this.onStrokeBegin,
    required this.onStrokeEnd,
  });

  @override
  State<PixelEditOverlay> createState() => _PixelEditOverlayState();
}

class _PixelEditOverlayState extends State<PixelEditOverlay> {
  int? _pointer; // only one finger draws at a time
  Offset? _lastPos;
  bool _drawing = true; // true = turn pixels on, false = erase

  int? _cellAt(Offset p, double side) {
    if (p.dx < 0 || p.dy < 0 || p.dx >= side || p.dy >= side) return null;
    final cell = side / widget.gridSize;
    final col = (p.dx / cell).floor();
    final row = (p.dy / cell).floor();
    return row * widget.gridSize + col;
  }

  void _down(PointerDownEvent e, double side) {
    if (_pointer != null) return; // ignore extra fingers
    _pointer = e.pointer;
    _lastPos = e.localPosition;
    _drawing = true;
    widget.onStrokeBegin();

    final cell = _cellAt(e.localPosition, side);
    if (cell == null) return;

    // The first cell touched decides the whole stroke: starting on an "on"
    // pixel erases, starting on an "off" pixel draws. No flicker mid-drag.
    _drawing = !widget.isOn(cell);
    widget.onSetCell(cell, _drawing);
  }

  void _move(PointerMoveEvent e, double side) {
    if (e.pointer != _pointer) return;
    final from = _lastPos ?? e.localPosition;
    final to = e.localPosition;
    _lastPos = to;

    // Sample along the segment so a fast drag can't skip over cells.
    final cellSize = side / widget.gridSize;
    final steps = max(1, ((to - from).distance / (cellSize / 2)).ceil());
    for (var s = 1; s <= steps; s++) {
      final p = from + (to - from) * (s / steps);
      final cell = _cellAt(p, side);
      if (cell != null) widget.onSetCell(cell, _drawing);
    }
  }

  void _end(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _lastPos = null;
    widget.onStrokeEnd();
  }

  @override
  void dispose() {
    // Clears flags; avoids keeping the stroke "open"
    if (_pointer != null) widget.onStrokeEnd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _down(e, side),
          onPointerMove: (e) => _move(e, side),
          onPointerUp: _end,
          onPointerCancel: _end,
          child: CustomPaint(painter: _GridLinesPainter(widget.gridSize)),
        );
      },
    );
  }
}

class _GridLinesPainter extends CustomPainter {
  final int gridSize;

  _GridLinesPainter(this.gridSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;
    final cell = size.width / gridSize;

    for (var i = 1; i < gridSize; i++) {
      canvas.drawLine(
        Offset(i * cell, 0),
        Offset(i * cell, size.height),
        paint,
      );
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), paint);
    }
  }

  @override
  bool shouldRepaint(_GridLinesPainter old) => old.gridSize != gridSize;
}
