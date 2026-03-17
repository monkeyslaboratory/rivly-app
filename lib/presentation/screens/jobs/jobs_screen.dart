import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../logic/dashboard/dashboard_cubit.dart';
import '../../../logic/dashboard/dashboard_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/scale_button.dart';
import '../../widgets/job_creation_modal.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  @override
  void initState() {
    super.initState();
    final state = context.read<DashboardCubit>().state;
    if (state.jobs.isEmpty && !state.isLoading) {
      context.read<DashboardCubit>().loadDashboard();
    }
  }

  void _openCreateModal() {
    JobCreationModal.show(
      context,
      onJobCreated: () {
        context.read<DashboardCubit>().loadDashboard();
      },
    );
  }

  void _confirmDelete(BuildContext context, String jobId, String jobName) {
    final l = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteJob),
        content: Text('${l.confirmDelete} "$jobName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DashboardCubit>().deleteJob(jobId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.isLoading && state.jobs.isEmpty) {
          return LoadingShimmer.list(count: 5);
        }

        if (state.jobs.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildJobsList(context, state);
      },
    );
  }

  Widget _buildJobsList(BuildContext context, DashboardState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.jobs,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.manageJobs,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ScaleButton(
                onPressed: _openCreateModal,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 18,
                        color: isDark
                            ? AppColors.darkBg
                            : AppColors.lightBgElevated,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.newJob,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkBg
                              : AppColors.lightBgElevated,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Job cards
          ...state.jobs.map((job) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _JobCard(
                  name: job.name,
                  productUrl: job.productUrl,
                  status: job.status,
                  competitorCount: job.competitors.length,
                  scheduleFrequency: job.scheduleFrequency,
                  createdAt: job.createdAt,
                  isDark: isDark,
                  onRun: () =>
                      context.read<DashboardCubit>().triggerRun(job.id),
                  onDelete: () =>
                      _confirmDelete(context, job.id, job.name),
                  onTap: () => context.go('/jobs/${job.id}'),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.darkBgSubtle
                    : AppColors.lightBorder,
              ),
              child: Icon(
                Icons.work_outline,
                size: 36,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l.noJobsYet,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.createFirstJob,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ScaleButton(
              onPressed: _openCreateModal,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 18,
                      color: isDark
                          ? AppColors.darkBg
                          : AppColors.lightBgElevated,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.createFirstJobButton,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkBg
                            : AppColors.lightBgElevated,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Job Card
// ---------------------------------------------------------------------------
class _JobCard extends StatefulWidget {
  final String name;
  final String productUrl;
  final String status;
  final int competitorCount;
  final String scheduleFrequency;
  final DateTime createdAt;
  final bool isDark;
  final VoidCallback onRun;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _JobCard({
    required this.name,
    required this.productUrl,
    required this.status,
    required this.competitorCount,
    required this.scheduleFrequency,
    required this.createdAt,
    required this.isDark,
    required this.onRun,
    required this.onDelete,
    this.onTap,
  });

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final borderColor =
        widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor =
        widget.isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated;
    final hoverBg = widget.isDark
        ? AppColors.darkBgSubtle.withValues(alpha: 0.5)
        : AppColors.lightBgSubtle;
    final textPrimary = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted =
        widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isHovered ? hoverBg : bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: !widget.isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + status chip
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusChip(status: widget.status),
                ],
              ),
              const SizedBox(height: 8),

              // Product URL
              Text(
                widget.productUrl,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.accentSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Meta row
              Row(
                children: [
                  Icon(Icons.people_outline, size: 14, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    l.competitorsCount(widget.competitorCount),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule_outlined, size: 14, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    widget.scheduleFrequency,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: textMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat.yMMMd().format(widget.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  ScaleButton(
                    onPressed: widget.onRun,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            size: 16,
                            color: widget.isDark
                                ? AppColors.darkBg
                                : AppColors.lightBgElevated,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l.run,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: widget.isDark
                                  ? AppColors.darkBg
                                  : AppColors.lightBgElevated,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DeleteButton(
                    isDark: widget.isDark,
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delete Button with hover-to-red
// ---------------------------------------------------------------------------
class _DeleteButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _DeleteButton({required this.isDark, required this.onTap});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mutedColor =
        widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final color = _isHovered ? AppColors.error : mutedColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.error.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? AppColors.error.withValues(alpha: 0.3)
                  : (widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                l.delete,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Chip — colored dot, no orange for active status
// ---------------------------------------------------------------------------
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = AppColors.success;
      case 'running':
        color = AppColors.accentSecondary;
      case 'error':
      case 'failed':
        color = AppColors.error;
      default:
        color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
