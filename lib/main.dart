import 'dart:developer' as dev;
import 'dart:math';
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
  //------------------------------------------------------------------------------
  // BOARD STATE
  //------------------------------------------------------------------------------
  
  // The chess board represented as a 2D array
  // '-' means empty square, lowercase is white, uppercase is black
  List<List<String>> boardMatrix =
      List.generate(8, (row) => List.generate(8, (col) => '-'))
        ..[0][4] = 'K'  // Black king
        ..[7][4] = 'k'; // White king

  // Currently selected piece and position
  String? selectedPiece;
  int? fromRow;
  int? fromCol;
  
  // Whether we're in setup mode (drag pieces) or play mode (evaluate moves)
  bool setupMode = true;
  
  // Best move calculated for the current position
  Move? bestMove;

  //------------------------------------------------------------------------------
  // PIECE DEFINITIONS
  //------------------------------------------------------------------------------
  
  // Standard piece values for evaluation (in centipawns)
  final Map<String, int> pieceValues = {
    'p': 1, 'P': 1,  // Pawns
    'r': 5, 'R': 5,  // Rooks
    'n': 3, 'N': 3,  // Knights
    'b': 3, 'B': 3,  // Bishops
    'q': 9, 'Q': 9,  // Queens
    'k': 0, 'K': 0,  // Kings (not used for capture evaluation)
  };

  // Piece image mappings
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

  //------------------------------------------------------------------------------
  // BOARD MANIPULATION METHODS
  //------------------------------------------------------------------------------
  
  // Update the board when a piece is moved
  void updateBoard(int toRow, int toCol) {
    if (selectedPiece != null) {
      // Don't allow placing pieces on kings
      if (boardMatrix[toRow][toCol] == 'k' ||
          boardMatrix[toRow][toCol] == 'K') {
        return;
      }

      setState(() {
        boardMatrix[toRow][toCol] = selectedPiece!;
        if (fromRow != null && fromCol != null) {
          // Remove the piece from its original position
          boardMatrix[fromRow!][fromCol!] = '-';
        }
        selectedPiece = null;
        fromRow = null;
        fromCol = null;
        bestMove = null; // Clear best move highlight
      });

      printBoard();
    }
  }

  // Remove a piece from the board
  void removePiece() {
    if (fromRow != null && fromCol != null && selectedPiece != null) {
      // Don't allow kings to be removed
      if (boardMatrix[fromRow!][fromCol!] == 'k' ||
          boardMatrix[fromRow!][fromCol!] == 'K') {
        return;
      }
      
      setState(() {
        boardMatrix[fromRow!][fromCol!] = '-';
        selectedPiece = null;
        fromRow = null;
        fromCol = null;
        bestMove = null; // Clear best move highlight
      });
      
      printBoard();
    }
  }

  // Toggle between setup mode and play mode
  void toggleSetupMode(bool value) {
    setState(() {
      setupMode = value;
      // Clear any selections when switching modes
      selectedPiece = null;
      fromRow = null;
      fromCol = null;
      bestMove = null;
    });
  }

  // Print the board to the console for debugging
  void printBoard() {
    for (var row in boardMatrix) {
      dev.log(row.join(' '));
    }
    dev.log('--------------------------');
  }

  //------------------------------------------------------------------------------
  // CHESS UTILITY METHODS
  //------------------------------------------------------------------------------
  
  // Check if a position is within board bounds
  bool isValidPosition(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  // Check if a piece is an opponent's piece (based on case)
  bool isOpponent(String piece, String targetPiece) {
    if (piece == '-' || targetPiece == '-') return false;
    return (piece.toLowerCase() == piece && targetPiece.toUpperCase() == targetPiece) ||
           (piece.toUpperCase() == piece && targetPiece.toLowerCase() == targetPiece);
  }

  //------------------------------------------------------------------------------
  // MOVE GENERATION
  //------------------------------------------------------------------------------
  
  // Generate all valid moves for a rook at the given position
  List<Move> getValidRookMoves(int row, int col) {
    List<Move> moves = [];
    String piece = boardMatrix[row][col];
    
    // If not a rook, return empty list
    if (piece.toLowerCase() != 'r') {
      dev.log("Not a rook at position ($row, $col): $piece");
      return moves;
    }
    
    dev.log("Finding valid moves for $piece at ($row, $col)");
    
    // Define the four directions for rook movement (up, right, down, left)
    List<List<int>> directions = [
      [-1, 0], [0, 1], [1, 0], [0, -1]
    ];

    for (var direction in directions) {
      int dr = direction[0];
      int dc = direction[1];
      
      dev.log("Checking direction: ($dr, $dc)");
      
      int r = row + dr;
      int c = col + dc;
      
      // Continue in this direction until we hit a piece or the edge of the board
      while (isValidPosition(r, c)) {
        String targetPiece = boardMatrix[r][c];
        
        if (targetPiece == '-') {
          // Empty square - valid move
          try {
            Move move = evaluateMove(piece, row, col, r, c);
            moves.add(move);
            dev.log("Added empty square move to ($r, $c)");
          } catch (e) {
            dev.log("Error evaluating move: $e");
          }
        } else if (isOpponent(piece, targetPiece)) {
          // Opponent's piece - can capture
          int score = calculateCaptureScore(targetPiece);
          
          moves.add(Move(row, col, r, c, score, "Capture $targetPiece"));
          dev.log("Added capture move to ($r, $c): $targetPiece with score $score");
          break; // Can't move further in this direction
        } else {
          // Our own piece - blocked
          dev.log("Blocked by own piece at ($r, $c)");
          break;
        }
        
        // Move further in this direction
        r += dr;
        c += dc;
      }
    }
    
    dev.log("Total valid moves: ${moves.length}");
    return moves;
  }

  //------------------------------------------------------------------------------
  // POSITION EVALUATION
  //------------------------------------------------------------------------------
  
  // Calculate score for capturing a piece
  int calculateCaptureScore(String piece) {
    if (piece == '-') return 0;
    
    // Standard piece values in centipawns (1/100th of a pawn)
    switch (piece.toLowerCase()) {
      case 'q': // Queen
        return 900; // Standard chess piece value
      case 'r': // Rook
        return 500;
      case 'b': // Bishop
      case 'n': // Knight
        return 320;
      case 'p': // Pawn
        return 100;
      default:
        return 100;
    }
  }

  // Evaluate a move based on various criteria
  Move evaluateMove(String piece, int fromRow, int fromCol, int toRow, int toCol) {
    // Base score starts at 0
    int score = 0;
    String reason = "Positioning";
    
    // Simulate the move on a copy of the board
    List<List<String>> tempBoard = List.generate(
      boardMatrix.length,
      (i) => List.generate(boardMatrix[i].length, (j) => boardMatrix[i][j])
    );
    
    // Make the move on the temporary board
    tempBoard[toRow][toCol] = piece;
    tempBoard[fromRow][fromCol] = '-';
    
    //--------------------------------------------------
    // 1. Material evaluation - captures
    //--------------------------------------------------
    String capturedPiece = boardMatrix[toRow][toCol];
    if (capturedPiece != '-') {
      int captureValue = calculateCaptureScore(capturedPiece);
      score += captureValue;
      reason = "Capture ${capturedPiece.toUpperCase()}";
    }
    
    //--------------------------------------------------
    // 2. King safety - checks and checkmate detection
    //--------------------------------------------------
    
    // Find the opponent's king
    String opponentKing = piece.toLowerCase() == piece ? 'K' : 'k';
    int kingRow = -1;
    int kingCol = -1;
    
    // Locate opponent's king
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (tempBoard[r][c] == opponentKing) {
          kingRow = r;
          kingCol = c;
          break;
        }
      }
      if (kingRow != -1) break;
    }
    
    if (kingRow != -1) {
      // Check if rook can attack king in this position
      if ((kingRow == toRow || kingCol == toCol)) {
        // Check if path to king is clear
        bool pathClear = true;
        if (kingRow == toRow) {
          int startCol = min(kingCol, toCol) + 1;
          int endCol = max(kingCol, toCol);
          for (int c = startCol; c < endCol; c++) {
            if (tempBoard[toRow][c] != '-') {
              pathClear = false;
              break;
            }
          }
        } else {
          int startRow = min(kingRow, toRow) + 1;
          int endRow = max(kingRow, toRow);
          for (int r = startRow; r < endRow; r++) {
            if (tempBoard[r][toCol] != '-') {
              pathClear = false;
              break;
            }
          }
        }
        
        // If king is in check
        if (pathClear) {
          
          // Higher score for check, but less than capturing a queen
          score += 400;
          
          // Check if it might be checkmate (approximation)
          bool kingCanMove = false;
          
          // Check if king has any escape squares
          List<List<int>> kingMoves = [
            [-1, -1], [-1, 0], [-1, 1],
            [0, -1],           [0, 1],
            [1, -1],  [1, 0],  [1, 1]
          ];
          
          for (var move in kingMoves) {
            int r = kingRow + move[0];
            int c = kingCol + move[1];
            
            if (isValidPosition(r, c) && 
                (tempBoard[r][c] == '-' || 
                 isOpponent(opponentKing, tempBoard[r][c]))) {
              // Rough check if the square is attacked
              bool squareIsAttacked = false;
              
              // Simplified attack detection - just check if our rook attacks it
              if (r == toRow || c == toCol) {
                squareIsAttacked = true;
              }
              
              if (!squareIsAttacked) {
                kingCanMove = true;
                break;
              }
            }
          }
          
          // If king can't move and is in check, it might be checkmate
          if (!kingCanMove) {
            score += 10000; // Huge bonus for checkmate
            reason = "Checkmate";
          } else {
            reason = "Checks the king";
          }
        }
      }
    }
    
    //--------------------------------------------------
    // 3. Positional evaluation
    //--------------------------------------------------
    if (reason == "Positioning") {
      // Calculate piece mobility (how many squares it controls)
      int mobility = 0;
      List<List<int>> directions = [
        [-1, 0], [0, 1], [1, 0], [0, -1] // Rook directions
      ];
      
      for (var direction in directions) {
        int dr = direction[0];
        int dc = direction[1];
        
        int r = toRow + dr;
        int c = toCol + dc;
        
        while (isValidPosition(r, c)) {
          mobility++;
          if (tempBoard[r][c] != '-') break;
          r += dr;
          c += dc;
        }
      }
      
      // Bonus for mobility
      score += mobility * 10;
      
      // Bonus for controlling central files (columns d and e)
      if (toCol == 3 || toCol == 4) {
        score += 30;
        reason = "Controls central file";
      }
      
      // Bonus for controlling 7th/2nd rank (opponent's second rank)
      bool isWhitePiece = piece.toLowerCase() == piece;
      if ((isWhitePiece && toRow == 1) || (!isWhitePiece && toRow == 6)) {
        score += 50;
        reason = "Controls opponent's 2nd rank";
      }
      
      // Bonus for controlling open files (files with no pawns)
      bool openFile = true;
      for (int r = 0; r < 8; r++) {
        if (tempBoard[r][toCol].toLowerCase() == 'p') {
          openFile = false;
          break;
        }
      }
      
      if (openFile) {
        score += 40;
        reason = "Controls open file";
      }
      
      // Prefer to move rooks connected (on same row)
      bool rooksConnected = false;
      for (int c = 0; c < 8; c++) {
        if (c != toCol && tempBoard[toRow][c].toLowerCase() == 'r' && 
            (tempBoard[toRow][c].toLowerCase() == piece.toLowerCase())) {
          // Same color rook on same row
          rooksConnected = true;
          break;
        }
      }
      
      if (rooksConnected) {
        score += 25;
        reason = "Connected rooks";
      }
    }
    
    return Move(fromRow, fromCol, toRow, toCol, score, reason);
  }

  // Find the best move for a rook
  void findBestRookMove() {
    if (selectedPiece == null || selectedPiece!.toLowerCase() != 'r' || 
        fromRow == null || fromCol == null) {
      dev.log("Cannot evaluate: not a rook or position not set");
      return;
    }
    
    dev.log("Evaluating best move for rook at ($fromRow, $fromCol)");
    
    // Get all valid moves for this rook
    List<Move> validMoves = getValidRookMoves(fromRow!, fromCol!);
    
    dev.log("Found ${validMoves.length} valid moves");
    for (var move in validMoves) {
      dev.log(" - $move");
    }
    
    if (validMoves.isEmpty) {
      dev.log("No valid moves for this rook");
      return;
    }
    
    // Sort moves by score (descending)
    validMoves.sort((a, b) => b.score.compareTo(a.score));
    
    // The best move is the first one after sorting
    bestMove = validMoves.first;
    
    // Log the best move and reason
    dev.log("Best move: $bestMove");
    
    setState(() {
      // Update UI to highlight the best move
    });
  }

  //------------------------------------------------------------------------------
  // USER INTERACTION HANDLERS
  //------------------------------------------------------------------------------
  
  // Handle start of drag operation
  void onDragStart(String piece, int row, int col) {
    // Set which piece is being dragged and from where
    selectedPiece = piece;
    fromRow = row;
    fromCol = col;
  }

  // Handle piece selection (in play mode)
  void onPieceSelected(String piece, int row, int col) {
    dev.log("Piece selected: $piece at ($row, $col)");
    
    // Clear previous best move
    setState(() {
      bestMove = null;
    });
    
    selectedPiece = piece;
    fromRow = row;
    fromCol = col;
    
    // If a rook is selected, evaluate best moves
    if (piece.toLowerCase() == 'r') {
      dev.log("Rook selected, finding best move");
      findBestRookMove();
    }
  }

  //------------------------------------------------------------------------------
  // WIDGET BUILDING
  //------------------------------------------------------------------------------
  
  @override
  Widget build(BuildContext context) {
    return ChessBoardLayout(
      // Board state
      boardMatrix: boardMatrix,
      pieceIcons: pieceIcons,
      selectedPiece: selectedPiece,
      fromRow: fromRow,
      fromCol: fromCol,
      bestMove: bestMove,
      setupMode: setupMode,
      
      // Event callbacks
      onSetupModeChanged: toggleSetupMode,
      onUpdate: (toRow, toCol) => updateBoard(toRow, toCol),
      onDragStart: onDragStart,
      onPieceSelected: onPieceSelected,
      onNewPieceDrag: (piece) {
        selectedPiece = piece;
        fromRow = null;
        fromCol = null;
        bestMove = null; // Clear best move highlight
      },
      onPieceRemoved: removePiece,
    );
  }
}
