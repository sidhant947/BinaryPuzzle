import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:binarypuzzle/domain/models/game_level.dart';

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

  static final Map<int, List<int>> _validRowsCache = {};

  static List<int> _getValidRows(int n) {
    if (_validRowsCache.containsKey(n)) {
      return _validRowsCache[n]!;
    }
    final half = n ~/ 2;
    final valid = <int>[];
    final limit = 1 << n;
    for (int i = 0; i < limit; i++) {
      int ones = 0;
      for (int b = 0; b < n; b++) {
        if ((i & (1 << b)) != 0) ones++;
      }
      if (ones != half) continue;

      bool ok = true;
      for (int b = 0; b < n - 2; b++) {
        final b1 = (i >> b) & 1;
        final b2 = (i >> (b + 1)) & 1;
        final b3 = (i >> (b + 2)) & 1;
        if (b1 == b2 && b2 == b3) {
          ok = false;
          break;
        }
      }
      if (ok) valid.add(i);
    }
    _validRowsCache[n] = valid;
    return valid;
  }

  List<List<int>> _generateValidBoard(int n, Random random) {
    final validRows = _getValidRows(n);
    final mask = (1 << n) - 1;
    final half = n ~/ 2;

    for (int attempt = 0; attempt < 50; attempt++) {
      final board = List<int>.filled(n, 0);
      final colOnes = List<int>.filled(n, 0);
      int steps = 0;

      bool solve(int rowIndex) {
        steps++;
        if (steps > 5000) return false;
        if (rowIndex == n) {
          for (int c1 = 0; c1 < n; c1++) {
            for (int c2 = c1 + 1; c2 < n; c2++) {
              bool same = true;
              for (int r = 0; r < n; r++) {
                if (((board[r] >> c1) & 1) != ((board[r] >> c2) & 1)) {
                  same = false;
                  break;
                }
              }
              if (same) return false;
            }
          }
          return true;
        }

        final shuffled = List<int>.from(validRows)..shuffle(random);
        final remainingRows = n - rowIndex - 1;

        rowLoop:
        for (final row in shuffled) {
          for (int prevR = 0; prevR < rowIndex; prevR++) {
            if (board[prevR] == row) continue rowLoop;
          }

          if (rowIndex >= 2) {
            final r1 = board[rowIndex - 1];
            final r2 = board[rowIndex - 2];
            if ((((row & r1 & r2) | ((~row & ~r1 & ~r2) & mask))) != 0) {
              continue rowLoop;
            }
          }

          for (int c = 0; c < n; c++) {
            final bit = (row >> c) & 1;
            final newOnes = colOnes[c] + bit;
            if (newOnes > half) continue rowLoop;
            final newZeros = rowIndex + 1 - newOnes;
            if (newZeros > half) continue rowLoop;
            if (newOnes + remainingRows < half) continue rowLoop;
            if (newZeros + remainingRows < half) continue rowLoop;
          }

          board[rowIndex] = row;
          for (int c = 0; c < n; c++) {
            colOnes[c] += (row >> c) & 1;
          }

          if (solve(rowIndex + 1)) return true;

          for (int c = 0; c < n; c++) {
            colOnes[c] -= (row >> c) & 1;
          }
        }

        return false;
      }

      if (solve(0)) {
        return List.generate(
          n,
          (r) => List<int>.generate(n, (c) => (board[r] >> c) & 1),
        );
      }
    }

    return List.generate(n, (_) => List<int>.filled(n, 0));
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
