import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tamabudchi_app/barrel.dart';

class PixelAnimation extends StatefulWidget {
  final Duration baseFrameDuration;
  final int gridSize;
  final List<Set<int>> frames;
  final PixelPlaybackController controller;

  const PixelAnimation({
    super.key,
    required this.controller,
    required this.frames,
    required this.gridSize,
    this.baseFrameDuration = const Duration(milliseconds: 400),
  });

  @override
  State<PixelAnimation> createState() => _PixelAnimationState();
}

class _PixelAnimationState extends State<PixelAnimation>
    with SingleTickerProviderStateMixin {
  Duration accumulated = Duration.zero;
  Duration lastElapsed = Duration.zero;

  late final Ticker ticker;

  PixelPlaybackController get controller => widget.controller;

  @override
  void initState() {
    super.initState();

    ticker = createTicker(onTick);
    controller.addListener(syncTicker);
    syncTicker();
  }

  @override
  void didUpdateWidget(covariant PixelAnimation old) {
    super.didUpdateWidget(old);

    if (old.controller != widget.controller) {
      old.controller.removeListener(syncTicker);
      widget.controller.addListener(syncTicker);
      syncTicker();
    }
  }

  void onTick(Duration elapsed) {
    final dt = elapsed - lastElapsed;
    lastElapsed = elapsed;
    accumulated += dt * controller.speed;
    while (accumulated >= widget.baseFrameDuration) {
      accumulated -= widget.baseFrameDuration;
      controller.advance();
    }
  }

  void syncTicker() {
    if (controller.playing && !ticker.isActive) {
      lastElapsed = Duration.zero; // restart at zero on start()
      ticker.start();
    } else if (!controller.playing && ticker.isActive) {
      ticker.stop();
    }
  }

  @override
  void dispose() {
    controller.removeListener(syncTicker);
    ticker.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: PixelGridPainter(
            frame: widget.frames[controller.frameIndex],
            gridSize: widget.gridSize,
          ),
        ),
      ),
    );
  }
}
