package com.huit.pdt.domain.notification.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class NotificationServiceImpl implements NotificationService {

    private final NamedParameterJdbcTemplate jdbc;
    private final Optional<FirebaseMessaging> firebaseMessaging;

    @Override
    public void createAndPush(String studentId, String type, String title, String body, Long refId, String refType) {
        String insertSql = "INSERT INTO notification (student_id, type, title, body, ref_id, ref_type) VALUES (:studentId, :type, :title, :body, :refId, :refType)";
        MapSqlParameterSource insertParams = new MapSqlParameterSource()
                .addValue("studentId", studentId)
                .addValue("type", type)
                .addValue("title", title)
                .addValue("body", body)
                .addValue("refId", refId)
                .addValue("refType", refType);
        jdbc.update(insertSql, insertParams);
        log.info("Created notification for student {}: {}", studentId, title);

        String fcmTokenSql = "SELECT fcm_token FROM student_device_token WHERE student_id = :studentId ORDER BY updated_at DESC";
        List<String> tokens = jdbc.queryForList(fcmTokenSql, Map.of("studentId", studentId), String.class);

        if (!firebaseMessaging.isPresent()) {
            log.debug("FirebaseMessaging is not available. Skipping FCM push.");
            return;
        }

        for (String token : tokens) {
            try {
                Message message = Message.builder()
                        .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                        .setToken(token)
                        .putData("type", type)
                        .putData("refId", refId != null ? refId.toString() : "")
                        .putData("refType", refType != null ? refType : "")
                        .build();
                String messageId = firebaseMessaging.get().send(message);
                log.info("Successfully sent FCM notification: {}", messageId);
            } catch (FirebaseMessagingException e) {
                if (MessagingErrorCode.UNREGISTERED.equals(e.getMessagingErrorCode())) {
                    jdbc.update("DELETE FROM student_device_token WHERE fcm_token = :token", Map.of("token", token));
                }
                log.warn("Failed to send FCM notification to token {}: {}", token, e.getMessage());
            }
        }
    }
}
