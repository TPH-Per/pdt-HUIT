import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String mssv;
  final String password;

  const LoginRequested({required this.mssv, required this.password});

  @override
  List<Object?> get props => [mssv, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class TokenRefreshed extends AuthEvent {
  final String token;

  const TokenRefreshed({required this.token});

  @override
  List<Object?> get props => [token];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}
