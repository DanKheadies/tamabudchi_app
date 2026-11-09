import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SpriteLibrary library = SpriteLibrary();
  await library.load();

  runApp(Tamabudchi(library: library));
}

class Tamabudchi extends StatelessWidget {
  final SpriteLibrary library;

  const Tamabudchi({super.key, required this.library});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamabudchi',
      theme: ThemeData(
        // colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        colorScheme: ColorScheme.dark(),
      ),
      debugShowCheckedModeBanner: false,
      home: LibraryScreen(library: library),
    );
  }
}
