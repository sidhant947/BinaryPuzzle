import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:binarypuzzle/ui/core/theme/app_colors.dart';
import 'package:binarypuzzle/ui/core/utils/app_haptics.dart';
import 'package:binarypuzzle/ui/core/widgets/tangible_button.dart';
import 'package:binarypuzzle/ui/providers.dart';

class HowToPlayView extends ConsumerWidget {
  const HowToPlayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    AppColors.currentTheme = settings.theme;
    AppHaptics.isEnabled = settings.isHapticsEnabled;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      AppHaptics.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.headingDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'How to Play',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headingDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  _guideStep(
                    stepNumber: '1',
                    title: 'Fill with 0s and 1s',
                    description: 'Every cell in the grid must be filled with either a 0 or a 1.',
                  ),
                  const SizedBox(height: 16),
                  _guideStep(
                    stepNumber: '2',
                    title: 'No Three-in-a-Row',
                    description: 'No more than two identical numbers may be placed consecutively in any row or column (e.g. 000 and 111 are not allowed).',
                  ),
                  const SizedBox(height: 16),
                  _guideStep(
                    stepNumber: '3',
                    title: 'Equal Number of 0s and 1s',
                    description: 'Each row and each column must contain an equal number of 0s and 1s (e.g. three 0s and three 1s in a 6x6 grid).',
                  ),
                  const SizedBox(height: 16),
                  _guideStep(
                    stepNumber: '4',
                    title: 'Unique Rows and Columns',
                    description: 'All completed rows must be unique, and all completed columns must be unique.',
                  ),
                  const SizedBox(height: 16),
                  _guideStep(
                    stepNumber: '5',
                    title: 'Controls',
                    description: '• Tap any empty cell to place 0.\n• Tap again to switch to 1.\n• Tap once more to clear the cell.',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: TangibleButton(
                text: 'Got it',
                height: 44,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideStep({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$stepNumber.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.headingDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.subtext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
