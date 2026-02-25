-- ===========================================================
-- HỆ THỐNG QUẢN LÝ PHÒNG ĐÀO TẠO — ĐẠI HỌC CÔNG THƯƠNG TP.HCM (HUIT)
-- PostgreSQL Database · Single-file Init Migration
-- ===========================================================
SET timezone = 'Asia/Ho_Chi_Minh';
-- ===========================================================
-- 1. ROLE — Vai trò người dùng
-- ===========================================================
CREATE TABLE role (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT
);
COMMENT ON TABLE role IS 'Admin / Registrar (Cán bộ đào tạo)';
INSERT INTO role (role_name, display_name, description)
VALUES (
        'Admin',
        'Quản trị viên',
        'Quản trị hệ thống'
    ),
    (
        'Registrar',
        'Cán bộ đào tạo',
        'Cán bộ phòng đào tạo – xử lý yêu cầu sinh viên'
    );
-- ===========================================================
-- 2. SERVICE_CATEGORY — Nhóm dịch vụ
-- ===========================================================
CREATE TABLE service_category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE service_category IS 'Nhóm dịch vụ đào tạo (Học vụ, Tài chính, Hỗ trợ SV)';
INSERT INTO service_category (name, description)
VALUES ('Học vụ', 'Academic affairs services'),
    ('Tài chính', 'Financial services'),
    ('Hỗ trợ SV', 'Student support services');
-- ===========================================================
-- 3. SERVICE_DESK — Quầy phục vụ
-- ===========================================================
CREATE TABLE service_desk (
    id SERIAL PRIMARY KEY,
    desk_code VARCHAR(20) UNIQUE NOT NULL,
    desk_name VARCHAR(100) NOT NULL,
    location VARCHAR(200),
    service_category_id INTEGER REFERENCES service_category(id),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE service_desk IS 'Quầy tiếp nhận sinh viên';
INSERT INTO service_desk (
        desk_code,
        desk_name,
        location,
        service_category_id
    )
VALUES ('SD01', 'Quầy 1 – Học vụ', 'Tầng 1', 1),
    ('SD02', 'Quầy 2 – Tài chính', 'Tầng 1', 2),
    ('SD03', 'Quầy 3 – Hỗ trợ SV', 'Tầng 1', 3);
-- ===========================================================
-- 4. ACADEMIC_SERVICE — Dịch vụ đào tạo
-- ===========================================================
CREATE TABLE academic_service (
    id SERIAL PRIMARY KEY,
    service_code VARCHAR(20) UNIQUE NOT NULL,
    service_name VARCHAR(200) NOT NULL,
    description TEXT,
    processing_days INTEGER DEFAULT 5,
    service_category_id INTEGER REFERENCES service_category(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE academic_service IS 'Dịch vụ đào tạo (bảng điểm, xác nhận SV, …)';
INSERT INTO academic_service (
        service_code,
        service_name,
        description,
        processing_days,
        service_category_id
    )
VALUES (
        'DV001',
        'Xin bảng điểm',
        'Cấp bảng điểm học tập',
        3,
        1
    ),
    (
        'DV002',
        'Đơn bảo lưu',
        'Bảo lưu kết quả học tập',
        5,
        1
    ),
    (
        'DV003',
        'Xác nhận sinh viên',
        'Cấp giấy xác nhận đang là sinh viên',
        2,
        1
    ),
    (
        'DV004',
        'Cấp lại thẻ SV',
        'Cấp lại thẻ sinh viên bị mất/hỏng',
        7,
        3
    ),
    (
        'DV005',
        'Đơn xin chuyển ngành',
        'Chuyển ngành học',
        15,
        1
    );
-- ===========================================================
-- 5. REGISTRAR — Cán bộ đào tạo (was: staff)
-- ===========================================================
CREATE TABLE registrar (
    id SERIAL PRIMARY KEY,
    registrar_code VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    role_id INTEGER NOT NULL REFERENCES role(id),
    desk_id INTEGER REFERENCES service_desk(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE registrar IS 'Cán bộ phòng đào tạo – xử lý yêu cầu sinh viên';
-- Mật khẩu mặc định: 123456 (bcrypt)
INSERT INTO registrar (
        registrar_code,
        full_name,
        email,
        phone,
        password_hash,
        role_id,
        desk_id
    )
VALUES (
        'ADMIN',
        'Administrator',
        'admin@huit.edu.vn',
        '0900000000',
        '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        1,
        NULL
    ),
    (
        'NV001',
        'Nguyễn Văn An',
        'nva@huit.edu.vn',
        '0901111111',
        '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        2,
        1
    ),
    (
        'NV002',
        'Trần Thị Bình',
        'ttb@huit.edu.vn',
        '0902222222',
        '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        2,
        2
    ),
    (
        'NV003',
        'Lê Văn Cường',
        'lvc@huit.edu.vn',
        '0903333333',
        '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        2,
        3
    );
-- ===========================================================
-- 6. STUDENT — Sinh viên
-- ===========================================================
CREATE TABLE student (
    student_id VARCHAR(10) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    major VARCHAR(200),
    date_of_birth DATE,
    gender VARCHAR(10),
    phone VARCHAR(20),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE student IS 'Sinh viên sử dụng dịch vụ Phòng Đào tạo (MSSV là PK)';
INSERT INTO student (
        student_id,
        full_name,
        major,
        date_of_birth,
        gender,
        phone,
        email
    )
VALUES (
        '2001215001',
        'Phạm Văn An',
        'Công nghệ thông tin',
        '2002-05-15',
        'Male',
        '0901234567',
        'pva@student.huit.edu.vn'
    ),
    (
        '2001215002',
        'Hoàng Thị Bình',
        'Quản trị kinh doanh',
        '2003-10-20',
        'Female',
        '0901234568',
        'htb@student.huit.edu.vn'
    ),
    (
        '2001215003',
        'Trần Minh Châu',
        'An toàn thông tin',
        '2002-08-12',
        'Male',
        '0901234569',
        'tmc@student.huit.edu.vn'
    );
-- ===========================================================
-- 7. REQUEST — Yêu cầu / hồ sơ sinh viên
-- ===========================================================
CREATE TABLE request (
    id SERIAL PRIMARY KEY,
    request_code VARCHAR(50) UNIQUE NOT NULL,
    student_id VARCHAR(10) NOT NULL REFERENCES student(student_id),
    service_id INTEGER NOT NULL REFERENCES academic_service(id),
    current_phase INTEGER DEFAULT 2,
    -- 0=cancelled,1=queue,2=pending,3=processing,4=completed,5=received,6=supplement
    priority INTEGER DEFAULT 0,
    queue_number INTEGER,
    queue_prefix VARCHAR(10) DEFAULT '',
    appointment_date DATE,
    expected_time TIME,
    deadline DATE,
    cancel_reason TEXT,
    cancel_type INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE request IS 'Yêu cầu dịch vụ sinh viên với theo dõi giai đoạn xử lý';
-- ===========================================================
-- 8. REQUEST_HISTORY — Lịch sử xử lý
-- ===========================================================
CREATE TABLE request_history (
    id SERIAL PRIMARY KEY,
    request_id INTEGER NOT NULL REFERENCES request(id) ON DELETE CASCADE,
    desk_id INTEGER REFERENCES service_desk(id),
    registrar_id INTEGER REFERENCES registrar(id),
    action VARCHAR(50) NOT NULL,
    phase_from INTEGER,
    phase_to INTEGER NOT NULL,
    content TEXT,
    appointment_date DATE,
    expected_time TIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE request_history IS 'Lịch sử thay đổi trạng thái yêu cầu';
-- ===========================================================
-- 9. APPOINTMENT — Lịch hẹn
-- ===========================================================
CREATE TABLE appointment (
    id SERIAL PRIMARY KEY,
    request_id INTEGER NOT NULL REFERENCES request(id),
    registrar_id INTEGER REFERENCES registrar(id),
    appointment_date DATE NOT NULL,
    appointment_time TIME,
    status INTEGER DEFAULT 0,
    -- 0=scheduled,1=completed,2=cancelled
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE appointment IS 'Lịch hẹn trả kết quả / bổ sung hồ sơ';
-- ===========================================================
-- 10. REPORT — Phản ánh, góp ý
-- ===========================================================
CREATE TABLE report (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL REFERENCES student(student_id),
    request_id INTEGER REFERENCES request(id),
    report_type INTEGER DEFAULT 0,
    -- 0=feedback, 1=complaint, 2=compliment
    title VARCHAR(200),
    content TEXT NOT NULL,
    status INTEGER DEFAULT 0,
    -- 0=pending, 1=resolved
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE report IS 'Phản ánh / góp ý từ sinh viên';
-- ===========================================================
-- 11. REPLY — Trả lời phản ánh
-- ===========================================================
CREATE TABLE reply (
    id SERIAL PRIMARY KEY,
    report_id INTEGER NOT NULL REFERENCES report(id) ON DELETE CASCADE,
    registrar_id INTEGER NOT NULL REFERENCES registrar(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reply IS 'Trả lời phản ánh từ cán bộ đào tạo';
-- ===========================================================
-- 12. STUDENT_FEEDBACK — Góp ý / phản ánh (bảng phụ nếu cần)
-- ===========================================================
CREATE TABLE student_feedback (
    id SERIAL PRIMARY KEY,
    feedback_code VARCHAR(50) UNIQUE,
    student_id VARCHAR(10) REFERENCES student(student_id),
    feedback_type INTEGER DEFAULT 0,
    title VARCHAR(200),
    content TEXT,
    attachments JSONB,
    request_id INTEGER REFERENCES request(id),
    status INTEGER DEFAULT 0,
    priority INTEGER DEFAULT 0,
    registrar_id INTEGER REFERENCES registrar(id),
    internal_note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    completed_at TIMESTAMP,
    rating INTEGER,
    rating_feedback TEXT
);
COMMENT ON TABLE student_feedback IS 'Góp ý / phản ánh / khen ngợi sinh viên (chi tiết)';
-- ===========================================================
-- 13. SYSTEM CONFIG — Cấu hình hệ thống
-- ===========================================================
CREATE TABLE system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(50) UNIQUE NOT NULL,
    config_value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE system_config IS 'Bảng cấu hình hệ thống';
INSERT INTO system_config (config_key, config_value, description)
VALUES (
        'MAX_QUEUE_PER_DAY',
        '100',
        'Số lượt tối đa mỗi ngày'
    ),
    (
        'WORKING_HOURS_START',
        '07:30',
        'Giờ bắt đầu làm việc'
    ),
    (
        'WORKING_HOURS_END',
        '16:30',
        'Giờ kết thúc làm việc'
    ),
    (
        'SLOT_DURATION_MINUTES',
        '24',
        'Thời gian mỗi lượt (phút)'
    );
-- ===========================================================
-- 14. VIEWS — Báo cáo nhanh
-- ===========================================================
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
-- ===========================================================
-- DONE ✓ — Phòng Đào tạo HUIT — Clean Schema
-- ===========================================================