-- V9: Create student_device_token table for FCM push notifications

CREATE TABLE IF NOT EXISTS student_device_token (
    id BIGSERIAL PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL,
    device_token VARCHAR(500) NOT NULL UNIQUE,
    device_type VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES student(student_id) ON DELETE CASCADE,
    CONSTRAINT valid_device_type CHECK (device_type IN ('IOS', 'ANDROID', 'WEB'))
);

CREATE INDEX idx_student_device_token_student_id ON student_device_token(student_id);
CREATE INDEX idx_student_device_token_is_active ON student_device_token(is_active);
CREATE INDEX idx_student_device_token_created_at ON student_device_token(created_at DESC);

ALTER TABLE student_device_token OWNER TO per;
