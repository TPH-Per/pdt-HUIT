-- V8__create_refresh_token.sql
CREATE TABLE refresh_token (
    id         BIGSERIAL PRIMARY KEY,
    token      VARCHAR(512) UNIQUE NOT NULL,
    user_id    VARCHAR(50)  NOT NULL,
    user_type  VARCHAR(20)  NOT NULL,
    expires_at TIMESTAMPTZ  NOT NULL,
    revoked    BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_refresh_token_active ON refresh_token(token) WHERE NOT revoked;
CREATE INDEX idx_refresh_token_user   ON refresh_token(user_id, user_type) WHERE NOT revoked;