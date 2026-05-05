import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/Provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/app_state.dart';
import '../../data/models.dart';
import '../../data/api_service.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/huit_app_bar.dart';
import '../../shared/widgets/huit_button.dart';

class QueueTrackingPage extends StatefulWidget {
  const QueueTrackingPage({super.key, required this.appointmentId});
  final int appointmentId;

  @override
  State<QueueTrackingPage> createState() => _QueueTrackingPageState();
}

class _QueueTrackingPageState extends State<QueueTrackingPage> {
  final _api = ApiService();
  Appointment? _appointment;
  bool _loading = true;
  Timer? _timer;

  // Mock live data
  int _currentServing = 45;
  int _peopleAhead = 12;

  @override
  void initState() {
    super.initState();
    _fetchAppointment();
    // Refresh every 30s
    _timer =
        Timer.periodic(const Duration(seconds: 30), (_) => _fetchAppointment());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAppointment() async {
    final state = context.read<AppState>();
    try {
      final apt = await _api.getAppointmentDetail(
          widget.appointmentId, state.studentId);
      if (mounted)
        setState(() {
          _appointment = apt;
          _loading = false;
        });
    } catch (_) {
      // Use mock
      final mock = mockAppointments.firstWhere(
        (a) => a.id == widget.appointmentId,
        orElse: () => mockAppointments.first,
      );
      if (mounted) {
        setState(() {
          _appointment = mock;
          _loading = false;
        });
      }
    }

    // Simulate queue movement
    if (mounted) {
      setState(() {
        if (_peopleAhead > 0) {
          _currentServing += 1;
          _peopleAhead = (_peopleAhead - 1).clamp(0, 999);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_appointment == null) {
      return Scaffold(
        appBar: const HuitAppBar(title: 'Theo dõi hàng đợi'),
        body: Center(
          child: Text('Không tìm thấy lịch hẹn',
              style: AppTextStyles.body.copyWith(color: AppColors.accent)),
        ),
      );
    }

    final isCompleted = _appointment!.normalizedStatus == 'completed';
    final isProcessing = _appointment!.normalizedStatus == 'processing';

    return Column(
      children: [
        // ── Live Status Banner ───────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 12, 20, 20),
          decoration: BoxDecoration(
            gradient: isCompleted
                ? const LinearGradient(
                    colors: [Color(0xFF1B6B35), Color(0xFF28A745)])
                : isProcessing
                    ? const LinearGradient(
                        colors: [Color(0xFFF39C12), Color(0xFFE67E22)])
                    : AppColors.heroGradient,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (!isCompleted) _LiveDot(),
                      const SizedBox(width: 6),
                      Text(
                        isCompleted
                            ? 'Hoàn thành'
                            : isProcessing
                                ? 'Đang được phục vụ'
                                : 'TRỰC TIẾP • Đang chờ',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang phục vụ số',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white70),
                      ),
                      Text(
                        'A${_currentServing.toString().padLeft(3, '0')}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Số của bạn',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          _appointment!.queueDisplay,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Body ──────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 4),

                // Status card
                if (isCompleted)
                  _StatusCard(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.success,
                    iconBg: AppColors.successLight,
                    title: 'Đã hoàn thành!',
                    subtitle: 'Phiên làm việc đã kết thúc. Cảm ơn bạn!',
                  )
                else if (isProcessing)
                  _StatusCard(
                    icon: Icons.support_agent_rounded,
                    iconColor: const Color(0xFFF39C12),
                    iconBg: AppColors.warningLight,
                    title: 'Đến lượt bạn rồi!',
                    subtitle: 'Vui lòng đến quầy tiếp nhận ngay bây giờ.',
                  )
                else ...[
                  // People ahead
                  _InfoTile(
                    icon: Icons.people_outline_rounded,
                    label: 'Số người đứng trước',
                    value: '$_peopleAhead người',
                    valueColor: _peopleAhead <= 3
                        ? AppColors.success
                        : _peopleAhead <= 8
                            ? const Color(0xFFF39C12)
                            : AppColors.textHeading,
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.access_time_outlined,
                    label: 'Thời gian chờ ước tính',
                    value: '~${_peopleAhead * 5} phút',
                    valueColor: AppColors.textHeading,
                  ),
                ],

                const SizedBox(height: 16),

                // Appointment info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thông tin lịch hẹn', style: AppTextStyles.h4),
                      const Divider(height: 16),
                      _Row('Thủ tục', _appointment!.procedureName),
                      _Row('Mã lịch hẹn', _appointment!.code),
                      _Row('Ngày hẹn', _appointment!.appointmentDate),
                      _Row('Giờ hẹn', _appointment!.appointmentTime),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tip
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primarySurface),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mang theo đầy đủ giấy tờ theo yêu cầu và thẻ sinh viên khi đến quầy.',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                HuitButton(
                  label: 'Quay lại danh sách',
                  fullWidth: true,
                  variant: HuitButtonVariant.outline,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sub-Widgets ────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.4 + 0.6 * _ctrl.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFFF4444),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(subtitle,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Text(
            value,
            style: AppTextStyles.h4.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
