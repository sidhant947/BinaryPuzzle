import 'package:binarypuzzle/domain/models/game_level.dart';

class CellRules {
  const CellRules._();

  static bool hasThreeConsecutive(List<int?> line) {
    for (int i = 0; i < line.length - 2; i++) {
      final a = line[i];
      final b = line[i + 1];
      final c = line[i + 2];
      if (a != null && a == b && b == c) {
        return true;
      }
    }
    return false;
  }

  static bool hasEqualCounts(List<int?> line) {
    final half = line.length ~/ 2;
    int zeros = 0;
    int ones = 0;
    for (final v in line) {
      if (v == 0) zeros++;
      if (v == 1) ones++;
    }
    return zeros == half && ones == half;
  }

  static bool lineCountsValid(List<int?> line) {
    final half = line.length ~/ 2;
    int zeros = 0;
    int ones = 0;
    for (final v in line) {
      if (v == 0) zeros++;
      if (v == 1) ones++;
    }
    return zeros <= half && ones <= half;
  }


  static bool isComplete(List<List<int?>> grid, GameLevel level) {
    final n = level.gridSize;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (grid[r][c] == null) return false;
      }
    }

    for (int r = 0; r < n; r++) {
      if (hasThreeConsecutive(grid[r])) return false;
      if (!hasEqualCounts(grid[r])) return false;
    }

    for (int c = 0; c < n; c++) {
      final col = [for (int r = 0; r < n; r++) grid[r][c]];
      if (hasThreeConsecutive(col)) return false;
      if (!hasEqualCounts(col)) return false;
    }

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

  static Map<String, dynamic>? suggestHint(
    List<List<int?>> grid,
    GameLevel level,
  ) {
    final n = level.gridSize;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (grid[r][c] == null || grid[r][c] != level.solutionGrid[r][c]) {
          return {
            'row': r,
            'col': c,
            'value': level.solutionGrid[r][c],
          };
        }
      }
    }
    return null;
  }
}
