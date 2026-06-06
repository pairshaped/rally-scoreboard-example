-- Mark a game as final.
--
-- Only updates final state. Does not set scores. Score updates belong in
-- update_game_score.sql. If a UI action combines "save score and finalize,"
-- model it as an explicit two-step operation.

UPDATE games
SET
    period = 'Final',
    final = 1
WHERE id = :game_id
RETURNING
    id,
    home_code,
    away_code,
    home_score,
    away_score,
    period,
    final
