import 'package:equatable/equatable.dart';

abstract class QueueEvent extends Equatable {
  const QueueEvent();

  @override
  List<Object?> get props => [];
}

class JoinQueueRequested extends QueueEvent {
  final int serviceId;

  const JoinQueueRequested({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}

class LeaveQueueRequested extends QueueEvent {
  const LeaveQueueRequested();
}

class QueueStatusRequested extends QueueEvent {
  const QueueStatusRequested();
}

class WebSocketConnected extends QueueEvent {
  const WebSocketConnected();
}

class WebSocketDisconnected extends QueueEvent {
  const WebSocketDisconnected();
}

class QueuePositionUpdated extends QueueEvent {
  final int position;
  final int peopleAhead;

  const QueuePositionUpdated({required this.position, required this.peopleAhead});

  @override
  List<Object?> get props => [position, peopleAhead];
}
