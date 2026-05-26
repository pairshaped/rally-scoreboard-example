-- Load one public game by id.
--
-- Joins team names so the public detail page can render a complete GameDetail.

SELECT
    g.id,
    g.home_code,
    home.name AS home_name,
    g.away_code,
    away.name AS away_name,
    g.home_score,
    g.away_score,
    g.period,
    g.final
FROM games AS g
INNER JOIN teams AS home ON g.home_code = home.code
INNER JOIN teams AS away ON g.away_code = away.code
WHERE g.id = :game_id
