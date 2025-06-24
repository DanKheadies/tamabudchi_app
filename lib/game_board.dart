import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tamabudchi_app/piece.dart';
import 'package:tamabudchi_app/pixel.dart';
import 'package:tamabudchi_app/values.dart';

/// Create the game board with pieces.
List<List<Tetromino?>> gameBoard = List.generate(
  colLength,
  (i) => List.generate(rowLength, (j) => null),
);

/// A 2x2 grid with null representing an empty space.
/// A non empty space will have the color to represent landed pieces.
class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  bool gameOver = false;
  int currentScore = 0;
  int speedNormal = 400;
  int speedUp = 200;

  // current tetris piece
  Piece currentPiece = Piece(type: Tetromino.L);

  late Timer gameLoopTimer;

  @override
  void initState() {
    super.initState();

    // Start game on app start
    startGame();
  }

  void startGame() {
    currentPiece.initializePiece();

    // Frame refresh rate
    gameLoop(speedNormal);
  }

  // Loop that keeps the pieces moving
  void gameLoop(int frameRate) {
    gameLoopTimer = Timer.periodic(Duration(milliseconds: frameRate), (timer) {
      setState(() {
        // Clear lines
        clearLines();

        // Check landing
        checkLanding();

        // Check for game over
        if (gameOver) {
          timer.cancel();
          showGameOverDialog();
        }

        // Move the current piece down
        currentPiece.movePiece(Direction.down);
      });
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Game Over'),
            content: Text('Your score is: $currentScore'),
            actions: [
              TextButton(
                onPressed: () {
                  resetGame();
                  Navigator.of(context).pop();
                },
                child: Text('Play Again'),
              ),
            ],
          ),
    );
  }

  void resetGame() {
    // Clear the game board
    gameBoard = List.generate(
      colLength,
      (i) => List.generate(rowLength, (j) => null),
    );

    gameOver = false;
    currentScore = 0;

    createNewPiece();

    startGame();
  }

  /// Check for collision in the future position.
  /// Return true -> there is a collision
  /// return false -> there is no collision
  bool checkForCollision(Direction direction) {
    // Loop through each position of the current piece
    for (int i = 0; i < currentPiece.position.length; i++) {
      // Calculate the row and column of the current position.
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      // Adjust the row and col based on the direction.
      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      // Check if the piece is out of bounds, i.e. too low or far left / right.
      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      }

      // Check if the position is occupied by another piece.
      if (row >= 0 && col >= 0) {
        if (gameBoard[row][col] != null) {
          return true;
        }
      }
    }

    // If no collections are detected, return false.
    return false;
  }

  void checkLanding() {
    // If going down is occupied..
    if (checkForCollision(Direction.down)) {
      // Mark position as occupied on the gameboard.
      for (int i = 0; i < currentPiece.position.length; i++) {
        // Calculate the row and column of the current position.
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;

        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }

      // Once it lands, create the next piece.
      createNewPiece();
    }
  }

  void createNewPiece() {
    // Create a random object to generate rando Tetromino types.
    Random rand = Random();

    // Create a new piece with a random type.
    Tetromino randomType =
        Tetromino.values[rand.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();

    // The game is over when there's a piece at the top level. We'll check if
    // there's a piece at the top when we create a new piece instead of every
    // frame. New piees can go through the top, but if there's a piece there,
    // it should be game over.
    if (isGameOver()) {
      setState(() {
        gameOver = true;
      });
    }
  }

  void moveDown() {
    // Make sure the move is valid before moving.
    if (!checkForCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.down);
      });
    }
  }

  void moveLeft() {
    // Make sure the move is valid before moving.
    if (!checkForCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  void moveRight() {
    // Make sure the move is valid before moving.
    if (!checkForCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }
  }

  void rotatePiece() {
    setState(() {
      currentPiece.rotatePiece();
    });
  }

  void clearLines() {
    // 1: Loop thru row of the game board from bottom to top.
    for (int row = colLength - 1; row >= 0; row--) {
      // 2: Initialize a variable to track if the row is full.
      bool rowIsFull = true;

      // 3: Check if the row is full, i.e. all cols have a filled piece.
      for (int col = 0; col < rowLength; col++) {
        // If there's an empty column, rowIsNotFull so false and break.
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }

      // 4: Row is full, so clear and shift rows down.
      if (rowIsFull) {
        // 5: Move all rows above the cleared row down one level.
        for (int r = row; r > 0; r--) {
          // Copy the above row to the current row.
          gameBoard[r] = List.from(gameBoard[r - 1]);
        }

        // 6: Set the top row to empty.
        gameBoard[0] = List.generate(row, (index) => null);

        // 7: Increase the score.
        currentScore++;
      }
    }
  }

  bool isGameOver() {
    // Check if any columns in the top row are filled.
    for (int col = 0; col < rowLength; col++) {
      if (gameBoard[0][col] != null) {
        return true;
      }
    }

    // If the top row is empty, game is still going.
    return false;
  }

  @override
  void dispose() {
    gameLoopTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // onLongPress: () {
        //   moveDown();
        // },
        // onVerticalDragDown:
        //     (details) => setState(() {
        //       speedFactor = 5;
        //     }),
        onLongPress: () {
          print('long press start');
          gameLoopTimer.cancel();
          gameLoop(speedUp);
        },
        onLongPressEnd: (details) {
          print('long press end');
          gameLoopTimer.cancel();
          gameLoop(speedNormal);
        },
        onLongPressCancel: () {
          print('long press cancel');
          gameLoopTimer.cancel();
          gameLoop(speedNormal);
        },
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: rowLength,
                ),
                itemCount: rowLength * colLength,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  // Get row and col of each index
                  int row = (index / rowLength).floor();
                  int col = index % rowLength;

                  if (currentPiece.position.contains(index)) {
                    // Current piece
                    return Pixel(
                      color: currentPiece.color,
                      child: index.toString(),
                    );
                  } else if (gameBoard[row][col] != null) {
                    // Landed pieces
                    final Tetromino? tetrominoType = gameBoard[row][col];
                    return Pixel(
                      color: tetrominoColors[tetrominoType]!,
                      child: index.toString(),
                    );
                  } else {
                    // Blank pixel
                    return Pixel(
                      color: Colors.grey[900]!,
                      child: index.toString(),
                    );
                  }
                },
              ),
            ),
            Text('Score: $currentScore', style: TextStyle(color: Colors.white)),
            Padding(
              padding: const EdgeInsets.only(bottom: 50, top: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: moveLeft,
                    color: Colors.white,
                    icon: Icon(Icons.arrow_back_ios),
                  ),
                  IconButton(
                    onPressed: rotatePiece,
                    color: Colors.white,
                    icon: Icon(Icons.rotate_right),
                  ),
                  IconButton(
                    onPressed: moveRight,
                    color: Colors.white,
                    icon: Icon(Icons.arrow_forward_ios),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
