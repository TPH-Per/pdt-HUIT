import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'shared/cubits/connectivity_cubit.dart';
import 'shared/widgets/offline_banner.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/queue/presentation/bloc/queue_bloc.dart';
import 'features/requests/presentation/bloc/requests_bloc.dart';
import 'features/appointments/presentation/bloc/appointments_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'data/api_service.dart';
import 'core/storage/secure_storage.dart';

class HuitStudentApp extends StatelessWidget {
  const HuitStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => AuthRepository(
            apiService: ApiService(),
            secureStorage: SecureStorage(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ConnectivityCubit(),
          ),
          BlocProvider(
            create: (context) => QueueBloc(),
          ),
          BlocProvider(
            create: (context) => RequestsBloc(),
          ),
          BlocProvider(
            create: (context) => AppointmentsBloc(),
          ),
          BlocProvider(
            create: (context) => NotificationsBloc(),
          ),
          BlocProvider(
            create: (context) => ProfileBloc(),
          ),
        ],
        child: MaterialApp.router(
          title: 'HUIT Student – Phòng Đào Tạo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: AppRouterConfig.router(),
          builder: (context, child) {
            return Column(
              children: [
                const OfflineBanner(),
                Expanded(child: child ?? const SizedBox()),
              ],
            );
          },
        ),
      ),
    );
  }
}

