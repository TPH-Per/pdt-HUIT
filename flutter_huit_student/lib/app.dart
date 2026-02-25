import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/app_state.dart';
import 'features/auth/login_page.dart';

class HuitStudentApp extends StatelessWidget {
  const HuitStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'HUIT Student – Phòng Đào Tạo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LoginPage(),
      ),
    );
  }
}
