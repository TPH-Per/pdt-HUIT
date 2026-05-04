-- flyway:noTransaction
-- V10: Add performance indexes for concurrent queue operations

CREATE INDEX CONCURRENTLY idx_queue_current_number ON queue(current_number);
CREATE INDEX CONCURRENTLY idx_queue_updated_at ON queue(updated_at DESC);
CREATE INDEX CONCURRENTLY idx_student_full_name ON student(full_name);
CREATE INDEX CONCURRENTLY idx_appointment_status_date ON appointment(status, appointment_date);
CREATE INDEX CONCURRENTLY idx_request_phase_student ON request(current_phase, student_id);
CREATE INDEX CONCURRENTLY idx_student_feedback_student_id ON student_feedback(student_id);
CREATE INDEX CONCURRENTLY idx_registrar_desk_id ON registrar(desk_id);
