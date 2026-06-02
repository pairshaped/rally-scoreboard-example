@target(erlang)
import api/domain/game.{
  type AdminGameSummary, type GameDetail, type GameSnapshot, type GameStatus,
  type PublicGameSummary, AdminGameSummary, Final, GameDetail, GameSnapshot,
  Live, PublicGameSummary, Scheduled, Team,
}
@target(erlang)
import api/domain/standing.{type StandingRow, StandingRow}
@target(erlang)
import api/domain/team.{TeamDetail}
@target(erlang)
import api/to_client.{type ToClient}
@target(erlang)
import api/to_server.{type ToServer}
@target(erlang)
import generated/api/ack.{
  type ApiLoadError, type ApiSaveError, ApiLoadError, ApiSaveError,
}
@target(erlang)
import generated/api/server as generated_server
@target(erlang)
import generated/sql/games_sql
@target(erlang)
import generated/sql/standings_sql
@target(erlang)
import generated/sql/teams_sql
@target(erlang)
import gleam/int
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{type Option, None, Some}
@target(erlang)
import sqlight

@target(erlang)
pub type DispatchReply {
  LoadReply(ack: Result(Nil, List(ApiLoadError)), messages: List(ToClient))
  SaveReply(ack: Result(Nil, List(ApiSaveError)), messages: List(ToClient))
}

@target(erlang)
pub fn dispatch(
  db db: sqlight.Connection,
  message message: ToServer,
  admin_authorized admin_authorized: Bool,
) -> List(ToClient) {
  dispatch_reply(db: db, message: message, admin_authorized:)
  |> reply_messages
}

@target(erlang)
pub fn dispatch_reply(
  db db: sqlight.Connection,
  message message: ToServer,
  admin_authorized admin_authorized: Bool,
) -> DispatchReply {
  case is_admin_message(message), admin_authorized {
    True, False -> unauthorized_reply(message)
    _, _ ->
      case message {
        to_server.LoadGames -> load_games(db)
        to_server.LoadGame(game_id) -> load_game(db, game_id)
        to_server.LoadStandings -> load_standings(db)
        to_server.LoadTeam(slug) -> load_team(db, slug)
        to_server.LoadAdminGames -> load_admin_games(db)
        to_server.UpdateScore(game_id, home_score, away_score, period) ->
          update_score(db, game_id, home_score, away_score, period)
        to_server.MarkFinal(game_id) -> mark_final(db, game_id)
        to_server.CorrectResult(game_id, home_score, away_score) ->
          correct_result(db, game_id, home_score, away_score)
      }
  }
}

@target(erlang)
fn unauthorized_reply(message: ToServer) -> DispatchReply {
  case is_load_message(message) {
    True -> load_failed("Unauthorized.")
    False -> save_failed("Unauthorized.")
  }
}

@target(erlang)
fn is_load_message(message: ToServer) -> Bool {
  case message {
    to_server.LoadGames
    | to_server.LoadGame(_)
    | to_server.LoadStandings
    | to_server.LoadTeam(_)
    | to_server.LoadAdminGames -> True
    _ -> False
  }
}

@target(erlang)
fn is_admin_message(message: ToServer) -> Bool {
  case message {
    to_server.LoadAdminGames
    | to_server.UpdateScore(_, _, _, _)
    | to_server.MarkFinal(_)
    | to_server.CorrectResult(_, _, _) -> True
    _ -> False
  }
}

@target(erlang)
pub fn reply_messages(reply: DispatchReply) -> List(ToClient) {
  case reply {
    LoadReply(messages: messages, ..) -> messages
    SaveReply(messages: messages, ..) -> messages
  }
}

@target(erlang)
pub fn reply_ack(reply: DispatchReply) -> BitArray {
  case reply {
    LoadReply(ack, ..) -> generated_server.encode_load_ack(ack)
    SaveReply(ack, ..) -> generated_server.encode_save_ack(ack)
  }
}

@target(erlang)
pub fn push(module module: String, message message: ToClient) -> BitArray {
  generated_server.encode_push(module, message)
}

@target(erlang)
fn load_games(db: sqlight.Connection) -> DispatchReply {
  case games_sql.list_public_games(db: db, team_filter: "") {
    Ok(rows) ->
      load_succeeded([
        to_client.GamesLoaded(list.map(rows, public_game_summary_from_row)),
      ])
    Error(sqlight.SqlightError(..)) -> load_failed("Could not load games.")
  }
}

@target(erlang)
fn load_game(db: sqlight.Connection, game_id: Int) -> DispatchReply {
  case games_sql.get_game(db: db, game_id: game_id) {
    Ok([row, ..]) ->
      load_succeeded([to_client.GameLoaded(game_detail_from_row(row))])
    Ok([]) -> load_failed("Game not found.")
    Error(sqlight.SqlightError(..)) -> load_failed("Could not load game.")
  }
}

@target(erlang)
fn load_standings(db: sqlight.Connection) -> DispatchReply {
  case standings_sql.list_standings(db) {
    Ok(rows) ->
      load_succeeded([
        to_client.StandingsLoaded(list.map(rows, standing_from_row)),
      ])
    Error(sqlight.SqlightError(..)) -> load_failed("Could not load standings.")
  }
}

@target(erlang)
fn load_team(db: sqlight.Connection, slug: String) -> DispatchReply {
  case teams_sql.get_team_by_slug(db: db, slug: slug) {
    Ok([row, ..]) -> load_team_games(db, row)
    Ok([]) -> load_failed("Team not found.")
    Error(sqlight.SqlightError(..)) -> load_failed("Could not load team.")
  }
}

@target(erlang)
fn load_team_games(
  db: sqlight.Connection,
  row: teams_sql.GetTeamBySlugRow,
) -> DispatchReply {
  let team_code = optional_string(row.code)

  case games_sql.list_public_games(db: db, team_filter: team_code) {
    Ok(games) ->
      load_succeeded([
        to_client.TeamLoaded(TeamDetail(
          code: team_code,
          name: row.name,
          slug: row.slug,
          wins: row.wins,
          losses: row.losses,
          points_for: row.points_for,
          points_against: row.points_against,
          recent_games: list.map(games, public_game_summary_from_row),
        )),
      ])
    Error(sqlight.SqlightError(..)) -> load_failed("Could not load team games.")
  }
}

@target(erlang)
fn load_admin_games(db: sqlight.Connection) -> DispatchReply {
  case games_sql.list_admin_games(db) {
    Ok(rows) ->
      load_succeeded([
        to_client.AdminGamesLoaded(list.map(rows, admin_game_summary_from_row)),
      ])
    Error(sqlight.SqlightError(..)) ->
      load_failed("Could not load admin games.")
  }
}

// nolint: label_possible -- private ToServer handler mirrors constructor field order.
@target(erlang)
fn update_score(
  db: sqlight.Connection,
  game_id: Int,
  home_score: Int,
  away_score: Int,
  period: String,
) -> DispatchReply {
  case
    games_sql.update_game_score(db, home_score, away_score, period, game_id)
  {
    Ok([_, ..]) -> saved_game_reply(db, game_id)
    Ok([]) -> save_failed("Game not found.")
    Error(sqlight.SqlightError(..)) -> save_failed("Could not update score.")
  }
}

@target(erlang)
fn mark_final(db: sqlight.Connection, game_id: Int) -> DispatchReply {
  case games_sql.update_game_final(db: db, game_id: game_id) {
    Ok([_, ..]) -> saved_game_reply(db, game_id)
    Ok([]) -> save_failed("Game not found.")
    Error(sqlight.SqlightError(..)) -> save_failed("Could not mark final.")
  }
}

// nolint: label_possible -- private ToServer handler mirrors constructor field order.
@target(erlang)
fn correct_result(
  db: sqlight.Connection,
  game_id: Int,
  home_score: Int,
  away_score: Int,
) -> DispatchReply {
  case
    games_sql.update_game_score(db, home_score, away_score, "Final", game_id)
  {
    Ok([_, ..]) -> mark_final(db, game_id)
    Ok([]) -> save_failed("Game not found.")
    Error(sqlight.SqlightError(..)) -> save_failed("Could not correct result.")
  }
}

@target(erlang)
fn saved_game_reply(db: sqlight.Connection, game_id: Int) -> DispatchReply {
  case game_snapshot(db, game_id) {
    Ok(snapshot) -> save_succeeded([to_client.GameUpdated(snapshot)])
    Error(Nil) -> save_succeeded([])
  }
}

@target(erlang)
fn load_succeeded(messages: List(ToClient)) -> DispatchReply {
  LoadReply(ack: Ok(Nil), messages:)
}

@target(erlang)
fn load_failed(message: String) -> DispatchReply {
  LoadReply(ack: Error([ApiLoadError(message:)]), messages: [])
}

@target(erlang)
fn save_succeeded(messages: List(ToClient)) -> DispatchReply {
  SaveReply(ack: Ok(Nil), messages:)
}

@target(erlang)
fn save_failed(message: String) -> DispatchReply {
  SaveReply(ack: Error([ApiSaveError(field: None, message:)]), messages: [])
}

@target(erlang)
fn game_snapshot(
  db: sqlight.Connection,
  game_id: Int,
) -> Result(GameSnapshot, Nil) {
  case games_sql.get_game(db: db, game_id: game_id) {
    Ok([row, ..]) -> Ok(game_snapshot_from_row(row))
    _ -> Error(Nil)
  }
}

@target(erlang)
fn public_game_summary_from_row(
  row: games_sql.ListPublicGamesRow,
) -> PublicGameSummary {
  PublicGameSummary(
    id: row.id,
    home: Team(row.home_code, row.home_name, row.home_slug),
    away: Team(row.away_code, row.away_name, row.away_slug),
    home_score: row.home_score,
    away_score: row.away_score,
    status: game_status(row.period, row.final),
  )
}

@target(erlang)
fn game_detail_from_row(row: games_sql.GetGameRow) -> GameDetail {
  GameDetail(
    id: row.id,
    home: Team(row.home_code, row.home_name, row.home_slug),
    away: Team(row.away_code, row.away_name, row.away_slug),
    home_score: row.home_score,
    away_score: row.away_score,
    status: game_status(row.period, row.final),
    scoring_summary: [score_summary(row)],
  )
}

@target(erlang)
fn game_snapshot_from_row(row: games_sql.GetGameRow) -> GameSnapshot {
  GameSnapshot(
    id: row.id,
    home: Team(row.home_code, row.home_name, row.home_slug),
    away: Team(row.away_code, row.away_name, row.away_slug),
    home_score: row.home_score,
    away_score: row.away_score,
    status: game_status(row.period, row.final),
  )
}

@target(erlang)
fn admin_game_summary_from_row(
  row: games_sql.ListAdminGamesRow,
) -> AdminGameSummary {
  AdminGameSummary(
    id: row.id,
    home_code: row.home_code,
    away_code: row.away_code,
    home_score: row.home_score,
    away_score: row.away_score,
    status: game_status(row.period, row.final),
    needs_attention: row.final != 1,
  )
}

@target(erlang)
fn standing_from_row(row: standings_sql.ListStandingsRow) -> StandingRow {
  StandingRow(
    team_code: optional_string(row.team_code),
    team_name: row.team_name,
    slug: row.team_slug,
    wins: row.wins,
    losses: row.losses,
    points_for: row.points_for,
    points_against: row.points_against,
  )
}

@target(erlang)
fn game_status(period: String, final: Int) -> GameStatus {
  case final == 1, period {
    True, _ -> Final
    False, "Scheduled" -> Scheduled
    False, _ -> Live(period)
  }
}

@target(erlang)
fn optional_string(value: Option(String)) -> String {
  case value {
    Some(value) -> value
    None -> ""
  }
}

@target(erlang)
fn score_summary(row: games_sql.GetGameRow) -> String {
  row.away_code
  <> " "
  <> int.to_string(row.away_score)
  <> ", "
  <> row.home_code
  <> " "
  <> int.to_string(row.home_score)
}
