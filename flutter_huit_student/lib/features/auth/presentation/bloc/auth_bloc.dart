import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<TokenRefreshed>(_onTokenRefreshed);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final token = await authRepository.getToken();
      if (token != null) {
        final studentId = await authRepository.getStudentId();
        if (studentId != null) {
          emit(AuthAuthenticated(
            studentId: studentId,
            studentName: '',
            email: '',
            phone: '',
          ));
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final result = await authRepository.login(event.mssv, event.password);
      await authRepository.saveToken(result['token']);
      await authRepository.saveRefreshToken(result['refreshToken']);
      await authRepository.saveStudentId(event.mssv);

      emit(AuthAuthenticated(
        studentId: event.mssv,
        studentName: result['fullName'] ?? '',
        email: result['email'] ?? '',
        phone: result['phone'] ?? '',
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onTokenRefreshed(
      TokenRefreshed event, Emitter<AuthState> emit) async {
    try {
      await authRepository.saveToken(event.token);
      if (state is AuthAuthenticated) {
        final current = state as AuthAuthenticated;
        emit(AuthAuthenticated(
          studentId: current.studentId,
          studentName: current.studentName,
          email: current.email,
          phone: current.phone,
        ));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
