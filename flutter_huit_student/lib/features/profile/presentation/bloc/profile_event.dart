import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchProfileEvent extends ProfileEvent {
  const FetchProfileEvent();
}

class ProfileUpdatedEvent extends ProfileEvent {
  final String email;
  final String phone;

  const ProfileUpdatedEvent({required this.email, required this.phone});

  @override
  List<Object?> get props => [email, phone];
}
