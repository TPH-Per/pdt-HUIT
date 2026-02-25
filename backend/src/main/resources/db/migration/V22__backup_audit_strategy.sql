-- =====================================================
-- V22: Database Backup Strategy
-- Tạo cấu trúc hỗ trợ backup và audit trong database
-- =====================================================
-- 1. BẢNG LƯU LỊCH SỬ BACKUP
CREATE TABLE IF NOT EXISTS backup_history (
    id SERIAL PRIMARY KEY,
    backup_type VARCHAR(50) NOT NULL,
    -- 'FULL', 'INCREMENTAL', 'SCHEMA', 'DATA'
    backup_name VARCHAR(255) NOT NULL,
    -- Tên file backup
    backup_path VARCHAR(500),
    -- Đường dẫn lưu trữ
    backup_size_mb DECIMAL(10, 2),
    -- Kích thước (MB)
    table_count INTEGER,
    -- Số bảng được backup
    row_count BIGINT,
    -- Tổng số dòng
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    duration_seconds INTEGER,
    status VARCHAR(20) DEFAULT 'IN_PROGRESS',
    -- 'IN_PROGRESS', 'COMPLETED', 'FAILED'
    error_message TEXT,
    created_by VARCHAR(100) DEFAULT 'system',
    notes TEXT
);
CREATE INDEX idx_backup_history_date ON backup_history(started_at DESC);
CREATE INDEX idx_backup_history_status ON backup_history(status);
-- 2. BẢNG AUDIT LOG (Theo dõi mọi thay đổi)
CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER,
    action VARCHAR(10) NOT NULL,
    -- 'INSERT', 'UPDATE', 'DELETE'
    old_data JSONB,
    -- Dữ liệu cũ (cho UPDATE/DELETE)
    new_data JSONB,
    -- Dữ liệu mới (cho INSERT/UPDATE)
    changed_fields TEXT [],
    -- Các field bị thay đổi
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT NOW(),
    ip_address VARCHAR(45),
    user_agent TEXT
);
CREATE INDEX idx_audit_log_table ON audit_log(table_name);
CREATE INDEX idx_audit_log_date ON audit_log(changed_at DESC);
CREATE INDEX idx_audit_log_action ON audit_log(action);
-- 3. BẢNG DATA SNAPSHOT (Lưu trạng thái dữ liệu theo thời gian)
CREATE TABLE IF NOT EXISTS data_snapshot (
    id SERIAL PRIMARY KEY,
    snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
    table_name VARCHAR(100) NOT NULL,
    row_count BIGINT NOT NULL,
    data_size_kb DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(snapshot_date, table_name)
);
-- 4. FUNCTION: Ghi log backup
CREATE OR REPLACE FUNCTION fn_log_backup_start(
        p_backup_type VARCHAR(50),
        p_backup_name VARCHAR(255),
        p_created_by VARCHAR(100) DEFAULT 'system'
    ) RETURNS INTEGER AS $$
DECLARE v_backup_id INTEGER;
BEGIN
INSERT INTO backup_history (backup_type, backup_name, created_by, status)
VALUES (
        p_backup_type,
        p_backup_name,
        p_created_by,
        'IN_PROGRESS'
    )
RETURNING id INTO v_backup_id;
RETURN v_backup_id;
END;
$$ LANGUAGE plpgsql;
-- 5. FUNCTION: Cập nhật khi backup hoàn thành
CREATE OR REPLACE FUNCTION fn_log_backup_complete(
        p_backup_id INTEGER,
        p_backup_path VARCHAR(500),
        p_backup_size_mb DECIMAL(10, 2),
        p_table_count INTEGER,
        p_row_count BIGINT
    ) RETURNS VOID AS $$ BEGIN
UPDATE backup_history
SET backup_path = p_backup_path,
    backup_size_mb = p_backup_size_mb,
    table_count = p_table_count,
    row_count = p_row_count,
    completed_at = NOW(),
    duration_seconds = EXTRACT(
        EPOCH
        FROM (NOW() - started_at)
    )::INTEGER,
    status = 'COMPLETED'
WHERE id = p_backup_id;
END;
$$ LANGUAGE plpgsql;
-- 6. FUNCTION: Đánh dấu backup thất bại
CREATE OR REPLACE FUNCTION fn_log_backup_failed(
        p_backup_id INTEGER,
        p_error_message TEXT
    ) RETURNS VOID AS $$ BEGIN
UPDATE backup_history
SET completed_at = NOW(),
    duration_seconds = EXTRACT(
        EPOCH
        FROM (NOW() - started_at)
    )::INTEGER,
    status = 'FAILED',
    error_message = p_error_message
WHERE id = p_backup_id;
END;
$$ LANGUAGE plpgsql;
-- 7. FUNCTION: Tạo snapshot dữ liệu hàng ngày
CREATE OR REPLACE FUNCTION fn_create_daily_snapshot() RETURNS VOID AS $$
DECLARE r RECORD;
BEGIN FOR r IN
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE'
    AND table_name NOT IN ('audit_log', 'backup_history', 'data_snapshot') LOOP
INSERT INTO data_snapshot (snapshot_date, table_name, row_count)
SELECT CURRENT_DATE,
    r.table_name,
    (
        SELECT COUNT(*)
        FROM pg_catalog.pg_class c
            JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relname = r.table_name
            AND n.nspname = 'public'
    ) ON CONFLICT (snapshot_date, table_name) DO
UPDATE
SET row_count = EXCLUDED.row_count,
    created_at = NOW();
END LOOP;
END;
$$ LANGUAGE plpgsql;
-- 8. FUNCTION: Generic audit trigger
CREATE OR REPLACE FUNCTION fn_audit_trigger() RETURNS TRIGGER AS $$
DECLARE v_old_data JSONB;
v_new_data JSONB;
v_changed_fields TEXT [];
v_record_id INTEGER;
BEGIN IF TG_OP = 'DELETE' THEN v_old_data := to_jsonb(OLD);
v_record_id := OLD.id;
v_new_data := NULL;
ELSIF TG_OP = 'INSERT' THEN v_old_data := NULL;
v_new_data := to_jsonb(NEW);
v_record_id := NEW.id;
ELSIF TG_OP = 'UPDATE' THEN v_old_data := to_jsonb(OLD);
v_new_data := to_jsonb(NEW);
v_record_id := NEW.id;
-- Tìm các field bị thay đổi
SELECT array_agg(key) INTO v_changed_fields
FROM jsonb_each(v_old_data) old_kv
    JOIN jsonb_each(v_new_data) new_kv USING (key)
WHERE old_kv.value IS DISTINCT
FROM new_kv.value;
END IF;
INSERT INTO audit_log (
        table_name,
        record_id,
        action,
        old_data,
        new_data,
        changed_fields
    )
VALUES (
        TG_TABLE_NAME,
        v_record_id,
        TG_OP,
        v_old_data,
        v_new_data,
        v_changed_fields
    );
IF TG_OP = 'DELETE' THEN RETURN OLD;
ELSE RETURN NEW;
END IF;
END;
$$ LANGUAGE plpgsql;
-- 9. Tạo audit triggers cho các bảng quan trọng
DO $$
DECLARE important_tables TEXT [] := ARRAY ['staff', 'citizen', 'application', 'procedure', 'appointment'];
t TEXT;
BEGIN FOREACH t IN ARRAY important_tables LOOP -- Drop trigger nếu đã tồn tại
EXECUTE format(
    'DROP TRIGGER IF EXISTS trg_audit_%s ON %I',
    t,
    t
);
-- Tạo trigger mới
EXECUTE format(
    '
            CREATE TRIGGER trg_audit_%s
            AFTER INSERT OR UPDATE OR DELETE ON %I
            FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger()
        ',
    t,
    t
);
END LOOP;
END;
$$;
-- 10. VIEW: Thống kê backup
CREATE OR REPLACE VIEW vw_backup_statistics AS
SELECT backup_type,
    COUNT(*) as total_backups,
    COUNT(*) FILTER (
        WHERE status = 'COMPLETED'
    ) as successful,
    COUNT(*) FILTER (
        WHERE status = 'FAILED'
    ) as failed,
    ROUND(AVG(backup_size_mb), 2) as avg_size_mb,
    ROUND(AVG(duration_seconds), 0) as avg_duration_sec,
    MAX(started_at) as last_backup
FROM backup_history
GROUP BY backup_type;
-- 11. VIEW: Audit log gần đây
CREATE OR REPLACE VIEW vw_recent_changes AS
SELECT al.id,
    al.table_name,
    al.record_id,
    al.action,
    al.changed_fields,
    al.changed_at,
    al.changed_by
FROM audit_log al
WHERE al.changed_at > NOW() - INTERVAL '7 days'
ORDER BY al.changed_at DESC;
-- 12. FUNCTION: Cleanup old audit logs (giữ 90 ngày)
CREATE OR REPLACE FUNCTION fn_cleanup_old_audit_logs(p_days INTEGER DEFAULT 90) RETURNS INTEGER AS $$
DECLARE v_deleted INTEGER;
BEGIN
DELETE FROM audit_log
WHERE changed_at < NOW() - (p_days || ' days')::INTERVAL;
GET DIAGNOSTICS v_deleted = ROW_COUNT;
RETURN v_deleted;
END;
$$ LANGUAGE plpgsql;
-- 13. FUNCTION: Lấy thông tin backup gần nhất
CREATE OR REPLACE FUNCTION fn_get_last_backup(p_backup_type VARCHAR DEFAULT NULL) RETURNS TABLE (
        backup_id INTEGER,
        backup_type VARCHAR,
        backup_name VARCHAR,
        backup_size_mb DECIMAL,
        completed_at TIMESTAMP,
        status VARCHAR,
        hours_ago NUMERIC
    ) AS $$ BEGIN RETURN QUERY
SELECT bh.id,
    bh.backup_type,
    bh.backup_name,
    bh.backup_size_mb,
    bh.completed_at,
    bh.status,
    ROUND(
        EXTRACT(
            EPOCH
            FROM (NOW() - bh.completed_at)
        ) / 3600,
        1
    )
FROM backup_history bh
WHERE (
        p_backup_type IS NULL
        OR bh.backup_type = p_backup_type
    )
    AND bh.status = 'COMPLETED'
ORDER BY bh.completed_at DESC
LIMIT 1;
END;
$$ LANGUAGE plpgsql;
-- 14. Insert sample backup record
INSERT INTO backup_history (
        backup_type,
        backup_name,
        backup_path,
        backup_size_mb,
        table_count,
        row_count,
        completed_at,
        duration_seconds,
        status,
        created_by
    )
VALUES (
        'FULL',
        'initial_backup_20260205',
        'C:\Backups\HANHCHINHCONGQ5\database',
        15.5,
        15,
        1000,
        NOW(),
        30,
        'COMPLETED',
        'system'
    );
COMMENT ON TABLE backup_history IS 'Lưu lịch sử các lần backup database';
COMMENT ON TABLE audit_log IS 'Audit log theo dõi mọi thay đổi dữ liệu trong các bảng quan trọng';
COMMENT ON TABLE data_snapshot IS 'Snapshot số lượng record theo ngày để theo dõi tăng trưởng dữ liệu';