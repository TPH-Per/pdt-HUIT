import 'package:equatable/equatable.dart';

abstract class RequestsEvent extends Equatable {
  const RequestsEvent();

  @override
  List<Object?> get props => [];
}

class LoadRequests extends RequestsEvent {
  const LoadRequests();
}

class CreateRequest extends RequestsEvent {
  final Map<String, dynamic> requestData;

  const CreateRequest({required this.requestData});

  @override
  List<Object?> get props => [requestData];
}

class CancelRequest extends RequestsEvent {
  final int requestId;

  const CancelRequest({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}
