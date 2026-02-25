-- ===========================================================
-- V5: Add password_hash to student table for student auth
-- ===========================================================
ALTER TABLE student
ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);
-- Set default password '123456' (bcrypt) for existing students
UPDATE student
SET password_hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
WHERE password_hash IS NULL;
ALTER TABLE student
ALTER COLUMN password_hash
SET NOT NULL;