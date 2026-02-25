import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.animate = false});

  final String status;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (animate)
            _PulsingDot(color: fg)
          else
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: fg,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  (Color bg, Color fg, String label) get _style {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return (AppColors.infoLight, AppColors.primary, 'Sắp tới');
      case 'waiting':
        return (AppColors.warningLight, const Color(0xFFF39C12), 'Đang chờ');
      case 'processing':
        return (AppColors.successLight, AppColors.success, 'Đang xử lý');
      case 'completed':
        return (const Color(0xFFF0F0F0), AppColors.textSecondary, 'Hoàn thành');
      case 'cancelled':
        return (AppColors.accentSurface, AppColors.accent, 'Đã huỷ');
      case 'verified':
        return (AppColors.successLight, AppColors.success, 'Đã xác nhận');
      case 'pending':
        return (AppColors.warningLight, const Color(0xFFF39C12), 'Chờ duyệt');
      case 'rejected':
        return (AppColors.accentSurface, AppColors.accent, 'Bị từ chối');
      case 'replied':
        return (AppColors.successLight, AppColors.success, 'Đã trả lời');
      default:
        return (AppColors.border, AppColors.textSecondary, status);
    }
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
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
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
