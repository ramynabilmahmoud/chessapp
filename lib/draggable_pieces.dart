import 'package:flutter/material.dart';

class DraggablePiece extends StatelessWidget {
  final String piece;
  final String? imagePath;
  final double size;
  final VoidCallback onDragStarted;

  const DraggablePiece({
    super.key,
    required this.piece,
    required this.imagePath,
    required this.onDragStarted,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) return Text(piece);
    return Draggable<String>(
      data: piece,
      onDragStarted: onDragStarted,
      feedback: Material(
        color: Colors.transparent,
        child: Image.asset(imagePath!, width: size, height: size),
      ),
      child: Image.asset(imagePath!, width: size, height: size),
    );
  }
}
