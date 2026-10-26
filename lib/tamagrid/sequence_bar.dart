import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

class SequenceBar extends StatefulWidget {
  final double barSize;
  final int frameCount;
  final PixelPlaybackController playback;

  const SequenceBar({
    super.key,
    required this.barSize,
    required this.frameCount,
    required this.playback,
  });

  @override
  State<SequenceBar> createState() => _SequenceBarState();
}

class _SequenceBarState extends State<SequenceBar> {
  // late final playback = PixelPlaybackController(frameCount: widget.frameCount);

  // @override
  // void dispose() {
  //   playback.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green.shade100,
      height: widget.barSize,
      margin: EdgeInsets.only(bottom: widget.barSize / 4),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            color: Colors.deepPurple,
            onPressed: () => widget.playback.step(-1),
            icon: const Icon(Icons.skip_previous),
          ),
          IconButton(
            color: Colors.deepPurple,
            onPressed: widget.playback.toggle,
            icon: Icon(
              widget.playback.playing ? Icons.pause : Icons.play_arrow,
            ),
          ),
          IconButton(
            color: Colors.deepPurple,
            onPressed: widget.playback.step,
            icon: Icon(Icons.skip_next),
          ),
          IconButton(
            color: Colors.deepPurple,
            onPressed: widget.playback.slowDown,
            icon: Icon(Icons.fast_rewind),
          ),
          IconButton(
            color: Colors.deepPurple,
            onPressed: widget.playback.speedUp,
            icon: Icon(Icons.fast_forward),
          ),
        ],
      ),
    );
  }
}
