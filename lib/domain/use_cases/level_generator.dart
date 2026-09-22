import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:binarypuzzle/domain/models/game_level.dart';
import 'package:binarypuzzle/domain/use_cases/cell_rules.dart';

class LevelGenerator {
  final Map<int, GameLevel> _cache = {};
  final Set<int> _generating = {};

  Future<GameLevel> generateAsync(int levelNumber) async {
    if (_cache.containsKey(levelNumber)) {
      return _cache.remove(levelNumber)!;
    }
    return compute(_isolateGenerate, levelNumber);
  }

  static GameLevel _isolateGenerate(int levelNumber) {
    return LevelGenerator()._generateInternal(levelNumber);
  }

  GameLevel _generateInternal(int levelNumber) {
    final random = Random(levelNumber);
    final gridSize = _getGridSize(levelNumber);
    return _generateLevelWithSeed(levelNumber, gridSize, random);
  }

  void pregenerateAround(int currentLevel, {int range = 1}) {
    for (int i = 0; i <= range; i++) {
      final levelNumber = currentLevel + i;
      if (levelNumber < 1) continue;
      if (!_cache.containsKey(levelNumber) && !_generating.contains(levelNumber)) {
        _generating.add(levelNumber);
        compute(_isolateGenerate, levelNumber).then((level) {
          _cache[levelNumber] = level;
          _generating.remove(levelNumber);
        }).catchError((e) {
          _generating.remove(levelNumber);
        });
      }
    }
  }

  Future<GameLevel> generateRandomAsync({required int gridSize, required int seed}) {
    return compute(_isolateGenerateRandom, {'gridSize': gridSize, 'seed': seed});
  }

  static GameLevel _isolateGenerateRandom(Map<String, int> params) {
    return LevelGenerator().generateRandom(
      gridSize: params['gridSize']!,
      seed: params['seed']!,
    );
  }

  GameLevel generateRandom({required int gridSize, required int seed}) {
    final random = Random(seed);
    return _generateLevelWithSeed(-1, gridSize, random);
  }

  int _getGridSize(int level) {
    if (level <= 3) return 4;
    if (level <= 15) return 6;
    if (level <= 35) return 8;
    if (level <= 65) return 10;
    return 12;
  }

  GameLevel _generateLevelWithSeed(
    int levelNumber,
    int gridSize,
    Random random,
  ) {
    final sol = _generateValidBoard(gridSize, random);
    final initial = _createPuzzleFromSolution(sol, gridSize, random);

    return GameLevel(
      levelNumber: levelNumber,
      gridSize: gridSize,
      initialGrid: initial,
      solutionGrid: sol,
    );
  }

  List<List<int>> _generateValidBoard(int n, Random random) {
    final grid = List.generate(n, (_) => List<int?>.filled(n, null));
    _solveBoard(grid, n, random);
    return List.generate(n, (r) => List.generate(n, (c) => grid[r][c] ?? 0));
  }

  bool _solveBoard(List<List<int?>> grid, int n, Random random) {
    int targetR = -1;
    int targetC = -1;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (grid[r][c] == null) {
          targetR = r;
          targetC = c;
          break;
        }
      }
      if (targetR != -1) break;
    }

    if (targetR == -1) return _validateFullBoard(grid, n);

    final values = [0, 1]..shuffle(random);
    for (final v in values) {
      grid[targetR][targetC] = v;
      if (_isPartialPlacementValid(grid, n, targetR, targetC)) {
        if (_solveBoard(grid, n, random)) return true;
      }
      grid[targetR][targetC] = null;
    }

    return false;
  }

  bool _isPartialPlacementValid(List<List<int?>> grid, int n, int r, int c) {
    final row = grid[r];
    if (c >= 2 && row[c] == row[c - 1] && row[c] == row[c - 2]) return false;
    if (c >= 1 && c < n - 1 && row[c - 1] != null && row[c + 1] != null && row[c] == row[c - 1] && row[c] == row[c + 1]) return false;
    if (c < n - 2 && row[c + 1] != null && row[c + 2] != null && row[c] == row[c + 1] && row[c] == row[c + 2]) return false;

    if (!CellRules.lineCountsValid(row)) return false;

    final col = [for (int i = 0; i < n; i++) grid[i][c]];
    if (r >= 2 && col[r] == col[r - 1] && col[r] == col[r - 2]) return false;
    if (r >= 1 && r < n - 1 && col[r - 1] != null && col[r + 1] != null && col[r] == col[r - 1] && col[r] == col[r + 1]) return false;
    if (r < n - 2 && col[r + 1] != null && col[r + 2] != null && col[r] == col[r + 1] && col[r] == col[r + 2]) return false;

    if (!CellRules.lineCountsValid(col)) return false;

    return true;
  }

  bool _validateFullBoard(List<List<int?>> grid, int n) {
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        bool sameRow = true;
        for (int k = 0; k < n; k++) {
          if (grid[i][k] != grid[j][k]) {
            sameRow = false;
            break;
          }
        }
        if (sameRow) return false;

        bool sameCol = true;
        for (int k = 0; k < n; k++) {
          if (grid[k][i] != grid[k][j]) {
            sameCol = false;
            break;
          }
        }
        if (sameCol) return false;
      }
    }
    return true;
  }

  List<List<int?>> _createPuzzleFromSolution(
    List<List<int>> solution,
    int n,
    Random random,
  ) {
    final puzzle = List.generate(
      n,
      (r) => List<int?>.generate(n, (c) => solution[r][c]),
    );

    final positions = <Point<int>>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        positions.add(Point(r, c));
      }
    }
    positions.shuffle(random);

    final targetClues = (n * n * 0.42).round().clamp(n, n * n);
    int currentClues = n * n;

    for (final pos in positions) {
      if (currentClues <= targetClues) break;
      puzzle[pos.x][pos.y] = null;
      currentClues--;
    }

    return puzzle;
  }
}
