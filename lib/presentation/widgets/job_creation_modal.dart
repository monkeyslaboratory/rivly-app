import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../data/repositories/job_repository.dart';

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

class _JobCreationModalState extends State<JobCreationModal> {
  final _formKey = GlobalKey<FormState>();
  final _productUrlController = TextEditingController();
  final _jobNameController = TextEditingController();
  final _competitorsController = TextEditingController();
  final _customTagController = TextEditingController();
  final JobRepository _jobRepository = JobRepository();

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _autoFindCompetitors = true;

  final Map<String, bool> _presetAreas = {
    'Homepage': true,
    'Pricing': true,
    'Navigation': true,
    'Onboarding': false,
    'Mobile UX': false,
  };

  final List<String> _customTags = [];

  @override
  void dispose() {
    _productUrlController.dispose();
    _jobNameController.dispose();
    _competitorsController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  String _generateJobName(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.replaceFirst('www.', '');
      return '$host vs Competitors';
    } catch (_) {
      return 'My Analysis';
    }
  }

  void _addCustomTag() {
    final tag = _customTagController.text.trim();
    if (tag.isNotEmpty && !_customTags.contains(tag)) {
      setState(() {
        _customTags.add(tag);
        _customTagController.clear();
      });
    }
  }

  void _removeCustomTag(String tag) {
    setState(() {
      _customTags.remove(tag);
    });
  }

  List<String> _getSelectedAreas() {
    final selected = _presetAreas.entries
        .where((e) => e.value)
        .map((e) => e.key.toLowerCase().replaceAll(' ', '_'))
        .toList();
    selected.addAll(
        _customTags.map((t) => t.toLowerCase().replaceAll(' ', '_')));
    return selected;
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    var productUrl = _productUrlController.text.trim();
    if (!productUrl.startsWith('http://') && !productUrl.startsWith('https://')) {
      productUrl = 'https://$productUrl';
    }
    final jobName = _jobNameController.text.trim().isNotEmpty
        ? _jobNameController.text.trim()
        : _generateJobName(productUrl);

    final selectedAreas = _getSelectedAreas();

    try {
      // Create the job (backend auto-assigns team)
      final job = await _jobRepository.createJob(
        name: jobName,
        productUrl: productUrl,
        areas: selectedAreas,
      );

      // Add competitors manually if auto-find is OFF
      if (!_autoFindCompetitors) {
        final competitorLines = _competitorsController.text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

        for (final url in competitorLines) {
          try {
            await _jobRepository.addCompetitor(
              job.id,
              _extractDomain(url),
              url.startsWith('http') ? url : 'https://$url',
            );
          } catch (_) {
            // Continue adding remaining competitors
          }
        }
      }

      // Trigger the run
      try {
        await _jobRepository.triggerRun(job.id);
      } catch (_) {
        // Run trigger failed but job was created
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onJobCreated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Analysis started!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

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
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.accentPrimary,
                              AppColors.accentSecondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'New Analysis',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
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
                  ),
                  const SizedBox(height: 28),

                  // Product URL
                  const _FieldLabel(label: "What's your product URL?"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _productUrlController,
                    decoration: const InputDecoration(
                      hintText: 'https://yourproduct.com',
                      prefixIcon: Icon(Icons.link, size: 20),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your product URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Job Name
                  const _FieldLabel(label: 'Job Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _jobNameController,
                    decoration: const InputDecoration(
                      hintText: 'My Product vs Competitors',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Auto-find competitors toggle
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel(label: 'Competitors'),
                            const SizedBox(height: 2),
                            Text(
                              _autoFindCompetitors
                                  ? 'AI will discover competitors after analysis'
                                  : 'Enter competitor URLs manually',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text(
                            'Auto-find',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Switch(
                            value: _autoFindCompetitors,
                            onChanged: (value) {
                              setState(() {
                                _autoFindCompetitors = value;
                              });
                            },
                            activeTrackColor: AppColors.accentPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Competitors text field (disabled when auto-find is ON)
                  TextFormField(
                    controller: _competitorsController,
                    enabled: !_autoFindCompetitors,
                    decoration: InputDecoration(
                      hintText: _autoFindCompetitors
                          ? 'AI will discover competitors after analysis'
                          : 'https://competitor1.com\nhttps://competitor2.com',
                    ),
                    maxLines: 4,
                    minLines: 3,
                    validator: (value) {
                      if (!_autoFindCompetitors &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Add at least one competitor URL or enable auto-find';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Analysis Areas
                  const _FieldLabel(label: 'Analysis Areas'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
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
                        // Preset + custom tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Preset area chips
                            ..._presetAreas.entries.map((entry) {
                              final isSelected = entry.value;
                              return FilterChip(
                                label: Text(
                                  entry.key,
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
                                onSelected: (selected) {
                                  setState(() {
                                    _presetAreas[entry.key] = selected;
                                  });
                                },
                                selectedColor: AppColors.accentSecondary,
                                backgroundColor: isDark
                                    ? AppColors.darkBgSubtle
                                    : AppColors.lightBgSubtle,
                                checkmarkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.accentSecondary
                                        : borderColor,
                                  ),
                                ),
                                showCheckmark: true,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                              );
                            }),
                            // Custom tag chips
                            ..._customTags.map((tag) {
                              return Chip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: AppColors.accentSecondary,
                                deleteIconColor: Colors.white70,
                                onDeleted: () => _removeCustomTag(tag),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                    color: AppColors.accentSecondary,
                                  ),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Custom tag input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customTagController,
                                decoration: InputDecoration(
                                  hintText: 'Add custom area...',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 13),
                                onSubmitted: (_) => _addCustomTag(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              child: TextButton(
                                onPressed: _addCustomTag,
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Add'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
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
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rocket_launch_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Create & Run Analysis'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
