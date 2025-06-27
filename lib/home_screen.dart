import 'package:flutter/material.dart';
import 'package:tamabudchi_app/pixel_art/art_board.dart';
import 'package:tamabudchi_app/tetris/game_board.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    print(screenSize.height);
    print(MediaQuery.of(context).devicePixelRatio);
    bool isVertical = screenSize.height > screenSize.width;
    double statusBarHeight = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GameBoard()),
              );
            },
            child: Text('Tetris'),
          ),
          const SizedBox(height: 100, width: double.infinity),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ArtBoard(
                        isVertical: isVertical,
                        colLength: isVertical ? 35 : 15,
                        rowLength: isVertical ? 15 : 35,
                        resetGameBoard: () => print('reset'),
                        screenHeight: screenSize.height,
                        statusBarHeight: statusBarHeight,
                      ),
                ),
              );
            },
            child: Text('Pixel Art'),
          ),
        ],
      ),
    );
  }
}
