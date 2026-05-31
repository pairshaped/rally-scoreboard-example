-- List games for the admin Mount.
--
-- Returns editable game rows without joining display names.

SELECT
    g.id,
    g.home_code,
    g.away_code,
    g.home_score,
    g.away_score,
    g.period,
    g.final
FROM games AS g
ORDER BY g.id
