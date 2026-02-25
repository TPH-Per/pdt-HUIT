-- =============================================
-- V24: REFACTOR TO UNIVERSITY STUDENT SERVICES
-- Hành chính công → Hệ thống Một cửa Đại học
-- =============================================
SET timezone = 'Asia/Ho_Chi_Minh';
-- =============================================
-- STEP 1: DROP VIEWS (they reference old table/column names)
-- =============================================
DROP VIEW IF EXISTS vw_queue_today CASCADE;
DROP VIEW IF EXISTS vw_daily_stats CASCADE;
-- =============================================
-- STEP 2: DROP FOREIGN KEY CONSTRAINTS
-- =============================================
-- Application (→ request) FKs
ALTER TABLE application DROP CONSTRAINT IF EXISTS fk_app_procedure;
ALTER TABLE application DROP CONSTRAINT IF EXISTS fk_app_citizen;
ALTER TABLE application DROP CONSTRAINT IF EXISTS fk_app_zalo;
-- ApplicationHistory FKs
ALTER TABLE application_history DROP CONSTRAINT IF EXISTS fk_history_app;
ALTER TABLE application_history DROP CONSTRAINT IF EXISTS fk_history_counter;
ALTER TABLE application_history DROP CONSTRAINT IF EXISTS fk_history_staff;
-- Appointment FKs
ALTER TABLE appointment DROP CONSTRAINT IF EXISTS appointment_application_id_fkey;
-- Staff FKs
ALTER TABLE staff DROP CONSTRAINT IF EXISTS fk_staff_counter;
ALTER TABLE staff DROP CONSTRAINT IF EXISTS fk_staff_role;
-- Counter / Procedure FKs
ALTER TABLE counter DROP CONSTRAINT IF EXISTS fk_counter_pt;
ALTER TABLE procedure DROP CONSTRAINT IF EXISTS fk_procedure_pt;
-- Report FKs
ALTER TABLE report DROP CONSTRAINT IF EXISTS fk_report_citizen;
ALTER TABLE report DROP CONSTRAINT IF EXISTS fk_report_app;
-- Reply FKs
ALTER TABLE reply DROP CONSTRAINT IF EXISTS fk_reply_report;
ALTER TABLE reply DROP CONSTRAINT IF EXISTS fk_reply_staff;
-- =============================================
-- STEP 3: DROP ZaloAccount TABLE
-- =============================================
ALTER TABLE application DROP COLUMN IF EXISTS zalo_account_id;
DROP TABLE IF EXISTS zaloaccount CASCADE;
-- =============================================
-- STEP 4: RENAME TABLES
-- =============================================
ALTER TABLE citizen
    RENAME TO student;
ALTER TABLE procedure
    RENAME TO academic_service;
ALTER TABLE procedure_type
    RENAME TO service_category;
ALTER TABLE counter
    RENAME TO service_desk;
ALTER TABLE application
    RENAME TO request;
ALTER TABLE application_history
    RENAME TO request_history;
-- Rename GopYPhanAnh → student_feedback
DO $$ BEGIN IF EXISTS (
    SELECT
    FROM information_schema.tables
    WHERE table_name = 'gopyphananh'
) THEN
ALTER TABLE "GopYPhanAnh"
    RENAME TO student_feedback;
END IF;
END $$;
-- =============================================
-- STEP 5: RENAME COLUMNS — student (was citizen)
-- =============================================
ALTER TABLE student
    RENAME COLUMN citizen_id TO student_id;
ALTER TABLE student
    RENAME COLUMN address TO major;
-- Resize student_id from VARCHAR(12) to VARCHAR(10) for MSSV
ALTER TABLE student
ALTER COLUMN student_id TYPE VARCHAR(10);
-- =============================================
-- STEP 6: RENAME COLUMNS — academic_service (was procedure)
-- =============================================
ALTER TABLE academic_service
    RENAME COLUMN procedure_code TO service_code;
ALTER TABLE academic_service
    RENAME COLUMN procedure_name TO service_name;
ALTER TABLE academic_service
    RENAME COLUMN procedure_type_id TO service_category_id;
-- =============================================
-- STEP 7: RENAME COLUMNS — service_desk (was counter)
-- =============================================
ALTER TABLE service_desk
    RENAME COLUMN counter_code TO desk_code;
ALTER TABLE service_desk
    RENAME COLUMN counter_name TO desk_name;
ALTER TABLE service_desk
    RENAME COLUMN procedure_type_id TO service_category_id;
-- =============================================
-- STEP 8: RENAME COLUMNS — request (was application)
-- =============================================
ALTER TABLE request
    RENAME COLUMN application_code TO request_code;
ALTER TABLE request
    RENAME COLUMN procedure_id TO service_id;
ALTER TABLE request
    RENAME COLUMN citizen_id TO student_id;
-- Resize student_id FK
ALTER TABLE request
ALTER COLUMN student_id TYPE VARCHAR(10);
-- =============================================
-- STEP 9: RENAME COLUMNS — request_history (was application_history)
-- =============================================
ALTER TABLE request_history
    RENAME COLUMN application_id TO request_id;
ALTER TABLE request_history
    RENAME COLUMN counter_id TO desk_id;
-- =============================================
-- STEP 10: RENAME COLUMNS — appointment
-- =============================================
ALTER TABLE appointment
    RENAME COLUMN application_id TO request_id;
-- =============================================
-- STEP 11: RENAME COLUMNS — staff
-- =============================================
ALTER TABLE staff
    RENAME COLUMN counter_id TO desk_id;
-- =============================================
-- STEP 12: RENAME COLUMNS — report
-- =============================================
ALTER TABLE report
    RENAME COLUMN citizen_id TO student_id;
ALTER TABLE report
    RENAME COLUMN application_id TO request_id;
ALTER TABLE report
ALTER COLUMN student_id TYPE VARCHAR(10);
-- =============================================
-- STEP 13: RENAME COLUMNS — student_feedback (was GopYPhanAnh)
-- =============================================
DO $$ BEGIN IF EXISTS (
    SELECT
    FROM information_schema.tables
    WHERE table_name = 'student_feedback'
) THEN -- Rename Vietnamese columns to English
ALTER TABLE student_feedback
    RENAME COLUMN magopy TO feedback_code;
ALTER TABLE student_feedback
    RENAME COLUMN cccd TO student_id;
ALTER TABLE student_feedback
    RENAME COLUMN loaigopy TO feedback_type;
ALTER TABLE student_feedback
    RENAME COLUMN tieude TO title;
ALTER TABLE student_feedback
    RENAME COLUMN noidung TO content;
ALTER TABLE student_feedback
    RENAME COLUMN filedinhkem TO attachments;
ALTER TABLE student_feedback
    RENAME COLUMN hosoid TO request_id;
ALTER TABLE student_feedback
    RENAME COLUMN trangthai TO status;
ALTER TABLE student_feedback
    RENAME COLUMN douutien TO priority;
ALTER TABLE student_feedback
    RENAME COLUMN nhanvienxulyid TO staff_id;
ALTER TABLE student_feedback
    RENAME COLUMN ghichunoibo TO internal_note;
ALTER TABLE student_feedback
    RENAME COLUMN ngaytao TO created_at;
ALTER TABLE student_feedback
    RENAME COLUMN ngayxuly TO processed_at;
ALTER TABLE student_feedback
    RENAME COLUMN ngayhoanthanh TO completed_at;
ALTER TABLE student_feedback
    RENAME COLUMN danhgia TO rating;
ALTER TABLE student_feedback
    RENAME COLUMN phanhoidanhgia TO rating_feedback;
-- Drop zalo column
ALTER TABLE student_feedback DROP COLUMN IF EXISTS zaloid;
-- Resize student_id
ALTER TABLE student_feedback
ALTER COLUMN student_id TYPE VARCHAR(10);
END IF;
END $$;
-- =============================================
-- STEP 14: RECREATE FOREIGN KEY CONSTRAINTS
-- =============================================
-- request (was application)
ALTER TABLE request
ADD CONSTRAINT fk_request_service FOREIGN KEY (service_id) REFERENCES academic_service(id);
ALTER TABLE request
ADD CONSTRAINT fk_request_student FOREIGN KEY (student_id) REFERENCES student(student_id);
-- request_history
ALTER TABLE request_history
ADD CONSTRAINT fk_history_request FOREIGN KEY (request_id) REFERENCES request(id) ON DELETE CASCADE;
ALTER TABLE request_history
ADD CONSTRAINT fk_history_desk FOREIGN KEY (desk_id) REFERENCES service_desk(id);
ALTER TABLE request_history
ADD CONSTRAINT fk_history_staff FOREIGN KEY (staff_id) REFERENCES staff(id);
-- appointment
ALTER TABLE appointment
ADD CONSTRAINT fk_appointment_request FOREIGN KEY (request_id) REFERENCES request(id);
-- staff
ALTER TABLE staff
ADD CONSTRAINT fk_staff_desk FOREIGN KEY (desk_id) REFERENCES service_desk(id);
ALTER TABLE staff
ADD CONSTRAINT fk_staff_role FOREIGN KEY (role_id) REFERENCES role(id);
-- service_desk
ALTER TABLE service_desk
ADD CONSTRAINT fk_desk_category FOREIGN KEY (service_category_id) REFERENCES service_category(id);
-- academic_service
ALTER TABLE academic_service
ADD CONSTRAINT fk_service_category FOREIGN KEY (service_category_id) REFERENCES service_category(id);
-- report
ALTER TABLE report
ADD CONSTRAINT fk_report_student FOREIGN KEY (student_id) REFERENCES student(student_id);
ALTER TABLE report
ADD CONSTRAINT fk_report_request FOREIGN KEY (request_id) REFERENCES request(id);
-- reply
ALTER TABLE reply
ADD CONSTRAINT fk_reply_report FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE;
ALTER TABLE reply
ADD CONSTRAINT fk_reply_staff FOREIGN KEY (staff_id) REFERENCES staff(id);
-- =============================================
-- STEP 15: RECREATE VIEWS
-- =============================================
CREATE VIEW vw_queue_today AS
SELECT r.id,
    r.request_code,
    r.queue_prefix || r.queue_number AS queue_display,
    r.queue_number,
    s.full_name AS student_name,
    s.phone AS student_phone,
    svc.service_name,
    r.expected_time,
    r.current_phase,
    r.created_at
FROM request r
    JOIN student s ON r.student_id = s.student_id
    JOIN academic_service svc ON r.service_id = svc.id
WHERE r.appointment_date = CURRENT_DATE
    AND r.current_phase IN (1, 3)
ORDER BY r.queue_number;
CREATE VIEW vw_daily_stats AS
SELECT h.desk_id,
    d.desk_name,
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
FROM request_history h
    JOIN service_desk d ON h.desk_id = d.id
GROUP BY h.desk_id,
    d.desk_name,
    DATE(h.created_at);
-- =============================================
-- STEP 16: UPDATE SAMPLE DATA
-- =============================================
-- Update service categories (was procedure_type)
UPDATE service_category
SET name = 'Học vụ',
    description = 'Academic affairs services'
WHERE id = 1;
UPDATE service_category
SET name = 'Tài chính',
    description = 'Financial services'
WHERE id = 2;
UPDATE service_category
SET name = 'Hỗ trợ SV',
    description = 'Student support services'
WHERE id = 3;
-- Update service desks (was counters)
UPDATE service_desk
SET desk_code = 'SD01',
    desk_name = 'Quầy 1 - Học vụ',
    location = 'Tầng 1'
WHERE id = 1;
UPDATE service_desk
SET desk_code = 'SD02',
    desk_name = 'Quầy 2 - Tài chính',
    location = 'Tầng 1'
WHERE id = 2;
UPDATE service_desk
SET desk_code = 'SD03',
    desk_name = 'Quầy 3 - Hỗ trợ SV',
    location = 'Tầng 1'
WHERE id = 3;
-- Update academic services (was procedures)
UPDATE academic_service
SET service_code = 'DV001',
    service_name = 'Xin bảng điểm',
    description = 'Cấp bảng điểm học tập',
    processing_days = 3
WHERE id = 1;
UPDATE academic_service
SET service_code = 'DV002',
    service_name = 'Đơn bảo lưu',
    description = 'Bảo lưu kết quả học tập',
    processing_days = 5
WHERE id = 2;
UPDATE academic_service
SET service_code = 'DV003',
    service_name = 'Xác nhận sinh viên',
    description = 'Cấp giấy xác nhận đang là sinh viên',
    processing_days = 2
WHERE id = 3;
UPDATE academic_service
SET service_code = 'DV004',
    service_name = 'Cấp lại thẻ SV',
    description = 'Cấp lại thẻ sinh viên bị mất/hỏng',
    processing_days = 7
WHERE id = 4;
UPDATE academic_service
SET service_code = 'DV005',
    service_name = 'Đơn xin chuyển ngành',
    description = 'Chuyển ngành học',
    processing_days = 15
WHERE id = 5;
-- Update sample students (was citizens)
UPDATE student
SET student_id = '2001215001',
    full_name = 'Phạm Văn An',
    major = 'Công nghệ thông tin',
    date_of_birth = '2002-05-15',
    gender = 'Male',
    phone = '0901234567',
    email = 'pva@student.edu.vn'
WHERE student_id = '079001234567';
UPDATE student
SET student_id = '2001215002',
    full_name = 'Hoàng Thị Bình',
    major = 'Quản trị kinh doanh',
    date_of_birth = '2003-10-20',
    gender = 'Female',
    phone = '0901234568',
    email = 'htb@student.edu.vn'
WHERE student_id = '079001234568';
-- Update staff emails
UPDATE staff
SET email = 'admin@university.edu.vn'
WHERE staff_code = 'ADMIN';
UPDATE staff
SET email = 'nva@university.edu.vn'
WHERE staff_code = 'NV001';
UPDATE staff
SET email = 'ttb@university.edu.vn'
WHERE staff_code = 'NV002';
UPDATE staff
SET email = 'lvc@university.edu.vn'
WHERE staff_code = 'NV003';
-- =============================================
-- STEP 17: UPDATE TABLE COMMENTS
-- =============================================
COMMENT ON TABLE student IS 'Students using university one-stop services (MSSV as PK)';
COMMENT ON TABLE academic_service IS 'Academic services offered (transcript, enrollment confirmation, etc.)';
COMMENT ON TABLE service_category IS 'Service categories grouping services and desks';
COMMENT ON TABLE service_desk IS 'Service desks serving students';
COMMENT ON TABLE request IS 'Student service requests with phase tracking';
COMMENT ON TABLE request_history IS 'History of request phase changes';
COMMENT ON TABLE appointment IS 'Scheduled appointments for service requests';
COMMENT ON TABLE report IS 'Student reports and complaints';
COMMENT ON TABLE reply IS 'Staff replies to student reports';
DO $$ BEGIN IF EXISTS (
    SELECT
    FROM information_schema.tables
    WHERE table_name = 'student_feedback'
) THEN COMMENT ON TABLE student_feedback IS 'Student feedback, complaints, and compliments';
END IF;
END $$;
-- Update request student_id FKs for resized MSSV
UPDATE request
SET student_id = '2001215001'
WHERE student_id = '079001234567';
UPDATE request
SET student_id = '2001215002'
WHERE student_id = '079001234568';
UPDATE report
SET student_id = '2001215001'
WHERE student_id = '079001234567';
UPDATE report
SET student_id = '2001215002'
WHERE student_id = '079001234568';