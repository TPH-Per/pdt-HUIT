import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';
import '../../shared/widgets/huit_app_bar.dart';
import '../../shared/widgets/huit_button.dart';
import '../../shared/widgets/status_badge.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HuitAppBar(
        title: 'Góp Ý',
        subtitle: 'Phòng Đào Tạo HUIT',
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
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(
                    icon: Icon(Icons.send_outlined, size: 18),
                    text: 'Gửi góp ý'),
                Tab(
                    icon: Icon(Icons.history_outlined, size: 18),
                    text: 'Lịch sử'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                _SendFeedbackTab(),
                _FeedbackHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Send Feedback Tab ─────────────────────────────────────
class _SendFeedbackTab extends StatefulWidget {
  const _SendFeedbackTab();

  @override
  State<_SendFeedbackTab> createState() => _SendFeedbackTabState();
}

class _SendFeedbackTabState extends State<_SendFeedbackTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  int? _selectedAppointmentId;
  String _category = 'Thái độ phục vụ';
  int _rating = 0;
  bool _submitting = false;
  bool _submitted = false;

  final _categories = [
    'Thái độ phục vụ',
    'Thời gian chờ',
    'Cơ sở vật chất',
    'Thủ tục hành chính',
    'Hệ thống ứng dụng',
    'Khác',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAppointmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Vui lòng chọn hồ sơ / lịch hẹn để góp ý'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      if (!mounted) return;
      int typeMap = _categories.indexOf(_category);
      if (typeMap == -1) typeMap = 0;

      await context.read<AppState>().submitFeedback(
            _titleCtrl.text.trim(),
            _contentCtrl.text.trim(),
            typeMap,
            _selectedAppointmentId,
          );

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() {
        _submitted = false;
        _titleCtrl.clear();
        _contentCtrl.clear();
        _selectedAppointmentId = null;
        _rating = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi: \${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 42),
              ),
              const SizedBox(height: 16),
              Text('Gửi góp ý thành công!',
                  style: AppTextStyles.h3.copyWith(color: AppColors.success)),
              const SizedBox(height: 6),
              Text(
                'Cảm ơn bạn đã đóng góp ý kiến. Phòng Đào Tạo sẽ phản hồi trong thời gian sớm nhất.',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Choose Appointment
            Consumer<AppState>(builder: (context, appState, child) {
              // Chỉ lấy những hồ sơ đã hoàn thành hoặc liên quan để có thể góp ý
              final eligibleAppointments = appState.appointments
                  .where(
                      (a) => a.normalizedStatus == 'completed' || a.id != null)
                  .toList();

              return DropdownButtonFormField<int>(
                value: _selectedAppointmentId,
                decoration: const InputDecoration(
                  labelText: 'Hồ sơ / Lịch hẹn gốc *',
                  prefixIcon: Icon(Icons.description_outlined,
                      color: AppColors.primary),
                ),
                items: eligibleAppointments.map((a) {
                  return DropdownMenuItem<int>(
                    value: a.id,
                    child: Text('${a.code} - ${a.procedureName}',
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedAppointmentId = v),
                validator: (v) => v == null ? 'Bắt buộc chọn hồ sơ' : null,
                isExpanded: true,
              );
            }),
            const SizedBox(height: 14),

            // Rating
            Text('Đánh giá chất lượng phục vụ', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i < _rating
                          ? const Color(0xFFFFC107)
                          : AppColors.border,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Phân loại góp ý',
                prefixIcon:
                    Icon(Icons.category_outlined, color: AppColors.primary),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
              validator: (v) => v == null ? 'Chọn phân loại' : null,
            ),
            const SizedBox(height: 14),

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary),
                hintText: 'Tóm tắt vấn đề bạn muốn góp ý...',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Nhập tiêu đề' : null,
            ),
            const SizedBox(height: 14),

            // Content
            TextFormField(
              controller: _contentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Nội dung chi tiết',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 64),
                  child: Icon(Icons.message_outlined, color: AppColors.primary),
                ),
                hintText: 'Mô tả chi tiết vấn đề hoặc đề xuất của bạn...',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.length < 10
                  ? 'Nội dung quá ngắn (tối thiểu 10 ký tự)'
                  : null,
            ),
            const SizedBox(height: 24),

            HuitButton(
              label: 'Gửi góp ý',
              fullWidth: true,
              size: HuitButtonSize.large,
              isLoading: _submitting,
              icon: Icons.send_rounded,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feedback History Tab ──────────────────────────────────
class _FeedbackHistoryTab extends StatelessWidget {
  const _FeedbackHistoryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.loadingFeedbacks) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final feedbacks = appState.feedbacks;

        if (feedbacks.isEmpty) {
          return Center(
            child: Text(
              'Bạn chưa có lịch sử góp ý nào.',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => appState.refreshFeedbacks(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: feedbacks.length,
            itemBuilder: (_, i) => _FeedbackCard(item: feedbacks[i]),
          ),
        );
      },
    );
  }
}

class _FeedbackCard extends StatefulWidget {
  const _FeedbackCard({required this.item});
  final FeedbackItem item;

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                StatusBadge(status: widget.item.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.date,
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.content,
              style: AppTextStyles.body.copyWith(fontSize: 13),
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (_expanded && widget.item.reply != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply_rounded,
                            color: AppColors.success, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          'Phản hồi từ Phòng Đào Tạo',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.success,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item.reply!,
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFF1B5E20),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _expanded ? 'Thu gọn' : 'Xem thêm',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
