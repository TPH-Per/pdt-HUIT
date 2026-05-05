import 'package:equatable/equatable.dart';

class RequestItem extends Equatable {
  final int id;
  final String code;
  final String title;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;

  const RequestItem({
    required this.id,
    required this.code,
    required this.title,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  @override
  List<Object?> get props =>
      [id, code, title, status, createdAt, completedAt];
}

abstract class RequestsState extends Equatable {
  const RequestsState();

  @override
  List<Object?> get props => [];
}

class RequestsInitial extends RequestsState {
  const RequestsInitial();
}

class RequestsLoading extends RequestsState {
  const RequestsLoading();
}

class RequestsLoaded extends RequestsState {
  final List<RequestItem> requests;

  const RequestsLoaded({required this.requests});

  @override
  List<Object?> get props => [requests];
}

class RequestsError extends RequestsState {
  final String message;

  const RequestsError({required this.message});

  @override
  List<Object?> get props => [message];
}
