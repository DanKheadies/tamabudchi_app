import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

void main() {
  runApp(const TamabudchiApp());
}

class TamabudchiApp extends StatelessWidget {
  const TamabudchiApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamabudchi',
      theme: ThemeData(
        // colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        colorScheme: ColorScheme.dark(),
      ),
      debugShowCheckedModeBanner: false,
      home: const Tamabudchi(),
    );
  }
}
