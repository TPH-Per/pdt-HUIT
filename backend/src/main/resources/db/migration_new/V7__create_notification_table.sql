-- V7__create_notification.sql
CREATE TABLE notification (
    id         BIGSERIAL PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL REFERENCES student(student_id) ON DELETE CASCADE,
    type       VARCHAR(50)  NOT NULL,
    title      VARCHAR(255) NOT NULL,
    body       TEXT,
    is_read    BOOLEAN DEFAULT FALSE,
    ref_id     BIGINT,
    ref_type   VARCHAR(30),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_notification_student_unread
    ON notification(student_id, is_read, created_at DESC);