import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/colors.dart';
import '../../../logic/stepper/stepper_cubit.dart';
import '../../../logic/stepper/stepper_state.dart';

class Step7Confirm extends StatelessWidget {
  const Step7Confirm({super.key});

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
                'Confirm',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Review your job configuration before creating.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _SummaryItem(
                icon: Icons.label_outline,
                label: 'Job Name',
                value: state.jobName,
              ),
              _SummaryItem(
                icon: Icons.link,
                label: 'Product URL',
                value: state.productUrl,
              ),
              if (state.productCategory != null)
                _SummaryItem(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: state.productCategory!,
                ),
              _SummaryItem(
                icon: Icons.people_outline,
                label: 'Competitors',
                value: '${state.selectedCompetitors.length} selected',
              ),
              ...state.selectedCompetitors.map((c) => Padding(
                    padding: const EdgeInsets.only(left: 48, bottom: 4),
                    child: Text(
                      '${c.name} - ${c.url}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
              const SizedBox(height: 8),
              _SummaryItem(
                icon: Icons.analytics_outlined,
                label: 'Analysis Areas',
                value: '${state.selectedAreas.length} areas',
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: state.selectedAreas
                      .map((a) => Chip(
                            label: Text(a, style: const TextStyle(fontSize: 11)),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              _SummaryItem(
                icon: Icons.schedule_outlined,
                label: 'Schedule',
                value: state.schedule,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accentPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.accentPrimary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Once created, the first analysis run will start automatically.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.accentPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accentPrimary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
