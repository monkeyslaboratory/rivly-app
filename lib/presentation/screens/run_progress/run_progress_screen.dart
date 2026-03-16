import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
      child: _RunProgressBody(runId: runId),
    );
  }
}

class _RunProgressBody extends StatelessWidget {
  final String runId;
  const _RunProgressBody({required this.runId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              if (state.isRunning) {
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
                  const SizedBox(height: 24),
                  RivlyButton(
                    label: 'Back to Dashboard',
                    onPressed: () => context.go('/dashboard'),
                    variant: RivlyButtonVariant.outline,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // -- Circular progress ring --
                _buildProgressRing(context, state),
                const SizedBox(height: 24),

                // -- Phase label & ETA --
                Text(
                  state.phaseLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (state.isRunning)
                  Text(
                    state.etaLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                  ),

                const SizedBox(height: 32),

                // -- Phase timeline --
                _buildPhaseTimeline(context, state, isDark),

                const SizedBox(height: 28),

                // -- Linear progress bar --
                _buildLinearProgress(context, state, isDark),

                const SizedBox(height: 28),

                // -- Error card --
                if (state.isFailed && state.run != null) ...[
                  _buildErrorCard(context, state, isDark),
                  const SizedBox(height: 20),
                ],

                // -- Duration badge (when completed) --
                if (state.isCompleted && state.run?.durationSeconds != null) ...[
                  _buildDurationBadge(context, state, isDark),
                  const SizedBox(height: 20),
                ],

                // -- Actions --
                if (state.isCompleted)
                  RivlyButton(
                    label: 'View Report',
                    onPressed: () {
                      context.go('/reports/${state.run!.id}');
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
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Progress ring
  // ---------------------------------------------------------------------------
  Widget _buildProgressRing(BuildContext context, RunProgressState state) {
    final Color ringColor;
    final String ringLabel;

    if (state.isFailed) {
      ringColor = AppColors.error;
      ringLabel = 'Failed';
    } else if (state.isCompleted) {
      ringColor = AppColors.success;
      ringLabel = 'Complete';
    } else {
      ringColor = AppColors.accentPrimary;
      ringLabel = 'Running';
    }

    return ScoreGauge(
      score: state.progress,
      size: 160,
      strokeWidth: 12,
      color: ringColor,
      label: ringLabel,
    );
  }

  // ---------------------------------------------------------------------------
  // Phase timeline
  // ---------------------------------------------------------------------------
  static const _phases = [
    _PhaseInfo('preflight', 'Preflight', 'Checking accessibility'),
    _PhaseInfo('screenshots', 'Screenshots', 'Capturing pages'),
    _PhaseInfo('analyzing', 'AI Analysis', 'Claude analyzing'),
    _PhaseInfo('scoring', 'Scoring', 'Calculating UX scores'),
  ];

  Widget _buildPhaseTimeline(
      BuildContext context, RunProgressState state, bool isDark) {
    final currentPhase = state.run?.currentPhase ?? '';
    final phaseOrder = _phases.map((p) => p.key).toList();
    final currentIdx = phaseOrder.indexOf(currentPhase);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: List.generate(_phases.length, (i) {
          final phase = _phases[i];
          final _PhaseStatus phaseStatus;

          if (state.isCompleted) {
            phaseStatus = _PhaseStatus.done;
          } else if (state.isFailed) {
            if (currentIdx >= 0 && i < currentIdx) {
              phaseStatus = _PhaseStatus.done;
            } else if (i == currentIdx) {
              phaseStatus = _PhaseStatus.failed;
            } else {
              phaseStatus = _PhaseStatus.pending;
            }
          } else if (currentIdx < 0) {
            phaseStatus = _PhaseStatus.pending;
          } else if (i < currentIdx) {
            phaseStatus = _PhaseStatus.done;
          } else if (i == currentIdx) {
            phaseStatus = _PhaseStatus.active;
          } else {
            phaseStatus = _PhaseStatus.pending;
          }

          return _buildPhaseRow(context, phase, phaseStatus, isDark,
              isLast: i == _phases.length - 1);
        }),
      ),
    );
  }

  Widget _buildPhaseRow(BuildContext context, _PhaseInfo phase,
      _PhaseStatus status, bool isDark,
      {bool isLast = false}) {
    final IconData icon;
    final Color iconColor;
    final FontWeight fontWeight;
    final Color textColor;
    final String trailing;

    switch (status) {
      case _PhaseStatus.done:
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        fontWeight = FontWeight.w500;
        textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        trailing = 'done';
      case _PhaseStatus.active:
        icon = Icons.radio_button_checked;
        iconColor = AppColors.accentSecondary;
        fontWeight = FontWeight.w600;
        textColor = AppColors.accentSecondary;
        trailing = 'running';
      case _PhaseStatus.failed:
        icon = Icons.error;
        iconColor = AppColors.error;
        fontWeight = FontWeight.w600;
        textColor = AppColors.error;
        trailing = 'failed';
      case _PhaseStatus.pending:
        icon = Icons.radio_button_unchecked;
        iconColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
        fontWeight = FontWeight.w400;
        textColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
        trailing = '';
    }

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                phase.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
            ),
            if (trailing.isNotEmpty)
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 12,
                  color: status == _PhaseStatus.active
                      ? AppColors.accentSecondary
                      : status == _PhaseStatus.failed
                          ? AppColors.error
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                  fontWeight: status == _PhaseStatus.active
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
          ],
        ),
        if (!isLast) ...[
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 20,
                color: status == _PhaseStatus.done
                    ? AppColors.success.withValues(alpha: 0.5)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Linear progress bar
  // ---------------------------------------------------------------------------
  Widget _buildLinearProgress(
      BuildContext context, RunProgressState state, bool isDark) {
    final progressColor = state.isFailed
        ? AppColors.error
        : state.isCompleted
            ? AppColors.success
            : AppColors.accentPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
              ),
              Text(
                '${state.progress}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: progressColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress / 100.0,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error card
  // ---------------------------------------------------------------------------
  Widget _buildErrorCard(
      BuildContext context, RunProgressState state, bool isDark) {
    final errorText = state.run?.errorLog.isNotEmpty == true
        ? state.run!.errorLog
        : 'An unknown error occurred.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Run Failed',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorText,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Duration badge
  // ---------------------------------------------------------------------------
  Widget _buildDurationBadge(
      BuildContext context, RunProgressState state, bool isDark) {
    final secs = state.run!.durationSeconds!;
    final label = secs < 60
        ? '${secs}s'
        : '${(secs / 60).floor()}m ${secs % 60}s';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: AppColors.success),
          const SizedBox(width: 6),
          Text(
            'Completed in $label',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper types
// ---------------------------------------------------------------------------
class _PhaseInfo {
  final String key;
  final String label;
  final String description;
  const _PhaseInfo(this.key, this.label, this.description);
}

enum _PhaseStatus { pending, active, done, failed }
