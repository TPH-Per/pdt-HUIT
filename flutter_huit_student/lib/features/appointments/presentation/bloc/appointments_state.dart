import 'package:equatable/equatable.dart';

class AppointmentItem extends Equatable {
  final int id;
  final String code;
  final String procedureName;
  final String status;
  final DateTime appointmentDate;
  final String appointmentTime;
  final int? peopleAhead;

  const AppointmentItem({
    required this.id,
    required this.code,
    required this.procedureName,
    required this.status,
    required this.appointmentDate,
    required this.appointmentTime,
    this.peopleAhead,
  });

  @override
  List<Object?> get props =>
      [id, code, procedureName, status, appointmentDate, appointmentTime, peopleAhead];
}

abstract class AppointmentsState extends Equatable {
  const AppointmentsState();

  @override
  List<Object?> get props => [];
}

class AppointmentsInitial extends AppointmentsState {
  const AppointmentsInitial();
}

class AppointmentsLoading extends AppointmentsState {
  const AppointmentsLoading();
}

class AppointmentsLoaded extends AppointmentsState {
  final List<AppointmentItem> appointments;

  const AppointmentsLoaded({required this.appointments});

  @override
  List<Object?> get props => [appointments];
}

class AppointmentsError extends AppointmentsState {
  final String message;

  const AppointmentsError({required this.message});

  @override
  List<Object?> get props => [message];
}
