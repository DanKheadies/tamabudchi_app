import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tamabudchi_app/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChannels.textInput.invokeMethod('TextInput.hide');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Tamabudchi', home: HomeScreen());
  }
}
