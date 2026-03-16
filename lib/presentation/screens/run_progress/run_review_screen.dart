import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../data/repositories/run_repository.dart';
import '../../widgets/common/rivly_button.dart';

class RunReviewScreen extends StatefulWidget {
  final String runId;

  const RunReviewScreen({super.key, required this.runId});

  @override
  State<RunReviewScreen> createState() => _RunReviewScreenState();
}

class _RunReviewScreenState extends State<RunReviewScreen> {
  final RunRepository _runRepository = RunRepository();
  final DioClient _dioClient = DioClient();

  bool _isLoading = true;
  bool _isApproving = false;
  bool _isAddingPage = false;
  String? _error;
  List<_ScreenshotEntry> _screenshots = [];
  final TextEditingController _urlController = TextEditingController();
  String? _competitorName;

  @override
  void initState() {
    super.initState();
    _loadRunData();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadRunData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _runRepository.getRawRun(widget.runId);
      final screenshots = (data['screenshots'] as List<dynamic>?) ?? [];

      // Try to get competitor name from job data
      final jobData = data['job_detail'] as Map<String, dynamic>?;
      final competitors = (jobData?['competitors'] as List<dynamic>?) ?? [];
      if (competitors.isNotEmpty) {
        final first = competitors[0] as Map<String, dynamic>;
        _competitorName = first['url'] as String? ?? first['name'] as String?;
      }

      setState(() {
        _screenshots = screenshots.map((s) {
          final shot = s as Map<String, dynamic>;
          final status = shot['status'] as String? ?? 'unknown';
          return _ScreenshotEntry(
            id: shot['id'] as String,
            pageName: shot['page_name'] as String? ?? 'Unknown',
            pageUrl: shot['page_url'] as String? ?? '',
            status: status,
            width: (shot['width'] as num?)?.toInt(),
            height: (shot['height'] as num?)?.toInt(),
            selected: status == 'success',
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load run data. Please try again.';
        _isLoading = false;
      });
    }
  }

  int get _selectedCount => _screenshots.where((s) => s.selected).length;

  void _toggleScreenshot(int index) {
    setState(() {
      _screenshots[index] = _screenshots[index].copyWith(
        selected: !_screenshots[index].selected,
      );
    });
  }

  Future<void> _addCustomPage() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Basic URL validation
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid URL starting with http:// or https://'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isAddingPage = true);

    try {
      final added = await _runRepository.addPages(widget.runId, [url]);
      setState(() {
        for (final shot in added) {
          final status = shot['status'] as String? ?? 'unknown';
          _screenshots.add(_ScreenshotEntry(
            id: shot['id'] as String,
            pageName: shot['page_name'] as String? ?? 'Custom page',
            pageUrl: shot['page_url'] as String? ?? url,
            status: status,
            width: (shot['width'] as num?)?.toInt(),
            height: (shot['height'] as num?)?.toInt(),
            selected: status == 'success',
          ));
        }
        _urlController.clear();
        _isAddingPage = false;
      });
    } catch (e) {
      setState(() => _isAddingPage = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add page: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _approveAndStart() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one page to analyze.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isApproving = true);

    try {
      final removeIds = _screenshots
          .where((s) => !s.selected)
          .map((s) => s.id)
          .toList();

      await _runRepository.approveRun(widget.runId, removeIds: removeIds);

      if (!mounted) return;
      context.go('/runs/${widget.runId}');
    } catch (e) {
      setState(() => _isApproving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start analysis: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showFullScreenshot(BuildContext context, _ScreenshotEntry shot) {
    final token = _dioClient.dio.options.headers['Authorization'];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.darkBgElevated,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shot.pageName,
                          style: const TextStyle(
                            color: AppColors.darkTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shot.pageUrl,
                          style: const TextStyle(
                            color: AppColors.darkTextMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.darkTextPrimary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            // Screenshot
            Flexible(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      ApiConstants.screenshotImage(shot.id),
                      headers: token != null
                          ? {'Authorization': token.toString()}
                          : null,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          height: 300,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: AppColors.darkTextMuted),
                                SizedBox(height: 8),
                                Text(
                                  'Failed to load screenshot',
                                  style: TextStyle(color: AppColors.darkTextMuted),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/runs/${widget.runId}'),
        ),
        title: const Text('Review Pages'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(context)
              : _buildContent(context, isDark),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error!),
          const SizedBox(height: 24),
          RivlyButton(
            label: 'Retry',
            onPressed: _loadRunData,
            variant: RivlyButtonVariant.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    final successCount = _screenshots.where((s) => s.status == 'success').length;
    final totalCount = _screenshots.length;

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            children: [
              // Header info
              _buildHeaderCard(context, isDark, successCount, totalCount),
              const SizedBox(height: 20),

              // Screenshot list
              ..._buildScreenshotCards(context, isDark),

              const SizedBox(height: 24),

              // Add custom page section
              _buildAddPageSection(context, isDark),

              // Extra bottom padding for the bottom bar
              const SizedBox(height: 100),
            ],
          ),
        ),

        // Bottom action bar
        _buildBottomBar(context, isDark),
      ],
    );
  }

  Widget _buildHeaderCard(
      BuildContext context, bool isDark, int successCount, int totalCount) {
    final siteName = _competitorName ?? 'the site';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentSecondary.withValues(alpha: 0.08),
            AppColors.accentPrimary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  color: AppColors.accentSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We found $totalCount pages',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$successCount captured successfully',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Review the discovered pages on $siteName. '
            'Uncheck any pages you want to exclude, or add custom URLs below. '
            'Then start AI analysis.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildScreenshotCards(BuildContext context, bool isDark) {
    return List.generate(_screenshots.length, (index) {
      final shot = _screenshots[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ScreenshotCard(
          entry: shot,
          isDark: isDark,
          dioClient: _dioClient,
          onToggle: () => _toggleScreenshot(index),
          onTap: () => _showFullScreenshot(context, shot),
        ),
      );
    });
  }

  Widget _buildAddPageSection(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
        borderRadius: BorderRadius.circular(16),
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
            children: [
              Icon(
                Icons.add_link,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Add a custom page',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Add a specific URL that wasn\'t discovered automatically.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  enabled: !_isAddingPage,
                  decoration: InputDecoration(
                    hintText: 'https://example.com/page',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkBgElevated
                        : AppColors.lightBgElevated,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.accentSecondary,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.link, size: 18),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCustomPage(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isAddingPage ? null : _addCustomPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentSecondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _isAddingPage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Selected count
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedCount page${_selectedCount == 1 ? '' : 's'} selected',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (_selectedCount == 0)
                    Text(
                      'Select at least one page',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Start Analysis button
            RivlyButton(
              label: 'Start Analysis',
              onPressed: _selectedCount > 0 && !_isApproving
                  ? _approveAndStart
                  : null,
              isLoading: _isApproving,
              icon: Icons.auto_awesome,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screenshot card widget
// ---------------------------------------------------------------------------
class _ScreenshotCard extends StatelessWidget {
  final _ScreenshotEntry entry;
  final bool isDark;
  final DioClient dioClient;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _ScreenshotCard({
    required this.entry,
    required this.isDark,
    required this.dioClient,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = entry.status == 'success';
    final borderColor = !isSuccess
        ? AppColors.warning.withValues(alpha: 0.4)
        : entry.selected
            ? AppColors.accentSecondary.withValues(alpha: 0.3)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06));

    final bgColor = !isSuccess
        ? AppColors.warning.withValues(alpha: 0.04)
        : isDark
            ? AppColors.darkBgSecondary
            : AppColors.lightBgSecondary;

    final token = dioClient.dio.options.headers['Authorization'];

    return GestureDetector(
      onTap: isSuccess ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: entry.selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 72,
                height: 50,
                color: isDark ? AppColors.darkBgSubtle : AppColors.lightBgSubtle,
                child: isSuccess
                    ? Image.network(
                        ApiConstants.screenshotImage(entry.id),
                        headers: token != null
                            ? {'Authorization': token.toString()}
                            : null,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child:
                                Icon(Icons.broken_image, size: 20, color: AppColors.darkTextMuted),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          entry.status == 'timeout'
                              ? Icons.timer_off_outlined
                              : Icons.warning_amber_rounded,
                          size: 22,
                          color: AppColors.warning,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page name badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.pageName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // URL
                  Text(
                    entry.pageUrl,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Status row
                  Row(
                    children: [
                      if (entry.width != null && entry.height != null) ...[
                        Text(
                          '${entry.width}x${entry.height}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\u2022',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _StatusBadge(status: entry.status),
                    ],
                  ),
                ],
              ),
            ),

            // Checkbox
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: entry.selected
                      ? AppColors.accentSecondary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: entry.selected
                        ? AppColors.accentSecondary
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.15)),
                    width: 2,
                  ),
                ),
                child: entry.selected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (status) {
      case 'success':
        color = AppColors.success;
        label = 'success';
        icon = Icons.check_circle_outline;
      case 'timeout':
        color = AppColors.warning;
        label = 'timeout';
        icon = Icons.timer_off_outlined;
      case 'error':
        color = AppColors.error;
        label = 'error';
        icon = Icons.error_outline;
      default:
        color = AppColors.warning;
        label = status;
        icon = Icons.help_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------
class _ScreenshotEntry {
  final String id;
  final String pageName;
  final String pageUrl;
  final String status;
  final int? width;
  final int? height;
  final bool selected;

  const _ScreenshotEntry({
    required this.id,
    required this.pageName,
    required this.pageUrl,
    required this.status,
    this.width,
    this.height,
    this.selected = true,
  });

  _ScreenshotEntry copyWith({
    String? id,
    String? pageName,
    String? pageUrl,
    String? status,
    int? width,
    int? height,
    bool? selected,
  }) {
    return _ScreenshotEntry(
      id: id ?? this.id,
      pageName: pageName ?? this.pageName,
      pageUrl: pageUrl ?? this.pageUrl,
      status: status ?? this.status,
      width: width ?? this.width,
      height: height ?? this.height,
      selected: selected ?? this.selected,
    );
  }
}
