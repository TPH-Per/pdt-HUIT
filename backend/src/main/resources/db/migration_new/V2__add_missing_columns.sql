-- ===========================================================
-- V2: Add missing columns to match entity definitions
-- ===========================================================
-- 1. Role: add created_at column
ALTER TABLE role
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
-- 2. AcademicService: add display_order, form_schema, required_documents
ALTER TABLE academic_service
ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
ALTER TABLE academic_service
ADD COLUMN IF NOT EXISTS form_schema JSONB;
ALTER TABLE academic_service
ADD COLUMN IF NOT EXISTS required_documents TEXT;
-- Update display_order for existing services
UPDATE academic_service
SET display_order = id
WHERE display_order IS NULL
    OR display_order = 0;