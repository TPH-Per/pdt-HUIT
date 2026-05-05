-- V11: Create vw_daily_stats view for dashboard reporting
DROP VIEW IF EXISTS vw_daily_stats CASCADE;

CREATE VIEW vw_daily_stats AS
SELECT
    COUNT(*) FILTER (WHERE current_phase NOT IN (0,4)) AS total_active,
    COUNT(*) FILTER (WHERE current_phase = 1)          AS waiting,
    COUNT(*) FILTER (WHERE current_phase = 2)          AS pending,
    COUNT(*) FILTER (WHERE current_phase = 3)          AS processing,
    COUNT(*) FILTER (WHERE current_phase = 4)          AS completed,
    COUNT(*) FILTER (WHERE current_phase = 0)          AS cancelled
FROM request
WHERE CAST(created_at AT TIME ZONE 'UTC' AS DATE) = CURRENT_DATE;