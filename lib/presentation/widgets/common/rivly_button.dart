import 'package:flutter/material.dart';

enum RivlyButtonVariant { primary, outline, ghost }

class RivlyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final RivlyButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const RivlyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = RivlyButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget button;
    switch (variant) {
      case RivlyButtonVariant.primary:
        final buttonStyle = Theme.of(context).elevatedButtonTheme.style;
        final fgColor = buttonStyle?.foregroundColor?.resolve({}) ??
            Theme.of(context).scaffoldBackgroundColor;
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle?.copyWith(
            minimumSize: WidgetStatePropertyAll(const Size(0, 52)),
          ),
          child: _buildChild(fgColor),
        );
        break;
      case RivlyButtonVariant.outline:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: Theme.of(context).outlinedButtonTheme.style?.copyWith(
                minimumSize: WidgetStatePropertyAll(const Size(0, 48)),
              ),
          child: _buildChild(Theme.of(context).colorScheme.onSurface),
        );
        break;
      case RivlyButtonVariant.ghost:
        button = TextButton(
          onPressed: effectiveOnPressed,
          child: _buildChild(Theme.of(context).colorScheme.onSurface),
        );
        break;
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }

  Widget _buildChild(Color indicatorColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );
  }
}
