-- V15: Rename bảng và thêm cột appointment vào application_history
-- Lý do: Tên bảng dùng snake_case cho tường minh, và lưu lịch sử các lần hẹn
-- 1. Drop views trước (vì phụ thuộc vào các cột sẽ bị xóa)
DROP VIEW IF EXISTS vw_queue_today CASCADE;
DROP VIEW IF EXISTS vw_daily_stats CASCADE;
-- 2. Rename bảng từ applicationhistory sang application_history
ALTER TABLE IF EXISTS applicationhistory
    RENAME TO application_history;
-- 3. Thêm cột vào application_history
ALTER TABLE application_history
ADD COLUMN IF NOT EXISTS appointment_date DATE,
    ADD COLUMN IF NOT EXISTS expected_time TIME,
    ADD COLUMN IF NOT EXISTS queue_number INTEGER,
    ADD COLUMN IF NOT EXISTS queue_prefix VARCHAR(5);
-- 4. Migrate dữ liệu hiện có từ application sang history (nếu có)
INSERT INTO application_history (
        application_id,
        counter_id,
        phase_from,
        phase_to,
        action,
        content,
        appointment_date,
        expected_time,
        queue_number,
        queue_prefix,
        created_at
    )
SELECT a.id,
    COALESCE(
        (
            SELECT id
            FROM counter
            WHERE is_active = true
            LIMIT 1
        ), 1
    ), 0, a.current_phase, 'MIGRATE', 'Migrated from application table', a.appointment_date, a.expected_time, a.queue_number, a.queue_prefix, COALESCE(a.created_at, NOW())
FROM application a
WHERE a.appointment_date IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM application_history h
        WHERE h.application_id = a.id
            AND h.appointment_date IS NOT NULL
    );
-- 5. Xóa cột khỏi application (giữ queue_number và queue_prefix để hiển thị)
ALTER TABLE application DROP COLUMN IF EXISTS appointment_date,
    DROP COLUMN IF EXISTS expected_time;
-- 6. Recreate views với tên bảng mới
CREATE VIEW vw_queue_today AS
SELECT a.id,
    a.application_code,
    a.queue_prefix || a.queue_number AS queue_display,
    a.queue_number,
    c.full_name AS citizen_name,
    c.phone AS citizen_phone,
    p.procedure_name,
    h.expected_time,
    a.current_phase,
    a.created_at
FROM application a
    JOIN citizen c ON a.citizen_id = c.citizen_id
    JOIN procedure p ON a.procedure_id = p.id
    LEFT JOIN LATERAL (
        SELECT expected_time
        FROM application_history
        WHERE application_id = a.id
            AND expected_time IS NOT NULL
        ORDER BY created_at DESC
        LIMIT 1
    ) h ON TRUE
WHERE a.current_phase IN (1, 3)
ORDER BY a.queue_number;
CREATE VIEW vw_daily_stats AS
SELECT h.counter_id,
    co.counter_name,
    DATE(h.created_at) AS date,
    COUNT(*) FILTER (
        WHERE h.phase_to = 1
    ) AS queue_count,
    COUNT(*) FILTER (
        WHERE h.phase_to = 3
    ) AS processing_count,
    COUNT(*) FILTER (
        WHERE h.phase_to = 4
    ) AS completed_count,
    COUNT(*) FILTER (
        WHERE h.phase_to = 0
    ) AS cancelled_count,
    COUNT(*) FILTER (
        WHERE h.phase_to = 2
    ) AS pending_count
FROM application_history h
    JOIN counter co ON h.counter_id = co.id
GROUP BY h.counter_id,
    co.counter_name,
    DATE(h.created_at);
-- 7. Thêm index cho appointment_date
CREATE INDEX IF NOT EXISTS idx_history_appointment ON application_history(appointment_date);
-- 8. Thêm comment
COMMENT ON COLUMN application_history.appointment_date IS 'Ngày hẹn cho lần này';
COMMENT ON COLUMN application_history.expected_time IS 'Giờ dự kiến cho lần hẹn này';
COMMENT ON COLUMN application_history.queue_number IS 'Số thứ tự cho lần hẹn này';
COMMENT ON COLUMN application_history.queue_prefix IS 'Tiền tố số thứ tự (A, B, C...)';