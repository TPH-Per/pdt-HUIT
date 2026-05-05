-- V9__create_student_device_token.sql
CREATE TABLE student_device_token (
    id         BIGSERIAL PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL REFERENCES student(student_id) ON DELETE CASCADE,
    fcm_token  VARCHAR(512) NOT NULL,
    platform   VARCHAR(10) DEFAULT 'android',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_student_fcm UNIQUE (student_id, fcm_token)
);