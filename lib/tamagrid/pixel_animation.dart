import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tamabudchi_app/barrel.dart';

/// A random multiplier within ±[jitterPercent] of 1.0 (e.g. 30 -> 0.7 to 1.3).
double jitterFactor(int jitterPercent, Random random) {
  final spread = jitterPercent / 100;
  return 1 + (random.nextDouble() * 2 - 1) * spread;
}

/// How long to hold a frame: base time scaled by [factor], never below the
/// sprite minimum so a big jitter can't produce a zero-length frame.
Duration holdDuration(Duration base, double factor) {
  final ms = (base.inMilliseconds * factor).round();
  return Duration(milliseconds: max(Sprite.minFrameMs, ms));
}

class PixelAnimation extends StatefulWidget {
  final bool onionSkin;
  final Duration baseFrameDuration;
  final int gridSize;
  final int jitterPercent;
  final List<Set<int>> frames;
  final PixelPlaybackController controller;
  final Random? random; // injectable for tests; null means a real Random

  const PixelAnimation({
    super.key,
    required this.controller,
    required this.frames,
    required this.gridSize,
    this.baseFrameDuration = const Duration(milliseconds: 400),
    this.jitterPercent = 0,
    this.onionSkin = false,
    this.random,
  });

  @override
  State<PixelAnimation> createState() => _PixelAnimationState();
}

class _PixelAnimationState extends State<PixelAnimation>
    with SingleTickerProviderStateMixin {
  double _factor = 1.0;
  Duration accumulated = Duration.zero;
  Duration lastElapsed = Duration.zero;

  late final Random _random = widget.random ?? Random();
  late final Ticker ticker;

  PixelPlaybackController get controller => widget.controller;

  @override
  void initState() {
    super.initState();

    _factor = jitterFactor(widget.jitterPercent, _random);
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

    if (old.jitterPercent != widget.jitterPercent) {
      _factor = jitterFactor(widget.jitterPercent, _random);
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
      builder: (context, _) {
        final frames = widget.frames;
        final index = controller.frameIndex;

        // The animation loops; frame 0's "previous" is the last frame.
        final showGhost =
            widget.onionSkin && !controller.playing && frames.length > 1;
        final ghost = showGhost
            ? frames[(index - 1 + frames.length) % frames.length]
            : null;

        return AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: PixelGridPainter(
              frame: widget.frames[controller.frameIndex],
              ghost: ghost,
              gridSize: widget.gridSize,
            ),
          ),
        );
      },
    );
  }

  void onTick(Duration elapsed) {
    final dt = elapsed - lastElapsed;
    lastElapsed = elapsed;
    accumulated += dt;

    var hold = holdDuration(widget.baseFrameDuration, _factor);
    while (accumulated >= hold) {
      accumulated -= hold;
      controller.advance();
      _factor = jitterFactor(
        widget.jitterPercent,
        _random,
      ); // roll for next frame
      hold = holdDuration(widget.baseFrameDuration, _factor);
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
}
