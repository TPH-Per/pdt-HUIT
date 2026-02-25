-- =====================================================
-- V25: Đổi tên Staff → Registrar (Cán bộ đào tạo)
-- Hệ thống quản lý Phòng Đào tạo
-- =====================================================
-- 1. Drop views liên quan
DROP VIEW IF EXISTS vw_queue_today;
DROP VIEW IF EXISTS vw_daily_stats;
-- 2. Drop tất cả FK constraints referencing 'staff' table
ALTER TABLE request_history DROP CONSTRAINT IF EXISTS fk_request_history_staff;
ALTER TABLE appointment DROP CONSTRAINT IF EXISTS fk_appointment_staff;
ALTER TABLE reply DROP CONSTRAINT IF EXISTS fk_reply_staff;
ALTER TABLE student_feedback DROP CONSTRAINT IF EXISTS fk_feedback_staff;
-- Drop FK từ staff ra ngoài
ALTER TABLE staff DROP CONSTRAINT IF EXISTS fk_staff_role;
ALTER TABLE staff DROP CONSTRAINT IF EXISTS fk_staff_desk;
-- 3. Rename table: staff → registrar
ALTER TABLE staff
    RENAME TO registrar;
-- 4. Rename column trong registrar: staff_code → registrar_code
ALTER TABLE registrar
    RENAME COLUMN staff_code TO registrar_code;
-- 5. Rename FK columns trong các bảng khác: staff_id → registrar_id
ALTER TABLE request_history
    RENAME COLUMN staff_id TO registrar_id;
ALTER TABLE appointment
    RENAME COLUMN staff_id TO registrar_id;
ALTER TABLE reply
    RENAME COLUMN staff_id TO registrar_id;
ALTER TABLE student_feedback
    RENAME COLUMN staff_id TO registrar_id;
-- 6. Recreate FK constraints cho registrar
ALTER TABLE registrar
ADD CONSTRAINT fk_registrar_role FOREIGN KEY (role_id) REFERENCES role(id);
ALTER TABLE registrar
ADD CONSTRAINT fk_registrar_desk FOREIGN KEY (desk_id) REFERENCES service_desk(id);
-- 7. Recreate FK constraints từ các bảng khác → registrar
ALTER TABLE request_history
ADD CONSTRAINT fk_request_history_registrar FOREIGN KEY (registrar_id) REFERENCES registrar(id);
ALTER TABLE appointment
ADD CONSTRAINT fk_appointment_registrar FOREIGN KEY (registrar_id) REFERENCES registrar(id);
ALTER TABLE reply
ADD CONSTRAINT fk_reply_registrar FOREIGN KEY (registrar_id) REFERENCES registrar(id);
ALTER TABLE student_feedback
ADD CONSTRAINT fk_feedback_registrar FOREIGN KEY (registrar_id) REFERENCES registrar(id);
-- 8. Cập nhật Role: "Staff" → "Registrar"
UPDATE role
SET role_name = 'Registrar',
    display_name = 'Cán bộ đào tạo',
    description = 'Cán bộ phòng đào tạo - xử lý yêu cầu sinh viên'
WHERE role_name = 'Staff';
-- 9. Cập nhật comments
COMMENT ON TABLE registrar IS 'Bảng cán bộ đào tạo - nhân sự phòng đào tạo xử lý yêu cầu sinh viên';
COMMENT ON COLUMN registrar.registrar_code IS 'Mã cán bộ đào tạo (unique)';
-- 10. Recreate views
CREATE OR REPLACE VIEW vw_queue_today AS
SELECT r.id AS request_id,
    r.request_code,
    r.queue_number,
    r.queue_prefix,
    r.current_phase,
    r.priority,
    s.student_id,
    s.full_name AS student_name,
    s.phone AS student_phone,
    asvc.service_name,
    asvc.service_code,
    rh.appointment_date,
    rh.expected_time,
    rh.registrar_id,
    reg.full_name AS registrar_name,
    sd.desk_name,
    sd.desk_code
FROM request r
    JOIN student s ON r.student_id = s.student_id
    JOIN academic_service asvc ON r.service_id = asvc.id
    LEFT JOIN request_history rh ON rh.request_id = r.id
    AND rh.appointment_date = CURRENT_DATE
    LEFT JOIN registrar reg ON rh.registrar_id = reg.id
    LEFT JOIN service_desk sd ON rh.desk_id = sd.id
WHERE rh.appointment_date = CURRENT_DATE
    AND r.current_phase IN (1, 2, 3)
ORDER BY rh.expected_time ASC;
CREATE OR REPLACE VIEW vw_daily_stats AS
SELECT CURRENT_DATE AS stat_date,
    COUNT(*) AS total_requests,
    COUNT(
        CASE
            WHEN r.current_phase = 1 THEN 1
        END
    ) AS waiting,
    COUNT(
        CASE
            WHEN r.current_phase = 2 THEN 1
        END
    ) AS pending,
    COUNT(
        CASE
            WHEN r.current_phase = 3 THEN 1
        END
    ) AS processing,
    COUNT(
        CASE
            WHEN r.current_phase = 4 THEN 1
        END
    ) AS completed,
    COUNT(
        CASE
            WHEN r.current_phase = 0 THEN 1
        END
    ) AS cancelled
FROM request r
    JOIN request_history rh ON rh.request_id = r.id
WHERE rh.appointment_date = CURRENT_DATE;