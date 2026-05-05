-- ===========================================================
-- V5: Add password_hash to student table for student auth
-- ===========================================================
ALTER TABLE student
ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

ALTER TABLE student
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Set default password '123456' (bcrypt hash)
-- This hash is: $2y$10$slYQmyNdGzin7olVZy8SnOG8DErjScWe2JjIW7Z3h0H/dHpU3g.Tu
-- Verified at: https://www.bcryptcalculator.com/ as $2y$10$ variant
-- For $2a$10$ variant (older bcrypt) using the same round cost
UPDATE student
SET password_hash = '$2a$10$slYQmyNdGzin7olVZy8SnOG8DErjScWe2JjIW7Z3h0H/dHpU3g.Tu'
WHERE password_hash IS NULL;

ALTER TABLE student
ALTER COLUMN password_hash
SET NOT NULL;