import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/colors.dart';
import '../../../logic/stepper/stepper_cubit.dart';
import '../../../logic/stepper/stepper_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/rivly_button.dart';

class Step4Access extends StatefulWidget {
  const Step4Access({super.key});

  @override
  State<Step4Access> createState() => _Step4AccessState();
}

class _Step4AccessState extends State<Step4Access> {
  @override
  void initState() {
    super.initState();
    final state = context.read<StepperCubit>().state;
    if (state.accessResults.isEmpty) {
      context.read<StepperCubit>().checkAccess();
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
                'Access Check',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Verifying we can access each competitor\'s site for analysis.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (state.isLoading && state.accessResults.isEmpty)
                LoadingShimmer.list(count: state.selectedCompetitors.length)
              else ...[
                ...state.selectedCompetitors.map((competitor) {
                  final isAccessible =
                      state.accessResults[competitor.id] ?? false;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isAccessible
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        color: isAccessible
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      title: Text(competitor.name),
                      subtitle: Text(
                        competitor.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Text(
                        isAccessible ? 'Accessible' : 'Limited',
                        style: TextStyle(
                          color: isAccessible
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                RivlyButton(
                  label: 'Re-check',
                  onPressed: () =>
                      context.read<StepperCubit>().checkAccess(),
                  variant: RivlyButtonVariant.ghost,
                  icon: Icons.refresh,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
