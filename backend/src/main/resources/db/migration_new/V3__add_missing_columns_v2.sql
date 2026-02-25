-- ===========================================================
-- V3: Add missing columns for request_history, report, reply
-- Fixes 500 errors on queue dashboard and feedback endpoints
-- ===========================================================
-- 1. REQUEST_HISTORY: entity expects form_data, attachments, queue_number, queue_prefix
ALTER TABLE request_history
ADD COLUMN IF NOT EXISTS form_data JSONB;
ALTER TABLE request_history
ADD COLUMN IF NOT EXISTS attachments JSONB;
ALTER TABLE request_history
ADD COLUMN IF NOT EXISTS queue_number INTEGER;
ALTER TABLE request_history
ADD COLUMN IF NOT EXISTS queue_prefix VARCHAR(10);
-- 2. REPORT: entity expects attachments column
ALTER TABLE report
ADD COLUMN IF NOT EXISTS attachments JSONB;
-- 3. REPLY: entity expects attachments column
ALTER TABLE reply
ADD COLUMN IF NOT EXISTS attachments JSONB;
-- 4. REPORT: Fix nullable constraint — entity says request_id nullable=false
--    but DB allows NULL. We keep DB nullable since reports CAN exist without a request.
--    Instead, fix the entity (done in Java code).