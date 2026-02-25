-- V14: Rename ProcedureCounter to ProcedureType and add name, description
-- This migration handles both fresh install and upgrade cases
-- 1. Rename table if exists
DO $$ BEGIN IF EXISTS (
    SELECT
    FROM information_schema.tables
    WHERE table_name = 'procedurecounter'
) THEN
ALTER TABLE procedurecounter
    RENAME TO procedure_type;
END IF;
END $$;
-- 2. Add new columns if not exists
DO $$ BEGIN IF NOT EXISTS (
    SELECT
    FROM information_schema.columns
    WHERE table_name = 'procedure_type'
        AND column_name = 'name'
) THEN
ALTER TABLE procedure_type
ADD COLUMN name VARCHAR(100) NOT NULL DEFAULT 'Unnamed';
END IF;
IF NOT EXISTS (
    SELECT
    FROM information_schema.columns
    WHERE table_name = 'procedure_type'
        AND column_name = 'description'
) THEN
ALTER TABLE procedure_type
ADD COLUMN description TEXT;
END IF;
END $$;
-- 3. Rename procedure_counter_id to procedure_type_id in Counter
DO $$ BEGIN IF EXISTS (
    SELECT
    FROM information_schema.columns
    WHERE table_name = 'counter'
        AND column_name = 'procedure_counter_id'
) THEN
ALTER TABLE counter
    RENAME COLUMN procedure_counter_id TO procedure_type_id;
END IF;
END $$;
-- 4. Rename procedure_counter_id to procedure_type_id in Procedure
DO $$ BEGIN IF EXISTS (
    SELECT
    FROM information_schema.columns
    WHERE table_name = 'procedure'
        AND column_name = 'procedure_counter_id'
) THEN
ALTER TABLE procedure
    RENAME COLUMN procedure_counter_id TO procedure_type_id;
END IF;
END $$;
-- 5. Rename procedure_counter_id to procedure_type_id in Staff
DO $$ BEGIN IF EXISTS (
    SELECT
    FROM information_schema.columns
    WHERE table_name = 'staff'
        AND column_name = 'procedure_counter_id'
) THEN
ALTER TABLE staff
    RENAME COLUMN procedure_counter_id TO procedure_type_id;
END IF;
END $$;
-- 6. Update constraints
ALTER TABLE counter DROP CONSTRAINT IF EXISTS fk_counter_pc;
ALTER TABLE counter DROP CONSTRAINT IF EXISTS fk_counter_pt;
DO $$ BEGIN IF EXISTS (
    SELECT
    FROM information_schema.columns
    WHERE table_name = 'counter'
        AND column_name = 'procedure_type_id'
) THEN
ALTER TABLE counter
ADD CONSTRAINT fk_counter_pt FOREIGN KEY (procedure_type_id) REFERENCES procedure_type(id);
END IF;
END $$;
ALTER TABLE procedure DROP CONSTRAINT IF EXISTS fk_procedure_pc;
ALTER TABLE procedure DROP CONSTRAINT IF EXISTS fk_procedure_pt;
DO $$ BEGIN IF EXISTS (
    SELECT
    FROM information_schema.columns
    WHERE table_name = 'procedure'
        AND column_name = 'procedure_type_id'
) THEN
ALTER TABLE procedure
ADD CONSTRAINT fk_procedure_pt FOREIGN KEY (procedure_type_id) REFERENCES procedure_type(id);
END IF;
END $$;
ALTER TABLE staff DROP CONSTRAINT IF EXISTS fk_staff_pc;
ALTER TABLE staff DROP CONSTRAINT IF EXISTS fk_staff_pt;
DO $$ BEGIN IF EXISTS (
    SELECT
    FROM information_schema.columns
    WHERE table_name = 'staff'
        AND column_name = 'procedure_type_id'
) THEN
ALTER TABLE staff
ADD CONSTRAINT fk_staff_pt FOREIGN KEY (procedure_type_id) REFERENCES procedure_type(id);
END IF;
END $$;
-- 7. Update existing records with meaningful names
UPDATE procedure_type
SET name = 'Hộ tịch',
    description = 'Các thủ tục liên quan đến hộ tịch'
WHERE id = 1
    AND name = 'Unnamed';
UPDATE procedure_type
SET name = 'Đất đai',
    description = 'Các thủ tục liên quan đến đất đai'
WHERE id = 2
    AND name = 'Unnamed';
UPDATE procedure_type
SET name = 'Kinh doanh',
    description = 'Các thủ tục liên quan đến kinh doanh'
WHERE id = 3
    AND name = 'Unnamed';
-- 8. Remove default
ALTER TABLE procedure_type
ALTER COLUMN name DROP DEFAULT;
-- 9. Add comments
COMMENT ON TABLE procedure_type IS 'Procedure Type - groups procedures and counters by category';