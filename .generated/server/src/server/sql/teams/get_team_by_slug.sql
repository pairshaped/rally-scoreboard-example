-- Look up a team by its URL slug, including its win/loss record from final games.
--
-- Returns team identity (code, name, slug) plus aggregated record data.
-- The slug is the URL-friendly identifier; it may contain non-ASCII characters
-- that arrived percent-decoded from the route param.

WITH team_games AS (
    SELECT
        home_code AS team_code,
        home_score AS points_for,
        away_score AS points_against,
        CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS win,
        CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS loss
    FROM games
    WHERE final = 1
    UNION ALL
    SELECT
        away_code AS team_code,
        away_score AS points_for,
        home_score AS points_against,
        CASE WHEN away_score > home_score THEN 1 ELSE 0 END AS win,
        CASE WHEN away_score < home_score THEN 1 ELSE 0 END AS loss
    FROM games
    WHERE final = 1
)
SELECT
    t.code,
    t.name,
    t.slug,
    COALESCE(SUM(team_games.win), 0) AS wins,
    COALESCE(SUM(team_games.loss), 0) AS losses,
    COALESCE(SUM(team_games.points_for), 0) AS points_for,
    COALESCE(SUM(team_games.points_against), 0) AS points_against
FROM teams AS t
LEFT JOIN team_games ON t.code = team_games.team_code
WHERE t.slug = :slug
GROUP BY t.code, t.name, t.slug
