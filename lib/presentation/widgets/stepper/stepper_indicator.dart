import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class StepperIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const StepperIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels = const [
      'Product',
      'Competitors',
      'Areas',
      'Access',
      'Schedule',
      'Name',
      'Confirm',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isOdd) {
                final stepBefore = index ~/ 2;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: stepBefore < currentStep
                        ? AppColors.accentPrimary
                        : Theme.of(context).dividerColor,
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isActive = stepIndex == currentStep;
              final isCompleted = stepIndex < currentStep;

              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive || isCompleted
                      ? AppColors.accentPrimary
                      : Colors.transparent,
                  border: Border.all(
                    color: isActive || isCompleted
                        ? AppColors.accentPrimary
                        : Theme.of(context).dividerColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                          ),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          if (currentStep < stepLabels.length)
            Text(
              stepLabels[currentStep],
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.accentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
        ],
      ),
    );
  }
}
