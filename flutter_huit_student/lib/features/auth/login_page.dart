import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/app_state.dart';
import '../../shared/widgets/huit_button.dart';
import '../../shared/layouts/main_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (!mounted) return;
      await context.read<AppState>().login(
            _idCtrl.text.trim(),
            _passCtrl.text,
          );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero ─────────────────────────────────────
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.42,
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 16),
                    // Logo
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/huit_logo.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school_rounded,
                          size: 50,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Phòng Đào Tạo HUIT',
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Trường Đại Học Công Thương TP.HCM',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form ─────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đăng nhập', style: AppTextStyles.h2),
                          const SizedBox(height: 4),
                          Text(
                            'Sử dụng tài khoản cổng thông tin sinh viên',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // MSSV
                          TextFormField(
                            controller: _idCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Mã số sinh viên',
                              prefixIcon: Icon(Icons.badge_outlined,
                                  color: AppColors.primary),
                              hintText: 'VD: 21110001',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Nhập MSSV của bạn';
                              if (v.length < 7) return 'MSSV không hợp lệ';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  color: AppColors.primary),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Nhập mật khẩu';
                              if (v.length < 6) return 'Mật khẩu quá ngắn';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                'Quên mật khẩu?',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          HuitButton(
                            label: 'Đăng nhập',
                            isLoading: _loading,
                            onPressed: _loading ? null : _login,
                            fullWidth: true,
                            size: HuitButtonSize.large,
                            icon: Icons.login_rounded,
                          ),
                          const SizedBox(height: 20),

                          Center(
                            child: Text(
                              'Gặp sự cố? Liên hệ phòng đào tạo:\n(028) 3815 8086',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
