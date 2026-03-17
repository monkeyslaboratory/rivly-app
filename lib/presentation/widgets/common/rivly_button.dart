import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: _buildChild(Colors.white),
        );
        break;
      case RivlyButtonVariant.outline:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            backgroundColor: Colors.transparent,
            elevation: 0,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            side: BorderSide(
              color: Colors.black.withValues(alpha: 0.2),
              width: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: _buildChild(Theme.of(context).colorScheme.onSurface),
        );
        break;
      case RivlyButtonVariant.ghost:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
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

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      );
    }
    return Text(label);
  }
}
