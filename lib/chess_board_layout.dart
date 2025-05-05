import 'package:flutter/material.dart';

// Define Move class here to avoid circular import
class Move {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final int score;
  final String reason;

  Move(this.fromRow, this.fromCol, this.toRow, this.toCol, this.score, this.reason);
  
  @override
  String toString() {
    return 'Move(($fromRow,$fromCol) to ($toRow,$toCol), score: $score, reason: $reason)';
  }
}

class ChessBoardLayout extends StatelessWidget {
  final List<List<String>> boardMatrix;
  final Map<String, String> pieceIcons;
  final String? selectedPiece;
  final int? fromRow;
  final int? fromCol;
  final Move? bestMove;
  final bool setupMode;
  final void Function(int toRow, int toCol) onUpdate;
  final void Function(String piece, int row, int col) onDragStart;
  final void Function(String piece, int row, int col)? onPieceSelected;
  final void Function(String piece) onNewPieceDrag;
  final void Function()? onPieceRemoved;
  final void Function(bool)? onSetupModeChanged;

  const ChessBoardLayout({
    super.key,
    required this.boardMatrix,
    required this.pieceIcons,
    required this.selectedPiece,
    required this.fromRow,
    required this.fromCol,
    required this.onUpdate,
    required this.onDragStart,
    required this.onNewPieceDrag,
    this.onPieceRemoved,
    this.bestMove,
    this.onPieceSelected,
    this.setupMode = true,
    this.onSetupModeChanged,
  });

  // Convert move to algebraic chess notation
  String getMoveNotation(Move move) {
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final piece = boardMatrix[move.fromRow][move.fromCol];
    final isCapture = boardMatrix[move.toRow][move.toCol] != '-';
    
    // Get piece symbol (R for rook, N for knight, etc.)
    String pieceSymbol = '';
    switch (piece.toLowerCase()) {
      case 'r': pieceSymbol = 'R'; break;
      case 'n': pieceSymbol = 'N'; break;
      case 'b': pieceSymbol = 'B'; break;
      case 'q': pieceSymbol = 'Q'; break;
      case 'k': pieceSymbol = 'K'; break;
      default: pieceSymbol = ''; // Pawn has no letter prefix
    }
    
    // Construct the move notation
    final captureSymbol = isCapture ? 'x' : '';
    final toSquare = files[move.toCol] + (8 - move.toRow).toString();
    
    // For pawns
    if (piece.toLowerCase() == 'p') {
      if (isCapture) {
        return '${files[move.fromCol]}$captureSymbol$toSquare';
      } else {
        return toSquare; 
      }
    }
    
    // For other pieces
    return '$pieceSymbol$captureSymbol$toSquare';
  }

  Widget _buildPieceIcon(String piece, {double size = 30}) {
    final path = pieceIcons[piece];
    if (path == null) return Text(piece);
    return Image.asset(path, width: size, height: size);
  }

  Widget _buildSquare(BuildContext context, int row, int col) {
    final piece = boardMatrix[row][col];
    
    // Determine if this square is the best move destination
    final bool isBestMoveDestination = bestMove != null && 
                                      bestMove!.toRow == row && 
                                      bestMove!.toCol == col;
    
    // Determine if this is the currently selected piece
    final bool isSelectedPiece = fromRow == row && fromCol == col && selectedPiece != null;
                                      
    return DragTarget<String>(
      onAcceptWithDetails: setupMode ? (_) => onUpdate(row, col) : null,
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: isSelectedPiece 
                 ? Colors.lightBlue.withOpacity(0.6) 
                 : (row + col) % 2 == 0 ? Colors.brown[300] : Colors.white,
            border: Border.all(
              color: isBestMoveDestination ? Colors.green : Colors.black,
              width: isBestMoveDestination ? 3.0 : 1.0,
            ),
          ),
          child: piece != '-' 
              ? _buildPieceWidget(piece, row, col, isBestMoveDestination)
              : isBestMoveDestination
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox.shrink(),
        );
      },
    );
  }
  
  // Build a piece widget based on setup mode
  Widget _buildPieceWidget(String piece, int row, int col, bool isBestMoveDestination) {
    if (setupMode) {
      // In setup mode - pieces are draggable
      return Draggable<String>(
        data: piece,
        onDragStarted: () => onDragStart(piece, row, col),
        onDraggableCanceled: (_, __) {
          // This is called when the drag is canceled (dropped outside a valid target)
          if (onPieceRemoved != null) {
            onPieceRemoved!();
          }
        },
        feedback: Material(
          color: Colors.transparent,
          child: _buildPieceIcon(piece, size: 40),
        ),
        childWhenDragging: const SizedBox.shrink(),
        child: _buildPieceContent(piece, isBestMoveDestination),
      );
    } else {
      // In play mode - pieces are tappable but not draggable
      return GestureDetector(
        onTap: () {
          // In play mode, clicking on a rook evaluates best moves
          if (piece.toLowerCase() == 'r' && onPieceSelected != null) {
            onPieceSelected!(piece, row, col);
          }
        },
        child: _buildPieceContent(piece, isBestMoveDestination),
      );
    }
  }
  
  // Common content for both draggable and non-draggable modes
  Widget _buildPieceContent(String piece, bool isBestMoveDestination) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(child: _buildPieceIcon(piece)),
        if (isBestMoveDestination)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Game'), 
        centerTitle: true,
        actions: [
          if (bestMove != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  getMoveNotation(bestMove!),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Setup mode toggle
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Play Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: setupMode,
                  onChanged: onSetupModeChanged,
                  activeColor: Colors.blue,
                ),
                const Text('Setup Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              itemCount: 64,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) {
                final row = index ~/ 8;
                final col = index % 8;
                return _buildSquare(context, row, col);
              },
            ),
          ),
          // Only show piece palette in setup mode
          if (setupMode)
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 30),
              child: Column(
                children: [
                  const Text(
                    'Black Pieces',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    children:
                        ['R', 'N', 'B', 'Q', 'P'].map((piece) {
                          return Draggable<String>(
                            data: piece,
                            onDragStarted: () => onNewPieceDrag(piece),
                            feedback: Material(
                              color: Colors.transparent,
                              child: _buildPieceIcon(piece, size: 40),
                            ),
                            child: _buildPieceIcon(piece),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'White Pieces',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    children:
                        ['r', 'n', 'b', 'q', 'p'].map((piece) {
                          return Draggable<String>(
                            data: piece,
                            onDragStarted: () => onNewPieceDrag(piece),
                            feedback: Material(
                              color: Colors.transparent,
                              child: _buildPieceIcon(piece, size: 40),
                            ),
                            child: _buildPieceIcon(piece),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
