import 'package:flutter_bloc/flutter_bloc.dart';
import 'requests_event.dart';
import 'requests_state.dart';

class RequestsBloc extends Bloc<RequestsEvent, RequestsState> {
  RequestsBloc() : super(const RequestsInitial()) {
    on<LoadRequests>(_onRequestsLoaded);
    on<CreateRequest>(_onRequestCreated);
    on<CancelRequest>(_onRequestCancelled);
  }

  Future<void> _onRequestsLoaded(
      LoadRequests event, Emitter<RequestsState> emit) async {
    emit(const RequestsLoading());
    try {
      emit(const RequestsLoaded(requests: []));
    } catch (e) {
      emit(RequestsError(message: e.toString()));
    }
  }

  Future<void> _onRequestCreated(
      CreateRequest event, Emitter<RequestsState> emit) async {
    try {
      if (state is RequestsLoaded) {
        final current = state as RequestsLoaded;
        final newRequest = RequestItem(
          id: DateTime.now().millisecondsSinceEpoch,
          code: 'REQ${DateTime.now().millisecondsSinceEpoch}',
          title: event.requestData['title'] ?? '',
          status: 'pending',
          createdAt: DateTime.now(),
        );
        emit(RequestsLoaded(
          requests: [newRequest, ...current.requests],
        ));
      }
    } catch (e) {
      emit(RequestsError(message: e.toString()));
    }
  }

  Future<void> _onRequestCancelled(
      CancelRequest event, Emitter<RequestsState> emit) async {
    try {
      if (state is RequestsLoaded) {
        final current = state as RequestsLoaded;
        emit(RequestsLoaded(
          requests:
              current.requests.where((r) => r.id != event.requestId).toList(),
        ));
      }
    } catch (e) {
      emit(RequestsError(message: e.toString()));
    }
  }
}
