import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {
  const LoadNotifications();
}

class ReceiveNotification extends NotificationsEvent {
  final String title;
  final String body;

  const ReceiveNotification({required this.title, required this.body});

  @override
  List<Object?> get props => [title, body];
}

class MarkNotificationAsRead extends NotificationsEvent {
  final int notificationId;

  const MarkNotificationAsRead({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}
