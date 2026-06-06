import gleam/dynamic/decode
import sqlight

/// Generated from src/public/pages/games/id_/sql/get_game.sql
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

/// Generated from src/public/pages/games/id_/sql/get_game.sql
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
