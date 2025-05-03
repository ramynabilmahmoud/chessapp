import 'dart:developer';

import 'package:flutter/material.dart';

import 'chess_board_layout.dart';

void main() => runApp(const ChessApp());

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ChessBoardScreen(),
    );
  }
}

class ChessBoardScreen extends StatefulWidget {
  const ChessBoardScreen({super.key});

  @override
  State<ChessBoardScreen> createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  List<List<String>> boardMatrix =
      List.generate(8, (row) => List.generate(8, (col) => '-'))
        ..[0][4] = 'K'
        ..[7][4] = 'k';

  String? selectedPiece;
  int? fromRow;
  int? fromCol;

  Map<String, String> pieceIcons = {
    'r': 'assets/images/white_rook.png',
    'n': 'assets/images/white_knight.png',
    'b': 'assets/images/white_bishop.png',
    'q': 'assets/images/white_queen.png',
    'k': 'assets/images/white_king.png',
    'p': 'assets/images/white_pawn.png',
    'R': 'assets/images/black_rook.png',
    'N': 'assets/images/black_knight.png',
    'B': 'assets/images/black_bishop.png',
    'Q': 'assets/images/black_queen.png',
    'K': 'assets/images/black_king.png',
    'P': 'assets/images/black_pawn.png',
  };

  void updateBoard(int toRow, int toCol) {
    if (selectedPiece != null) {
      if (boardMatrix[toRow][toCol] == 'k' ||
          boardMatrix[toRow][toCol] == 'K') {
        return;
      }

      setState(() {
        boardMatrix[toRow][toCol] = selectedPiece!;
        if (fromRow != null &&
            fromCol != null &&
            boardMatrix[fromRow!][fromCol!] != 'k' &&
            boardMatrix[fromRow!][fromCol!] != 'K') {
          boardMatrix[fromRow!][fromCol!] = '-';
        }
        selectedPiece = null;
        fromRow = null;
        fromCol = null;
      });

      printBoard();
    }
  }

  void printBoard() {
    for (var row in boardMatrix) {
      log(row.join(' '));
    }
    log('--------------------------');
  }

  @override
  Widget build(BuildContext context) {
    return ChessBoardLayout(
      boardMatrix: boardMatrix,
      pieceIcons: pieceIcons,
      selectedPiece: selectedPiece,
      fromRow: fromRow,
      fromCol: fromCol,
      onUpdate: (toRow, toCol) => updateBoard(toRow, toCol),
      onDragStart: (piece, row, col) {
        if (piece == 'k' || piece == 'K') return;
        selectedPiece = piece;
        fromRow = row;
        fromCol = col;
      },
      onNewPieceDrag: (piece) {
        selectedPiece = piece;
        fromRow = null;
        fromCol = null;
      },
    );
  }
}
