import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/competitor_model.dart';
import '../../../logic/stepper/stepper_cubit.dart';
import '../../../logic/stepper/stepper_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/rivly_button.dart';

class Step2Competitors extends StatefulWidget {
  const Step2Competitors({super.key});

  @override
  State<Step2Competitors> createState() => _Step2CompetitorsState();
}

class _Step2CompetitorsState extends State<Step2Competitors> {
  @override
  void initState() {
    super.initState();
    final state = context.read<StepperCubit>().state;
    if (state.discoveredCompetitors.isEmpty) {
      context.read<StepperCubit>().discoverCompetitors();
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
                'Competitors',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'We discovered these competitors. Select the ones you want to track.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (state.isLoading && state.discoveredCompetitors.isEmpty)
                LoadingShimmer.list(count: 4)
              else ...[
                ...state.discoveredCompetitors.map((competitor) {
                  final isSelected = state.selectedCompetitors
                      .any((c) => c.id == competitor.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => context
                          .read<StepperCubit>()
                          .toggleCompetitor(competitor),
                      title: Text(competitor.name),
                      subtitle: Text(
                        competitor.url,
                        style: TextStyle(
                          color: AppColors.accentSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondary: null,
                      activeColor: AppColors.accentPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                RivlyButton(
                  label: 'Add Manually',
                  onPressed: () => _showAddCompetitorDialog(context),
                  variant: RivlyButtonVariant.outline,
                  icon: Icons.add,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '${state.selectedCompetitors.length} selected',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCompetitorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Competitor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Competitor name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://competitor.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                final competitor = CompetitorModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  url: urlController.text,
                  accessStatus: 'public',
                );
                context.read<StepperCubit>().addManualCompetitor(competitor);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
