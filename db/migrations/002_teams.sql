-- Teams table with URL-friendly slugs.
--
-- Slugs can carry non-ASCII characters; the browser decodes percent-encoded
-- slugs before routing. One seed slug intentionally uses a non-ASCII
-- character (montréal-meteors) to exercise the UTF-8 round-trip through
-- SSR base64 hydration flags.

CREATE TABLE IF NOT EXISTS teams (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_teams_slug ON teams (slug);
