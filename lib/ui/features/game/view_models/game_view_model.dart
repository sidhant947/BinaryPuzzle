import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:binarypuzzle/data/repositories/progress_repository.dart';
import 'package:binarypuzzle/domain/models/game_level.dart';
import 'package:binarypuzzle/domain/use_cases/cell_rules.dart';
import 'package:binarypuzzle/domain/use_cases/level_generator.dart';
import 'package:binarypuzzle/ui/core/utils/app_haptics.dart';

@immutable
class _Snapshot {
  const _Snapshot(this.grid, this.moveCount);
  final List<List<int?>> grid;
  final int moveCount;
}

@immutable
class GameViewModelState {
  const GameViewModelState({
    this.level,
    this.grid = const [],
    this.isLoading = false,
    this.isComplete = false,
    this.moveCount = 0,
    this.elapsedSeconds = 0,
    this.canUndo = false,
    this.hintCell,
    this.hintsRemaining = 2,
    this.error,
    this.isRandomMode = false,
    this.randomDifficulty,
    this.randomSeed,
    this.randomGridSize,
  });

  final GameLevel? level;
  final List<List<int?>> grid;
  final bool isLoading;
  final bool isComplete;
  final int moveCount;
  final int elapsedSeconds;
  final bool canUndo;
  final Map<String, int>? hintCell;
  final int hintsRemaining;
  final String? error;
  final bool isRandomMode;
  final String? randomDifficulty;
  final int? randomSeed;
  final int? randomGridSize;

  GameViewModelState copyWith({
    GameLevel? level,
    List<List<int?>>? grid,
    bool? isLoading,
    bool? isComplete,
    int? moveCount,
    int? elapsedSeconds,
    bool? canUndo,
    Map<String, int>? hintCell,
    bool clearHint = false,
    int? hintsRemaining,
    String? error,
    bool? isRandomMode,
    String? randomDifficulty,
    int? randomSeed,
    int? randomGridSize,
  }) {
    return GameViewModelState(
      level: level ?? this.level,
      grid: grid ?? this.grid,
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
      moveCount: moveCount ?? this.moveCount,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      canUndo: canUndo ?? this.canUndo,
      hintCell: clearHint ? null : (hintCell ?? this.hintCell),
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      error: error,
      isRandomMode: isRandomMode ?? this.isRandomMode,
      randomDifficulty: randomDifficulty ?? this.randomDifficulty,
      randomSeed: randomSeed ?? this.randomSeed,
      randomGridSize: randomGridSize ?? this.randomGridSize,
    );
  }
}

class GameViewModel extends StateNotifier<GameViewModelState> {
  GameViewModel({
    required this.progressRepository,
    required this.levelGenerator,
  }) : super(const GameViewModelState());

  final ProgressRepository progressRepository;
  final LevelGenerator levelGenerator;

  static const int _maxUndo = 50;
  final List<_Snapshot> _undoStack = [];
  Timer? _timer;
  Timer? _hintTimer;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _stopTimer();
        return;
      }
      if (state.isComplete) {
        _timer?.cancel();
        return;
      }
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> loadLevel(int levelNumber) async {
    _undoStack.clear();
    state = const GameViewModelState(isLoading: true);

    try {
      final level = await levelGenerator.generateAsync(levelNumber);
      if (!mounted) return;

      final progress = await progressRepository.getProgress();
      if (!mounted) return;

      List<List<int?>> grid = List.generate(
        level.gridSize,
        (r) => List<int?>.generate(level.gridSize, (c) => level.initialGrid[r][c]),
      );
      int moveCount = 0;
      int elapsed = 0;

      if (progress.savedLevelNumber == levelNumber && progress.savedGrid != null) {
        final saved = progress.savedGrid!;
        if (saved.length == level.gridSize && saved.first.length == level.gridSize) {
          grid = List.generate(
            level.gridSize,
            (r) => List<int?>.generate(
              level.gridSize,
              (c) => saved[r][c] == -1 ? null : saved[r][c],
            ),
          );
          moveCount = progress.savedMoveCount;
          elapsed = progress.savedElapsedSeconds;
        }
      }

      final isComplete = CellRules.isComplete(grid, level);

      state = GameViewModelState(
        level: level,
        grid: grid,
        moveCount: moveCount,
        elapsedSeconds: elapsed,
        isComplete: isComplete,
        hintsRemaining: 2,
      );

      if (!isComplete) _startTimer();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load level: $e',
      );
    }
  }

  int _parseGridSize(String difficulty) {
    switch (difficulty.toLowerCase().trim()) {
      case 'easy':
        return 6;
      case 'medium':
        return 8;
      case 'hard':
        return 10;
      case 'expert':
        return 12;
      default:
        final parts = difficulty.toLowerCase().split('x');
        final size = int.tryParse(parts[0].trim());
        return (size != null && size >= 4 && size <= 12) ? size : 6;
    }
  }

  Future<void> loadRandomLevel(String difficulty, {int? seed}) async {
    _undoStack.clear();
    final levelSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    final gridSize = _parseGridSize(difficulty);

    state = GameViewModelState(
      isLoading: true,
      isRandomMode: true,
      randomDifficulty: difficulty,
      randomSeed: levelSeed,
      randomGridSize: gridSize,
      hintsRemaining: 2,
    );

    try {
      final level = await levelGenerator.generateRandomAsync(
        gridSize: gridSize,
        seed: levelSeed,
      );
      if (!mounted) return;

      final grid = List.generate(
        level.gridSize,
        (r) => List<int?>.generate(level.gridSize, (c) => level.initialGrid[r][c]),
      );

      state = state.copyWith(
        level: level,
        grid: grid,
        moveCount: 0,
        elapsedSeconds: 0,
        canUndo: false,
        isLoading: false,
        randomGridSize: gridSize,
        hintsRemaining: 2,
      );
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load random level: $e',
      );
    }
  }

  void onCellTapped(int r, int c) {
    final level = state.level;
    if (state.isComplete || level == null) return;
    if (r < 0 || r >= level.gridSize || c < 0 || c >= level.gridSize) return;

    if (level.initialGrid[r][c] != null) {
      AppHaptics.selectionClick();
      return;
    }

    _pushUndo();

    final currentVal = state.grid[r][c];
    final int? nextVal;
    if (currentVal == null) {
      nextVal = 0;
    } else if (currentVal == 0) {
      nextVal = 1;
    } else {
      nextVal = null;
    }

    final newGrid = List.generate(
      level.gridSize,
      (row) => List<int?>.from(state.grid[row]),
    );
    newGrid[r][c] = nextVal;

    final isComplete = CellRules.isComplete(newGrid, level);

    if (isComplete) {
      AppHaptics.heavyImpact();
      AppHaptics.vibrate();
      _stopTimer();
    } else if (nextVal == 0) {
      AppHaptics.lightImpact();
    } else if (nextVal == 1) {
      AppHaptics.mediumImpact();
    } else {
      AppHaptics.selectionClick();
    }

    state = state.copyWith(
      grid: newGrid,
      moveCount: state.moveCount + 1,
      isComplete: isComplete,
      canUndo: _undoStack.isNotEmpty,
      clearHint: true,
    );

    _persistInProgress();
  }

  void _pushUndo() {
    final copy = List.generate(
      state.grid.length,
      (r) => List<int?>.from(state.grid[r]),
    );
    _undoStack.add(_Snapshot(copy, state.moveCount));
    if (_undoStack.length > _maxUndo) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (_undoStack.isEmpty || state.level == null || state.isComplete) return;
    final snapshot = _undoStack.removeLast();
    AppHaptics.lightImpact();

    state = state.copyWith(
      grid: snapshot.grid,
      moveCount: snapshot.moveCount,
      canUndo: _undoStack.isNotEmpty,
      clearHint: true,
    );
    _persistInProgress();
  }

  void revealHint() {
    final level = state.level;
    if (level == null || state.isComplete || state.hintsRemaining <= 0) return;

    final hint = CellRules.suggestHint(state.grid, level);
    if (hint == null) return;

    final r = hint['row'] as int;
    final c = hint['col'] as int;
    final val = hint['value'] as int;

    _pushUndo();

    final newGrid = List.generate(
      level.gridSize,
      (row) => List<int?>.from(state.grid[row]),
    );
    newGrid[r][c] = val;

    final isComplete = CellRules.isComplete(newGrid, level);

    if (isComplete) {
      AppHaptics.heavyImpact();
      AppHaptics.vibrate();
      _stopTimer();
    } else {
      AppHaptics.mediumImpact();
    }

    state = state.copyWith(
      grid: newGrid,
      moveCount: state.moveCount + 1,
      isComplete: isComplete,
      canUndo: _undoStack.isNotEmpty,
      hintsRemaining: state.hintsRemaining - 1,
      hintCell: {'row': r, 'col': c},
    );

    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) state = state.copyWith(clearHint: true);
    });

    _persistInProgress();
  }

  void _persistInProgress() {
    final level = state.level;
    if (level == null || state.isRandomMode || state.isComplete) return;
    progressRepository.saveInProgress(
      level.levelNumber,
      state.grid,
      state.moveCount,
      state.elapsedSeconds,
    );
  }

  Future<void> completeLevel() async {
    final level = state.level;
    if (level == null || !state.isComplete) return;
    if (state.isRandomMode) {
      await progressRepository.addRandomLevelMoves(state.moveCount);
    } else {
      await progressRepository.completeLevel(level.levelNumber, state.moveCount);
      if (!mounted) return;
      await progressRepository.recordLevelResult(
        level.levelNumber,
        state.moveCount,
        state.elapsedSeconds,
      );
      if (!mounted) return;
      await progressRepository.clearInProgress();
    }
  }

  Future<void> resetLevel() async {
    final level = state.level;
    if (level == null) return;
    if (state.isRandomMode) {
      await loadRandomLevel(state.randomDifficulty ?? '6x6', seed: state.randomSeed);
    } else {
      await progressRepository.clearInProgress();
      if (!mounted) return;
      await loadLevel(level.levelNumber);
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _hintTimer?.cancel();
    super.dispose();
  }
}
