import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

class Tamabudchi extends StatefulWidget {
  const Tamabudchi({super.key});

  @override
  State<Tamabudchi> createState() => _TamabudchiState();
}

class _TamabudchiState extends State<Tamabudchi> {
  List<Set<int>> frames = [];
  List<Set<int>> framesSimple = [
    {0, 2, 4, 6, 8},
    {0, 1, 2, 4, 6, 7, 8},
    {4},
  ];
  List<Set<int>> framesSpiral = [
    {4},
    {1},
    {2},
    {5},
    {8},
    {7},
    {6},
    {3},
    {0},
    {},
    {4},
    {4, 1},
    {4, 1, 2},
    {4, 1, 2, 5},
    {4, 1, 2, 5, 8},
    {4, 1, 2, 5, 8, 7},
    {4, 1, 2, 5, 8, 7, 6},
    {4, 1, 2, 5, 8, 7, 6, 3},
    {4, 1, 2, 5, 8, 7, 6, 3, 0},
    {},
  ];

  late PixelPlaybackController playback;

  @override
  void initState() {
    super.initState();

    frames = framesSimple;
    playback = PixelPlaybackController(frameCount: frames.length);
  }

  @override
  void dispose() {
    playback.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Standard')),
      body: SafeArea(
        // Build a responsive shell to maintain a center, square of pixels with
        // actions in horizontal & vertical spaces.
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth >= constraints.maxHeight;
            double barSize = 60;
            // Limiting-dimension
            double limen = isWide
                ? constraints.maxHeight
                : constraints.maxWidth;
            double limenAndBars = limen + (barSize * 2) + (barSize / 2);

            return Stack(
              children: [
                Center(
                  child: !isWide
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (constraints.maxHeight > limenAndBars) ...[
                              SequenceBar(
                                barSize: barSize,
                                frameCount: frames.length,
                                isHorizontal: true,
                                playback: playback,
                              ),
                            ],
                            TamaGrid(frames: frames, playback: playback),
                            if (constraints.maxHeight > limenAndBars) ...[
                              Container(
                                color: Colors.yellow.shade100,
                                height: barSize,
                                margin: EdgeInsets.only(top: barSize / 4),
                                width: double.infinity,
                                child: Center(
                                  child: IconButton(
                                    color: Colors.deepPurple,
                                    icon: Icon(Icons.cyclone),
                                    onPressed: () {
                                      setState(() {
                                        frames = frames == framesSimple
                                            ? framesSpiral
                                            : framesSimple;
                                        playback = PixelPlaybackController(
                                          frameCount: frames.length,
                                        );
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (constraints.maxWidth > limenAndBars) ...[
                              SequenceBar(
                                barSize: barSize,
                                frameCount: frames.length,
                                isHorizontal: false,
                                playback: playback,
                              ),
                            ],
                            TamaGrid(frames: frames, playback: playback),
                            if (constraints.maxWidth > limenAndBars) ...[
                              Container(
                                color: Colors.yellow.shade100,
                                height: double.infinity,
                                margin: EdgeInsets.only(left: barSize / 4),
                                width: barSize,
                              ),
                            ],
                          ],
                        ),
                ),
                // Vertical with floater
                if (!isWide && constraints.maxHeight <= limenAndBars) ...[
                  Positioned(
                    top: limen / 100,
                    left: limen / 100,
                    child: Opacity(
                      opacity: 0.75,
                      child: SequenceBar(
                        barSize: barSize,
                        frameCount: frames.length,
                        isFloating: true,
                        isHorizontal: true,
                        limen: limen,
                        playback: playback,
                      ),
                    ),
                  ),
                ],
                // Horizontal w/ floater
                if (isWide && constraints.maxWidth < limenAndBars) ...[
                  Positioned(
                    top: limen / 100,
                    left: limen / 100,
                    child: Opacity(
                      opacity: 0.75,
                      child: SequenceBar(
                        barSize: barSize,
                        frameCount: frames.length,
                        isFloating: true,
                        isHorizontal: false,
                        limen: limen,
                        playback: playback,
                      ),
                    ),
                  ),
                ],
                if (!isWide && constraints.maxHeight <= limenAndBars) ...[
                  Positioned(
                    bottom: limen / 100,
                    left: limen / 100,
                    child: Opacity(
                      opacity: 0.75,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.yellow.shade100,
                        ),
                        height: barSize,
                        width: limen - limen / 50,
                      ),
                    ),
                  ),
                ],
                if (isWide && constraints.maxWidth < limenAndBars) ...[
                  Positioned(
                    top: limen / 100,
                    right: limen / 100,
                    child: Opacity(
                      opacity: 0.75,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.yellow.shade100,
                        ),
                        height: limen - limen / 50,
                        width: barSize,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
