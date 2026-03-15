import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../logic/stepper/stepper_cubit.dart';
import '../../../logic/stepper/stepper_state.dart';
import '../../widgets/common/rivly_button.dart';
import '../../widgets/stepper/stepper_indicator.dart';
import 'step1_product.dart';
import 'step2_competitors.dart';
import 'step3_areas.dart';
import 'step4_access.dart';
import 'step5_schedule.dart';
import 'step6_name.dart';
import 'step7_confirm.dart';

class StepperScreen extends StatelessWidget {
  const StepperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StepperCubit(),
      child: const _StepperScreenBody(),
    );
  }
}

class _StepperScreenBody extends StatelessWidget {
  const _StepperScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('New Job'),
      ),
      body: BlocConsumer<StepperCubit, StepperState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              StepperIndicator(
                currentStep: state.currentStep,
                totalSteps: state.totalSteps,
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildStepContent(state.currentStep),
              ),
              _buildNavigationBar(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return const Step1Product();
      case 1:
        return const Step2Competitors();
      case 2:
        return const Step3Areas();
      case 3:
        return const Step4Access();
      case 4:
        return const Step5Schedule();
      case 5:
        return const Step6Name();
      case 6:
        return const Step7Confirm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationBar(BuildContext context, StepperState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (state.currentStep > 0)
              RivlyButton(
                label: 'Back',
                onPressed: () =>
                    context.read<StepperCubit>().previousStep(),
                variant: RivlyButtonVariant.outline,
              ),
            const Spacer(),
            if (state.currentStep < state.totalSteps - 1)
              RivlyButton(
                label: 'Continue',
                onPressed: state.canProceed
                    ? () => context.read<StepperCubit>().nextStep()
                    : null,
                isLoading: state.isLoading,
              )
            else
              RivlyButton(
                label: 'Create Job',
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final jobId =
                            await context.read<StepperCubit>().createJob();
                        if (jobId != null && context.mounted) {
                          context.go('/dashboard');
                        }
                      },
                isLoading: state.isLoading,
              ),
          ],
        ),
      ),
    );
  }
}
