import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/colors.dart';
import '../../../logic/stepper/stepper_cubit.dart';
import '../../../logic/stepper/stepper_state.dart';

class Step5Schedule extends StatelessWidget {
  const Step5Schedule({super.key});

  static const _scheduleOptions = [
    {'value': 'manual', 'label': 'Manual', 'description': 'Run on demand'},
    {
      'value': 'daily',
      'label': 'Daily',
      'description': 'Run once every day'
    },
    {
      'value': 'weekly',
      'label': 'Weekly',
      'description': 'Run once every week'
    },
    {
      'value': 'monthly',
      'label': 'Monthly',
      'description': 'Run once every month'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StepperCubit, StepperState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'How often should this competitive analysis run?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ..._scheduleOptions.map((option) {
                final isSelected = state.schedule == option['value'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.accentPrimary
                          : Theme.of(context).dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    onTap: () {
                      context
                          .read<StepperCubit>()
                          .setSchedule(option['value']!);
                    },
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? AppColors.accentPrimary
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    title: Text(option['label']!),
                    subtitle: Text(
                      option['description']!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
