-- Demo games for local development and smoke tests.
--
-- This is a complete six-team single round robin: every pair appears once.
-- It includes a mix of scheduled, live, and final games so all views have
-- data to render without needing game creation in the example app.

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
