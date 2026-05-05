import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/huit_app_bar.dart';
import '../../shared/widgets/huit_button.dart';
import '../feedback/feedback_page.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: '');
    _phoneCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (!mounted) return;
      // TODO: Integrate with ProfileBloc
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông tin thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi cập nhật thông tin'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancel() {
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HuitAppBar(
        title: 'Trang Cá Nhân',
        showBackButton: false,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 20),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Card ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isEditing
                    ? _EditForm(
                        emailCtrl: _emailCtrl,
                        phoneCtrl: _phoneCtrl,
                        saving: _saving,
                        onSave: _save,
                        onCancel: _cancel,
                      )
                    : _ProfileInfo(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Academic Info ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _InfoSection(
                title: 'Thông tin học vụ',
                items: [
                  _InfoItem(
                      icon: Icons.school_outlined,
                      label: 'Khoa',
                      value: ''),
                  _InfoItem(
                      icon: Icons.class_outlined,
                      label: 'Lớp',
                      value: ''),
                  _InfoItem(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _emailCtrl.text),
                  _InfoItem(
                      icon: Icons.phone_outlined,
                      label: 'Số điện thoại',
                      value: _phoneCtrl.text),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Menu ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _InfoSection(
                title: 'Tiện ích',
                items: [
                  _InfoItem(
                    icon: Icons.rate_review_outlined,
                    label: 'Gửi góp ý',
                    value: '',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackPage()),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                  ),
                  _InfoItem(
                    icon: Icons.phone_outlined,
                    label: 'Liên hệ Phòng Đào Tạo',
                    value: '(028) 3815 8086',
                    onTap: null,
                  ),
                  _InfoItem(
                    icon: Icons.language_outlined,
                    label: 'Website HUIT',
                    value: 'huit.edu.vn',
                    onTap: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Logout ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HuitButton(
                label: 'Đăng xuất',
                fullWidth: true,
                variant: HuitButtonVariant.danger,
                icon: Icons.logout_rounded,
                onPressed: () => _confirmLogout(context),
              ),
            ),
            const SizedBox(height: 28),

            // Version
            Text(
              'HUIT Student v1.0.0 • Phòng Đào Tạo',
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Integrate with AuthBloc for logout
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            child: const Text('Đăng xuất',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

// ── Sub-Widgets ────────────────────────────────────────────

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('info'),
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: const Center(
            child: Icon(Icons.person_rounded, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Student Name',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                'MSSV: N/A',
                style: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('edit'),
      children: [
        TextField(
          controller: emailCtrl,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.emailAddress,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            fillColor: Colors.white.withOpacity(0.15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white),
            ),
            hintText: 'Email sinh viên',
            hintStyle: TextStyle(color: Colors.white60),
            labelText: 'Email',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneCtrl,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 2),
          decoration: InputDecoration(
            fillColor: Colors.white.withOpacity(0.15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white),
            ),
            hintText: 'Số điện thoại',
            hintStyle: TextStyle(color: Colors.white60),
            labelText: 'Số điện thoại',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HuitButton(
                label: 'Huỷ',
                variant: HuitButtonVariant.outline,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HuitButton(
                label: 'Lưu',
                isLoading: saving,
                icon: Icons.save_outlined,
                onPressed: saving ? null : onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.items});
  final String title;
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(i == 0 ? 14 : 0),
                        topRight: Radius.circular(i == 0 ? 14 : 0),
                        bottomLeft:
                            Radius.circular(i == items.length - 1 ? 14 : 0),
                        bottomRight:
                            Radius.circular(i == items.length - 1 ? 14 : 0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(item.icon,
                                  color: AppColors.primary, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.label,
                                      style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w500)),
                                  if (item.value.isNotEmpty)
                                    Text(item.value,
                                        style: AppTextStyles.caption
                                            .copyWith(fontSize: 12)),
                                ],
                              ),
                            ),
                            item.trailing ??
                                (item.onTap != null
                                    ? const Icon(Icons.chevron_right_rounded,
                                        color: AppColors.textSecondary)
                                    : const SizedBox.shrink()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 16),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;
}
