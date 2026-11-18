import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SpriteLibrary library = SpriteLibrary();
  final AppSettings settings = AppSettings();
  await library.load();
  await settings.load();

  runApp(Tamabudchi(library: library, settings: settings));
}

class Tamabudchi extends StatelessWidget {
  final AppSettings settings;
  final SpriteLibrary library;

  const Tamabudchi({super.key, required this.library, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamabudchi',
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      home: LibraryScreen(library: library, settings: settings),
    );
  }
}
