-- V6: Create queue_tickets table for managing ticket assignments

CREATE TABLE queue_tickets (
    id             BIGSERIAL PRIMARY KEY,
    ticket_number  INTEGER NOT NULL,
    ticket_prefix  VARCHAR(5) DEFAULT 'A',
    student_id     VARCHAR(10) REFERENCES student(student_id) ON DELETE SET NULL,
    desk_id        INTEGER NOT NULL REFERENCES service_desk(id),
    registrar_id   INTEGER REFERENCES registrar(id),
    request_id     INTEGER REFERENCES request(id) ON DELETE CASCADE,
    status         VARCHAR(20) NOT NULL DEFAULT 'WAITING',
    CONSTRAINT chk_queue_status
        CHECK (status IN ('WAITING','CALLING','SERVING','COMPLETED','SKIPPED','CANCELLED')),
    created_at     TIMESTAMPTZ DEFAULT NOW(),
    called_at      TIMESTAMPTZ,
    served_at      TIMESTAMPTZ,
    completed_at   TIMESTAMPTZ,
    notes          TEXT
);
CREATE UNIQUE INDEX uidx_ticket_number_desk_day
    ON queue_tickets(desk_id, ticket_number, (CAST(created_at AT TIME ZONE 'UTC' AS DATE)));
CREATE INDEX idx_queue_tickets_desk_status
    ON queue_tickets(desk_id, status, created_at ASC);
CREATE INDEX idx_queue_tickets_student
    ON queue_tickets(student_id, created_at DESC);

CREATE OR REPLACE FUNCTION reset_daily_queue() RETURNS void AS $$
BEGIN
    UPDATE queue_tickets
    SET status = 'CANCELLED', notes = 'Auto-cancelled: end of business day'
    WHERE status IN ('WAITING','CALLING') AND DATE(created_at) < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;