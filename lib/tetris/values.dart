// Grid dimensions
import 'package:flutter/material.dart';

int colLength = 15; // 16
int rowLength = 10; // 32

enum Direction { left, right, down }

enum Tetromino { L, J, I, O, S, Z, T }

/* 
 
 o
 o
 o o

   o
   o
 o o

 o
 o
 o
 o

 o o
 o o

   o o
 o o

 o o
   o o

 o
 o o
 o

*/

const Map<Tetromino, Color> tetrominoColors = {
  Tetromino.L: Color(0xFFffa500),
  Tetromino.J: Color.fromARGB(255, 0, 102, 255),
  Tetromino.I: Color.fromARGB(255, 242, 0, 255),
  Tetromino.O: Color(0xFFffff00),
  Tetromino.S: Color(0xFF008000),
  Tetromino.Z: Color(0xFFff0000),
  Tetromino.T: Color.fromARGB(255, 144, 0, 255),
};
