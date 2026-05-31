-- Games table used by public and admin Mounts.

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
