CREATE TABLE IF NOT EXISTS polypod_events (
    interest_id INTEGER NOT NULL,
    from_source VARCHAR(255) NOT NULL,
    media URL VARCHAR(255) NOT NULL,
    headline VARCHAR(255) NOT NULL,
    info string,
    seemore URL VARCHAR(255),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (interest_id, created_at)
);