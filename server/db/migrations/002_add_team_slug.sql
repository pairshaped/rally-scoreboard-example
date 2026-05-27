-- Add slug column to teams for URL-friendly team pages.
--
-- Slugs are URL-safe identifiers that can carry non-ASCII characters;
-- the browser decodes percent-encoded slugs before routing.
-- One seed slug intentionally uses a non-ASCII character (montréal-meteors)
-- to exercise the UTF-8 round-trip through SSR base64 hydration flags.
--
-- Seed teams get hand-written slugs. Any other team (not in the seed list)
-- gets a fallback slug derived from the team code so the unique index and
-- URL generation always work, even for rows inserted outside migrations.

ALTER TABLE teams ADD COLUMN slug TEXT NOT NULL DEFAULT '';

UPDATE teams SET slug = 'toronto-towers' WHERE code = 'TOR';
UPDATE teams SET slug = 'montréal-meteors' WHERE code = 'MTL';
UPDATE teams SET slug = 'vancouver-voyagers' WHERE code = 'VAN';
UPDATE teams SET slug = 'new-york-comets' WHERE code = 'NYC';
UPDATE teams SET slug = LOWER(code) WHERE slug = '';

CREATE UNIQUE INDEX IF NOT EXISTS idx_teams_slug ON teams (slug);
