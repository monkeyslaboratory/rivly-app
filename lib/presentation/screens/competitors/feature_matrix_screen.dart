import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/tokens/colors.dart';
import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../../../core/theme/tokens/typography.dart';
import '../../../data/repositories/run_repository.dart';
import '../../../logic/dashboard/dashboard_cubit.dart';
import '../../widgets/common/loading_shimmer.dart';

/// Feature Matrix screen -- the CORE analytical view.
///
/// Displays features vs competitors in a table format with PoP/PoD
/// classification, coverage percentages, summary cards, filter bar,
/// and animated coverage bars.
///
/// Example:
/// ```dart
/// const FeatureMatrixScreen()
/// ```
class FeatureMatrixScreen extends StatefulWidget {
  const FeatureMatrixScreen({super.key});

  @override
  State<FeatureMatrixScreen> createState() => _FeatureMatrixScreenState();
}

class _FeatureMatrixScreenState extends State<FeatureMatrixScreen>
    with TickerProviderStateMixin {
  final RunRepository _runRepository = RunRepository();
  bool _isLoading = true;
  String? _error;
  List<_FeatureCategory> _categories = [];
  List<String> _competitorNames = [];
  DateTime? _lastUpdated;

  // UI state
  final Set<String> _collapsedCategories = {};
  _ClassificationFilter _classFilter = _ClassificationFilter.all;
  _ViewMode _viewMode = _ViewMode.fullMatrix;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Animation
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _loadFeatureMatrix();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFeatureMatrix() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashState = context.read<DashboardCubit>().state;
      List<_FeatureCategory> allCategories = [];
      Set<String> competitorNamesSet = {};
      DateTime? latestUpdate;

      for (final job in dashState.jobs) {
        final runs = await _runRepository.getRuns(job.id);
        final completedRuns = runs.where((r) => r.isCompleted).toList();

        for (final run in completedRuns) {
          try {
            final rawRun = await _runRepository.getRawRun(run.id);
            final comparison =
                rawRun['comparison'] as Map<String, dynamic>? ?? {};
            final matrixList =
                (comparison['feature_matrix'] as List<dynamic>?) ?? [];

            if (matrixList.isNotEmpty) {
              final updatedAt = run.createdAt;
              if (latestUpdate == null || updatedAt.isAfter(latestUpdate)) {
                latestUpdate = updatedAt;
              }
            }

            for (final item in matrixList) {
              if (item is! Map<String, dynamic>) continue;
              final catName =
                  (item['category'] as String?) ?? 'Uncategorized';
              final features = (item['features'] as List<dynamic>?) ?? [];

              final parsedFeatures = <_FeatureItem>[];
              for (final f in features) {
                if (f is! Map<String, dynamic>) continue;
                final featureName =
                    (f['name'] ?? f['feature'] ?? '').toString();
                final ourProduct_ = _parsePresence(
                    (f['our_product'] ?? f['ours'] ?? '').toString());
                final competitors =
                    (f['competitors'] as Map<String, dynamic>?) ?? {};

                final compMap = <String, _Presence>{};
                for (final entry in competitors.entries) {
                  competitorNamesSet.add(entry.key);
                  compMap[entry.key] =
                      _parsePresence(entry.value.toString());
                }

                parsedFeatures.add(_FeatureItem(
                  name: featureName,
                  ourPresence: ourProduct_,
                  competitors: compMap,
                ));
              }

              if (parsedFeatures.isNotEmpty) {
                final existingIdx =
                    allCategories.indexWhere((c) => c.name == catName);
                if (existingIdx >= 0) {
                  allCategories[existingIdx] = _FeatureCategory(
                    name: catName,
                    features: [
                      ...allCategories[existingIdx].features,
                      ...parsedFeatures,
                    ],
                  );
                } else {
                  allCategories.add(_FeatureCategory(
                    name: catName,
                    features: parsedFeatures,
                  ));
                }
              }
            }
          } catch (_) {
            // Skip runs that fail
          }
        }
      }

      setState(() {
        _categories = allCategories;
        _competitorNames = competitorNamesSet.toList()..sort();
        _lastUpdated = latestUpdate;
        _isLoading = false;
        _hasAnimated = false;
      });

      // Trigger animation after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _hasAnimated = true);
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  _Presence _parsePresence(String value) {
    final lower = value.toLowerCase().trim();
    if (lower == 'yes' || lower == 'true' || lower == 'present') {
      return _Presence.yes;
    }
    if (lower == 'partial') {
      return _Presence.partial;
    }
    return _Presence.no;
  }

  // -- Computed stats --

  _MatrixStats _computeStats() {
    int totalFeatures = 0;
    int popFeatures = 0;
    int popWeHave = 0;
    int ourAdvantages = 0;
    int criticalGaps = 0;

    for (final cat in _categories) {
      for (final f in cat.features) {
        totalFeatures++;
        final meta = _featureMeta(f);
        if (meta.isPoP) {
          popFeatures++;
          if (meta.weHaveIt) {
            popWeHave++;
          } else {
            criticalGaps++;
          }
        } else if (meta.weHaveIt && meta.competitorCount == 0) {
          ourAdvantages++;
        }
      }
    }

    final popCoveragePercent =
        popFeatures > 0 ? (popWeHave / popFeatures * 100).round() : 100;

    return _MatrixStats(
      totalFeatures: totalFeatures,
      popCoveragePercent: popCoveragePercent,
      ourAdvantages: ourAdvantages,
      criticalGaps: criticalGaps,
    );
  }

  _FeatureMeta _featureMeta(_FeatureItem f) {
    final competitorCount =
        f.competitors.values.where((p) => p != _Presence.no).length;
    final totalComps = f.competitors.length;
    final mostHaveIt =
        totalComps > 0 && competitorCount / totalComps >= 0.5;
    final weHaveIt = f.ourPresence != _Presence.no;

    final isPoP = mostHaveIt;
    final isGap = isPoP && !weHaveIt;
    final isAdvantage = weHaveIt && competitorCount == 0;

    // Compute score
    int ourScore = _presenceScore(f.ourPresence);
    double competitorAvg = totalComps > 0
        ? f.competitors.values
                .map(_presenceScore)
                .fold<int>(0, (a, b) => a + b) /
            totalComps
        : 0;

    // Coverage
    final coverageCount = competitorCount + (weHaveIt ? 1 : 0);
    final coverageTotal = totalComps + 1;
    final coveragePercent =
        coverageTotal > 0 ? (coverageCount / coverageTotal * 100).round() : 0;

    return _FeatureMeta(
      competitorCount: competitorCount,
      totalComps: totalComps,
      isPoP: isPoP,
      isGap: isGap,
      isAdvantage: isAdvantage,
      weHaveIt: weHaveIt,
      ourScore: ourScore,
      competitorAvg: competitorAvg,
      coveragePercent: coveragePercent,
    );
  }

  int _presenceScore(_Presence p) {
    switch (p) {
      case _Presence.yes:
        return 4;
      case _Presence.partial:
        return 2;
      case _Presence.no:
        return 0;
    }
  }

  // -- Filtering --

  List<_FeatureItem> _filterFeatures(List<_FeatureItem> features) {
    return features.where((f) {
      final meta = _featureMeta(f);

      // Classification filter
      if (_classFilter == _ClassificationFilter.pop && !meta.isPoP) {
        return false;
      }
      if (_classFilter == _ClassificationFilter.pod && meta.isPoP) {
        return false;
      }

      // View mode: gaps only
      if (_viewMode == _ViewMode.gapsOnly) {
        final isGapRow =
            meta.isGap || (meta.weHaveIt && meta.ourScore < meta.competitorAvg);
        if (!isGapRow) return false;
      }

      // Search
      if (_searchQuery.isNotEmpty) {
        if (!f.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).round()}w ago';
  }

  String _formatLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
            (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _shortenName(String name) {
    return name
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '')
        .replaceAll(RegExp(r'/$'), '')
        .split('.')
        .first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? PulseColors.dark : PulseColors.light;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.surface0,
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError(c, l)
              : _categories.isEmpty
                  ? _buildEmpty(c, l)
                  : _buildContent(c, l),
    );
  }

  // -- Loading --

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(width: 200, height: 28),
          const SizedBox(height: PulseSpacing.sm),
          const LoadingShimmer(width: 300, height: 16),
          const SizedBox(height: PulseSpacing.xxl),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: PulseSpacing.md),
              child: LoadingShimmer(height: 80, borderRadius: 10),
            ),
          ),
        ],
      ),
    );
  }

  // -- Error --

  Widget _buildError(PulseColors c, AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: c.danger),
            const SizedBox(height: PulseSpacing.base),
            Text(
              l.somethingWentWrong,
              style: PulseTypography.h3(color: c.textPrimary),
            ),
            const SizedBox(height: PulseSpacing.sm),
            Text(
              _error!,
              style: PulseTypography.body(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // -- Empty --

  Widget _buildEmpty(PulseColors c, AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surface2,
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 36,
                  color: c.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: PulseSpacing.xl),
            Text(
              l.noFeatureData.split('.').first,
              style: PulseTypography.h3(color: c.textPrimary),
            ),
            const SizedBox(height: PulseSpacing.sm),
            Text(
              'Run a competitive analysis to see feature comparisons.',
              style: PulseTypography.body(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PulseSpacing.xl),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: _loadFeatureMatrix,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PulseRadii.sm),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: PulseSpacing.xl),
                ),
                child: Text(
                  'Run analysis',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Content --

  Widget _buildContent(PulseColors c, AppLocalizations l) {
    final stats = _computeStats();

    return RefreshIndicator(
      onRefresh: _loadFeatureMatrix,
      child: ListView(
        padding: const EdgeInsets.all(PulseSpacing.xl),
        children: [
          // PAGE HEADER (64px)
          _buildPageHeader(c, l, stats),
          const SizedBox(height: PulseSpacing.xl),

          // SUMMARY CARDS
          _buildSummaryCards(c, l, stats),
          const SizedBox(height: PulseSpacing.xl),

          // FILTER BAR
          _buildFilterBar(c, l),
          const SizedBox(height: PulseSpacing.base),

          // MATRIX TABLE
          _buildMatrixTable(c, l),
        ],
      ),
    );
  }

  // -- Page Header --

  Widget _buildPageHeader(
      PulseColors c, AppLocalizations l, _MatrixStats stats) {
    final subtitle = StringBuffer()
      ..write('${stats.totalFeatures} features across ')
      ..write('${_competitorNames.length} competitor')
      ..write(_competitorNames.length != 1 ? 's' : '');
    if (_lastUpdated != null) {
      subtitle
        ..write(' · Last updated ')
        ..write(_timeAgo(_lastUpdated!));
    }

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.featureMatrixTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Export button (secondary)
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO(tech): Implement export
              },
              icon: Icon(Icons.download_rounded, size: 16, color: c.textSecondary),
              label: Text(
                'Export',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.borderDefault),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PulseRadii.sm),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: PulseSpacing.md),
              ),
            ),
          ),
          const SizedBox(width: PulseSpacing.sm),
          // Run analysis button (primary)
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: _loadFeatureMatrix,
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: Text(
                'Run analysis',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PulseRadii.sm),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: PulseSpacing.md),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Summary Cards --

  Widget _buildSummaryCards(
      PulseColors c, AppLocalizations l, _MatrixStats stats) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: l.totalFeatures,
              value: '${stats.totalFeatures}',
              suffix: 'tracked',
              colors: c,
              animationDelay: 0,
              hasAnimated: _hasAnimated,
            ),
          ),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: _SummaryCard(
              label: l.popCoverage,
              value: '${stats.popCoveragePercent}%',
              suffix: null,
              valueColor:
                  stats.popCoveragePercent == 100 ? c.trendUp : null,
              colors: c,
              animationDelay: 1,
              hasAnimated: _hasAnimated,
            ),
          ),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: _SummaryCard(
              label: l.ourAdvantages,
              value: '${stats.ourAdvantages}',
              suffix: 'unique',
              colors: c,
              animationDelay: 2,
              hasAnimated: _hasAnimated,
            ),
          ),
          const SizedBox(width: PulseSpacing.md),
          Expanded(
            child: _SummaryCard(
              label: l.criticalGaps,
              value: stats.criticalGaps > 0 ? '${stats.criticalGaps}' : 'None',
              suffix: null,
              valueColor:
                  stats.criticalGaps > 0 ? c.danger : c.trendUp,
              colors: c,
              animationDelay: 3,
              hasAnimated: _hasAnimated,
            ),
          ),
        ],
      ),
    );
  }

  // -- Filter Bar --

  Widget _buildFilterBar(PulseColors c, AppLocalizations l) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // Classification pills
          _FilterPill(
            label: 'All',
            isActive: _classFilter == _ClassificationFilter.all,
            colors: c,
            onTap: () =>
                setState(() => _classFilter = _ClassificationFilter.all),
          ),
          const SizedBox(width: PulseSpacing.sm),
          _FilterPill(
            label: 'PoP',
            isActive: _classFilter == _ClassificationFilter.pop,
            colors: c,
            onTap: () =>
                setState(() => _classFilter = _ClassificationFilter.pop),
          ),
          const SizedBox(width: PulseSpacing.sm),
          _FilterPill(
            label: 'PoD',
            isActive: _classFilter == _ClassificationFilter.pod,
            colors: c,
            onTap: () =>
                setState(() => _classFilter = _ClassificationFilter.pod),
          ),
          const SizedBox(width: PulseSpacing.base),
          // View toggle (segmented)
          _SegmentedToggle(
            options: const ['Full matrix', 'Gaps only'],
            selectedIndex: _viewMode == _ViewMode.fullMatrix ? 0 : 1,
            colors: c,
            onChanged: (i) => setState(() {
              _viewMode =
                  i == 0 ? _ViewMode.fullMatrix : _ViewMode.gapsOnly;
            }),
          ),
          const Spacer(),
          // Search
          SizedBox(
            width: 200,
            height: 32,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: c.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search features...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: c.textTertiary,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: c.textTertiary,
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                filled: true,
                fillColor: c.surface2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: PulseSpacing.md,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PulseRadii.sm),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PulseRadii.sm),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PulseRadii.sm),
                  borderSide: BorderSide(color: c.accent, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Matrix Table --

  Widget _buildMatrixTable(PulseColors c, AppLocalizations l) {
    if (_viewMode == _ViewMode.gapsOnly) {
      return _buildGapsOnlyTable(c, l);
    }
    return _buildFullMatrixTable(c, l);
  }

  Widget _buildFullMatrixTable(PulseColors c, AppLocalizations l) {
    // Compute total table width
    final double featureColW = 240;
    final double oursColW = 120;
    final double compColW = 100;
    final double typeColW = 72;
    final double coverageColW = 88;
    final totalWidth = featureColW +
        oursColW +
        (_competitorNames.length * compColW) +
        typeColW +
        coverageColW;

    int globalRowIndex = 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.borderDefault),
        borderRadius: BorderRadius.circular(PulseRadii.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PulseRadii.md),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row (40px, surface2 bg, sticky)
                _buildTableHeaderRow(c, l, featureColW, oursColW, compColW,
                    typeColW, coverageColW),
                // Category sections
                ..._categories.map((cat) {
                  final filtered = _filterFeatures(cat.features);
                  if (filtered.isEmpty) return const SizedBox.shrink();

                  final hasGaps = filtered.any((f) => _featureMeta(f).isGap);
                  final isCollapsed =
                      _collapsedCategories.contains(cat.name);

                  final rows = <Widget>[];

                  // Category header (36px)
                  rows.add(_buildCategoryHeader(
                    c,
                    cat.name,
                    filtered.length,
                    hasGaps,
                    isCollapsed,
                    totalWidth,
                  ));

                  // Feature rows (52px each)
                  if (!isCollapsed) {
                    for (final f in filtered) {
                      rows.add(_buildFeatureRow(
                        f,
                        c,
                        l,
                        featureColW,
                        oursColW,
                        compColW,
                        typeColW,
                        coverageColW,
                        globalRowIndex,
                      ));
                      globalRowIndex++;
                    }
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: rows,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGapsOnlyTable(PulseColors c, AppLocalizations l) {
    // Collect all gap features across categories, flattened
    final gapFeatures = <_FeatureItem>[];
    for (final cat in _categories) {
      for (final f in cat.features) {
        final meta = _featureMeta(f);
        final isGapRow =
            meta.isGap || (meta.weHaveIt && meta.ourScore < meta.competitorAvg);
        if (!isGapRow) continue;

        // Apply search filter
        if (_searchQuery.isNotEmpty &&
            !f.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          continue;
        }
        // Apply classification filter
        if (_classFilter == _ClassificationFilter.pop && !meta.isPoP) continue;
        if (_classFilter == _ClassificationFilter.pod && meta.isPoP) continue;

        gapFeatures.add(f);
      }
    }

    // Sort by priority: gaps first (missing PoP), then low coverage
    gapFeatures.sort((a, b) {
      final aMeta = _featureMeta(a);
      final bMeta = _featureMeta(b);
      // PoP gaps first
      if (aMeta.isGap && !bMeta.isGap) return -1;
      if (!aMeta.isGap && bMeta.isGap) return 1;
      // Then by coverage asc
      return aMeta.coveragePercent.compareTo(bMeta.coveragePercent);
    });

    if (gapFeatures.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.borderDefault),
          borderRadius: BorderRadius.circular(PulseRadii.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(PulseSpacing.xxl),
          child: Center(
            child: Text(
              'No gaps found -- you are ahead!',
              style: PulseTypography.body(color: c.textSecondary),
            ),
          ),
        ),
      );
    }

    final double featureColW = 240;
    final double oursColW = 120;
    final double compColW = 100;
    final double priorityColW = 72;
    final double coverageColW = 88;
    final totalWidth = featureColW +
        oursColW +
        (_competitorNames.length * compColW) +
        priorityColW +
        coverageColW;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.borderDefault),
        borderRadius: BorderRadius.circular(PulseRadii.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PulseRadii.md),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildGapsHeaderRow(c, featureColW, oursColW, compColW,
                    priorityColW, coverageColW),
                // Rows
                ...gapFeatures.asMap().entries.map((entry) {
                  return _buildGapFeatureRow(
                    entry.value,
                    c,
                    featureColW,
                    oursColW,
                    compColW,
                    priorityColW,
                    coverageColW,
                    entry.key,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -- Table Header Row --

  Widget _buildTableHeaderRow(
    PulseColors c,
    AppLocalizations l,
    double featureW,
    double oursW,
    double compW,
    double typeW,
    double coverageW,
  ) {
    final headerStyle = GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: c.textTertiary,
      letterSpacing: 0.5,
    );

    return Container(
      height: 40,
      color: c.surface2,
      child: Row(
        children: [
          SizedBox(
            width: featureW,
            child: Padding(
              padding: const EdgeInsets.only(left: PulseSpacing.base),
              child: Text('FEATURE', style: headerStyle),
            ),
          ),
          Container(
            width: oursW,
            color: c.accent.withValues(alpha: 0.04),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: PulseSpacing.md),
            child: Text(
              'OURS',
              style: headerStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ..._competitorNames.map((name) => SizedBox(
                width: compW,
                child: Padding(
                  padding: const EdgeInsets.only(left: PulseSpacing.sm),
                  child: Text(
                    _shortenName(name).toUpperCase(),
                    style: headerStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )),
          SizedBox(
            width: typeW,
            child: Padding(
              padding: const EdgeInsets.only(left: PulseSpacing.sm),
              child: Text('TYPE', style: headerStyle),
            ),
          ),
          SizedBox(
            width: coverageW,
            child: Padding(
              padding: const EdgeInsets.only(left: PulseSpacing.sm),
              child: Text('COVERAGE', style: headerStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGapsHeaderRow(
    PulseColors c,
    double featureW,
    double oursW,
    double compW,
    double priorityW,
    double coverageW,
  ) {
    final headerStyle = GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: c.textTertiary,
      letterSpacing: 0.5,
    );

    return Container(
      height: 40,
      color: c.surface2,
      child: Row(
        children: [
          SizedBox(
            width: featureW,
            child: Padding(
              padding: const EdgeInsets.only(left: PulseSpacing.base),
              child: Text('FEATURE', style: headerStyle),
            ),
          ),
          Container(
            width: oursW,
            color: c.accent.withValues(alpha: 0.04),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: PulseSpacing.md),
            child: Text(
              'OURS',
              style: headerStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ..._competitorNames.map((name) => SizedBox(
                width: compW,
                child: Padding(
                  padding: const EdgeInsets.only(left: PulseSpacing.sm),
                  child: Text(
                    _shortenName(name).toUpperCase(),
                    style: headerStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )),
          SizedBox(
            width: priorityW,
            child: Padding(
              padding: const EdgeInsets.only(left: PulseSpacing.sm),
              child: Text('PRIORITY', style: headerStyle),
            ),
          ),
          SizedBox(
            width: coverageW,
            child: Padding(
              padding: const EdgeInsets.only(left: PulseSpacing.sm),
              child: Text('COVERAGE', style: headerStyle),
            ),
          ),
        ],
      ),
    );
  }

  // -- Category Header --

  Widget _buildCategoryHeader(
    PulseColors c,
    String name,
    int featureCount,
    bool hasGaps,
    bool isCollapsed,
    double totalWidth,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isCollapsed) {
            _collapsedCategories.remove(name);
          } else {
            _collapsedCategories.add(name);
          }
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 36,
          width: totalWidth,
          color: c.surface0,
          padding: const EdgeInsets.symmetric(horizontal: PulseSpacing.base),
          child: Row(
            children: [
              AnimatedRotation(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                turns: isCollapsed ? -0.25 : 0,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(width: PulseSpacing.sm),
              Text(
                _formatLabel(name).toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: PulseSpacing.sm),
              Text(
                '($featureCount features)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: c.textTertiary,
                ),
              ),
              if (hasGaps) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.danger,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // -- Feature Row (Full Matrix) --

  Widget _buildFeatureRow(
    _FeatureItem feature,
    PulseColors c,
    AppLocalizations l,
    double featureW,
    double oursW,
    double compW,
    double typeW,
    double coverageW,
    int rowIndex,
  ) {
    final meta = _featureMeta(feature);

    return _FeatureRowWidget(
      key: ValueKey('row_${feature.name}'),
      feature: feature,
      meta: meta,
      colors: c,
      competitorNames: _competitorNames,
      featureColWidth: featureW,
      oursColWidth: oursW,
      compColWidth: compW,
      typeColWidth: typeW,
      coverageColWidth: coverageW,
      rowIndex: rowIndex,
      hasAnimated: _hasAnimated,
      showType: true,
    );
  }

  // -- Gap Feature Row --

  Widget _buildGapFeatureRow(
    _FeatureItem feature,
    PulseColors c,
    double featureW,
    double oursW,
    double compW,
    double priorityW,
    double coverageW,
    int rowIndex,
  ) {
    final meta = _featureMeta(feature);

    return _GapFeatureRowWidget(
      key: ValueKey('gap_${feature.name}'),
      feature: feature,
      meta: meta,
      colors: c,
      competitorNames: _competitorNames,
      featureColWidth: featureW,
      oursColWidth: oursW,
      compColWidth: compW,
      priorityColWidth: priorityW,
      coverageColWidth: coverageW,
      rowIndex: rowIndex,
      hasAnimated: _hasAnimated,
    );
  }
}

// ============================================================================
// DATA TYPES
// ============================================================================

enum _Presence { yes, no, partial }

enum _ClassificationFilter { all, pop, pod }

enum _ViewMode { fullMatrix, gapsOnly }

class _FeatureCategory {
  final String name;
  final List<_FeatureItem> features;

  const _FeatureCategory({required this.name, required this.features});
}

class _FeatureItem {
  final String name;
  final _Presence ourPresence;
  final Map<String, _Presence> competitors;

  const _FeatureItem({
    required this.name,
    required this.ourPresence,
    required this.competitors,
  });
}

class _MatrixStats {
  final int totalFeatures;
  final int popCoveragePercent;
  final int ourAdvantages;
  final int criticalGaps;

  const _MatrixStats({
    required this.totalFeatures,
    required this.popCoveragePercent,
    required this.ourAdvantages,
    required this.criticalGaps,
  });
}

class _FeatureMeta {
  final int competitorCount;
  final int totalComps;
  final bool isPoP;
  final bool isGap;
  final bool isAdvantage;
  final bool weHaveIt;
  final int ourScore;
  final double competitorAvg;
  final int coveragePercent;

  const _FeatureMeta({
    required this.competitorCount,
    required this.totalComps,
    required this.isPoP,
    required this.isGap,
    required this.isAdvantage,
    required this.weHaveIt,
    required this.ourScore,
    required this.competitorAvg,
    required this.coveragePercent,
  });
}

// ============================================================================
// SUB-WIDGETS
// ============================================================================

// -- Summary Card --

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final Color? valueColor;
  final PulseColors colors;
  final int animationDelay;
  final bool hasAnimated;

  const _SummaryCard({
    required this.label,
    required this.value,
    this.suffix,
    this.valueColor,
    required this.colors,
    required this.animationDelay,
    required this.hasAnimated,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: hasAnimated ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: Duration(milliseconds: 300 + (animationDelay * 60)),
        offset: hasAnimated ? Offset.zero : const Offset(0, 0.1),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: BorderRadius.circular(PulseRadii.md),
            border: Border.all(color: c.borderDefault),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PulseSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: PulseSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: valueColor ?? c.textPrimary,
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: PulseSpacing.sm),
                      Text(
                        suffix!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: c.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -- Filter Pill --

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final PulseColors colors;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isActive,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isActive
                ? c.accent.withValues(alpha: 0.12)
                : c.surface2,
            borderRadius: BorderRadius.circular(PulseRadii.full),
            border: isActive
                ? Border.all(
                    color: c.accent.withValues(alpha: 0.3),
                    width: 0.5,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? c.accent : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// -- Segmented Toggle --

class _SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final PulseColors colors;
  final ValueChanged<int> onChanged;

  const _SegmentedToggle({
    required this.options,
    required this.selectedIndex,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(PulseRadii.sm),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.asMap().entries.map((entry) {
          final isSelected = entry.key == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(entry.key),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: PulseSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected ? c.surface1 : Colors.transparent,
                  borderRadius: BorderRadius.circular(PulseRadii.sm - 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color:
                        isSelected ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// -- Feature Row Widget (full matrix) --

class _FeatureRowWidget extends StatefulWidget {
  final _FeatureItem feature;
  final _FeatureMeta meta;
  final PulseColors colors;
  final List<String> competitorNames;
  final double featureColWidth;
  final double oursColWidth;
  final double compColWidth;
  final double typeColWidth;
  final double coverageColWidth;
  final int rowIndex;
  final bool hasAnimated;
  final bool showType;

  const _FeatureRowWidget({
    super.key,
    required this.feature,
    required this.meta,
    required this.colors,
    required this.competitorNames,
    required this.featureColWidth,
    required this.oursColWidth,
    required this.compColWidth,
    required this.typeColWidth,
    required this.coverageColWidth,
    required this.rowIndex,
    required this.hasAnimated,
    required this.showType,
  });

  @override
  State<_FeatureRowWidget> createState() => _FeatureRowWidgetState();
}

class _FeatureRowWidgetState extends State<_FeatureRowWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final meta = widget.meta;
    final f = widget.feature;

    // Row tint
    Color? rowTint;
    Color? leftBarColor;
    if (meta.isGap) {
      rowTint = c.danger.withValues(alpha: 0.03);
      leftBarColor = c.danger;
    } else if (meta.isAdvantage) {
      rowTint = c.trendUp.withValues(alpha: 0.03);
      leftBarColor = c.trendUp;
    }

    final hoverBg = _isHovered ? c.surface2 : null;
    final effectiveBg = hoverBg ?? rowTint;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 52,
        decoration: BoxDecoration(
          color: effectiveBg,
          border: Border(
            bottom: BorderSide(
              color: c.borderDefault.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            // Left bar indicator
            if (leftBarColor != null && !_isHovered)
              Container(width: 3, color: leftBarColor)
            else
              const SizedBox(width: 3),

            // Feature name (240px)
            SizedBox(
              width: widget.featureColWidth - 3,
              child: Padding(
                padding: const EdgeInsets.only(left: PulseSpacing.md),
                child: Text(
                  f.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Our product cell (120px, accent 4% bg)
            Container(
              width: widget.oursColWidth,
              color: c.accent.withValues(alpha: 0.04),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: PulseSpacing.md),
              child: _PresenceCell(
                presence: f.ourPresence,
                isOurs: true,
                isGap: meta.isGap && meta.isPoP,
                colors: c,
              ),
            ),

            // Competitor cells
            ...widget.competitorNames.map((name) {
              final presence = f.competitors[name] ?? _Presence.no;
              return SizedBox(
                width: widget.compColWidth,
                child: Padding(
                  padding: const EdgeInsets.only(left: PulseSpacing.sm),
                  child: _PresenceCell(
                    presence: presence,
                    isOurs: false,
                    isGap: false,
                    colors: c,
                  ),
                ),
              );
            }),

            // Type pill
            if (widget.showType)
              SizedBox(
                width: widget.typeColWidth,
                child: Padding(
                  padding: const EdgeInsets.only(left: PulseSpacing.sm),
                  child: _TypePill(isPoP: meta.isPoP, colors: c),
                ),
              ),

            // Coverage bar
            SizedBox(
              width: widget.coverageColWidth,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: PulseSpacing.sm, right: PulseSpacing.md),
                child: _CoverageBar(
                  percent: meta.coveragePercent,
                  colors: c,
                  animationDelay: widget.rowIndex * 20,
                  hasAnimated: widget.hasAnimated,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Gap Feature Row Widget --

class _GapFeatureRowWidget extends StatefulWidget {
  final _FeatureItem feature;
  final _FeatureMeta meta;
  final PulseColors colors;
  final List<String> competitorNames;
  final double featureColWidth;
  final double oursColWidth;
  final double compColWidth;
  final double priorityColWidth;
  final double coverageColWidth;
  final int rowIndex;
  final bool hasAnimated;

  const _GapFeatureRowWidget({
    super.key,
    required this.feature,
    required this.meta,
    required this.colors,
    required this.competitorNames,
    required this.featureColWidth,
    required this.oursColWidth,
    required this.compColWidth,
    required this.priorityColWidth,
    required this.coverageColWidth,
    required this.rowIndex,
    required this.hasAnimated,
  });

  @override
  State<_GapFeatureRowWidget> createState() => _GapFeatureRowWidgetState();
}

class _GapFeatureRowWidgetState extends State<_GapFeatureRowWidget> {
  bool _isHovered = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final meta = widget.meta;
    final f = widget.feature;

    final hoverBg = _isHovered ? c.surface2 : c.danger.withValues(alpha: 0.03);

    // Priority label
    String priority;
    Color priorityColor;
    if (meta.isGap) {
      priority = 'High';
      priorityColor = c.danger;
    } else {
      priority = 'Med';
      priorityColor = c.warning;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            color: hoverBg,
            border: Border(
              bottom: BorderSide(
                color: c.borderDefault.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    // Left bar
                    Container(width: 3, color: c.danger),

                    // Feature name
                    SizedBox(
                      width: widget.featureColWidth - 3,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: PulseSpacing.md),
                        child: Row(
                          children: [
                            Icon(
                              _isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 16,
                              color: c.textTertiary,
                            ),
                            const SizedBox(width: PulseSpacing.xs),
                            Expanded(
                              child: Text(
                                f.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: c.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Our product cell
                    Container(
                      width: widget.oursColWidth,
                      color: c.accent.withValues(alpha: 0.04),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: PulseSpacing.md),
                      child: _PresenceCell(
                        presence: f.ourPresence,
                        isOurs: true,
                        isGap: meta.isGap,
                        colors: c,
                      ),
                    ),

                    // Competitor cells
                    ...widget.competitorNames.map((name) {
                      final presence =
                          f.competitors[name] ?? _Presence.no;
                      return SizedBox(
                        width: widget.compColWidth,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: PulseSpacing.sm),
                          child: _PresenceCell(
                            presence: presence,
                            isOurs: false,
                            isGap: false,
                            colors: c,
                          ),
                        ),
                      );
                    }),

                    // Priority pill
                    SizedBox(
                      width: widget.priorityColWidth,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: PulseSpacing.sm),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(PulseRadii.sm),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            child: Text(
                              priority,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Coverage
                    SizedBox(
                      width: widget.coverageColWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: PulseSpacing.sm, right: PulseSpacing.md),
                        child: _CoverageBar(
                          percent: meta.coveragePercent,
                          colors: c,
                          animationDelay: widget.rowIndex * 20,
                          hasAnimated: widget.hasAnimated,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded detail
              if (_isExpanded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    PulseSpacing.xl,
                    PulseSpacing.md,
                    PulseSpacing.xl,
                    PulseSpacing.base,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.isGap
                            ? 'This is a Point of Parity feature that competitors have but we lack. Closing this gap is critical for competitive positioning.'
                            : 'Our implementation scores below competitor average. Consider improving this feature to match or exceed market standards.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: c.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: PulseSpacing.sm),
                      Text(
                        meta.isGap
                            ? 'Recommendation: Prioritize implementation to achieve parity.'
                            : 'Recommendation: Enhance existing implementation to close the quality gap.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: c.accent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Presence Cell --

class _PresenceCell extends StatelessWidget {
  final _Presence presence;
  final bool isOurs;
  final bool isGap;
  final PulseColors colors;

  const _PresenceCell({
    required this.presence,
    required this.isOurs,
    required this.isGap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    int score;
    Color dotColor;
    bool filled;

    switch (presence) {
      case _Presence.yes:
        score = 4;
        dotColor = isOurs ? c.accent : c.textPrimary;
        filled = true;
      case _Presence.partial:
        score = 2;
        dotColor = isOurs ? c.accent : c.textPrimary;
        filled = true;
      case _Presence.no:
        score = 0;
        // PoP gap absent: circle outline in danger 60%
        dotColor = (isOurs && isGap)
            ? c.danger.withValues(alpha: 0.6)
            : c.textTertiary.withValues(alpha: isOurs ? 0.4 : 0.3);
        filled = false;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          filled ? Icons.circle : Icons.circle_outlined,
          size: 10,
          color: dotColor,
        ),
        if (filled) ...[
          const SizedBox(width: 6),
          Text(
            '$score',
            style: isOurs
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    color: c.textPrimary,
                  )
                : GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: c.textSecondary,
                  ),
          ),
        ],
      ],
    );
  }
}

// -- Type Pill --

class _TypePill extends StatelessWidget {
  final bool isPoP;
  final PulseColors colors;

  const _TypePill({
    required this.isPoP,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final text = isPoP ? 'PoP' : 'PoD';
    final bgColor =
        isPoP ? c.surface2 : c.accent.withValues(alpha: 0.1);
    final textColor = isPoP ? c.textSecondary : c.accent;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(PulseRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// -- Coverage Bar --

class _CoverageBar extends StatefulWidget {
  final int percent;
  final PulseColors colors;
  final int animationDelay;
  final bool hasAnimated;

  const _CoverageBar({
    required this.percent,
    required this.colors,
    required this.animationDelay,
    required this.hasAnimated,
  });

  @override
  State<_CoverageBar> createState() => _CoverageBarState();
}

class _CoverageBarState extends State<_CoverageBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _maybeAnimate();
  }

  @override
  void didUpdateWidget(_CoverageBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasAnimated && !_started) {
      _maybeAnimate();
    }
  }

  void _maybeAnimate() {
    if (widget.hasAnimated && !_started) {
      _started = true;
      Future.delayed(Duration(milliseconds: widget.animationDelay), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final percent = widget.percent;

    // Bar fill color
    Color barColor;
    if (percent >= 80) {
      barColor = c.textTertiary;
    } else if (percent >= 40) {
      barColor = c.accent;
    } else {
      barColor = c.trendUp;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$percent%',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 64,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: DecoratedBox(
              decoration: BoxDecoration(color: c.surface2),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        (percent / 100) * _animation.value,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
