import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HuitAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HuitAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBackButton = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      leading: leading ??
          (showBackButton && Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.textWhite),
                  onPressed: () => Navigator.pop(context),
                )
              : null),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textWhite.withOpacity(0.75),
                fontSize: 11,
              ),
            ),
        ],
      ),
      actions: actions,
    );
  }
}

/// Gradient hero app bar (used on Home page)
class HuitHeroHeader extends StatelessWidget {
  const HuitHeroHeader({
    super.key,
    required this.studentName,
    required this.studentId,
    this.onNotification,
  });

  final String studentName;
  final String studentId;
  final VoidCallback? onNotification;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding:
          EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/huit_logo.webp',
                    height: 32,
                    errorBuilder: (_, __, ___) => Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phòng Đào Tạo',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'HUIT',
                        style: TextStyle(
                                                    fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: onNotification,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Greeting
          Text(
            'Xin chào,',
            style: AppTextStyles.body.copyWith(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          Text(
            studentName,
            style: const TextStyle(
                            fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge_outlined, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(
                  'MSSV: $studentId',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable info card
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Section header
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h4),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
