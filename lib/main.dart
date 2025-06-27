import 'package:flutter/material.dart';
import 'package:tamabudchi_app/pixel_art/art_board.dart';
// import 'package:tamabudchi_app/tetris/game_board.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print('build');
    Size screenSize = MediaQuery.of(context).size;
    bool isVertical = screenSize.height > screenSize.width;

    return MaterialApp(
      title: 'Tamabudchi',
      home: ArtBoard(
        isVertical: isVertical,
        colLength: isVertical ? 35 : 15,
        rowLength: isVertical ? 15 : 35,
        resetGameBoard: () => print('reset'),
        screenHeight: screenSize.height,
      ),
    );
  }
}
