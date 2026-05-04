-- V8: Create refresh_token table for JWT token rotation

CREATE TABLE IF NOT EXISTS refresh_token (
    id BIGSERIAL PRIMARY KEY,
    user_type VARCHAR(20) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_user_type CHECK (user_type IN ('ADMIN', 'REGISTRAR', 'STUDENT'))
);

CREATE INDEX idx_refresh_token_user_type_id ON refresh_token(user_type, user_id);
CREATE INDEX idx_refresh_token_token ON refresh_token(token);
CREATE INDEX idx_refresh_token_expires_at ON refresh_token(expires_at);
CREATE INDEX idx_refresh_token_revoked ON refresh_token(revoked);

ALTER TABLE refresh_token OWNER TO per;
