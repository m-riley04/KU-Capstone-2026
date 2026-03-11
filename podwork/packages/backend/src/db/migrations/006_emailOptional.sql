-- Rename old table
ALTER TABLE users RENAME TO users_old;

-- Create new table with email as optional
CREATE TABLE  users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT,
    password TEXT NOT NULL,
    username TEXT NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (id, email, password, username, created_at, updated_at)
SELECT id, email, password, username, created_at, updated_at FROM users_old;

DROP TABLE users_old;