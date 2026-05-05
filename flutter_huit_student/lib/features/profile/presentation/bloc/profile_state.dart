import 'package:equatable/equatable.dart';

class ProfileData extends Equatable {
  final String studentId;
  final String fullName;
  final String email;
  final String phone;
  final String? faculty;
  final String? className;

  const ProfileData({
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.faculty,
    this.className,
  });

  @override
  List<Object?> get props =>
      [studentId, fullName, email, phone, faculty, className];
}

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final ProfileData profile;

  const ProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}
