import 'package:equatable/equatable.dart';

abstract class QueueState extends Equatable {
  const QueueState();

  @override
  List<Object?> get props => [];
}

class QueueInitial extends QueueState {
  const QueueInitial();
}

class QueueLoading extends QueueState {
  const QueueLoading();
}

class QueueNotJoined extends QueueState {
  const QueueNotJoined();
}

class QueueJoined extends QueueState {
  final int position;
  final int peopleAhead;
  final int serviceId;
  final bool wsConnected;

  const QueueJoined({
    required this.position,
    required this.peopleAhead,
    required this.serviceId,
    required this.wsConnected,
  });

  @override
  List<Object?> get props => [position, peopleAhead, serviceId, wsConnected];
}

class QueueError extends QueueState {
  final String message;

  const QueueError({required this.message});

  @override
  List<Object?> get props => [message];
}

class QueueWebSocketConnected extends QueueState {
  const QueueWebSocketConnected();
}

class QueueWebSocketDisconnected extends QueueState {
  const QueueWebSocketDisconnected();
}
