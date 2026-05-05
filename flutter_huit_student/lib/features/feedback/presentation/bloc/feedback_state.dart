import 'package:equatable/equatable.dart';

abstract class FeedbackState extends Equatable {
  const FeedbackState();

  @override
  List<Object?> get props => [];
}

class FeedbackInitial extends FeedbackState {
  const FeedbackInitial();
}

class FeedbackSubmitting extends FeedbackState {
  const FeedbackSubmitting();
}

class FeedbackSubmitted extends FeedbackState {
  final String message;

  const FeedbackSubmitted({required this.message});

  @override
  List<Object?> get props => [message];
}

class FeedbackHistoryLoading extends FeedbackState {
  const FeedbackHistoryLoading();
}

class FeedbackHistoryLoaded extends FeedbackState {
  final List<Map<String, dynamic>> feedbacks;

  const FeedbackHistoryLoaded({required this.feedbacks});

  @override
  List<Object?> get props => [feedbacks];
}

class FeedbackError extends FeedbackState {
  final String message;

  const FeedbackError({required this.message});

  @override
  List<Object?> get props => [message];
}
