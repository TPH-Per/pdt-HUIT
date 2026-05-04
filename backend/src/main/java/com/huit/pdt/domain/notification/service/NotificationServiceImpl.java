package com.huit.pdt.domain.notification.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class NotificationServiceImpl implements NotificationService {

    private final NamedParameterJdbcTemplate jdbc;
    private final FirebaseMessaging firebaseMessaging;

    @Override
    public void createAndPush(String studentId, String type, String title, String body, Long refId, String refType) {
        String insertSql = "INSERT INTO notification (student_id, type, title, body, ref_id, ref_type) VALUES (:studentId, :type, :title, :body, :refId, :refType)";
        jdbc.update(insertSql, Map.of("studentId", studentId, "type", type, "title", title, "body", body, "refId", refId, "refType", refType));
        log.info("Created notification for student {}: {}", studentId, title);

        String fcmTokenSql = "SELECT fcm_token FROM student_device_token WHERE student_id = :studentId ORDER BY updated_at DESC LIMIT 1";
        String fcmToken = jdbc.query(fcmTokenSql, Map.of("studentId", studentId), (rs, rowNum) -> rs.getString("fcm_token")).stream().findFirst().orElse(null);

        if (fcmToken != null) {
            try {
                Message message = Message.builder().setNotification(Notification.builder().setTitle(title).setBody(body).build()).setToken(fcmToken).putData("type", type).putData("refId", refId != null ? refId.toString() : "").putData("refType", refType != null ? refType : "").build();
                String messageId = firebaseMessaging.send(message);
                log.info("Successfully sent FCM notification: {}", messageId);
            } catch (FirebaseMessagingException e) {
                log.error("Failed to send FCM notification to student {}: {}", studentId, e.getMessage());
            }
        } else {
            log.warn("No FCM token found for student {}", studentId);
        }
    }
}
