import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:binarypuzzle/data/repositories/progress_repository.dart';
import 'package:binarypuzzle/data/services/hive_service.dart';
import 'package:binarypuzzle/data/services/settings_service.dart';
import 'package:binarypuzzle/domain/models/app_settings.dart';
import 'package:binarypuzzle/domain/use_cases/level_generator.dart';
import 'package:binarypuzzle/ui/features/game/view_models/game_view_model.dart';
import 'package:binarypuzzle/ui/features/home/view_models/home_view_model.dart';
import 'package:binarypuzzle/ui/features/settings/view_models/settings_view_model.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final progressRepositoryProvider = ChangeNotifierProvider<ProgressRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ProgressRepository(hiveService: hiveService);
});

final levelGeneratorProvider = Provider<LevelGenerator>((ref) {
  return LevelGenerator();
});

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeViewModelState>((ref) {
      final progressRepository = ref.read(progressRepositoryProvider);
      final levelGenerator = ref.read(levelGeneratorProvider);
      return HomeViewModel(
        progressRepository: progressRepository,
        levelGenerator: levelGenerator,
      );
    });

final gameViewModelProvider =
    StateNotifierProvider.autoDispose<GameViewModel, GameViewModelState>((ref) {
      final progressRepository = ref.read(progressRepositoryProvider);
      final levelGenerator = ref.read(levelGeneratorProvider);
      return GameViewModel(
        progressRepository: progressRepository,
        levelGenerator: levelGenerator,
      );
    });

final settingsProvider =
    StateNotifierProvider<SettingsViewModel, AppSettings>((ref) {
      final settingsService = ref.watch(settingsServiceProvider);
      return SettingsViewModel(settingsService: settingsService);
    });
