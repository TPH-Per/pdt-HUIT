import 'package:flutter_bloc/flutter_bloc.dart';
import 'appointments_event.dart';
import 'appointments_state.dart';

class AppointmentsBloc extends Bloc<AppointmentsEvent, AppointmentsState> {
  AppointmentsBloc() : super(const AppointmentsInitial()) {
    on<LoadAppointments>(_onAppointmentsLoaded);
    on<CreateAppointment>(_onAppointmentCreated);
    on<CancelAppointment>(_onAppointmentCancelled);
  }

  Future<void> _onAppointmentsLoaded(
      LoadAppointments event, Emitter<AppointmentsState> emit) async {
    emit(const AppointmentsLoading());
    try {
      emit(const AppointmentsLoaded(appointments: []));
    } catch (e) {
      emit(AppointmentsError(message: e.toString()));
    }
  }

  Future<void> _onAppointmentCreated(
      CreateAppointment event, Emitter<AppointmentsState> emit) async {
    try {
      if (state is AppointmentsLoaded) {
        final current = state as AppointmentsLoaded;
        final newAppointment = AppointmentItem(
          id: DateTime.now().millisecondsSinceEpoch,
          code: 'APT${DateTime.now().millisecondsSinceEpoch}',
          procedureName: event.appointmentData['procedureName'] ?? '',
          status: 'scheduled',
          appointmentDate:
              DateTime.parse(event.appointmentData['appointmentDate']),
          appointmentTime: event.appointmentData['appointmentTime'] ?? '',
        );
        emit(AppointmentsLoaded(
          appointments: [newAppointment, ...current.appointments],
        ));
      }
    } catch (e) {
      emit(AppointmentsError(message: e.toString()));
    }
  }

  Future<void> _onAppointmentCancelled(
      CancelAppointment event, Emitter<AppointmentsState> emit) async {
    try {
      if (state is AppointmentsLoaded) {
        final current = state as AppointmentsLoaded;
        emit(AppointmentsLoaded(
          appointments: current.appointments
              .where((a) => a.id != event.appointmentId)
              .toList(),
        ));
      }
    } catch (e) {
      emit(AppointmentsError(message: e.toString()));
    }
  }
}
