-- V6: Create queue_tickets table for managing ticket assignments

CREATE TABLE IF NOT EXISTS queue_tickets (
    id SERIAL PRIMARY KEY,
    queue_id BIGINT NOT NULL,
    student_id VARCHAR(10) NOT NULL,
    desk_id INT NOT NULL,
    ticket_number VARCHAR(20) NOT NULL UNIQUE,
    status INT DEFAULT 0 CHECK (status IN (0, 1, 2)),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES student(student_id),
    FOREIGN KEY (desk_id) REFERENCES queue(id),
    CONSTRAINT queue_tickets_unique_desk_student UNIQUE (desk_id, student_id)
);

CREATE INDEX idx_queue_tickets_student_id ON queue_tickets(student_id);
CREATE INDEX idx_queue_tickets_desk_id ON queue_tickets(desk_id);
CREATE INDEX idx_queue_tickets_status ON queue_tickets(status);
CREATE INDEX idx_queue_tickets_created_at ON queue_tickets(created_at DESC);

ALTER TABLE queue_tickets OWNER TO per;
