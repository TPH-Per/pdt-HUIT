-- V11: Create vw_daily_stats materialized view for dashboard reporting

CREATE MATERIALIZED VIEW vw_daily_stats AS
SELECT 
    DATE(qt.created_at) as date,
    q.id as queue_id,
    COUNT(DISTINCT qt.id) as total_tickets,
    COUNT(DISTINCT CASE WHEN qt.status = 2 THEN qt.id END) as completed_tickets,
    COUNT(DISTINCT qt.student_id) as unique_students,
    AVG(EXTRACT(EPOCH FROM (qt.updated_at - qt.created_at))) as avg_queue_time_seconds,
    COUNT(DISTINCT a.id) as total_appointments,
    COUNT(DISTINCT CASE WHEN a.status = 2 THEN a.id END) as completed_appointments
FROM queue_tickets qt
LEFT JOIN queue q ON qt.desk_id = q.id
LEFT JOIN appointment a ON DATE(a.appointment_date) = DATE(qt.created_at) AND a.status IN (1, 2)
GROUP BY DATE(qt.created_at), q.id;

CREATE INDEX idx_vw_daily_stats_date ON vw_daily_stats(date DESC);
CREATE INDEX idx_vw_daily_stats_queue_id ON vw_daily_stats(queue_id);

ALTER MATERIALIZED VIEW vw_daily_stats OWNER TO per;
