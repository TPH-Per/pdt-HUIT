import 'package:flutter/material.dart';
import 'package:provider/Provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/app_state.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/huit_app_bar.dart';
import '../feedback/feedback_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final activeAppointments = state.appointments
        .where((a) => ['waiting', 'processing'].contains(a.normalizedStatus))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ─────────────────────────────────
          SliverToBoxAdapter(
            child: HuitHeroHeader(
              studentName: state.studentName,
              studentId: state.studentId,
            ),
          ),

          // ── Active Appointment Banner ─────────────────
          if (activeAppointments.isNotEmpty)
            SliverToBoxAdapter(
              child: _ActiveBanner(
                appointment: activeAppointments.first,
                context: context,
              ),
            ),

          // ── Quick Actions ────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Dịch vụ nhanh'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      _QuickCard(
                        icon: Icons.calendar_month_rounded,
                        iconBg: AppColors.primarySurface,
                        iconColor: AppColors.primary,
                        title: 'Đặt lịch hẹn',
                        subtitle: 'Đăng ký thủ tục tại phòng',
                        badge: null,
                        onTap: () => _switchTab(context, 1),
                      ),
                      _QuickCard(
                        icon: Icons.list_alt_rounded,
                        iconBg: const Color(0xFFFFF8E1),
                        iconColor: const Color(0xFFF39C12),
                        title: 'Lịch hẹn của tôi',
                        subtitle: 'Xem & theo dõi trạng thái',
                        badge: activeAppointments.isNotEmpty
                            ? '${activeAppointments.length}'
                            : null,
                        onTap: () => _switchTab(context, 2),
                      ),
                      _QuickCard(
                        icon: Icons.folder_open_rounded,
                        iconBg: AppColors.successLight,
                        iconColor: AppColors.success,
                        title: 'Hồ sơ số',
                        subtitle: 'Tài liệu học tập đã nộp',
                        badge: null,
                        onTap: () => _switchTab(context, 3),
                      ),
                      _QuickCard(
                        icon: Icons.rate_review_outlined,
                        iconBg: AppColors.accentSurface,
                        iconColor: AppColors.accent,
                        title: 'Góp ý',
                        subtitle: 'Phản hồi về dịch vụ',
                        badge: null,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FeedbackPage())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Procedures Quick Access ───────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Thủ tục phổ biến',
                  actionLabel: 'Xem tất cả',
                ),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: mockProcedures.length,
                    itemBuilder: (_, i) {
                      final p = mockProcedures[i];
                      return _ProcedureChip(
                          procedure: p, onTap: () => _switchTab(context, 1));
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── News ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Thông báo mới nhất'),
                ...mockNews.map((n) => _NewsItem(news: n)),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _switchTab(BuildContext context, int index) {
    context.read<AppState>().setTab(index);
  }
}

// ── Active Appointment Banner ─────────────────────────────
class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.appointment, required this.context});
  final dynamic appointment;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.queue_rounded,
                color: Color(0xFFF39C12), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn đang trong hàng chờ',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: const Color(0xFF856404),
                  ),
                ),
                Text(
                  'Số: ${appointment.queueDisplay} · ${appointment.procedureName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF664D03),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFF39C12), size: 20),
        ],
      ),
    );
  }
}

// ── Quick Action Card ─────────────────────────────────────
class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  if (badge != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Procedure Chip ────────────────────────────────────────
class _ProcedureChip extends StatelessWidget {
  const _ProcedureChip({required this.procedure, required this.onTap});
  final dynamic procedure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined,
                  color: AppColors.primary, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              procedure.name,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '${procedure.processingDays} ngày làm việc',
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ── News Item ─────────────────────────────────────────────
class _NewsItem extends StatelessWidget {
  const _NewsItem({required this.news});
  final Map<String, String> news;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_outlined,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news['title']!,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  news['date']!,
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}
