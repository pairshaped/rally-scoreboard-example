import gleam/dynamic/decode
import sqlight

/// Generated from src/server/sql/games/get_game.sql
pub type GetGameRow {
  GetGameRow(
    id: Int,
    home_code: String,
    home_name: String,
    home_slug: String,
    away_code: String,
    away_name: String,
    away_slug: String,
    home_score: Int,
    away_score: Int,
    period: String,
    final: Int,
  )
}

/// Generated from src/server/sql/games/get_game.sql
pub fn get_game(
  db db: sqlight.Connection,
  game_id game_id: Int,
) -> Result(List(GetGameRow), sqlight.Error) {
  sqlight.query(
    "SELECT g.id, g.home_code, home.name AS home_name, home.slug AS home_slug, g.away_code, away.name AS away_name, away.slug AS away_slug, g.home_score, g.away_score, g.period, g.final FROM games AS g INNER JOIN teams AS home ON g.home_code = home.code INNER JOIN teams AS away ON g.away_code = away.code WHERE g.id = :game_id",
    on: db,
    with: [sqlight.int(game_id)],
    expecting: {
      use id <- decode.field(0, decode.int)
      use home_code <- decode.field(1, decode.string)
      use home_name <- decode.field(2, decode.string)
      use home_slug <- decode.field(3, decode.string)
      use away_code <- decode.field(4, decode.string)
      use away_name <- decode.field(5, decode.string)
      use away_slug <- decode.field(6, decode.string)
      use home_score <- decode.field(7, decode.int)
      use away_score <- decode.field(8, decode.int)
      use period <- decode.field(9, decode.string)
      use final <- decode.field(10, decode.int)
      decode.success(GetGameRow(
        id:,
        home_code:,
        home_name:,
        home_slug:,
        away_code:,
        away_name:,
        away_slug:,
        home_score:,
        away_score:,
        period:,
        final:,
      ))
    },
  )
}

/// Generated from src/server/sql/games/list_admin_games.sql
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

/// Generated from src/server/sql/games/list_admin_games.sql
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

/// Generated from src/server/sql/games/list_public_games.sql
pub type ListPublicGamesRow {
  ListPublicGamesRow(
    id: Int,
    home_code: String,
    home_name: String,
    home_slug: String,
    away_code: String,
    away_name: String,
    away_slug: String,
    home_score: Int,
    away_score: Int,
    period: String,
    final: Int,
  )
}

/// Generated from src/server/sql/games/list_public_games.sql
pub fn list_public_games(
  db db: sqlight.Connection,
  team_filter team_filter: String,
) -> Result(List(ListPublicGamesRow), sqlight.Error) {
  sqlight.query(
    "SELECT g.id, g.home_code, home.name AS home_name, home.slug AS home_slug, g.away_code, away.name AS away_name, away.slug AS away_slug, g.home_score, g.away_score, g.period, g.final FROM games AS g INNER JOIN teams AS home ON g.home_code = home.code INNER JOIN teams AS away ON g.away_code = away.code WHERE :team_filter = '' OR g.home_code = :team_filter OR g.away_code = :team_filter ORDER BY g.id",
    on: db,
    with: [sqlight.text(team_filter)],
    expecting: {
      use id <- decode.field(0, decode.int)
      use home_code <- decode.field(1, decode.string)
      use home_name <- decode.field(2, decode.string)
      use home_slug <- decode.field(3, decode.string)
      use away_code <- decode.field(4, decode.string)
      use away_name <- decode.field(5, decode.string)
      use away_slug <- decode.field(6, decode.string)
      use home_score <- decode.field(7, decode.int)
      use away_score <- decode.field(8, decode.int)
      use period <- decode.field(9, decode.string)
      use final <- decode.field(10, decode.int)
      decode.success(ListPublicGamesRow(
        id:,
        home_code:,
        home_name:,
        home_slug:,
        away_code:,
        away_name:,
        away_slug:,
        home_score:,
        away_score:,
        period:,
        final:,
      ))
    },
  )
}

/// Generated from src/server/sql/games/update_game_final.sql
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

/// Generated from src/server/sql/games/update_game_final.sql
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

/// Generated from src/server/sql/games/update_game_score.sql
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

/// Generated from src/server/sql/games/update_game_score.sql
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
