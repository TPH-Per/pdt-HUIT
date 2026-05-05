import 'package:equatable/equatable.dart';

abstract class AppointmentsEvent extends Equatable {
  const AppointmentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAppointments extends AppointmentsEvent {
  const LoadAppointments();
}

class CreateAppointment extends AppointmentsEvent {
  final Map<String, dynamic> appointmentData;

  const CreateAppointment({required this.appointmentData});

  @override
  List<Object?> get props => [appointmentData];
}

class CancelAppointment extends AppointmentsEvent {
  final int appointmentId;

  const CancelAppointment({required this.appointmentId});

  @override
  List<Object?> get props => [appointmentId];
}
