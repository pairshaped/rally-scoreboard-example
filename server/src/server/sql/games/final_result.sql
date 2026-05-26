-- Mark a game final with corrected scores.
--
-- Returns the updated admin row so handlers can emit ToClient confirmations.

UPDATE games
SET
    home_score = :home_score,
    away_score = :away_score,
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
