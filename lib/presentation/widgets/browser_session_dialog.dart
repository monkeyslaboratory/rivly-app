import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/colors.dart';
import '../../logic/browser_session/browser_session_cubit.dart';
import '../../logic/browser_session/browser_session_state.dart';

class BrowserSessionDialog extends StatefulWidget {
  final String runId;
  final String? loginUrl;

  const BrowserSessionDialog({
    super.key,
    required this.runId,
    this.loginUrl,
  });

  static Future<bool> show(
    BuildContext context, {
    required String runId,
    String? loginUrl,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => BrowserSessionDialog(
            runId: runId,
            loginUrl: loginUrl,
          ),
        ) ??
        false;
  }

  @override
  State<BrowserSessionDialog> createState() => _BrowserSessionDialogState();
}

class _BrowserSessionDialogState extends State<BrowserSessionDialog> {
  late final BrowserSessionCubit _cubit;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _cubit = BrowserSessionCubit();
    _cubit.connect(widget.runId, loginUrl: widget.loginUrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _cubit.disconnect();
    _cubit.close();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    final character = event.character;

    // Special keys
    if (key == LogicalKeyboardKey.enter) {
      _cubit.sendKey('Enter');
    } else if (key == LogicalKeyboardKey.tab) {
      _cubit.sendKey('Tab');
    } else if (key == LogicalKeyboardKey.backspace) {
      _cubit.sendKey('Backspace');
    } else if (key == LogicalKeyboardKey.escape) {
      _cubit.sendKey('Escape');
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _cubit.sendKey('ArrowUp');
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _cubit.sendKey('ArrowDown');
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _cubit.sendKey('ArrowLeft');
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _cubit.sendKey('ArrowRight');
    } else if (key == LogicalKeyboardKey.delete) {
      _cubit.sendKey('Delete');
    } else if (key == LogicalKeyboardKey.home) {
      _cubit.sendKey('Home');
    } else if (key == LogicalKeyboardKey.end) {
      _cubit.sendKey('End');
    } else if (character != null && character.isNotEmpty) {
      _cubit.sendType(character);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Dialog.fullscreen(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Column(
            children: [
              _buildTopBar(context, isDark, l10n),
              Expanded(child: _buildBrowserView(context, isDark, l10n)),
              _buildBottomBar(context, isDark, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark, AppLocalizations l10n) {
    return BlocBuilder<BrowserSessionCubit, BrowserSessionState>(
      builder: (context, state) {
        final Color statusColor;
        final String statusText;

        switch (state.status) {
          case BrowserSessionStatus.idle:
          case BrowserSessionStatus.connecting:
            statusColor = AppColors.warning;
            statusText = l10n.connectingToBrowser;
          case BrowserSessionStatus.connected:
            statusColor = AppColors.success;
            statusText = l10n.browserSession;
          case BrowserSessionStatus.done:
            statusColor = AppColors.success;
            statusText = l10n.sessionComplete;
          case BrowserSessionStatus.error:
            statusColor = AppColors.error;
            statusText = l10n.error;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 16),
              // URL display
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBgSubtle : AppColors.lightBgSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.currentUrl,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Close button
              IconButton(
                onPressed: () => Navigator.of(context).pop(
                  state.status == BrowserSessionStatus.done && state.cookieCount > 0,
                ),
                icon: Icon(
                  Icons.close,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                tooltip: l10n.close,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrowserView(BuildContext context, bool isDark, AppLocalizations l10n) {
    return BlocBuilder<BrowserSessionCubit, BrowserSessionState>(
      builder: (context, state) {
        if (state.status == BrowserSessionStatus.connecting ||
            state.status == BrowserSessionStatus.idle) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.accentSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.connectingToBrowser,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (state.status == BrowserSessionStatus.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? l10n.error,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state.currentFrame == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.accentSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.connectingToBrowser,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final widgetWidth = constraints.maxWidth;
                final widgetHeight = constraints.maxHeight;

                return Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      _cubit.sendScroll(event.scrollDelta.dy);
                    }
                  },
                  child: GestureDetector(
                    onTapUp: (details) {
                      final localX = details.localPosition.dx;
                      final localY = details.localPosition.dy;
                      final remoteX = (localX * 1280 / widgetWidth).roundToDouble();
                      final remoteY = (localY * 720 / widgetHeight).roundToDouble();
                      _cubit.sendClick(remoteX, remoteY);
                    },
                    child: Image.memory(
                      state.currentFrame!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark, AppLocalizations l10n) {
    return BlocBuilder<BrowserSessionCubit, BrowserSessionState>(
      builder: (context, state) {
        final isDone = state.status == BrowserSessionStatus.done;
        final hasCookies = state.cookieCount > 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Row(
            children: [
              if (isDone && hasCookies) ...[
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.cookiesCaptured,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
              const Spacer(),
              if (!isDone)
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: state.status == BrowserSessionStatus.connected
                        ? () => _cubit.finishSession()
                        : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      l10n.imLoggedIn,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (isDone)
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(hasCookies),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      l10n.close,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
