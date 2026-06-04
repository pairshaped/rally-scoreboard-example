@target(erlang)
import broadcasts
@target(erlang)
import generated/rally/server_protocol
@target(erlang)
import generated/sql/public/pages/games/id__sql as game_detail_sql
@target(erlang)
import sqlight

@target(erlang)
pub fn push(
  module module: String,
  message message: broadcasts.Event,
) -> BitArray {
  server_protocol.encode_push(module, message)
}

@target(erlang)
pub fn game_updated_broadcast(
  db: sqlight.Connection,
  game_id: Int,
) -> Result(broadcasts.Event, Nil) {
  case game_detail_sql.get_game(db: db, game_id: game_id) {
    Ok([row, ..]) -> Ok(game_updated_event(row))
    _ -> Error(Nil)
  }
}

@target(erlang)
fn game_updated_event(row: game_detail_sql.GetGameRow) -> broadcasts.Event {
  broadcasts.BroadcastGameUpdated(broadcasts.BroadcastGameSnapshot(
    id: row.id,
    home: broadcasts.BroadcastTeam(
      code: row.home_code,
      name: row.home_name,
      slug: row.home_slug,
    ),
    away: broadcasts.BroadcastTeam(
      code: row.away_code,
      name: row.away_name,
      slug: row.away_slug,
    ),
    home_score: row.home_score,
    away_score: row.away_score,
    status: game_status(row.period, row.final),
  ))
}

@target(erlang)
fn game_status(period: String, final: Int) -> broadcasts.GameStatus {
  case final == 1, period {
    True, _ -> broadcasts.BroadcastFinal
    False, "Scheduled" -> broadcasts.BroadcastScheduled
    False, _ -> broadcasts.BroadcastLive(period)
  }
}
