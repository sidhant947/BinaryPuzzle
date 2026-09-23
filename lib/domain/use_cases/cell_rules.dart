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
    final solution = _findSolution(grid, n) ?? level.solutionGrid;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (grid[r][c] == null || grid[r][c] != solution[r][c]) {
          return {
            'row': r,
            'col': c,
            'value': solution[r][c],
          };
        }
      }
    }
    return null;
  }

  static List<List<int>>? _findSolution(List<List<int?>> grid, int n) {
    final copy = List.generate(n, (r) => List<int?>.from(grid[r]));
    if (_solve(copy, n)) {
      return List.generate(n, (r) => List<int>.generate(n, (c) => copy[r][c]!));
    }
    return null;
  }

  static bool _solve(List<List<int?>> grid, int n) {
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

    if (targetR == -1) return _validateFull(grid, n);

    for (final v in [0, 1]) {
      grid[targetR][targetC] = v;
      if (_isValidPartial(grid, n, targetR, targetC)) {
        if (_solve(grid, n)) return true;
      }
      grid[targetR][targetC] = null;
    }
    return false;
  }

  static bool _isValidPartial(List<List<int?>> grid, int n, int r, int c) {
    final row = grid[r];
    if (c >= 2 && row[c] == row[c - 1] && row[c] == row[c - 2]) return false;
    if (c >= 1 && c < n - 1 && row[c - 1] != null && row[c + 1] != null && row[c] == row[c - 1] && row[c] == row[c + 1]) return false;
    if (c < n - 2 && row[c + 1] != null && row[c + 2] != null && row[c] == row[c + 1] && row[c] == row[c + 2]) return false;
    if (!lineCountsValid(row)) return false;

    final col = [for (int i = 0; i < n; i++) grid[i][c]];
    if (r >= 2 && col[r] == col[r - 1] && col[r] == col[r - 2]) return false;
    if (r >= 1 && r < n - 1 && col[r - 1] != null && col[r + 1] != null && col[r] == col[r - 1] && col[r] == col[r + 1]) return false;
    if (r < n - 2 && col[r + 1] != null && col[r + 2] != null && col[r] == col[r + 1] && col[r] == col[r + 2]) return false;
    if (!lineCountsValid(col)) return false;

    return true;
  }

  static bool _validateFull(List<List<int?>> grid, int n) {
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        bool sameRow = true;
        bool sameCol = true;
        for (int k = 0; k < n; k++) {
          if (grid[i][k] != grid[j][k]) sameRow = false;
          if (grid[k][i] != grid[k][j]) sameCol = false;
        }
        if (sameRow || sameCol) return false;
      }
    }
    return true;
  }
}
