import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/run_model.dart';
import '../../widgets/common/rivly_card.dart';

class ReportListScreen extends StatelessWidget {
  final List<RunModel> completedRuns;

  const ReportListScreen({
    super.key,
    this.completedRuns = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Reports'),
      ),
      body: completedRuns.isEmpty ? _buildEmptyState(context) : _buildList(context),
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
            // Decorative icon with gradient circle
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accentSecondary.withValues(alpha: 0.1),
                          AppColors.accentPrimary.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentPrimary.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.article_outlined,
                    size: 44,
                    color: AppColors.accentSecondary.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'No reports yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 12),

            Text(
              'Run your first analysis to see\nUX reports here',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: 220,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.dashboard_outlined, size: 18),
                label: const Text('Go to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedRuns.length,
      itemBuilder: (context, index) {
        final run = completedRuns[index];
        return RivlyCard(
          onTap: () => context.go('/reports/${run.id}'),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assessment,
                  color: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Run ${run.id.substring(0, 8)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      DateFormat.yMMMd().add_jm().format(run.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        );
      },
    );
  }
}
