-- Insert a scheduled game for the admin Mount.
--
-- Returns the row shape needed to build an AdminGameSummary payload.

INSERT INTO games (home_code, away_code, home_score, away_score, period, final)
VALUES (:home_code, :away_code, 0, 0, 'Scheduled', 0)
RETURNING
    id,
    home_code,
    away_code,
    home_score,
    away_score,
    period,
    final
