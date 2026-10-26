import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

class SequenceBar extends StatelessWidget {
  final bool isHorizontal;
  final bool? isFloating;
  final double barSize;
  final double? limen;
  final int frameCount;
  final PixelPlaybackController playback;

  const SequenceBar({
    super.key,
    required this.barSize,
    required this.frameCount,
    required this.isHorizontal,
    required this.playback,
    this.isFloating = false,
    this.limen = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playback,
      builder: (context, _) {
        return Container(
          // color: Colors.green.shade100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isFloating! ? 15 : 0),
            color: Colors.green.shade100,
          ),
          height: isHorizontal
              ? barSize
              : isFloating!
              ? limen! - limen! / 50
              : double.infinity,
          margin: isHorizontal
              ? EdgeInsets.only(bottom: barSize / 4)
              : EdgeInsets.only(right: barSize / 4),
          width: !isHorizontal
              ? barSize
              : isFloating!
              ? limen! - limen! / 50
              : double.infinity,
          child: isHorizontal
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [...buttons()],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [...buttons()],
                ),
        );
      },
    );
  }

  List<Widget> buttons() {
    return [
      IconButton(
        color: Colors.deepPurple,
        onPressed: () => playback.step(-1),
        icon: const Icon(Icons.skip_previous),
      ),
      IconButton(
        color: Colors.deepPurple,
        onPressed: playback.toggle,
        icon: Icon(playback.playing ? Icons.pause : Icons.play_arrow),
      ),
      IconButton(
        color: Colors.deepPurple,
        onPressed: playback.step,
        icon: Icon(Icons.skip_next),
      ),
      IconButton(
        color: Colors.deepPurple,
        onPressed: playback.slowDown,
        icon: Icon(Icons.fast_rewind),
      ),
      IconButton(
        color: Colors.deepPurple,
        onPressed: playback.speedUp,
        icon: Icon(Icons.fast_forward),
      ),
    ];
  }
}
