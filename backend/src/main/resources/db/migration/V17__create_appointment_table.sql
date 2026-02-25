CREATE TABLE appointment (
    id SERIAL PRIMARY KEY,
    application_id INTEGER REFERENCES application(id),
    staff_id INTEGER REFERENCES staff(id),
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status INTEGER NOT NULL DEFAULT 0,
    -- 0: SCHEDULED, 1: COMPLETED, 2: CANCELLED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_appointment_date ON appointment(appointment_date);
CREATE INDEX idx_appointment_status ON appointment(status);
-- Migrate active appointments from history (Supplement & Queue phases)
INSERT INTO appointment (
        application_id,
        staff_id,
        appointment_date,
        appointment_time,
        status,
        created_at
    )
SELECT h.application_id,
    h.staff_id,
    h.appointment_date,
    h.expected_time,
    0,
    -- SCHEDULED
    h.created_at
FROM application_history h
    JOIN application a ON h.application_id = a.id
WHERE h.appointment_date >= CURRENT_DATE
    AND h.expected_time IS NOT NULL
    AND a.current_phase IN (1, 6) -- QUEUE, SUPPLEMENT
    AND h.id IN (
        SELECT MAX(id)
        FROM application_history
        WHERE appointment_date IS NOT NULL
        GROUP BY application_id
    );