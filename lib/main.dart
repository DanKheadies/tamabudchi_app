import 'package:flutter/material.dart';
import 'package:tamabudchi_app/game_board.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Tamabudchi', home: const GameBoard());
  }
}
