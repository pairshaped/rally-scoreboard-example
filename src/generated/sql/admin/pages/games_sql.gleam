import gleam/dynamic/decode
import sqlight

/// Generated from src/admin/pages/games/sql/list_admin_games.sql
pub type ListAdminGamesRow {
  ListAdminGamesRow(
    id: Int,
    home_code: String,
    away_code: String,
    home_score: Int,
    away_score: Int,
    period: String,
    final: Int,
  )
}

/// Generated from src/admin/pages/games/sql/list_admin_games.sql
pub fn list_admin_games(
  db db: sqlight.Connection,
) -> Result(List(ListAdminGamesRow), sqlight.Error) {
  sqlight.query(
    "SELECT g.id, g.home_code, g.away_code, g.home_score, g.away_score, g.period, g.final FROM games AS g ORDER BY g.id",
    on: db,
    with: [],
    expecting: {
      use id <- decode.field(0, decode.int)
      use home_code <- decode.field(1, decode.string)
      use away_code <- decode.field(2, decode.string)
      use home_score <- decode.field(3, decode.int)
      use away_score <- decode.field(4, decode.int)
      use period <- decode.field(5, decode.string)
      use final <- decode.field(6, decode.int)
      decode.success(ListAdminGamesRow(
        id:,
        home_code:,
        away_code:,
        home_score:,
        away_score:,
        period:,
        final:,
      ))
    },
  )
}

/// Generated from src/admin/pages/games/sql/update_game_final.sql
pub type UpdateGameFinalRow {
  UpdateGameFinalRow(
    id: Int,
    home_code: String,
    away_code: String,
    home_score: Int,
    away_score: Int,
    period: String,
    final: Int,
  )
}

/// Generated from src/admin/pages/games/sql/update_game_final.sql
pub fn update_game_final(
  db db: sqlight.Connection,
  game_id game_id: Int,
) -> Result(List(UpdateGameFinalRow), sqlight.Error) {
  sqlight.query(
    "UPDATE games SET period = 'Final', final = 1 WHERE id = :game_id RETURNING id, home_code, away_code, home_score, away_score, period, final",
    on: db,
    with: [sqlight.int(game_id)],
    expecting: {
      use id <- decode.field(0, decode.int)
      use home_code <- decode.field(1, decode.string)
      use away_code <- decode.field(2, decode.string)
      use home_score <- decode.field(3, decode.int)
      use away_score <- decode.field(4, decode.int)
      use period <- decode.field(5, decode.string)
      use final <- decode.field(6, decode.int)
      decode.success(UpdateGameFinalRow(
        id:,
        home_code:,
        away_code:,
        home_score:,
        away_score:,
        period:,
        final:,
      ))
    },
  )
}

/// Generated from src/admin/pages/games/sql/update_game_score.sql
pub type UpdateGameScoreRow {
  UpdateGameScoreRow(
    id: Int,
    home_code: String,
    away_code: String,
    home_score: Int,
    away_score: Int,
    period: String,
    final: Int,
  )
}

/// Generated from src/admin/pages/games/sql/update_game_score.sql
pub fn update_game_score(
  db db: sqlight.Connection,
  home_score home_score: Int,
  away_score away_score: Int,
  period period: String,
  game_id game_id: Int,
) -> Result(List(UpdateGameScoreRow), sqlight.Error) {
  sqlight.query(
    "UPDATE games SET home_score = :home_score, away_score = :away_score, period = :period, final = 0 WHERE id = :game_id RETURNING id, home_code, away_code, home_score, away_score, period, final",
    on: db,
    with: [
      sqlight.int(home_score),
      sqlight.int(away_score),
      sqlight.text(period),
      sqlight.int(game_id),
    ],
    expecting: {
      use id <- decode.field(0, decode.int)
      use home_code <- decode.field(1, decode.string)
      use away_code <- decode.field(2, decode.string)
      use home_score <- decode.field(3, decode.int)
      use away_score <- decode.field(4, decode.int)
      use period <- decode.field(5, decode.string)
      use final <- decode.field(6, decode.int)
      decode.success(UpdateGameScoreRow(
        id:,
        home_code:,
        away_code:,
        home_score:,
        away_score:,
        period:,
        final:,
      ))
    },
  )
}
