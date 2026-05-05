import 'package:flutter_bloc/flutter_bloc.dart';
import 'queue_event.dart';
import 'queue_state.dart';

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  QueueBloc() : super(const QueueInitial()) {
    on<JoinQueueRequested>(_onJoinQueueRequested);
    on<LeaveQueueRequested>(_onLeaveQueueRequested);
    on<QueueStatusRequested>(_onQueueStatusRequested);
    on<WebSocketConnected>(_onWebSocketConnected);
    on<WebSocketDisconnected>(_onWebSocketDisconnected);
    on<QueuePositionUpdated>(_onQueuePositionUpdated);
  }

  Future<void> _onJoinQueueRequested(
      JoinQueueRequested event, Emitter<QueueState> emit) async {
    emit(const QueueLoading());
    try {
      emit(QueueJoined(
        position: 1,
        peopleAhead: 0,
        serviceId: event.serviceId,
        wsConnected: false,
      ));
    } catch (e) {
      emit(QueueError(message: e.toString()));
    }
  }

  Future<void> _onLeaveQueueRequested(
      LeaveQueueRequested event, Emitter<QueueState> emit) async {
    try {
      emit(const QueueNotJoined());
    } catch (e) {
      emit(QueueError(message: e.toString()));
    }
  }

  Future<void> _onQueueStatusRequested(
      QueueStatusRequested event, Emitter<QueueState> emit) async {
    // Placeholder - will be implemented with repository
  }

  Future<void> _onWebSocketConnected(
      WebSocketConnected event, Emitter<QueueState> emit) async {
    if (state is QueueJoined) {
      final current = state as QueueJoined;
      emit(QueueJoined(
        position: current.position,
        peopleAhead: current.peopleAhead,
        serviceId: current.serviceId,
        wsConnected: true,
      ));
    } else {
      emit(const QueueWebSocketConnected());
    }
  }

  Future<void> _onWebSocketDisconnected(
      WebSocketDisconnected event, Emitter<QueueState> emit) async {
    if (state is QueueJoined) {
      final current = state as QueueJoined;
      emit(QueueJoined(
        position: current.position,
        peopleAhead: current.peopleAhead,
        serviceId: current.serviceId,
        wsConnected: false,
      ));
    } else {
      emit(const QueueWebSocketDisconnected());
    }
  }

  Future<void> _onQueuePositionUpdated(
      QueuePositionUpdated event, Emitter<QueueState> emit) async {
    if (state is QueueJoined) {
      final current = state as QueueJoined;
      emit(QueueJoined(
        position: event.position,
        peopleAhead: event.peopleAhead,
        serviceId: current.serviceId,
        wsConnected: current.wsConnected,
      ));
    }
  }
}
