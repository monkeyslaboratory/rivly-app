import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../data/repositories/run_repository.dart';
import '../../widgets/charts/score_gauge.dart';
import '../../widgets/common/rivly_button.dart';

class ReportDetailScreen extends StatefulWidget {
  final String runId;

  const ReportDetailScreen({super.key, required this.runId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen>
    with TickerProviderStateMixin {
  final RunRepository _runRepository = RunRepository();
  Map<String, dynamic>? _runData;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  List<_TabDef> _tabs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _rebuildTabs() {
    final data = _runData;
    if (data == null) return;

    final comparison = data['comparison'] as Map<String, dynamic>?;
    final reports = (data['reports'] as List<dynamic>?) ?? [];
    final screenshots = (data['screenshots'] as List<dynamic>?) ?? [];
    final overallScores = (data['overall_scores'] as List<dynamic>?) ?? [];

    final tabs = <_TabDef>[];

    // Tab 1: Overview (always present if we have scores or comparison)
    if (overallScores.isNotEmpty || comparison != null) {
      tabs.add(_TabDef('Overview', Icons.dashboard_outlined));
    }

    // Comparison tabs only if data exists
    if (comparison != null) {
      if (comparison['feature_matrix'] != null) {
        tabs.add(_TabDef('Features', Icons.grid_on_outlined));
      }
      if (comparison['flow_comparison'] != null) {
        tabs.add(_TabDef('Flows', Icons.route_outlined));
      }
      if (comparison['ux_scorecard'] != null) {
        tabs.add(_TabDef('Scorecard', Icons.bar_chart_outlined));
      }
      if (comparison['recommendations'] != null) {
        tabs.add(_TabDef('Actions', Icons.lightbulb_outline));
      }
    }

    if (screenshots.isNotEmpty) {
      tabs.add(_TabDef('Screenshots', Icons.image_outlined));
    }
    if (reports.isNotEmpty) {
      tabs.add(_TabDef('Reports', Icons.article_outlined));
    }

    // If no tabs at all, add a placeholder
    if (tabs.isEmpty) {
      tabs.add(_TabDef('Report', Icons.article_outlined));
    }

    final oldIndex = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(length: tabs.length, vsync: this);
    if (oldIndex < tabs.length) {
      _tabController.index = oldIndex;
    }
    _tabs = tabs;
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _runRepository.getRawRun(widget.runId);
      _runData = response;
      _rebuildTabs();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Analysis Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(isDark)
              : _runData != null
                  ? _buildReport(isDark)
                  : _buildEmpty(isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load report',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error ?? '',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            RivlyButton(label: 'Retry', onPressed: _loadReport),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined,
              size: 64,
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          const SizedBox(height: 16),
          Text('No report data',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          RivlyButton(
              label: 'Back to Dashboard',
              onPressed: () => context.go('/dashboard'),
              variant: RivlyButtonVariant.outline),
        ],
      ),
    );
  }

  Widget _buildReport(bool isDark) {
    final data = _runData!;
    final status = data['status'] as String? ?? '';
    final duration = data['duration_seconds'] as int?;

    return Column(
      children: [
        // Status header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _buildStatusHeader(status, duration, isDark),
        ),
        const SizedBox(height: 16),

        // Tab bar
        if (_tabs.length > 1)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBgSecondary
                  : AppColors.lightBgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.accentPrimary,
              unselectedLabelColor:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              indicatorColor: AppColors.accentPrimary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: _tabs
                  .map((t) => Tab(
                        height: 42,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 16),
                            const SizedBox(width: 6),
                            Text(t.label),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        const SizedBox(height: 8),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _tabs.map((t) => _buildTabContent(t.label, isDark)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(String label, bool isDark) {
    switch (label) {
      case 'Overview':
        return _buildOverviewTab(isDark);
      case 'Features':
        return _buildFeatureMatrixTab(isDark);
      case 'Flows':
        return _buildFlowComparisonTab(isDark);
      case 'Scorecard':
        return _buildScorecardTab(isDark);
      case 'Actions':
        return _buildRecommendationsTab(isDark);
      case 'Screenshots':
        return _buildScreenshotsTab(isDark);
      case 'Reports':
        return _buildDetailedReportsTab(isDark);
      default:
        return _buildPlaceholderTab(isDark);
    }
  }

  // ===========================================================================
  // Status header
  // ===========================================================================
  Widget _buildStatusHeader(String status, int? duration, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: status == 'completed'
            ? AppColors.success.withValues(alpha: 0.08)
            : status == 'failed'
                ? AppColors.error.withValues(alpha: 0.08)
                : (isDark
                    ? AppColors.darkBgSecondary
                    : AppColors.lightBgSecondary),
        border: Border.all(
          color: status == 'completed'
              ? AppColors.success.withValues(alpha: 0.2)
              : status == 'failed'
                  ? AppColors.error.withValues(alpha: 0.2)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            status == 'completed'
                ? Icons.check_circle
                : status == 'failed'
                    ? Icons.error
                    : Icons.hourglass_top,
            color: status == 'completed'
                ? AppColors.success
                : status == 'failed'
                    ? AppColors.error
                    : AppColors.accentPrimary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status == 'completed'
                      ? 'Analysis Complete'
                      : status == 'failed'
                          ? 'Analysis Failed'
                          : 'In Progress',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                ),
                if (duration != null)
                  Text('Completed in ${_formatDuration(duration)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 1: Overview
  // ===========================================================================
  Widget _buildOverviewTab(bool isDark) {
    final data = _runData!;
    final comparison = data['comparison'] as Map<String, dynamic>?;
    final overallScores = (data['overall_scores'] as List<dynamic>?) ?? [];

    final executiveSummary = comparison?['executive_summary'] as String?;
    final competitivePosition = comparison?['competitive_position'] as String?;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Executive summary
        if (executiveSummary != null && executiveSummary.isNotEmpty) ...[
          _sectionTitle(context, 'Executive Summary', Icons.summarize_outlined, isDark),
          const SizedBox(height: 10),
          _card(
            isDark,
            child: _buildBulletText(executiveSummary, isDark),
          ),
          const SizedBox(height: 20),
        ],

        // Competitive position
        if (competitivePosition != null && competitivePosition.isNotEmpty) ...[
          _sectionTitle(context, 'Competitive Position', Icons.emoji_events_outlined, isDark),
          const SizedBox(height: 10),
          _card(
            isDark,
            child: Text(
              competitivePosition,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Overall scores
        if (overallScores.isNotEmpty) ...[
          _sectionTitle(context, 'Competitor Scores', Icons.speed_outlined, isDark),
          const SizedBox(height: 10),
          ...overallScores.map((os) =>
              _buildOverallScoreCard(os as Map<String, dynamic>, isDark)),
        ],

        if (executiveSummary == null &&
            competitivePosition == null &&
            overallScores.isEmpty)
          _buildNoDataMessage(isDark, 'Overview data not available yet.'),
      ],
    );
  }

  Widget _buildBulletText(String text, bool isDark) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final cleaned = line.replaceFirst(RegExp(r'^[\s]*[-*\u2022]\s*'), '');
        final isBullet = cleaned != line;

        if (isBullet) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cleaned,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line.trim(),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverallScoreCard(Map<String, dynamic> os, bool isDark) {
    final score = os['overall_score'] as int? ?? 0;
    final delta = os['score_delta'] as int?;
    final insights = (os['top_insights'] as List<dynamic>?) ?? [];
    final productName = os['product_name'] as String? ?? os['url'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          ScoreGauge(
              score: score,
              size: 72,
              strokeWidth: 6,
              color: score >= 80
                  ? AppColors.success
                  : score >= 60
                      ? AppColors.accentPrimary
                      : AppColors.error),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (productName.isNotEmpty)
                  Text(
                    productName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('UX Score: $score',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary)),
                    if (delta != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (delta >= 0
                                  ? AppColors.success
                                  : AppColors.error)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${delta >= 0 ? "\u25b2" : "\u25bc"} ${delta.abs()}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: delta >= 0
                                  ? AppColors.success
                                  : AppColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (insights.isNotEmpty)
                  Text(insights.first.toString(),
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 2: Feature Matrix
  // ===========================================================================
  Widget _buildFeatureMatrixTab(bool isDark) {
    final comparison = _runData!['comparison'] as Map<String, dynamic>?;
    final featureMatrix =
        (comparison?['feature_matrix'] as List<dynamic>?) ?? [];

    if (featureMatrix.isEmpty) {
      return _buildNoDataMessage(isDark, 'Feature matrix not available.');
    }

    // Collect all product names from the first category
    final productNames = <String>[];
    if (featureMatrix.isNotEmpty) {
      final firstCat = featureMatrix.first as Map<String, dynamic>;
      final features = (firstCat['features'] as List<dynamic>?) ?? [];
      if (features.isNotEmpty) {
        final firstFeature = features.first as Map<String, dynamic>;
        final products =
            (firstFeature['products'] as Map<String, dynamic>?) ?? {};
        productNames.addAll(products.keys);
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: featureMatrix.length,
      itemBuilder: (context, catIndex) {
        final category = featureMatrix[catIndex] as Map<String, dynamic>;
        final categoryName = category['category'] as String? ?? '';
        final features = (category['features'] as List<dynamic>?) ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (catIndex > 0) const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                categoryName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _card(
              isDark,
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 44,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 40,
                  horizontalMargin: 16,
                  columnSpacing: 20,
                  headingTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  dataTextStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  columns: [
                    const DataColumn(label: Text('Feature')),
                    ...productNames.map((p) => DataColumn(
                          label: Text(
                            _shortenProductName(p),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  rows: features.map((f) {
                    final feature = f as Map<String, dynamic>;
                    final name = feature['name'] as String? ?? '';
                    final products =
                        (feature['products'] as Map<String, dynamic>?) ?? {};

                    return DataRow(cells: [
                      DataCell(SizedBox(
                        width: 160,
                        child: Text(name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      )),
                      ...productNames.map((p) {
                        final val = products[p];
                        return DataCell(
                          Center(child: _featureIndicator(val, isDark)),
                        );
                      }),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _featureIndicator(dynamic value, bool isDark) {
    if (value == true || value == 'yes' || value == 'true') {
      return const Icon(Icons.check_circle, color: AppColors.success, size: 20);
    } else if (value == false || value == 'no' || value == 'false') {
      return Icon(Icons.cancel, color: AppColors.error.withValues(alpha: 0.6), size: 20);
    } else if (value == 'partial' || value == 'limited') {
      return const Icon(Icons.warning_amber_rounded,
          color: AppColors.warning, size: 20);
    } else if (value is String && value.isNotEmpty) {
      return Text(value,
          style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary));
    }
    return Icon(Icons.remove,
        size: 16,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
  }

  String _shortenProductName(String name) {
    // Strip protocol and www
    var short = name
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\.'), '');
    // Strip trailing slash
    if (short.endsWith('/')) short = short.substring(0, short.length - 1);
    // Truncate
    if (short.length > 20) short = '${short.substring(0, 18)}...';
    return short;
  }

  // ===========================================================================
  // Tab 3: Flow Comparison
  // ===========================================================================
  Widget _buildFlowComparisonTab(bool isDark) {
    final comparison = _runData!['comparison'] as Map<String, dynamic>?;
    final flows =
        (comparison?['flow_comparison'] as List<dynamic>?) ?? [];

    if (flows.isEmpty) {
      return _buildNoDataMessage(isDark, 'Flow comparison not available.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: flows.length,
      itemBuilder: (context, index) {
        final flow = flows[index] as Map<String, dynamic>;
        final flowName = flow['flow_name'] as String? ?? flow['name'] as String? ?? 'Flow ${index + 1}';
        final products =
            (flow['products'] as Map<String, dynamic>?) ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 16),
            _sectionTitle(context, flowName, Icons.route_outlined, isDark),
            const SizedBox(height: 8),
            ...products.entries.map((entry) {
              final productName = entry.key;
              final productData = entry.value as Map<String, dynamic>? ?? {};
              final steps = productData['steps'] as int? ??
                  productData['steps_count'] as int?;
              final friction = productData['friction'] as String? ??
                  productData['friction_level'] as String? ?? '';
              final notable =
                  (productData['notable_features'] as List<dynamic>?) ?? [];
              final painPoints =
                  (productData['pain_points'] as List<dynamic>?) ?? [];

              return _card(
                isDark,
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product header
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.accentSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _shortenProductName(productName),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Metrics row
                    Row(
                      children: [
                        if (steps != null) ...[
                          _metricChip(
                              'Steps: $steps',
                              isDark,
                              AppColors.accentSecondary
                                  .withValues(alpha: 0.1)),
                          const SizedBox(width: 8),
                        ],
                        if (friction.isNotEmpty)
                          _metricChip(
                              'Friction: $friction',
                              isDark,
                              _frictionColor(friction)
                                  .withValues(alpha: 0.1)),
                      ],
                    ),

                    // Notable features
                    if (notable.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...notable.map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.star_outline,
                                    size: 14, color: AppColors.accentPrimary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    n.toString(),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],

                    // Pain points
                    if (painPoints.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...painPoints.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 14, color: AppColors.error),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    p.toString(),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Color _frictionColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.error;
      default:
        return AppColors.accentSecondary;
    }
  }

  Widget _metricChip(String text, bool isDark, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
    );
  }

  // ===========================================================================
  // Tab 4: UX Scorecard
  // ===========================================================================
  Widget _buildScorecardTab(bool isDark) {
    final comparison = _runData!['comparison'] as Map<String, dynamic>?;
    final scorecard = comparison?['ux_scorecard'] as Map<String, dynamic>?;

    if (scorecard == null) {
      return _buildNoDataMessage(isDark, 'UX scorecard not available.');
    }

    final dimensions =
        (scorecard['dimensions'] as List<dynamic>?) ?? [];
    final products =
        (scorecard['products'] as Map<String, dynamic>?) ??
            (scorecard['scores'] as Map<String, dynamic>?) ??
            {};

    // If dimensions is a list of strings, use it. If it's a list of maps, adapt.
    final dimensionNames = dimensions.map((d) {
      if (d is String) return d;
      if (d is Map) return (d['name'] as String?) ?? d.toString();
      return d.toString();
    }).toList();

    if (dimensionNames.isEmpty || products.isEmpty) {
      return _buildNoDataMessage(isDark, 'UX scorecard data incomplete.');
    }

    final productNames = products.keys.toList();

    // Assign colors per product
    final productColors = <String, Color>{};
    final palette = [
      AppColors.accentPrimary,
      AppColors.accentSecondary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.accentWarm,
    ];
    for (var i = 0; i < productNames.length; i++) {
      productColors[productNames[i]] = palette[i % palette.length];
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: productNames.map((p) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: productColors[p],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _shortenProductName(p),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Dimension rows
        ...dimensionNames.asMap().entries.map((entry) {
          final dimIndex = entry.key;
          final dimName = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _card(
              isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dimName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...productNames.map((pName) {
                    final scores =
                        (products[pName] as List<dynamic>?) ?? [];
                    final score = dimIndex < scores.length
                        ? (scores[dimIndex] as num?)?.toDouble() ?? 0.0
                        : 0.0;
                    final color = productColors[pName]!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              _shortenProductName(pName),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _scoreBar(score, 5.0, color, isDark),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 28,
                            child: Text(
                              score.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _scoreBar(
      double value, double maxValue, Color color, bool isDark) {
    final fraction = (value / maxValue).clamp(0.0, 1.0);
    return Container(
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: color,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Tab 5: Recommendations
  // ===========================================================================
  Widget _buildRecommendationsTab(bool isDark) {
    final comparison = _runData!['comparison'] as Map<String, dynamic>?;
    final recommendations =
        (comparison?['recommendations'] as List<dynamic>?) ?? [];

    if (recommendations.isEmpty) {
      return _buildNoDataMessage(isDark, 'No recommendations available.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final rec = recommendations[index] as Map<String, dynamic>;
        final finding = rec['finding'] as String? ?? '';
        final evidence = rec['evidence'] as String? ?? '';
        final impact = rec['impact'] as String? ?? '';
        final priority = (rec['priority'] as String? ?? 'medium').toLowerCase();
        final action = rec['action'] as String? ?? '';
        final reference = rec['reference_competitor'] as String? ??
            rec['reference'] as String? ?? '';

        final priorityColor = _priorityColor(priority);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _card(
            isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority badge + number
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                    const Spacer(),
                    if (reference.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.compare_arrows,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted),
                          const SizedBox(width: 4),
                          Text(
                            _shortenProductName(reference),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Finding
                if (finding.isNotEmpty) ...[
                  Text(
                    finding,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Evidence
                if (evidence.isNotEmpty) ...[
                  Text(
                    evidence,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Impact
                if (impact.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.trending_up,
                            size: 16, color: AppColors.accentPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            impact,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action
                if (action.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_forward_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          action,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return AppColors.accentPrimary;
      case 'medium':
        return AppColors.accentSecondary;
      case 'low':
        return const Color(0xFF9CA3AF);
      default:
        return AppColors.accentSecondary;
    }
  }

  // ===========================================================================
  // Tab 6: Screenshots
  // ===========================================================================
  Widget _buildScreenshotsTab(bool isDark) {
    final screenshots =
        (_runData!['screenshots'] as List<dynamic>?) ?? [];

    if (screenshots.isEmpty) {
      return _buildNoDataMessage(isDark, 'No screenshots available.');
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: screenshots.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final shot = screenshots[index] as Map<String, dynamic>;
              final shotId = shot['id'] as String;
              final pageName = shot['page_name'] as String? ?? '';
              final deviceType = shot['device_type'] as String? ?? '';
              final shotStatus = shot['status'] as String? ?? '';
              final imageUrl =
                  'http://localhost:8000/api/v1/runs/screenshots/$shotId/';

              return Container(
                width: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06)),
                  color: isDark
                      ? AppColors.darkBgSecondary
                      : AppColors.lightBgSecondary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: shotStatus == 'success'
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(Icons.broken_image,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted),
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: AppColors.error, size: 24),
                                    const SizedBox(height: 4),
                                    Text(shotStatus,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.error)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Icon(
                            deviceType == 'mobile'
                                ? Icons.phone_iphone
                                : Icons.desktop_windows_outlined,
                            size: 14,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pageName.replaceAll('_', ' '),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Tab 7: Detailed Reports
  // ===========================================================================
  Widget _buildDetailedReportsTab(bool isDark) {
    final reports =
        (_runData!['reports'] as List<dynamic>?) ?? [];

    final filtered = reports
        .where((r) => (r as Map<String, dynamic>)['score'] > 0)
        .toList();

    if (filtered.isEmpty) {
      return _buildNoDataMessage(isDark, 'No detailed reports available.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildReportCard(
            filtered[index] as Map<String, dynamic>, isDark);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, bool isDark) {
    final category = report['category'] as String? ?? '';
    final score = report['score'] as int? ?? 0;
    final summary = report['summary'] as String? ?? '';
    final recommendations =
        (report['recommendations'] as List<dynamic>?) ?? [];
    final scoreBreakdown =
        report['score_breakdown'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(category.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentSecondary)),
              ),
              const Spacer(),
              Text('$score/100',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: score >= 80
                          ? AppColors.success
                          : score >= 60
                              ? AppColors.accentPrimary
                              : AppColors.error)),
            ],
          ),
          const SizedBox(height: 12),

          // Summary
          Text(summary,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)),

          // Score breakdown
          if (scoreBreakdown.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: scoreBreakdown.entries.map((e) {
                final val = e.value as int? ?? 0;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                  child: Text('${e.key.replaceAll('_', ' ')}: $val',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted)),
                );
              }).toList(),
            ),
          ],

          // Recommendations
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...recommendations.take(3).map((r) {
              final rec = r as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 14, color: AppColors.accentPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(rec['action'] as String? ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Placeholder / no data
  // ===========================================================================
  Widget _buildPlaceholderTab(bool isDark) {
    return _buildNoDataMessage(isDark, 'No data available yet.');
  }

  Widget _buildNoDataMessage(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 48,
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Shared helpers
  // ===========================================================================
  Widget _sectionTitle(
      BuildContext context, String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accentPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _card(bool isDark,
      {required Widget child,
      EdgeInsets? padding,
      EdgeInsets? margin}) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: child,
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  const _TabDef(this.label, this.icon);
}
