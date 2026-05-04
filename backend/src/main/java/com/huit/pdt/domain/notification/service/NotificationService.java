package com.huit.pdt.domain.notification.service;

public interface NotificationService {
    void createAndPush(String studentId, String type, String title, String body, Long refId, String refType);
}
