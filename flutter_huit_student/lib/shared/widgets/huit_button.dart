import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum HuitButtonVariant { primary, secondary, outline, danger, ghost }
enum HuitButtonSize { small, medium, large }

class HuitButton extends StatelessWidget {
  const HuitButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = HuitButtonVariant.primary,
    this.size = HuitButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.iconRight = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final HuitButtonVariant variant;
  final HuitButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final bool iconRight;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _colors;
    final (hPad, vPad, textStyle, iconSize) = _sizing;

    Widget content = isLoading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && !iconRight) ...[
                Icon(icon, size: iconSize, color: fg),
                const SizedBox(width: 8),
              ],
              Text(label, style: textStyle.copyWith(color: fg)),
              if (icon != null && iconRight) ...[
                const SizedBox(width: 8),
                Icon(icon, size: iconSize, color: fg),
              ],
            ],
          );

    if (fullWidth) {
      content = Center(child: content);
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: border != null ? Border.all(color: border, width: 1.5) : null,
              boxShadow: variant == HuitButtonVariant.primary && onPressed != null
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            child: content,
          ),
        ),
      ),
    );
  }

  (Color bg, Color fg, Color? border) get _colors {
    final isDisabled = onPressed == null && !isLoading;
    switch (variant) {
      case HuitButtonVariant.primary:
        return isDisabled
            ? (AppColors.border, AppColors.textDisabled, null)
            : (AppColors.primary, AppColors.textWhite, null);
      case HuitButtonVariant.secondary:
        return (AppColors.primarySurface, AppColors.primary, null);
      case HuitButtonVariant.outline:
        return isDisabled
            ? (Colors.transparent, AppColors.textDisabled, AppColors.border)
            : (Colors.transparent, AppColors.primary, AppColors.primary);
      case HuitButtonVariant.danger:
        return (AppColors.accent, AppColors.textWhite, null);
      case HuitButtonVariant.ghost:
        return (Colors.transparent, AppColors.primary, null);
    }
  }

  (double hPad, double vPad, TextStyle textStyle, double iconSize) get _sizing {
    switch (size) {
      case HuitButtonSize.small:
        return (14, 8, AppTextStyles.label.copyWith(fontSize: 12), 14);
      case HuitButtonSize.medium:
        return (20, 13, AppTextStyles.labelLarge, 16);
      case HuitButtonSize.large:
        return (24, 16, AppTextStyles.labelLarge.copyWith(fontSize: 16), 18);
    }
  }
}
