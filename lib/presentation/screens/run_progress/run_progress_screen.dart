import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../logic/run_progress/run_progress_cubit.dart';
import '../../../logic/run_progress/run_progress_state.dart';
import '../../widgets/common/rivly_button.dart';
import '../../widgets/charts/score_gauge.dart';

class RunProgressScreen extends StatelessWidget {
  final String runId;

  const RunProgressScreen({super.key, required this.runId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RunProgressCubit()..startTracking(runId),
      child: const _RunProgressBody(),
    );
  }
}

class _RunProgressBody extends StatelessWidget {
  const _RunProgressBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Run Progress'),
        actions: [
          BlocBuilder<RunProgressCubit, RunProgressState>(
            builder: (context, state) {
              if (!state.isCompleted && !state.isFailed) {
                return IconButton(
                  icon: const Icon(Icons.stop_circle_outlined),
                  onPressed: () =>
                      context.read<RunProgressCubit>().cancelRun(),
                  tooltip: 'Cancel run',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<RunProgressCubit, RunProgressState>(
        builder: (context, state) {
          if (state.isLoading && state.run == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && state.run == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.error!),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress ring
                ScoreGauge(
                  score: (state.progress * 100).round(),
                  size: 160,
                  strokeWidth: 12,
                  color: state.isFailed
                      ? AppColors.error
                      : state.isCompleted
                          ? AppColors.success
                          : AppColors.accentPrimary,
                  label: state.isCompleted
                      ? 'Complete'
                      : state.isFailed
                          ? 'Failed'
                          : 'Running',
                ),
                const SizedBox(height: 24),

                // Status info
                if (state.currentStep != null) ...[
                  Text(
                    state.currentStep!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                ],
                if (state.currentCompetitor != null)
                  Text(
                    'Analyzing: ${state.currentCompetitor}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.accentSecondary,
                        ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${state.competitorsCompleted} / ${state.competitorsTotal} competitors',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 24),

                // Competitor status cards
                if (state.run != null && state.competitorsTotal > 0)
                  LinearProgressIndicator(
                    value: state.competitorsTotal > 0
                        ? state.competitorsCompleted /
                            state.competitorsTotal
                        : 0,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.isCompleted
                          ? AppColors.success
                          : AppColors.accentPrimary,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),

                const SizedBox(height: 24),

                // Live log
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBgSecondary
                        : AppColors.lightBgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: state.logs.isEmpty
                      ? Center(
                          child: Text(
                            'Waiting for logs...',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      : ListView.builder(
                          itemCount: state.logs.length,
                          reverse: true,
                          itemBuilder: (context, index) {
                            final logIndex =
                                state.logs.length - 1 - index;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                state.logs[logIndex],
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 24),

                // Actions
                if (state.isCompleted)
                  RivlyButton(
                    label: 'View Report',
                    onPressed: () {
                      final runId = state.run?.id;
                      if (runId != null) {
                        context.go('/reports/$runId');
                      }
                    },
                    width: double.infinity,
                    icon: Icons.assessment,
                  ),
                if (state.isFailed)
                  RivlyButton(
                    label: 'Back to Dashboard',
                    onPressed: () => context.go('/dashboard'),
                    variant: RivlyButtonVariant.outline,
                    width: double.infinity,
                  ),

                // Connection status
                if (!state.isCompleted && !state.isFailed) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isConnected
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.isConnected
                            ? 'Live connection'
                            : 'Reconnecting...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
