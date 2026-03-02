CREATE TABLE IF NOT EXISTS polypod_notifications (
    user_id INTEGER NOT NULL,
    notifType string NOT NULL DEFAULT 'base',
    from_source string NOT NULL,
    notification_data JSONB NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, created_at)
);