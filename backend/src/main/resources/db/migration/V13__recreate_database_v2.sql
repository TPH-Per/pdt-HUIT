-- =============================================
-- DATABASE V2.0 - DROP OLD TABLES AND CREATE NEW ONES
-- =============================================
-- Drop old tables (in reverse dependency order)
DROP TABLE IF EXISTS GopYPhanAnhTraLoi CASCADE;
DROP TABLE IF EXISTS GopYPhanAnh CASCADE;
DROP TABLE IF EXISTS AuditLog CASCADE;
DROP TABLE IF EXISTS HoSoXuLy CASCADE;
DROP TABLE IF EXISTS HoSo CASCADE;
DROP TABLE IF EXISTS LichSuXuLyLichHen CASCADE;
DROP TABLE IF EXISTS LichHen CASCADE;
DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS LoaiThuTuc CASCADE;
DROP TABLE IF EXISTS Quay CASCADE;
DROP TABLE IF EXISTS ZaloAccounts CASCADE;
DROP TABLE IF EXISTS Citizens CASCADE;
DROP TABLE IF EXISTS HeThongCauHinh CASCADE;
DROP TABLE IF EXISTS ChuyenMon CASCADE;
DROP TABLE IF EXISTS Roles CASCADE;
-- Drop old views if exist
DROP VIEW IF EXISTS vw_queue_today CASCADE;
DROP VIEW IF EXISTS vw_daily_stats CASCADE;
-- =============================================
-- 1. ROLE
-- =============================================
CREATE TABLE Role (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- =============================================
-- 2. CITIZEN (citizen_id = CCCD as Primary Key)
-- =============================================
CREATE TABLE Citizen (
    citizen_id VARCHAR(12) PRIMARY KEY,
    -- CCCD as PK
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(10),
    address TEXT,
    phone VARCHAR(15),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);
CREATE INDEX idx_citizen_phone ON Citizen(phone);
CREATE INDEX idx_citizen_name ON Citizen(full_name);
-- =============================================
-- 3. ZALO_ACCOUNT
-- =============================================
CREATE TABLE ZaloAccount (
    id SERIAL PRIMARY KEY,
    zalo_id VARCHAR(100) UNIQUE NOT NULL,
    zalo_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE
);
-- =============================================
-- 4. PROCEDURE_COUNTER (Master)
-- =============================================
CREATE TABLE ProcedureCounter (
    id SERIAL PRIMARY KEY,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- =============================================
-- 5. PROCEDURE
-- =============================================
CREATE TABLE Procedure (
    id SERIAL PRIMARY KEY,
    procedure_code VARCHAR(20) UNIQUE NOT NULL,
    procedure_name VARCHAR(200) NOT NULL,
    description TEXT,
    processing_days INT NOT NULL DEFAULT 15,
    form_schema JSONB,
    required_documents TEXT,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    procedure_counter_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_procedure_pc FOREIGN KEY (procedure_counter_id) REFERENCES ProcedureCounter(id)
);
-- =============================================
-- 6. COUNTER
-- =============================================
CREATE TABLE Counter (
    id SERIAL PRIMARY KEY,
    counter_code VARCHAR(10) UNIQUE NOT NULL,
    counter_name VARCHAR(50) NOT NULL,
    location VARCHAR(100),
    procedure_counter_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_counter_pc FOREIGN KEY (procedure_counter_id) REFERENCES ProcedureCounter(id)
);
-- =============================================
-- 7. STAFF
-- =============================================
CREATE TABLE Staff (
    id SERIAL PRIMARY KEY,
    staff_code VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(15),
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL,
    counter_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT fk_staff_role FOREIGN KEY (role_id) REFERENCES Role(id),
    CONSTRAINT fk_staff_counter FOREIGN KEY (counter_id) REFERENCES Counter(id)
);
CREATE INDEX idx_staff_counter ON Staff(counter_id)
WHERE is_active = TRUE;
CREATE INDEX idx_staff_role ON Staff(role_id);
-- =============================================
-- 8. APPLICATION
-- =============================================
CREATE TABLE Application (
    id SERIAL PRIMARY KEY,
    application_code VARCHAR(20) UNIQUE NOT NULL,
    procedure_id INT NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    -- FK to Citizen.citizen_id (CCCD)
    zalo_account_id INT,
    current_phase INT NOT NULL DEFAULT 1,
    queue_number INT,
    queue_prefix VARCHAR(5),
    appointment_date DATE,
    expected_time TIME,
    deadline DATE,
    priority INT DEFAULT 0,
    cancel_reason TEXT,
    cancel_type INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT fk_app_procedure FOREIGN KEY (procedure_id) REFERENCES Procedure(id),
    CONSTRAINT fk_app_citizen FOREIGN KEY (citizen_id) REFERENCES Citizen(citizen_id),
    CONSTRAINT fk_app_zalo FOREIGN KEY (zalo_account_id) REFERENCES ZaloAccount(id),
    CONSTRAINT uq_app_queue UNIQUE (appointment_date, queue_prefix, queue_number)
);
CREATE INDEX idx_app_citizen ON Application(citizen_id);
CREATE INDEX idx_app_procedure ON Application(procedure_id);
CREATE INDEX idx_app_phase ON Application(current_phase)
WHERE current_phase < 4;
CREATE INDEX idx_app_date ON Application(appointment_date);
-- =============================================
-- 9. APPLICATION_HISTORY
-- =============================================
CREATE TABLE ApplicationHistory (
    id SERIAL PRIMARY KEY,
    application_id INT NOT NULL,
    counter_id INT NOT NULL,
    staff_id INT,
    phase_from INT,
    phase_to INT NOT NULL,
    action VARCHAR(50) NOT NULL,
    content TEXT,
    form_data JSONB,
    attachments JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_history_app FOREIGN KEY (application_id) REFERENCES Application(id) ON DELETE CASCADE,
    CONSTRAINT fk_history_counter FOREIGN KEY (counter_id) REFERENCES Counter(id),
    CONSTRAINT fk_history_staff FOREIGN KEY (staff_id) REFERENCES Staff(id)
);
CREATE INDEX idx_history_app ON ApplicationHistory(application_id);
CREATE INDEX idx_history_counter ON ApplicationHistory(counter_id);
CREATE INDEX idx_history_time ON ApplicationHistory(created_at DESC);
-- =============================================
-- 10. REPORT
-- =============================================
CREATE TABLE Report (
    id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL,
    -- FK to Citizen.citizen_id (CCCD)
    application_id INT NOT NULL,
    report_type INT NOT NULL DEFAULT 0,
    title VARCHAR(200),
    content TEXT NOT NULL,
    attachments JSONB,
    status INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_report_citizen FOREIGN KEY (citizen_id) REFERENCES Citizen(citizen_id),
    CONSTRAINT fk_report_app FOREIGN KEY (application_id) REFERENCES Application(id)
);
CREATE INDEX idx_report_citizen ON Report(citizen_id);
CREATE INDEX idx_report_app ON Report(application_id);
CREATE INDEX idx_report_status ON Report(status)
WHERE status < 2;
-- =============================================
-- 11. REPLY
-- =============================================
CREATE TABLE Reply (
    id SERIAL PRIMARY KEY,
    report_id INT NOT NULL,
    staff_id INT NOT NULL,
    content TEXT NOT NULL,
    attachments JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reply_report FOREIGN KEY (report_id) REFERENCES Report(id) ON DELETE CASCADE,
    CONSTRAINT fk_reply_staff FOREIGN KEY (staff_id) REFERENCES Staff(id)
);
CREATE INDEX idx_reply_report ON Reply(report_id);
-- =============================================
-- VIEWS
-- =============================================
CREATE VIEW vw_queue_today AS
SELECT a.id,
    a.application_code,
    a.queue_prefix || a.queue_number AS queue_display,
    a.queue_number,
    c.full_name AS citizen_name,
    c.phone AS citizen_phone,
    p.procedure_name,
    a.expected_time,
    a.current_phase,
    a.created_at
FROM Application a
    JOIN Citizen c ON a.citizen_id = c.citizen_id
    JOIN Procedure p ON a.procedure_id = p.id
WHERE a.appointment_date = CURRENT_DATE
    AND a.current_phase IN (1, 3)
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
FROM ApplicationHistory h
    JOIN Counter co ON h.counter_id = co.id
GROUP BY h.counter_id,
    co.counter_name,
    DATE(h.created_at);
-- =============================================
-- INITIAL DATA
-- =============================================
INSERT INTO Role (role_name, display_name, description)
VALUES ('Admin', 'Quản trị viên', 'Full system access'),
    ('Staff', 'Nhân viên', 'Counter staff');
-- ProcedureCounter records
INSERT INTO ProcedureCounter (is_active)
VALUES (TRUE),
    (TRUE),
    (TRUE);
-- Counters
INSERT INTO Counter (
        counter_code,
        counter_name,
        location,
        procedure_counter_id
    )
VALUES ('Q01', 'Quầy 1 - Hộ tịch', 'Tầng 1', 1),
    ('Q02', 'Quầy 2 - Đất đai', 'Tầng 1', 2),
    ('Q03', 'Quầy 3 - Kinh doanh', 'Tầng 2', 3);
-- Procedures
INSERT INTO Procedure (
        procedure_code,
        procedure_name,
        processing_days,
        procedure_counter_id
    )
VALUES ('TT001', 'Đăng ký khai sinh', 3, 1),
    ('TT002', 'Đăng ký kết hôn', 5, 1),
    (
        'TT003',
        'Cấp giấy xác nhận tình trạng hôn nhân',
        3,
        1
    ),
    ('TT004', 'Đăng ký biến động đất đai', 15, 2),
    ('TT005', 'Cấp giấy phép kinh doanh', 10, 3);
-- Admin user (password: admin123)
INSERT INTO Staff (
        staff_code,
        full_name,
        email,
        password_hash,
        role_id,
        counter_id
    )
VALUES (
        'ADMIN',
        'Administrator',
        'admin@ubndq5.gov.vn',
        '$2a$10$N.zmhk0GD2LdMVz2G5s1.u3GVZQl5mNJIY7pVU4VzjLGjZ6q0z3Iy',
        1,
        NULL
    );
-- Sample staff (password: 123456)
INSERT INTO Staff (
        staff_code,
        full_name,
        email,
        password_hash,
        role_id,
        counter_id
    )
VALUES (
        'NV001',
        'Nguyễn Văn A',
        'nva@ubndq5.gov.vn',
        '$2a$10$N.zmhk0GD2LdMVz2G5s1.u3GVZQl5mNJIY7pVU4VzjLGjZ6q0z3Iy',
        2,
        1
    ),
    (
        'NV002',
        'Trần Thị B',
        'ttb@ubndq5.gov.vn',
        '$2a$10$N.zmhk0GD2LdMVz2G5s1.u3GVZQl5mNJIY7pVU4VzjLGjZ6q0z3Iy',
        2,
        2
    ),
    (
        'NV003',
        'Lê Văn C',
        'lvc@ubndq5.gov.vn',
        '$2a$10$N.zmhk0GD2LdMVz2G5s1.u3GVZQl5mNJIY7pVU4VzjLGjZ6q0z3Iy',
        2,
        3
    );
-- Sample citizens (citizen_id = CCCD)
INSERT INTO Citizen (
        citizen_id,
        full_name,
        date_of_birth,
        gender,
        address,
        phone,
        email
    )
VALUES (
        '079001234567',
        'Phạm Văn X',
        '1990-05-15',
        'Male',
        '123 Nguyễn Trãi, Q5',
        '0901234567',
        'pvx@gmail.com'
    ),
    (
        '079001234568',
        'Hoàng Thị Y',
        '1985-10-20',
        'Female',
        '456 Trần Hưng Đạo, Q5',
        '0901234568',
        'hty@gmail.com'
    );