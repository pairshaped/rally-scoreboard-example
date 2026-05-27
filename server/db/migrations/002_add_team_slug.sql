-- Add slug column to teams for URL-friendly team pages.
--
-- Slugs are URL-safe identifiers that can carry non-ASCII characters;
-- the browser decodes percent-encoded slugs before routing.
-- One seed slug intentionally uses a non-ASCII character (montréal-meteors)
-- to exercise the UTF-8 round-trip through SSR base64 hydration flags.

ALTER TABLE teams ADD COLUMN slug TEXT NOT NULL DEFAULT '';

UPDATE teams SET slug = 'toronto-towers' WHERE code = 'TOR';
UPDATE teams SET slug = 'montréal-meteors' WHERE code = 'MTL';
UPDATE teams SET slug = 'vancouver-voyagers' WHERE code = 'VAN';
UPDATE teams SET slug = 'new-york-comets' WHERE code = 'NYC';

CREATE UNIQUE INDEX IF NOT EXISTS idx_teams_slug ON teams (slug);
