import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/stepper/stepper_cubit.dart';
import '../../../logic/stepper/stepper_state.dart';

class Step6Name extends StatefulWidget {
  const Step6Name({super.key});

  @override
  State<Step6Name> createState() => _Step6NameState();
}

class _Step6NameState extends State<Step6Name> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<StepperCubit>().state;
    _nameController.text = state.jobName;
    if (_nameController.text.isEmpty && state.productName != null) {
      final suggestedName = '${state.productName} Analysis';
      _nameController.text = suggestedName;
      context.read<StepperCubit>().setJobName(suggestedName);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
                'Job Name',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Give this analysis job a memorable name.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Job Name',
                  hintText: 'e.g., Q1 Competitor Analysis',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                onChanged: (value) {
                  context.read<StepperCubit>().setJobName(value);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
