-- List games for the public Mount.
--
-- Joins team names so public pages can render readable game summaries.

SELECT
    g.id,
    g.home_code,
    home.name AS home_name,
    home.slug AS home_slug,
    g.away_code,
    away.name AS away_name,
    away.slug AS away_slug,
    g.home_score,
    g.away_score,
    g.period,
    g.final
FROM games AS g
INNER JOIN teams AS home ON g.home_code = home.code
INNER JOIN teams AS away ON g.away_code = away.code
WHERE
    :team_filter = ''
    OR g.home_code = :team_filter
    OR g.away_code = :team_filter
ORDER BY g.id
