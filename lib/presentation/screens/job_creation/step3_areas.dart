import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/colors.dart';
import '../../../logic/stepper/stepper_cubit.dart';
import '../../../logic/stepper/stepper_state.dart';
import '../../widgets/common/loading_shimmer.dart';

class Step3Areas extends StatefulWidget {
  const Step3Areas({super.key});

  @override
  State<Step3Areas> createState() => _Step3AreasState();
}

class _Step3AreasState extends State<Step3Areas> {
  @override
  void initState() {
    super.initState();
    final state = context.read<StepperCubit>().state;
    if (state.suggestedAreas.isEmpty) {
      context.read<StepperCubit>().fetchSuggestedAreas();
    }
  }

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
                'Analysis Areas',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose which areas to analyze across your competitors.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (state.isLoading && state.suggestedAreas.isEmpty)
                LoadingShimmer.list(count: 6, itemHeight: 48)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.suggestedAreas.map((area) {
                    final isSelected = state.selectedAreas.contains(area);
                    return FilterChip(
                      selected: isSelected,
                      onSelected: (_) =>
                          context.read<StepperCubit>().toggleArea(area),
                      label: Text(area),
                      selectedColor:
                          AppColors.accentPrimary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.accentPrimary,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.accentPrimary
                            : Theme.of(context).dividerColor,
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              Text(
                '${state.selectedAreas.length} areas selected',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
