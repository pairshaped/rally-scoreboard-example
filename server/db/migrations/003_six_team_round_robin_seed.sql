-- Reset local demo seed data to a six-team round robin.
--
-- This is intentionally destructive for the demo database. The app uses the
-- seeded league as a repeatable fixture for public pages, admin flows, and
-- websocket fanout checks.

DELETE FROM games;
DELETE FROM teams;

INSERT INTO teams (code, name, slug)
VALUES
    ('TOR', 'Toronto Towers', 'toronto-towers'),
    ('MTL', 'Montreal Meteors', 'montréal-meteors'),
    ('VAN', 'Vancouver Voyagers', 'vancouver-voyagers'),
    ('NYC', 'New York Comets', 'new-york-comets'),
    ('BOS', 'Boston Blizzards', 'boston-blizzards'),
    ('LAK', 'Los Angeles Knights', 'los-angeles-knights');

INSERT INTO games (
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
    (2, 'VAN', 'NYC', 1, 1, 'Final', 1),
    (3, 'BOS', 'LAK', 0, 0, 'Scheduled', 0),
    (4, 'TOR', 'VAN', 5, 3, 'Final', 1),
    (5, 'TOR', 'NYC', 0, 0, 'Scheduled', 0),
    (6, 'TOR', 'BOS', 6, 4, 'Final', 1),
    (7, 'TOR', 'LAK', 0, 0, 'Scheduled', 0),
    (8, 'MTL', 'VAN', 0, 0, 'Scheduled', 0),
    (9, 'MTL', 'NYC', 2, 5, 'Final', 1),
    (10, 'MTL', 'BOS', 0, 0, 'Scheduled', 0),
    (11, 'MTL', 'LAK', 3, 4, 'Final', 1),
    (12, 'VAN', 'BOS', 0, 0, 'Scheduled', 0),
    (13, 'VAN', 'LAK', 7, 6, 'Final', 1),
    (14, 'NYC', 'BOS', 0, 0, 'Scheduled', 0),
    (15, 'NYC', 'LAK', 5, 2, 'Final', 1);
