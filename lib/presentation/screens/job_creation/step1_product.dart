import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/validators.dart';
import '../../../logic/stepper/stepper_cubit.dart';
import '../../../logic/stepper/stepper_state.dart';
import '../../widgets/common/rivly_button.dart';

class Step1Product extends StatefulWidget {
  const Step1Product({super.key});

  @override
  State<Step1Product> createState() => _Step1ProductState();
}

class _Step1ProductState extends State<Step1Product> {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<StepperCubit>().state;
    _urlController.text = state.productUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
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
                'Your Product',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your product URL and we will analyze it to understand what you offer.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Product URL',
                  hintText: 'https://yourproduct.com',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                onChanged: (value) {
                  context.read<StepperCubit>().setProductUrl(value);
                },
              ),
              const SizedBox(height: 16),
              RivlyButton(
                label: 'Analyze Product',
                onPressed: Validators.url(_urlController.text) == null
                    ? () =>
                        context.read<StepperCubit>().analyzeProduct()
                    : null,
                isLoading: state.isLoading,
                icon: Icons.auto_awesome,
                width: double.infinity,
              ),
              if (state.productAnalyzed) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Product Analyzed',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                      if (state.productName != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.productName!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                      if (state.productDescription != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          state.productDescription!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (state.productCategory != null) ...[
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(state.productCategory!),
                          backgroundColor:
                              AppColors.accentSecondary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: AppColors.accentSecondaryLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
