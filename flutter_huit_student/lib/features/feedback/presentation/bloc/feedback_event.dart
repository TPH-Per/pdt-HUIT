import 'package:equatable/equatable.dart';

abstract class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

class SubmitFeedback extends FeedbackEvent {
  final String title;
  final String content;
  final String category;

  const SubmitFeedback({
    required this.title,
    required this.content,
    required this.category,
  });

  @override
  List<Object?> get props => [title, content, category];
}

class LoadFeedbackHistory extends FeedbackEvent {
  const LoadFeedbackHistory();
}
