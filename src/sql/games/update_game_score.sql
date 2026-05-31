-- Update a live game's score.
--
-- Clears final state and returns the admin row used for ToClient updates.

UPDATE games
SET
    home_score = :home_score,
    away_score = :away_score,
    period = :period,
    final = 0
WHERE id = :game_id
RETURNING
    id,
    home_code,
    away_code,
    home_score,
    away_score,
    period,
    final
