import 'package:flutter/material.dart';

@immutable
class GameLevel {
  const GameLevel({
    required this.levelNumber,
    required this.gridSize,
    required this.initialGrid,
    required this.solutionGrid,
  });

  final int levelNumber;
  final int gridSize;
  final List<List<int?>> initialGrid;
  final List<List<int>> solutionGrid;
}
