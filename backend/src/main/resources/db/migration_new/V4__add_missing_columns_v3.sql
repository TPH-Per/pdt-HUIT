-- ===========================================================
-- V4: Add remaining missing columns (entity vs DB schema gaps)
-- Fixes: StudentController 500 errors
-- ===========================================================
-- 1. STUDENT: entity expects updated_at column
ALTER TABLE student
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
-- 2. REQUEST: entity has form_data and attachments (JSONB) - may be missing
ALTER TABLE request
ADD COLUMN IF NOT EXISTS form_data JSONB;
ALTER TABLE request
ADD COLUMN IF NOT EXISTS attachments JSONB;
-- 3. APPOINTMENT: entity may expect additional fields
ALTER TABLE appointment
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
-- 4. Populate updated_at for existing student rows
UPDATE student
SET updated_at = created_at
WHERE updated_at IS NULL;
-- 5. SERVICE_CATEGORY: ensure display_order exists if entity uses it
ALTER TABLE service_category
ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
-- 6. SERVICE_DESK: ensure display_order exists if entity uses it
ALTER TABLE service_desk
ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;