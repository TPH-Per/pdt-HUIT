-- V10__performance_indexes.sql
CREATE INDEX idx_request_student_phase ON request(student_id, current_phase, created_at DESC);
CREATE INDEX idx_request_history_request ON request_history(request_id, created_at DESC);
CREATE INDEX idx_appointment_registrar_date ON appointment(registrar_id, appointment_date, status);
CREATE INDEX idx_student_feedback_student ON student_feedback(student_id, status, created_at DESC);
CREATE INDEX idx_report_student ON report(student_id, status, created_at DESC);
CREATE INDEX idx_reply_report ON reply(report_id, created_at ASC);