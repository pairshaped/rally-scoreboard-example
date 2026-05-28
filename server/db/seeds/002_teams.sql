-- Demo teams for local development and smoke tests.
--
-- Six-team round robin with URL-friendly slugs. The montréal-meteors slug
-- intentionally uses a non-ASCII character to exercise UTF-8 round-trips
-- through SSR base64 hydration flags.

INSERT OR IGNORE INTO teams (code, name, slug)
VALUES
    ('TOR', 'Toronto Towers', 'toronto-towers'),
    ('MTL', 'Montreal Meteors', 'montréal-meteors'),
    ('VAN', 'Vancouver Voyagers', 'vancouver-voyagers'),
    ('NYC', 'New York Comets', 'new-york-comets'),
    ('BOS', 'Boston Blizzards', 'boston-blizzards'),
    ('LAK', 'Los Angeles Knights', 'los-angeles-knights');
