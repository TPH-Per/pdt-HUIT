import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/app_state.dart';
import '../../data/models.dart';
import '../../shared/widgets/huit_app_bar.dart';
import '../../shared/widgets/status_badge.dart';
import '../queue/queue_tracking_page.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final upcoming = state.appointments
        .where((a) =>
            ['upcoming', 'waiting', 'processing'].contains(a.normalizedStatus))
        .toList();
    final completed = state.appointments
        .where((a) => a.normalizedStatus == 'completed')
        .toList();
    final cancelled = state.appointments
        .where((a) => a.normalizedStatus == 'cancelled')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HuitAppBar(
        title: 'Lịch Hẹn Của Tôi',
        subtitle: 'Phòng Đào Tạo HUIT',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 22),
            onPressed: () => state.refreshAppointments(),
          ),
        ],
        // Bottom TabBar
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTextStyles.label.copyWith(fontSize: 11),
              tabs: [
                Tab(text: 'Sắp tới (${upcoming.length})'),
                Tab(text: 'Hoàn thành (${completed.length})'),
                Tab(text: 'Đã huỷ (${cancelled.length})'),
              ],
            ),
          ),

          Expanded(
            child: state.loadingAppointments
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _AppointmentList(appointments: upcoming, allowTap: true),
                      _AppointmentList(
                          appointments: completed, allowTap: false),
                      _AppointmentList(
                          appointments: cancelled, allowTap: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.appointments,
    required this.allowTap,
  });

  final List<Appointment> appointments;
  final bool allowTap;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                color: AppColors.border, size: 56),
            const SizedBox(height: 12),
            Text('Không có lịch hẹn',
                style:
                    AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Nhấn tab Đặt lịch để tạo lịch mới',
                style: AppTextStyles.caption),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<AppState>().refreshAppointments(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: appointments.length,
        itemBuilder: (_, i) {
          final apt = appointments[i];
          return _AppointmentCard(appointment: apt, allowTap: allowTap);
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.allowTap,
  });

  final Appointment appointment;
  final bool allowTap;

  @override
  Widget build(BuildContext context) {
    final canTrack = allowTap &&
        ['waiting', 'processing'].contains(appointment.normalizedStatus);

    return GestureDetector(
      onTap: canTrack
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      QueueTrackingPage(appointmentId: appointment.id ?? 0),
                ),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Queue number badge
            Container(
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: appointment.normalizedStatus == 'cancelled'
                    ? AppColors.border
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Số',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: appointment.normalizedStatus == 'cancelled'
                          ? AppColors.textDisabled
                          : AppColors.primary,
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    appointment.queueDisplay,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: appointment.normalizedStatus == 'cancelled'
                          ? AppColors.textDisabled
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          appointment.procedureName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${appointment.appointmentDate}',
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        appointment.appointmentTime,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusBadge(
                        status: appointment.normalizedStatus,
                        animate: appointment.normalizedStatus == 'processing',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (canTrack)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_outlined,
                    color: AppColors.primary, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
