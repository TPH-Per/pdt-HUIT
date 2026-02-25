-- =====================================================
-- V23: Backup Procedures - Các thủ tục backup nâng cao
-- =====================================================
-- 1. FUNCTION: Export table data to JSON format
CREATE OR REPLACE FUNCTION fn_export_table_json(p_table_name VARCHAR) RETURNS JSONB AS $$
DECLARE v_result JSONB;
BEGIN EXECUTE format(
    'SELECT jsonb_agg(row_to_json(t)) FROM %I t',
    p_table_name
) INTO v_result;
RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$ LANGUAGE plpgsql;
-- 2. FUNCTION: Tạo backup point (savepoint) với metadata
CREATE OR REPLACE FUNCTION fn_create_backup_point(
        p_description VARCHAR DEFAULT 'Manual backup point'
    ) RETURNS INTEGER AS $$
DECLARE v_backup_id INTEGER;
v_table_count INTEGER;
v_total_rows BIGINT;
BEGIN -- Đếm số bảng và tổng số dòng
SELECT COUNT(*),
    COALESCE(SUM(n_tup_ins - n_tup_del), 0) INTO v_table_count,
    v_total_rows
FROM pg_stat_user_tables
WHERE schemaname = 'public';
-- Tạo backup record
INSERT INTO backup_history (
        backup_type,
        backup_name,
        table_count,
        row_count,
        status,
        notes,
        completed_at,
        duration_seconds
    )
VALUES (
        'POINT',
        'backup_point_' || to_char(NOW(), 'YYYYMMDD_HH24MISS'),
        v_table_count,
        v_total_rows,
        'COMPLETED',
        p_description,
        NOW(),
        0
    )
RETURNING id INTO v_backup_id;
-- Tạo snapshot cho tất cả bảng
PERFORM fn_create_daily_snapshot();
RETURN v_backup_id;
END;
$$ LANGUAGE plpgsql;
-- 3. TABLE: Lưu dữ liệu backup tạm thời cho các bảng nhỏ
CREATE TABLE IF NOT EXISTS backup_data_store (
    id SERIAL PRIMARY KEY,
    backup_id INTEGER REFERENCES backup_history(id),
    table_name VARCHAR(100) NOT NULL,
    data_json JSONB NOT NULL,
    row_count INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_backup_data_store_backup ON backup_data_store(backup_id);
-- 4. FUNCTION: Backup bảng cụ thể vào backup_data_store
CREATE OR REPLACE FUNCTION fn_backup_table(
        p_backup_id INTEGER,
        p_table_name VARCHAR
    ) RETURNS INTEGER AS $$
DECLARE v_data JSONB;
v_count INTEGER;
BEGIN -- Export data
v_data := fn_export_table_json(p_table_name);
v_count := jsonb_array_length(v_data);
-- Lưu vào store
INSERT INTO backup_data_store (backup_id, table_name, data_json, row_count)
VALUES (p_backup_id, p_table_name, v_data, v_count);
RETURN v_count;
END;
$$ LANGUAGE plpgsql;
-- 5. FUNCTION: Backup tất cả bảng quan trọng
CREATE OR REPLACE FUNCTION fn_backup_important_tables() RETURNS TABLE (table_name VARCHAR, rows_backed_up INTEGER) AS $$
DECLARE v_backup_id INTEGER;
important_tables TEXT [] := ARRAY ['staff', 'citizens', 'applications', 'procedures', 'appointments', 'counters', 'roles'];
t TEXT;
v_rows INTEGER;
BEGIN -- Tạo backup record
v_backup_id := fn_log_backup_start(
    'DATA',
    'important_tables_' || to_char(NOW(), 'YYYYMMDD_HH24MISS'),
    'system'
);
-- Backup từng bảng
FOREACH t IN ARRAY important_tables LOOP BEGIN v_rows := fn_backup_table(v_backup_id, t);
table_name := t;
rows_backed_up := v_rows;
RETURN NEXT;
EXCEPTION
WHEN OTHERS THEN table_name := t;
rows_backed_up := -1;
RETURN NEXT;
END;
END LOOP;
-- Cập nhật backup hoàn thành
UPDATE backup_history
SET status = 'COMPLETED',
    completed_at = NOW(),
    duration_seconds = EXTRACT(
        EPOCH
        FROM (NOW() - started_at)
    )::INTEGER
WHERE id = v_backup_id;
END;
$$ LANGUAGE plpgsql;
-- 6. FUNCTION: Restore table từ backup
CREATE OR REPLACE FUNCTION fn_restore_table_from_backup(
        p_backup_id INTEGER,
        p_table_name VARCHAR,
        p_truncate_first BOOLEAN DEFAULT FALSE
    ) RETURNS INTEGER AS $$
DECLARE v_data JSONB;
v_restored INTEGER := 0;
v_record JSONB;
BEGIN -- Lấy data từ backup store
SELECT data_json INTO v_data
FROM backup_data_store
WHERE backup_id = p_backup_id
    AND table_name = p_table_name;
IF v_data IS NULL THEN RAISE EXCEPTION 'Không tìm thấy backup cho bảng % với backup_id %',
p_table_name,
p_backup_id;
END IF;
-- Truncate nếu yêu cầu
IF p_truncate_first THEN EXECUTE format('TRUNCATE TABLE %I CASCADE', p_table_name);
END IF;
-- Restore từng record
FOR v_record IN
SELECT *
FROM jsonb_array_elements(v_data) LOOP BEGIN EXECUTE format(
        'INSERT INTO %I SELECT * FROM jsonb_populate_record(null::%I, $1) ON CONFLICT DO NOTHING',
        p_table_name,
        p_table_name
    ) USING v_record;
v_restored := v_restored + 1;
EXCEPTION
WHEN OTHERS THEN -- Skip errors, continue with next record
NULL;
END;
END LOOP;
RETURN v_restored;
END;
$$ LANGUAGE plpgsql;
-- 7. VIEW: Tổng quan backup data store
CREATE OR REPLACE VIEW vw_backup_data_summary AS
SELECT bh.id as backup_id,
    bh.backup_name,
    bh.started_at,
    bh.status,
    COUNT(bds.id) as tables_backed_up,
    SUM(bds.row_count) as total_rows,
    pg_size_pretty(SUM(pg_column_size(bds.data_json))) as data_size
FROM backup_history bh
    LEFT JOIN backup_data_store bds ON bh.id = bds.backup_id
WHERE bh.backup_type = 'DATA'
GROUP BY bh.id,
    bh.backup_name,
    bh.started_at,
    bh.status
ORDER BY bh.started_at DESC;
-- 8. FUNCTION: Cleanup old backup data (giữ N bản gần nhất)
CREATE OR REPLACE FUNCTION fn_cleanup_old_backup_data(p_keep_count INTEGER DEFAULT 5) RETURNS INTEGER AS $$
DECLARE v_deleted INTEGER := 0;
v_old_ids INTEGER [];
BEGIN -- Tìm các backup cũ cần xóa
SELECT ARRAY_AGG(id) INTO v_old_ids
FROM (
        SELECT id
        FROM backup_history
        WHERE backup_type = 'DATA'
        ORDER BY started_at DESC OFFSET p_keep_count
    ) old_backups;
IF v_old_ids IS NOT NULL THEN -- Xóa data
DELETE FROM backup_data_store
WHERE backup_id = ANY(v_old_ids);
GET DIAGNOSTICS v_deleted = ROW_COUNT;
-- Xóa history
DELETE FROM backup_history
WHERE id = ANY(v_old_ids);
END IF;
RETURN v_deleted;
END;
$$ LANGUAGE plpgsql;
-- 9. FUNCTION: So sánh 2 backup
CREATE OR REPLACE FUNCTION fn_compare_backups(
        p_backup_id_1 INTEGER,
        p_backup_id_2 INTEGER
    ) RETURNS TABLE (
        table_name VARCHAR,
        backup_1_rows INTEGER,
        backup_2_rows INTEGER,
        difference INTEGER
    ) AS $$ BEGIN RETURN QUERY
SELECT COALESCE(b1.table_name, b2.table_name)::VARCHAR as table_name,
    COALESCE(b1.row_count, 0)::INTEGER as backup_1_rows,
    COALESCE(b2.row_count, 0)::INTEGER as backup_2_rows,
    (
        COALESCE(b2.row_count, 0) - COALESCE(b1.row_count, 0)
    )::INTEGER as difference
FROM backup_data_store b1
    FULL OUTER JOIN backup_data_store b2 ON b1.table_name = b2.table_name
WHERE b1.backup_id = p_backup_id_1
    OR b2.backup_id = p_backup_id_2
ORDER BY table_name;
END;
$$ LANGUAGE plpgsql;
-- 10. Hướng dẫn sử dụng
COMMENT ON FUNCTION fn_create_backup_point IS 'Tạo backup point: SELECT fn_create_backup_point(''Mô tả'')';
COMMENT ON FUNCTION fn_backup_important_tables IS 'Backup các bảng quan trọng: SELECT * FROM fn_backup_important_tables()';
COMMENT ON FUNCTION fn_restore_table_from_backup IS 'Restore bảng: SELECT fn_restore_table_from_backup(backup_id, ''table_name'', true)';
COMMENT ON FUNCTION fn_cleanup_old_backup_data IS 'Dọn dẹp backup cũ: SELECT fn_cleanup_old_backup_data(5) -- giữ 5 bản';