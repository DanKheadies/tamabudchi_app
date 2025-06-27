import 'package:flutter/material.dart';

enum PixelDirection { down, left, right, up }

enum PixelArt { three, two, one, pixel, heart1, heart2, heart3, baeb }

// int colLength = 15; // 16
// int rowLength = 35; // 32

const Map<PixelArt, Color> pixelColors = {
  PixelArt.three: Color.fromARGB(255, 0, 102, 255),
  PixelArt.two: Color(0xFF008000),
  PixelArt.one:  Color(0xFFffff00),
  PixelArt.pixel: Color(0xFFffffff),
  PixelArt.heart1: Color.fromARGB(255, 144, 0, 255), 
  PixelArt.heart2: Color.fromARGB(255, 242, 0, 255),
  PixelArt.heart3: Color(0xFFff0000),
  PixelArt.baeb: Color(0xFFffa500),
};
