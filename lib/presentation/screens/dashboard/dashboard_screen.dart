import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/dashboard/dashboard_cubit.dart';
import '../../../logic/dashboard/dashboard_state.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../logic/theme/theme_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/rivly_card.dart';
import '../../widgets/job_creation_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
  }

  void _openCreateModal() {
    JobCreationModal.show(
      context,
      onJobCreated: () {
        context.read<DashboardCubit>().loadDashboard();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rivly',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        actions: [
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return IconButton(
                icon: Icon(
                  themeState.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                tooltip: 'Toggle theme',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              context.read<AuthCubit>().logout();
              context.go('/login');
            },
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.isLoading && state.jobs.isEmpty) {
            return LoadingShimmer.list(count: 5);
          }

          if (state.error != null && state.jobs.isEmpty) {
            return _buildErrorState(context, state.error!);
          }

          if (state.jobs.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<DashboardCubit>().loadDashboard(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Your Jobs',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                ...state.jobs.map((job) => RivlyCard(
                      onTap: () {
                        if (job.lastRunId != null) {
                          context.go('/reports/${job.lastRunId}');
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  job.name,
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              _StatusChip(status: job.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            job.productUrl,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.accentSecondary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${job.competitors.length} competitors',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.schedule_outlined,
                                size: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                job.schedule,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              Text(
                                DateFormat.yMMMd().format(job.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => context
                                      .read<DashboardCubit>()
                                      .triggerRun(job.id),
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  label: const Text('Run'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _confirmDelete(
                                    context, job.id, job.name),
                                child: const Icon(Icons.delete_outline,
                                    size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                if (state.recentRuns.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Recent Runs',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  ...state.recentRuns.map((run) => RivlyCard(
                        onTap: () {
                          if (run.status == 'running') {
                            context.go('/runs/${run.id}');
                          } else if (run.status == 'completed') {
                            context.go('/reports/${run.id}');
                          }
                        },
                        child: Row(
                          children: [
                            _StatusDot(status: run.status),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Run ${run.id.substring(0, 8)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    run.status.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat.yMMMd()
                                  .add_jm()
                                  .format(run.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateModal,
        icon: const Icon(Icons.add),
        label: const Text('New Job'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative icon composition with gradient circle
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Gradient circle background
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accentPrimary.withValues(alpha: 0.12),
                          AppColors.accentSecondary.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Second decorative ring
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentSecondary.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Icon composition
                  Icon(
                    Icons.insights,
                    size: 48,
                    color: AppColors.accentPrimary.withValues(alpha: 0.8),
                  ),
                  Positioned(
                    top: 30,
                    right: 28,
                    child: Icon(
                      Icons.auto_graph,
                      size: 24,
                      color:
                          AppColors.accentSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                  Positioned(
                    bottom: 35,
                    left: 28,
                    child: Icon(
                      Icons.radar,
                      size: 22,
                      color: AppColors.accentPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Heading
            Text(
              'No analyses yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 12),

            // Subtext
            Text(
              'Set up your first competitor analysis\nin under 2 minutes',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // CTA button
            SizedBox(
              width: 260,
              height: 52,
              child: ElevatedButton(
                onPressed: _openCreateModal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Create First Analysis'),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Plan info
            Text(
              'Free plan includes 1 job with 2 competitors',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgElevated : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 28,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.read<DashboardCubit>().loadDashboard(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String jobId, String jobName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text('Are you sure you want to delete "$jobName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DashboardCubit>().deleteJob(jobId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = AppColors.success;
        break;
      case 'running':
        color = AppColors.accentPrimary;
        break;
      case 'error':
        color = AppColors.error;
        break;
      default:
        color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = AppColors.success;
        break;
      case 'running':
        color = AppColors.accentPrimary;
        break;
      case 'failed':
        color = AppColors.error;
        break;
      default:
        color = AppColors.warning;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
