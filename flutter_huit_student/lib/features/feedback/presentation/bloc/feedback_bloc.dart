import 'package:flutter_bloc/flutter_bloc.dart';
import 'feedback_event.dart';
import 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  FeedbackBloc() : super(const FeedbackInitial()) {
    on<SubmitFeedback>(_onFeedbackSubmitted);
    on<LoadFeedbackHistory>(_onFeedbackHistoryLoaded);
  }

  Future<void> _onFeedbackSubmitted(
      SubmitFeedback event, Emitter<FeedbackState> emit) async {
    emit(const FeedbackSubmitting());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const FeedbackSubmitted(
        message: 'Cảm ơn bạn đã gửi phản hồi!',
      ));
      emit(const FeedbackInitial());
    } catch (e) {
      emit(FeedbackError(message: e.toString()));
    }
  }

  Future<void> _onFeedbackHistoryLoaded(
      LoadFeedbackHistory event, Emitter<FeedbackState> emit) async {
    emit(const FeedbackHistoryLoading());
    try {
      emit(const FeedbackHistoryLoaded(feedbacks: []));
    } catch (e) {
      emit(FeedbackError(message: e.toString()));
    }
  }
}
