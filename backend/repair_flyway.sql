-- Xóa migration failed để chạy lại
DELETE FROM flyway_schema_history
WHERE success = false;
-- Update checksum cho V15 nếu cần
UPDATE flyway_schema_history
SET checksum = NULL
WHERE version = '15';