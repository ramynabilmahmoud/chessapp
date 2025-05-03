import 'package:flutter/material.dart';

class ChessBoardLayout extends StatelessWidget {
  final List<List<String>> boardMatrix;
  final Map<String, String> pieceIcons;
  final String? selectedPiece;
  final int? fromRow;
  final int? fromCol;
  final void Function(int toRow, int toCol) onUpdate;
  final void Function(String piece, int row, int col) onDragStart;
  final void Function(String piece) onNewPieceDrag;

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
  });

  Widget _buildPieceIcon(String piece, {double size = 30}) {
    final path = pieceIcons[piece];
    if (path == null) return Text(piece);
    return Image.asset(path, width: size, height: size);
  }

  Widget _buildSquare(BuildContext context, int row, int col) {
    final piece = boardMatrix[row][col];
    return DragTarget<String>(
      onAcceptWithDetails: (_) => onUpdate(row, col),
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: (row + col) % 2 == 0 ? Colors.brown[300] : Colors.white,
            border: Border.all(color: Colors.black),
          ),
          child:
              piece != '-'
                  ? Draggable<String>(
                    data: piece,
                    onDragStarted: () => onDragStart(piece, row, col),
                    feedback: Material(
                      color: Colors.transparent,
                      child: _buildPieceIcon(piece, size: 40),
                    ),
                    childWhenDragging: const SizedBox.shrink(),
                    child: Center(child: _buildPieceIcon(piece)),
                  )
                  : const SizedBox.shrink(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chess Game'), centerTitle: true),
      body: Column(
        children: [
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
                      ['R', 'N', 'Q', 'P'].map((piece) {
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
                      ['r', 'n', 'q', 'p'].map((piece) {
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
