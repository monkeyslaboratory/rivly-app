import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../data/repositories/run_repository.dart';
import '../../widgets/browser_session_dialog.dart';
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
  bool _isAuthCrawling = false;
  String? _error;
  List<_ScreenshotEntry> _screenshots = [];
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _authLoginUrlController = TextEditingController();
  final TextEditingController _authEmailController = TextEditingController();
  final TextEditingController _authPasswordController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  String? _competitorName;

  // Auth mode: 0 = interactive, 1 = credentials
  int _authMode = 0;

  // Auth polling state
  Timer? _authPollTimer;
  String _currentAuthStatus = '';
  String _currentAuthMessage = '';
  bool _isSubmittingCode = false;

  @override
  void initState() {
    super.initState();
    _loadRunData();
  }

  @override
  void dispose() {
    _authPollTimer?.cancel();
    _urlController.dispose();
    _authLoginUrlController.dispose();
    _authEmailController.dispose();
    _authPasswordController.dispose();
    _verificationCodeController.dispose();
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

      // Track auth status from run data
      final authStatus = data['auth_status'] as String? ?? '';
      final hasAuthCookies = (data['auth_cookies'] as List<dynamic>?)?.isNotEmpty ?? false;

      setState(() {
        if (authStatus.isNotEmpty) {
          _currentAuthStatus = authStatus;
        }
        _screenshots = screenshots.map((s) {
          final shot = s as Map<String, dynamic>;
          final status = shot['status'] as String? ?? 'unknown';
          // If we have cookies and page is auth_required, treat as selected (will be recrawled)
          final shouldSelect = status == 'success' || (status == 'auth_required' && hasAuthCookies);
          return _ScreenshotEntry(
            id: shot['id'] as String,
            pageName: shot['page_name'] as String? ?? 'Unknown',
            pageUrl: shot['page_url'] as String? ?? '',
            status: status,
            width: (shot['width'] as num?)?.toInt(),
            height: (shot['height'] as num?)?.toInt(),
            selected: shouldSelect,
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

  /// After browser session completes, poll until recrawl finishes, then reload.
  Future<void> _waitForRecrawl() async {
    setState(() {
      _isAuthCrawling = true;
      _currentAuthStatus = 'logging_in';
      _currentAuthMessage = AppLocalizations.of(context).recrawlingPages;
    });

    const maxAttempts = 60; // 60 * 2s = 2 min max
    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      try {
        final data = await _runRepository.getRawRun(widget.runId);
        final authStatus = data['auth_status'] as String? ?? '';
        final authMessage = data['auth_message'] as String? ?? '';

        setState(() {
          _currentAuthStatus = authStatus;
          _currentAuthMessage = authMessage;
        });

        // Terminal states
        if (authStatus == 'logged_in' || authStatus == 'auth_failed') {
          break;
        }
      } catch (_) {
        // ignore poll errors, retry
      }
    }

    if (mounted) {
      setState(() => _isAuthCrawling = false);
      await _loadRunData();
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
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.validUrlRequired),
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

  List<_ScreenshotEntry> get _authRequiredScreenshots =>
      _screenshots.where((s) => s.status == 'auth_required').toList();

  Future<void> _submitAuthCredentials() async {
    final email = _authEmailController.text.trim();
    final password = _authPasswordController.text.trim();
    final loginUrl = _authLoginUrlController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.enterBothCredentials),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isAuthCrawling = true);

    try {
      await _runRepository.submitAuthCredentials(
        widget.runId,
        email: email,
        password: password,
        loginUrl: loginUrl.isNotEmpty ? loginUrl : null,
      );

      if (!mounted) return;
      setState(() {
        _currentAuthStatus = 'authenticating';
        _currentAuthMessage = 'Logging in...';
      });

      // Start polling for auth status updates
      _startAuthPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAuthCrawling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auth crawl failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startAuthPolling() {
    _authPollTimer?.cancel();
    _authPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final data = await RunRepository().getRawRun(widget.runId);
        final authStatus = data['auth_status'] as String? ?? '';
        final authMessage = data['auth_message'] as String? ?? '';
        if (!mounted) return;
        setState(() {
          _currentAuthStatus = authStatus;
          _currentAuthMessage = authMessage;
        });
        // Stop polling on terminal states
        if (authStatus == 'logged_in' || authStatus == 'auth_failed' || (authStatus.isEmpty && authMessage.isEmpty)) {
          _authPollTimer?.cancel();
          if (authStatus == 'logged_in') {
            // Reload screenshots to get recaptured pages
            await _loadRunData();
            if (!mounted) return;
            setState(() => _isAuthCrawling = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).authPagesRecaptured),
                backgroundColor: AppColors.success,
              ),
            );
            _authEmailController.clear();
            _authPasswordController.clear();
            _authLoginUrlController.clear();
          } else if (authStatus == 'auth_failed') {
            setState(() => _isAuthCrawling = false);
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _submitVerificationCode() async {
    final code = _verificationCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isSubmittingCode = true);

    try {
      await _runRepository.submitVerificationCode(widget.runId, code);
      if (!mounted) return;
      _verificationCodeController.clear();
      setState(() => _isSubmittingCode = false);
      // Continue polling — auth status will update
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingCode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit code: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _approveAndStart() async {
    if (_selectedCount == 0) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.selectAtLeastOnePage),
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
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.broken_image, size: 48, color: AppColors.darkTextMuted),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context).failedToLoadScreenshot,
                                  style: const TextStyle(color: AppColors.darkTextMuted),
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
        title: Text(AppLocalizations.of(context).reviewPages),
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
            label: AppLocalizations.of(context).retry,
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

              // Auth-required section (hide if already logged in via browser session)
              if (_authRequiredScreenshots.isNotEmpty && _currentAuthStatus != 'logged_in') ...[
                const SizedBox(height: 24),
                _buildAuthWallSection(context, isDark),
              ],

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
                      AppLocalizations.of(context).pagesFound(totalCount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context).pagesCaptured(successCount),
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
            AppLocalizations.of(context).reviewInstructions,
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

  Widget _buildAuthWallSection(BuildContext context, bool isDark) {
    final authPages = _authRequiredScreenshots;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentSecondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 20, color: AppColors.accentSecondary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).pagesRequireLogin(authPages.length),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).authWallDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 14),

          // Auth-required page list
          ...authPages.map((shot) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBgElevated
                        : AppColors.lightBgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accentSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 16, color: AppColors.accentSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shot.pageName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shot.pageUrl,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 16),

          // Segmented control: Interactive vs Credentials
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _buildSegmentButton(
                  context,
                  index: 0,
                  icon: Icons.open_in_browser,
                  label: AppLocalizations.of(context).interactiveLogin,
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildSegmentButton(
                  context,
                  index: 1,
                  icon: Icons.lock_outline,
                  label: AppLocalizations.of(context).loginCredentials,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab content
          if (_authMode == 0) ...[
            // Interactive login tab
            Text(
              AppLocalizations.of(context).interactiveLoginDesc,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isAuthCrawling
                    ? null
                    : () async {
                        final success = await BrowserSessionDialog.show(
                          context,
                          runId: widget.runId,
                          loginUrl: _authLoginUrlController.text.isNotEmpty
                              ? _authLoginUrlController.text
                              : null,
                        );
                        if (success && mounted) {
                          await _waitForRecrawl();
                        }
                      },
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: Text(
                  AppLocalizations.of(context).interactiveLogin,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Credentials tab
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.accentSecondary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).credentialsPrivacy,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Login URL field
            Text(
              AppLocalizations.of(context).loginUrl,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _authLoginUrlController,
              enabled: !_isAuthCrawling,
              decoration: _authInputDecoration(context, isDark: isDark, hintText: 'https://example.com/login', prefixIcon: Icons.link),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),

            // Email field
            Text(
              AppLocalizations.of(context).emailOrUsername,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _authEmailController,
              enabled: !_isAuthCrawling,
              decoration: _authInputDecoration(context, isDark: isDark, hintText: 'user@example.com', prefixIcon: Icons.person_outline),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            // Password field
            Text(
              AppLocalizations.of(context).password,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _authPasswordController,
              enabled: !_isAuthCrawling,
              obscureText: true,
              decoration: _authInputDecoration(context, isDark: isDark, hintText: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022', prefixIcon: Icons.lock_outline),
            ),
            const SizedBox(height: 18),

            // Authenticate button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isAuthCrawling ? null : _submitAuthCredentials,
                icon: _isAuthCrawling
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Icon(Icons.lock_open, size: 18),
                label: Text(
                  _isAuthCrawling ? AppLocalizations.of(context).authenticating : AppLocalizations.of(context).authenticateRecapture,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentSecondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],

          // Auth status feedback (shared)
          if (_currentAuthStatus.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAuthStatusCard(context, isDark),
          ],

          const SizedBox(height: 10),

          // Skip text
          if (_currentAuthStatus.isEmpty)
            Center(
              child: Text(
                AppLocalizations.of(context).skipAuthNote,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(BuildContext context, {required int index, required IconData icon, required String label, required bool isDark}) {
    final isSelected = _authMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: _isAuthCrawling ? null : () => setState(() => _authMode = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.accentPrimary.withValues(alpha: 0.2) : AppColors.accentPrimary.withValues(alpha: 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.accentPrimary : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.accentPrimary : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthStatusCard(BuildContext context, bool isDark) {
    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    switch (_currentAuthStatus) {
      case 'logged_in':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusLabel = 'Logged In';
      case 'auth_failed':
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        statusLabel = 'Authentication Failed';
      case 'captcha_required':
        statusColor = AppColors.warning;
        statusIcon = Icons.smart_toy_outlined;
        statusLabel = 'Captcha Required';
      case 'code_required':
        statusColor = AppColors.accentSecondary;
        statusIcon = Icons.pin_outlined;
        statusLabel = 'Verification Code Required';
      case 'authenticating':
        statusColor = AppColors.accentSecondary;
        statusIcon = Icons.lock_open;
        statusLabel = 'Authenticating';
      default:
        statusColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        statusIcon = Icons.info_outline;
        statusLabel = _currentAuthStatus;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Icon(statusIcon, size: 18, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              if (_currentAuthStatus == 'authenticating' || _currentAuthStatus == 'logging_in' || _currentAuthStatus == 'logged_in' && _isAuthCrawling)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
            ],
          ),

          // Status message
          if (_currentAuthMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _currentAuthMessage,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],

          // Captcha input
          if (_currentAuthStatus == 'captcha_required') ...[
            const SizedBox(height: 12),
            Text(
              'Enter the captcha code shown on the page:',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _verificationCodeController,
                    enabled: !_isSubmittingCode,
                    decoration: _authInputDecoration(
                      context,
                      isDark: isDark,
                      hintText: 'Enter captcha code',
                      prefixIcon: Icons.smart_toy_outlined,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitVerificationCode(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmittingCode ? null : _submitVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentSecondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _isSubmittingCode
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],

          // Verification code input
          if (_currentAuthStatus == 'code_required') ...[
            const SizedBox(height: 12),
            Text(
              'Check your email or phone for the verification code.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _verificationCodeController,
                    enabled: !_isSubmittingCode,
                    decoration: _authInputDecoration(
                      context,
                      isDark: isDark,
                      hintText: 'Enter verification code',
                      prefixIcon: Icons.pin_outlined,
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitVerificationCode(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmittingCode ? null : _submitVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentSecondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _isSubmittingCode
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],

          // Auth failed — retry button
          if (_currentAuthStatus == 'auth_failed') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentAuthStatus = '';
                    _currentAuthMessage = '';
                    _isAuthCrawling = false;
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],

          // Logged in — success with recapture progress
          if (_currentAuthStatus == 'logged_in' && _isAuthCrawling) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recapturing authenticated pages...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _authInputDecoration(
    BuildContext context, {
    required bool isDark,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        fontSize: 14,
      ),
      filled: true,
      fillColor: isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: AppColors.accentSecondary),
      ),
      prefixIcon: Icon(prefixIcon, size: 18),
    );
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
                AppLocalizations.of(context).addCustomPage,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).addCustomPageHint,
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
                      : Text(AppLocalizations.of(context).add, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    AppLocalizations.of(context).pagesSelected(_selectedCount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (_selectedCount == 0)
                    Text(
                      AppLocalizations.of(context).selectAtLeastOne,
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
              label: AppLocalizations.of(context).startAnalysis,
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
    final isAuthRequired = entry.status == 'auth_required';
    final borderColor = isAuthRequired
        ? AppColors.accentSecondary.withValues(alpha: 0.4)
        : !isSuccess
            ? AppColors.warning.withValues(alpha: 0.4)
            : entry.selected
                ? AppColors.accentSecondary.withValues(alpha: 0.3)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06));

    final bgColor = isAuthRequired
        ? AppColors.accentSecondary.withValues(alpha: 0.04)
        : !isSuccess
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
                          isAuthRequired
                              ? Icons.lock_outline
                              : entry.status == 'timeout'
                                  ? Icons.timer_off_outlined
                                  : Icons.warning_amber_rounded,
                          size: 22,
                          color: isAuthRequired
                              ? AppColors.accentSecondary
                              : AppColors.warning,
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

    final l = AppLocalizations.of(context);
    switch (status) {
      case 'success':
        color = AppColors.success;
        label = 'success';
        icon = Icons.check_circle_outline;
      case 'auth_required':
        color = AppColors.accentSecondary;
        label = l.loginRequired;
        icon = Icons.lock_outline;
      case 'timeout':
        color = AppColors.warning;
        label = 'timeout';
        icon = Icons.timer_off_outlined;
      case 'error':
        color = AppColors.error;
        label = l.error;
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
