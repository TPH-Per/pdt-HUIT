import 'package:flutter_bloc/flutter_bloc.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc() : super(const NotificationsInitial()) {
    on<LoadNotifications>(_onNotificationsLoaded);
    on<ReceiveNotification>(_onNotificationReceived);
    on<MarkNotificationAsRead>(_onNotificationMarkedAsRead);
  }

  Future<void> _onNotificationsLoaded(
      LoadNotifications event, Emitter<NotificationsState> emit) async {
    emit(const NotificationsLoading());
    try {
      emit(const NotificationsLoaded(notifications: []));
    } catch (e) {
      emit(NotificationsError(message: e.toString()));
    }
  }

  Future<void> _onNotificationReceived(
      ReceiveNotification event, Emitter<NotificationsState> emit) async {
    try {
      final newNotification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch,
        title: event.title,
        body: event.body,
        createdAt: DateTime.now(),
        isRead: false,
      );

      if (state is NotificationsLoaded) {
        final current = state as NotificationsLoaded;
        emit(NotificationsLoaded(
          notifications: [newNotification, ...current.notifications],
        ));
      } else {
        emit(NotificationsLoaded(notifications: [newNotification]));
      }
    } catch (e) {
      emit(NotificationsError(message: e.toString()));
    }
  }

  Future<void> _onNotificationMarkedAsRead(
      MarkNotificationAsRead event, Emitter<NotificationsState> emit) async {
    try {
      if (state is NotificationsLoaded) {
        final current = state as NotificationsLoaded;
        final updated = current.notifications.map((n) {
          return n.id == event.notificationId
              ? NotificationItem(
                  id: n.id,
                  title: n.title,
                  body: n.body,
                  createdAt: n.createdAt,
                  isRead: true,
                )
              : n;
        }).toList();
        emit(NotificationsLoaded(notifications: updated));
      }
    } catch (e) {
      emit(NotificationsError(message: e.toString()));
    }
  }
}
