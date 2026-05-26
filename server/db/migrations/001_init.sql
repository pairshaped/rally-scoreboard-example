-- Scoreboard schema and seed data.
--
-- Creates teams and games used by the public and admin Mounts, then seeds a
-- small league table for local development and smoke tests.

CREATE TABLE IF NOT EXISTS teams (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS games (
    id INTEGER PRIMARY KEY,
    home_code TEXT NOT NULL REFERENCES teams (code),
    away_code TEXT NOT NULL REFERENCES teams (code),
    home_score INTEGER NOT NULL DEFAULT 0,
    away_score INTEGER NOT NULL DEFAULT 0,
    period TEXT NOT NULL DEFAULT 'Scheduled',
    final INTEGER NOT NULL DEFAULT 0,
    CHECK (home_code <> away_code),
    CHECK (final IN (0, 1))
);

CREATE INDEX IF NOT EXISTS idx_games_home ON games (home_code);
CREATE INDEX IF NOT EXISTS idx_games_away ON games (away_code);
CREATE INDEX IF NOT EXISTS idx_games_final ON games (final);

INSERT OR IGNORE INTO teams (code, name)
VALUES
    ('TOR', 'Toronto Towers'),
    ('MTL', 'Montreal Meteors'),
    ('VAN', 'Vancouver Voyagers'),
    ('NYC', 'New York Comets');

INSERT OR IGNORE INTO games (
    id,
    home_code,
    away_code,
    home_score,
    away_score,
    period,
    final
)
VALUES
    (1, 'TOR', 'MTL', 4, 2, '3rd', 0),
    (2, 'VAN', 'NYC', 1, 1, 'Final', 1);
