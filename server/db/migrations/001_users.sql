-- Users table for shared authentication.
--
-- Stores normalized email, PBKDF2 password hashes, HMAC sign-in code hashes,
-- and an app-owned can_admin flag. Both admin and public Mounts authenticate
-- against this table.
--
-- Email is always stored trimmed and lowercased. Auth lookups normalize input
-- before querying so whitespace/case mismatches still find the row.

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT,
    password_hash TEXT NOT NULL,
    sign_in_code_hash TEXT NOT NULL,
    can_admin INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
