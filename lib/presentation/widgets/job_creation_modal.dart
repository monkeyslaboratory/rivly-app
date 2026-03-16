import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/colors.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../data/repositories/job_repository.dart';

// ---------------------------------------------------------------------------
// Helper model for competitor entries used within the wizard
// ---------------------------------------------------------------------------
class _CompetitorEntry {
  final String name;
  final String url;
  final int relevanceScore;
  bool isSelected;
  String accessStatus; // 'checking', 'accessible', 'blocked', 'geo_restricted'

  _CompetitorEntry({
    required this.name,
    required this.url,
    required this.relevanceScore,
    this.isSelected = true,
    this.accessStatus = 'checking',
  });
}

// ---------------------------------------------------------------------------
// Shimmer / pulsing placeholder widget
// ---------------------------------------------------------------------------
class _ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerBlock({
    this.width = double.infinity,
    this.height = 16,
  });

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isDark
                ? Colors.white.withValues(alpha: _animation.value * 0.12)
                : Colors.black.withValues(alpha: _animation.value * 0.08),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsing dot loader
// ---------------------------------------------------------------------------
class _PulsingDots extends StatefulWidget {
  final String message;
  const _PulsingDots({required this.message});

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final delay = i * 0.2;
                  final t =
                      ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
                  final scale = 0.5 + 0.5 * sin(t * pi);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentSecondary
                          .withValues(alpha: 0.4 + 0.6 * scale),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            widget.message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main Modal Widget
// ---------------------------------------------------------------------------
class JobCreationModal extends StatefulWidget {
  final VoidCallback? onJobCreated;

  const JobCreationModal({super.key, this.onJobCreated});

  static Future<void> show(BuildContext context,
      {VoidCallback? onJobCreated}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => JobCreationModal(onJobCreated: onJobCreated),
    );
  }

  @override
  State<JobCreationModal> createState() => _JobCreationModalState();
}

class _JobCreationModalState extends State<JobCreationModal>
    with TickerProviderStateMixin {
  final JobRepository _jobRepository = JobRepository();

  // ---- Controllers ----
  final _productUrlController = TextEditingController();
  final _competitorsController = TextEditingController();

  // ---- Animation ----
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _slidingForward = true;

  // ---- Step tracking ----
  int _currentStep = 1;
  bool _isProcessing = false;
  String? _processingMessage;
  String? _errorMessage;

  // ---- Success state ----
  final bool _showSuccess = false;
  late AnimationController _successController;
  late Animation<double> _successScale;

  // ---- Step 1: Product URL ----
  String? _productUrl;
  String? _productName;
  String? _productIndustry;
  bool _productAnalyzed = false;

  // ---- Step 2: Competitors ----
  bool _autoFindCompetitors = true;
  List<_CompetitorEntry> _competitors = [];
  bool _competitorsDiscovered = false;

  // ---- Step 3: Access Check ----
  final Map<String, String> _accessStatuses = {};
  bool _accessCheckDone = false;

  // ---- Step 4: Schedule ----
  String _scheduleType = 'once';
  int? _scheduleDayOfWeek;
  int? _scheduleDayOfMonth;
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 9, minute: 0);

  // ---- Step 5: Device ----
  String _deviceMode = 'desktop';

  // ---- Step titles ----
  List<String> _stepTitles(AppLocalizations l) => [
    l.productUrlStep,
    l.competitorsStep,
    l.accessCheck,
    l.schedule,
    l.device,
    l.reviewLaunch,
  ];

  List<String> _stepSubtitles(AppLocalizations l) => [
    l.enterProductUrl,
    l.chooseCompetitiveLandscape,
    l.verifyingAccess,
    l.setAnalysisCadence,
    l.chooseDevices,
    l.confirmLaunch,
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    ));

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _productUrlController.dispose();
    _competitorsController.dispose();
    _slideController.dispose();
    _successController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Navigation
  // ------------------------------------------------------------------
  void _goToStep(int step) {
    if (step < 1 || step > 6 || step == _currentStep) return;
    setState(() {
      _slidingForward = step > _currentStep;
      _slideAnimation = Tween<Offset>(
        begin: Offset(_slidingForward ? 1.0 : -1.0, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeInOutCubic,
      ));
      _currentStep = step;
      _errorMessage = null;
    });
    _slideController.forward(from: 0);
  }

  void _next() => _goToStep(_currentStep + 1);
  void _back() => _goToStep(_currentStep - 1);

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  String _extractProductName(String url) {
    final domain = _extractDomain(url);
    final parts = domain.split('.');
    if (parts.isEmpty) return domain;
    final name = parts.first;
    return name[0].toUpperCase() + name.substring(1);
  }

  List<_CompetitorEntry> _getSelectedCompetitors() {
    return _competitors.where((c) => c.isSelected).toList();
  }

  String _scheduleFrequencyApiValue() {
    switch (_scheduleType) {
      case 'weekly':
        return 'weekly';
      case 'biweekly':
        return 'biweekly';
      case 'monthly':
        return 'monthly';
      default:
        return 'once';
    }
  }

  // ------------------------------------------------------------------
  // Step 1 - Analyze product
  // ------------------------------------------------------------------
  Future<void> _analyzeProduct() async {
    final url = _productUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Please enter a URL');
      return;
    }
    final fullUrl = url.startsWith('http') ? url : 'https://$url';
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Analyzing your product...';
      _errorMessage = null;
    });

    try {
      final result = await _jobRepository.analyzeProduct(fullUrl);
      if (!mounted) return;
      setState(() {
        _productUrl = fullUrl;
        _productName = result['name'] as String? ?? _extractProductName(url);
        _productIndustry = result['industry'] as String? ?? 'SaaS';
        _productAnalyzed = true;
        _isProcessing = false;
        _processingMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Fallback to domain extraction
        _productUrl = fullUrl;
        _productName = _extractProductName(url);
        _productIndustry = 'SaaS';
        _productAnalyzed = true;
        _isProcessing = false;
        _processingMessage = null;
      });
    }
  }

  // ------------------------------------------------------------------
  // Step 2 - Discover competitors
  // ------------------------------------------------------------------
  Future<void> _discoverCompetitors() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Discovering competitors with AI...';
    });

    try {
      final results = await _jobRepository.discoverCompetitorsRaw(
        productUrl: _productUrl ?? '',
      );
      if (!mounted) return;
      setState(() {
        _competitors = results.map((c) => _CompetitorEntry(
          name: c['name'] as String? ?? '',
          url: c['url'] as String? ?? '',
          relevanceScore: (c['relevance_score'] as num?)?.toInt() ?? 85,
          isSelected: true,
          accessStatus: 'checking',
        )).toList();
        _competitorsDiscovered = true;
        _isProcessing = false;
        _processingMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _processingMessage = null;
        _errorMessage = 'Failed to discover competitors. Try manual entry.';
        _autoFindCompetitors = false;
      });
    }
  }

  // ------------------------------------------------------------------
  // Step 4 - Access check
  // ------------------------------------------------------------------
  Future<void> _runAccessCheck() async {
    final selected = _getSelectedCompetitors();
    if (selected.isEmpty) {
      setState(() => _accessCheckDone = true);
      return;
    }

    // Set all to checking
    for (final c in selected) {
      setState(() {
        _accessStatuses[c.url] = 'checking';
      });
    }

    try {
      final urls = selected.map((c) => c.url).toList();
      final response = await DioClient().post(
        ApiConstants.checkAccess,
        data: {'urls': urls},
      );

      if (!mounted) return;
      final results = response.data as List<dynamic>;
      for (final r in results) {
        final url = r['url'] as String;
        final status = r['status'] as String;
        setState(() {
          _accessStatuses[url] = status;
          for (final c in _competitors) {
            if (c.url == url) c.accessStatus = status;
          }
        });
      }
    } catch (e) {
      // Fallback: mark all as accessible
      for (final c in selected) {
        setState(() {
          _accessStatuses[c.url] = 'accessible';
          c.accessStatus = 'accessible';
        });
      }
    }

    setState(() => _accessCheckDone = true);
  }

  // ------------------------------------------------------------------
  // Step 7 - Submit
  // ------------------------------------------------------------------
  Future<void> _handleLaunch() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Creating analysis...';
      _errorMessage = null;
    });

    var productUrl = _productUrl ?? _productUrlController.text.trim();
    if (!productUrl.startsWith('http://') &&
        !productUrl.startsWith('https://')) {
      productUrl = 'https://$productUrl';
    }

    final jobName = '${_productName ?? _extractProductName(productUrl)} vs Competitors';
    final selectedCompetitors = _getSelectedCompetitors();

    try {
      final job = await _jobRepository.createJob(
        name: jobName,
        productUrl: productUrl,
        areas: [],
        deviceType: _deviceMode == 'both' ? 'both' : _deviceMode,
        scheduleFrequency: _scheduleFrequencyApiValue(),
      );

      for (final comp in selectedCompetitors) {
        try {
          await _jobRepository.addCompetitor(
            job.id,
            comp.name,
            comp.url,
          );
        } catch (_) {
          // continue
        }
      }

      final runResponse = await _jobRepository.triggerRun(job.id);

      if (!mounted) return;

      final runId = runResponse['id'] as String;
      Navigator.of(context).pop();
      widget.onJobCreated?.call();
      GoRouter.of(context).go('/runs/$runId');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgElevated : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: _showSuccess ? _buildSuccessState(isDark) : _buildWizard(isDark, borderColor),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Success overlay
  // ------------------------------------------------------------------
  Widget _buildSuccessState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _successScale,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).analysisLaunched,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).analysisRunning,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Main wizard container
  // ------------------------------------------------------------------
  Widget _buildWizard(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 20),
            _buildStepIndicator(isDark),
            const SizedBox(height: 8),
            // Step title + subtitle
            Text(
              _stepTitles(AppLocalizations.of(context))[_currentStep - 1],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _stepSubtitles(AppLocalizations.of(context))[_currentStep - 1],
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 20),
            // Error message
            if (_errorMessage != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 12),
            ],
            // Step content with slide animation
            ClipRect(
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildCurrentStep(isDark, borderColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Header with gradient bar and close button
  // ------------------------------------------------------------------
  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.accentPrimary, AppColors.accentSecondary],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppLocalizations.of(context).newAnalysis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Step indicator (horizontal dots)
  // ------------------------------------------------------------------
  Widget _buildStepIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final step = i + 1;
        final isCompleted = step < _currentStep;
        final isActive = step == _currentStep;
        final isUpcoming = step > _currentStep;

        Color bg;
        Widget child;

        if (isCompleted) {
          bg = AppColors.accentSecondary;
          child =
              const Icon(Icons.check_rounded, size: 12, color: Colors.white);
        } else if (isActive) {
          bg = isDark ? Colors.white : Colors.black;
          child = Text(
            '$step',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.black : Colors.white,
            ),
          );
        } else {
          bg = Colors.transparent;
          child = Text(
            '$step',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          );
        }

        return Row(
          children: [
            if (i > 0)
              Container(
                width: 24,
                height: 1.5,
                color: isCompleted
                    ? AppColors.accentSecondary.withValues(alpha: 0.5)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08)),
              ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                border: isUpcoming
                    ? Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.15),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Center(child: child),
            ),
          ],
        );
      }),
    );
  }

  // ------------------------------------------------------------------
  // Error banner
  // ------------------------------------------------------------------
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Route to current step builder
  // ------------------------------------------------------------------
  Widget _buildCurrentStep(bool isDark, Color borderColor) {
    switch (_currentStep) {
      case 1:
        return _buildStep1(isDark, borderColor);
      case 2:
        return _buildStep2(isDark, borderColor);
      case 3:
        return _buildStep4(isDark, borderColor);
      case 4:
        return _buildStep5(isDark, borderColor);
      case 5:
        return _buildStep6(isDark, borderColor);
      case 6:
        return _buildStep7(isDark, borderColor);
      default:
        return const SizedBox.shrink();
    }
  }

  // ==================================================================
  // STEP 1 – Product URL
  // ==================================================================
  Widget _buildStep1(bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // URL input + Analyze button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _productUrlController,
                decoration: InputDecoration(
                  hintText: 'https://yourproduct.com',
                  prefixIcon: const Icon(Icons.link, size: 20),
                  enabled: !_isProcessing && !_productAnalyzed,
                  isDense: true,
                ),
                keyboardType: TextInputType.url,
                onSubmitted: (_) {
                  if (!_productAnalyzed && !_isProcessing) _analyzeProduct();
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed:
                    _isProcessing || _productAnalyzed ? null : _analyzeProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  disabledBackgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(AppLocalizations.of(context).analyze,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Loading / result
        if (_isProcessing) ...[
          _buildShimmerCard(isDark, borderColor),
        ] else if (_productAnalyzed) ...[
          _buildProductResult(isDark, borderColor),
          const SizedBox(height: 20),
          _buildContinueButton(isDark, onPressed: _next),
        ],
      ],
    );
  }

  Widget _buildShimmerCard(bool isDark, Color borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PulsingDots(message: _processingMessage ?? 'Processing...'),
          const SizedBox(height: 12),
          const _ShimmerBlock(width: 180, height: 14),
          const SizedBox(height: 10),
          const _ShimmerBlock(width: 120, height: 12),
          const SizedBox(height: 10),
          const _ShimmerBlock(width: 200, height: 12),
        ],
      ),
    );
  }

  Widget _buildProductResult(bool isDark, Color borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
        color: AppColors.success.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.accentSecondary.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(
                (_productName ?? 'P')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _productName ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _productIndustry ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _extractDomain(_productUrl ?? ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _productAnalyzed = false;
                _productName = null;
                _productIndustry = null;
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppLocalizations.of(context).edit, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // STEP 2 – Competitors
  // ==================================================================
  Widget _buildStep2(bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.02),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: _autoFindCompetitors
                    ? AppColors.accentSecondary
                    : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).findWithAi,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Switch(
                value: _autoFindCompetitors,
                onChanged: (v) {
                  setState(() {
                    _autoFindCompetitors = v;
                    if (!v) {
                      _competitorsDiscovered = false;
                      _competitors = [];
                    }
                  });
                },
                activeTrackColor: AppColors.accentSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_autoFindCompetitors) ...[
          if (!_competitorsDiscovered && !_isProcessing)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _discoverCompetitors,
                icon: const Icon(Icons.search, size: 18),
                label: Text(AppLocalizations.of(context).discoverCompetitors),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentSecondary,
                  side: const BorderSide(color: AppColors.accentSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          if (_isProcessing) _buildShimmerCard(isDark, borderColor),
          if (_competitorsDiscovered && !_isProcessing)
            ..._competitors.map(
                (c) => _buildCompetitorCard(c, isDark, borderColor)),
        ] else ...[
          TextField(
            controller: _competitorsController,
            maxLines: 5,
            minLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'https://competitor1.com\nhttps://competitor2.com\nhttps://competitor3.com',
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildNavigationRow(isDark),
      ],
    );
  }

  Widget _buildCompetitorCard(
      _CompetitorEntry c, bool isDark, Color borderColor) {
    final statusColor = c.accessStatus == 'accessible'
        ? AppColors.success
        : c.accessStatus == 'blocked'
            ? AppColors.error
            : c.accessStatus == 'checking'
                ? AppColors.warning
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: c.isSelected
              ? AppColors.accentSecondary.withValues(alpha: 0.4)
              : borderColor,
        ),
        color: c.isSelected
            ? AppColors.accentSecondary.withValues(alpha: 0.04)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: c.isSelected,
              onChanged: (v) {
                setState(() => c.isSelected = v ?? true);
              },
              activeColor: AppColors.accentSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  c.url,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Relevance badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${c.relevanceScore}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accentPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Access status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // STEP 4 – Access Check (displayed as step 3)
  // ==================================================================
  Widget _buildStep4(bool isDark, Color borderColor) {
    final selected = _getSelectedCompetitors();

    // Auto-trigger access check when entering step 4
    if (_accessStatuses.isEmpty && !_accessCheckDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runAccessCheck());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              AppLocalizations.of(context).noCompetitorsSelected,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          )
        else
          ...selected.map((c) {
            final status = _accessStatuses[c.url] ?? 'checking';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.02),
              ),
              child: Row(
                children: [
                  _buildAccessIcon(status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          c.url,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _accessLabel(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accessColor(status),
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildBackButton(isDark),
            const SizedBox(width: 10),
            Expanded(
              child: _buildContinueButton(isDark, onPressed: _next),
            ),
            if (!_accessCheckDone) ...[
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  setState(() => _accessCheckDone = true);
                  _next();
                },
                child: Text(
                  AppLocalizations.of(context).skip,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAccessIcon(String status) {
    if (status == 'checking') {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor:
              AlwaysStoppedAnimation<Color>(AppColors.accentSecondary),
        ),
      );
    }
    if (status == 'accessible') {
      return const Icon(Icons.check_circle, color: AppColors.success, size: 20);
    }
    if (status == 'blocked') {
      return const Icon(Icons.cancel, color: AppColors.error, size: 20);
    }
    // geo_restricted
    return const Icon(Icons.warning_amber_rounded,
        color: AppColors.warning, size: 20);
  }

  String _accessLabel(String status) {
    final l = AppLocalizations.of(context);
    switch (status) {
      case 'accessible':
        return l.accessible;
      case 'blocked':
        return l.blocked;
      case 'geo_restricted':
        return l.geoRestricted;
      default:
        return l.checking;
    }
  }

  Color _accessColor(String status) {
    switch (status) {
      case 'accessible':
        return AppColors.success;
      case 'blocked':
        return AppColors.error;
      case 'geo_restricted':
        return AppColors.warning;
      default:
        return AppColors.accentSecondary;
    }
  }

  // ==================================================================
  // STEP 5 – Schedule
  // ==================================================================
  Widget _buildStep5(bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Radio options
        ..._buildScheduleRadios(isDark, borderColor),
        const SizedBox(height: 16),

        // Day-of-week picker for weekly / biweekly
        if (_scheduleType == 'weekly' || _scheduleType == 'biweekly') ...[
          _buildFieldLabel(AppLocalizations.of(context).dayOfWeek, isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(7, (i) {
              final labels = AppLocalizations.of(context).weekDays;
              final isSelected = _scheduleDayOfWeek == i;
              return ChoiceChip(
                label: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _scheduleDayOfWeek = i);
                },
                selectedColor: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black,
                labelStyle: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : null,
                ),
                backgroundColor:
                    isDark ? AppColors.darkBgSubtle : AppColors.lightBgSubtle,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: borderColor),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],

        // Day-of-month picker for monthly
        if (_scheduleType == 'monthly') ...[
          _buildFieldLabel(AppLocalizations.of(context).dayOfMonth, isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(28, (i) {
              final day = i + 1;
              final isSelected = _scheduleDayOfMonth == day;
              return GestureDetector(
                onTap: () => setState(() => _scheduleDayOfMonth = day),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark
                            ? AppColors.darkBgSubtle
                            : AppColors.lightBgSubtle),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],

        // Time picker
        if (_scheduleType != 'once') ...[
          _buildFieldLabel(AppLocalizations.of(context).time, isDark),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _scheduleTime,
              );
              if (picked != null) {
                setState(() => _scheduleTime = picked);
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.02),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                  const SizedBox(width: 10),
                  Text(
                    _scheduleTime.format(context),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        _buildNavigationRow(isDark),
      ],
    );
  }

  List<Widget> _buildScheduleRadios(bool isDark, Color borderColor) {
    final l = AppLocalizations.of(context);
    final options = [
      ('once', l.oneTime, l.runOnce),
      ('weekly', l.weekly, l.repeatWeekly),
      ('biweekly', l.biweekly, l.repeatBiweekly),
      ('monthly', l.monthly, l.repeatMonthly),
    ];

    return options.map((opt) {
      final isSelected = _scheduleType == opt.$1;
      return GestureDetector(
        onTap: () => setState(() => _scheduleType = opt.$1),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3))
                  : borderColor,
            ),
            color: isSelected
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03))
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.2)),
                    width: isSelected ? 5 : 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.$2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      opt.$3,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ==================================================================
  // STEP 6 – Device
  // ==================================================================
  Widget _buildStep6(bool isDark, Color borderColor) {
    final l = AppLocalizations.of(context);
    final devices = [
      ('desktop', Icons.desktop_windows_outlined, l.desktopOnly,
          l.desktopViewport),
      ('mobile', Icons.phone_iphone_outlined, l.mobileOnly,
          l.mobileViewport),
      ('both', Icons.devices_outlined, l.both,
          l.bothViewports),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...devices.map((d) {
          final isSelected = _deviceMode == d.$1;
          return GestureDetector(
            onTap: () => setState(() => _deviceMode = d.$1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3))
                      : borderColor,
                  width: isSelected ? 1.5 : 1,
                ),
                color: isSelected
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03))
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isSelected
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.06))
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03)),
                    ),
                    child: Icon(
                      d.$2,
                      size: 22,
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.$3,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          d.$4,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 22),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _buildNavigationRow(isDark),
      ],
    );
  }

  // ==================================================================
  // STEP 7 – Review & Launch
  // ==================================================================
  Widget _buildStep7(bool isDark, Color borderColor) {
    final l = AppLocalizations.of(context);
    final selectedCompetitors = _getSelectedCompetitors();
    final scheduleLabel = _scheduleType == 'once'
        ? l.oneTime
        : _scheduleType == 'weekly'
            ? l.weekly
            : _scheduleType == 'biweekly'
                ? l.biweekly
                : l.monthly;
    final deviceLabel = _deviceMode == 'both'
        ? l.desktopAndMobile
        : _deviceMode == 'desktop'
            ? l.desktopOnly
            : l.mobileOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.02),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(
                isDark,
                icon: Icons.link,
                label: l.product,
                value: _productName ?? _extractDomain(_productUrl ?? ''),
                subtitle: _extractDomain(_productUrl ?? ''),
              ),
              _buildSummaryDivider(borderColor),
              _buildSummaryRow(
                isDark,
                icon: Icons.people_outline,
                label: l.competitorsStep,
                value: l.nSelected(selectedCompetitors.length),
              ),
              _buildSummaryDivider(borderColor),
              _buildSummaryRow(
                isDark,
                icon: Icons.analytics_outlined,
                label: l.analysis,
                value: l.fullAutoAnalysis,
              ),
              _buildSummaryDivider(borderColor),
              _buildSummaryRow(
                isDark,
                icon: Icons.schedule,
                label: l.schedule,
                value: scheduleLabel,
              ),
              _buildSummaryDivider(borderColor),
              _buildSummaryRow(
                isDark,
                icon: Icons.devices,
                label: l.device,
                value: deviceLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildBackButton(isDark),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleLaunch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    disabledBackgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rocket_launch_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l.launchAnalysis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
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
    );
  }

  Widget _buildSummaryDivider(Color borderColor) {
    return Divider(height: 1, color: borderColor);
  }

  // ==================================================================
  // Shared navigation widgets
  // ==================================================================
  Widget _buildNavigationRow(bool isDark) {
    return Row(
      children: [
        _buildBackButton(isDark),
        const SizedBox(width: 10),
        Expanded(
          child: _buildContinueButton(isDark, onPressed: () {
            // On step 2, parse manual competitors if auto-find is off
            if (_currentStep == 2 && !_autoFindCompetitors) {
              _parseManualCompetitors();
            }
            _next();
          }),
        ),
      ],
    );
  }

  void _parseManualCompetitors() {
    final lines = _competitorsController.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    _competitors = lines.map((url) {
      final fullUrl = url.startsWith('http') ? url : 'https://$url';
      return _CompetitorEntry(
        name: _extractDomain(url),
        url: fullUrl,
        relevanceScore: 100,
        isSelected: true,
      );
    }).toList();
  }

  Widget _buildBackButton(bool isDark) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _back,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back_ios_new, size: 14),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context).back, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(bool isDark, {required VoidCallback onPressed}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context).next, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }
}
