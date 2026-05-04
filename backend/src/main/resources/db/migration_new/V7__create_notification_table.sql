-- V7: Create notification table for user notifications (queue status, appointment reminders, etc)

CREATE TABLE IF NOT EXISTS notification (
    id BIGSERIAL PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200),
    body TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES student(student_id) ON DELETE CASCADE
);

CREATE INDEX idx_notification_student_id ON notification(student_id);
CREATE INDEX idx_notification_created_at ON notification(created_at DESC);
CREATE INDEX idx_notification_is_read ON notification(is_read);
CREATE INDEX idx_notification_type ON notification(type);

ALTER TABLE notification OWNER TO per;
