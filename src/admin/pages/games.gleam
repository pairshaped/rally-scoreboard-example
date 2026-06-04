@target(javascript)
import generated/libero/result as wire_result
import generated/proute/admin/page_input
@target(javascript)
import generated/rally/client_transport as api_client
@target(erlang)
import generated/sql/admin/pages/games_sql

import gleam/int
import gleam/list

import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
@target(erlang)
import sqlight

@target(javascript)
import api/domain/game as api_game
@target(javascript)
import api/to_client
@target(javascript)
import api/to_server
import page_context.{type PageContext}

// TYPES

pub type GameStatus {
  Scheduled
  Live(period: String)
  Final
}

pub type AdminGameSummary {
  AdminGameSummary(
    id: Int,
    home_code: String,
    away_code: String,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
    needs_attention: Bool,
  )
}

pub type GameUpdate {
  GameUpdate(
    id: Int,
    home_code: String,
    away_code: String,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
  )
}

pub type LoadError {
  LoadError(message: String)
}

pub type SaveError {
  SaveError(message: String)
}

pub type ServerMsg {
  ServerUpdateScore(
    game_id: Int,
    home_score: Int,
    away_score: Int,
    period: String,
  )
  ServerMarkFinal(game_id: Int)
}

pub type Model {
  Model(games: List(AdminGameSummary))
}

pub type Message {
  AdjustAway(id: Int, home_score: Int, away_score: Int, delta: Int)
  AdjustHome(id: Int, home_score: Int, away_score: Int, delta: Int)
  Loaded(Result(List(AdminGameSummary), LoadError))
  MarkFinal(id: Int)
  Saved(Result(GameUpdate, SaveError))
  SaveFinished(id: Int, result: Result(Nil, SaveError))
}

// INIT

pub fn init(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  #(initial_model(page_context, query_params), init_effect())
}

pub fn initial_model(
  _page_context: PageContext,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(games: [])
}

// UPDATE

pub fn update(
  _page_context: PageContext,
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  case msg {
    Loaded(Ok(games)) -> #(Model(games: games), effect.none())
    Loaded(Error(_)) -> #(model, effect.none())
    Saved(Ok(game)) -> #(
      upsert_game(model, game_update_summary(game)),
      effect.none(),
    )
    Saved(Error(_)) -> #(model, effect.none())
    SaveFinished(_, Ok(Nil)) -> #(model, effect.none())
    SaveFinished(_, Error(_)) -> #(model, effect.none())
    AdjustAway(..) | AdjustHome(..) | MarkFinal(..) -> #(
      model,
      message_effect(msg),
    )
  }
}

pub fn admin_games_loaded(
  model _model: Model,
  games games: List(AdminGameSummary),
) -> #(Model, Effect(Message)) {
  #(Model(games: games), effect.none())
}

pub fn game_updated(
  model model: Model,
  game game: GameUpdate,
) -> #(Model, Effect(Message)) {
  #(upsert_game(model, game_update_summary(game)), effect.none())
}

// VIEW

pub fn view(model model: Model) -> Element(Message) {
  view_games(
    games: model.games,
    on_adjust_away: fn(id, home_score, away_score, delta) {
      AdjustAway(id:, home_score:, away_score:, delta:)
    },
    on_adjust_home: fn(id, home_score, away_score, delta) {
      AdjustHome(id:, home_score:, away_score:, delta:)
    },
    on_mark_final: fn(id) { MarkFinal(id:) },
  )
}

// HELPERS

fn view_games(
  games games: List(AdminGameSummary),
  on_adjust_away on_adjust_away: fn(Int, Int, Int, Int) -> msg,
  on_adjust_home on_adjust_home: fn(Int, Int, Int, Int) -> msg,
  on_mark_final on_mark_final: fn(Int) -> msg,
) -> Element(msg) {
  case games {
    [] -> html.p([attribute.class("muted")], [html.text("No games yet.")])
    _ ->
      html.div(
        [attribute.class("game-grid")],
        list.map(games, fn(game) {
          view_game_card(game, on_adjust_away, on_adjust_home, on_mark_final)
        }),
      )
  }
}

fn view_game_card(
  game: AdminGameSummary,
  on_adjust_away: fn(Int, Int, Int, Int) -> msg,
  on_adjust_home: fn(Int, Int, Int, Int) -> msg,
  on_mark_final: fn(Int) -> msg,
) -> Element(msg) {
  html.article([attribute.class("game-card")], [
    html.div([attribute.class("admin-score-row")], [
      html.strong([], [html.text(game.away_code)]),
      score_button(
        "-",
        on_adjust_away(game.id, game.home_score, game.away_score, -1),
      ),
      score_button(
        "+",
        on_adjust_away(game.id, game.home_score, game.away_score, 1),
      ),
      html.span([attribute.class("score")], [
        html.text(int.to_string(game.away_score)),
      ]),
    ]),
    html.div([attribute.class("admin-score-row")], [
      html.strong([], [html.text(game.home_code)]),
      score_button(
        "-",
        on_adjust_home(game.id, game.home_score, game.away_score, -1),
      ),
      score_button(
        "+",
        on_adjust_home(game.id, game.home_score, game.away_score, 1),
      ),
      html.span([attribute.class("score")], [
        html.text(int.to_string(game.home_score)),
      ]),
    ]),
    html.div([attribute.class("score-line admin-status-row")], [
      status_badge(game.status),
      final_action(game, on_mark_final),
    ]),
  ])
}

fn score_button(label: String, msg: msg) -> Element(msg) {
  html.button([attribute.class("small score-control"), event.on_click(msg)], [
    html.text(label),
  ])
}

fn final_action(
  game: AdminGameSummary,
  on_mark_final: fn(Int) -> msg,
) -> Element(msg) {
  case game.status {
    Final -> html.span([], [])
    _ ->
      html.button(
        [
          attribute.class("small secondary"),
          event.on_click(on_mark_final(game.id)),
        ],
        [html.text("Finalize")],
      )
  }
}

fn upsert_game(model: Model, game: AdminGameSummary) -> Model {
  let games =
    list.map(model.games, fn(existing) {
      case existing.id == game.id {
        True -> game
        False -> existing
      }
    })

  Model(games: games)
}

fn game_update_summary(game: GameUpdate) -> AdminGameSummary {
  AdminGameSummary(
    id: game.id,
    home_code: game.home_code,
    away_code: game.away_code,
    home_score: game.home_score,
    away_score: game.away_score,
    status: game.status,
    needs_attention: False,
  )
}

fn status_badge(status: GameStatus) -> Element(msg) {
  case status {
    Scheduled -> html.span([attribute.class("badge")], [html.text("Scheduled")])
    Live(period) ->
      html.span([attribute.class("badge live")], [html.text(period)])
    Final -> html.span([attribute.class("badge final")], [html.text("Final")])
  }
}

// EFFECTS

@target(javascript)
fn init_effect() -> Effect(Message) {
  api_client.send_load(
    module: "admin/games",
    message: to_server.LoadAdminGames,
    on_result: fn(result) { Loaded(map_load_result(result)) },
  )
}

@target(erlang)
fn init_effect() -> Effect(Message) {
  effect.none()
}

@target(javascript)
fn map_load_result(
  result: Result(to_client.ToClient, List(wire_result.ApiLoadError)),
) -> Result(List(AdminGameSummary), LoadError) {
  case result {
    Ok(to_client.AdminGamesLoaded(games)) ->
      Ok(list.map(games, wire_admin_game_summary))
    Ok(_) -> Error(LoadError(message: "Unexpected admin games response."))
    Error([wire_result.ApiLoadError(message: message), ..]) ->
      Error(LoadError(message: message))
    Error([]) -> Error(LoadError(message: "Could not load admin games."))
  }
}

@target(javascript)
fn wire_admin_game_summary(
  game: api_game.AdminGameSummary,
) -> AdminGameSummary {
  AdminGameSummary(
    id: game.id,
    home_code: game.home_code,
    away_code: game.away_code,
    home_score: game.home_score,
    away_score: game.away_score,
    status: wire_game_status(game.status),
    needs_attention: game.needs_attention,
  )
}

@target(javascript)
fn wire_game_status(status: api_game.GameStatus) -> GameStatus {
  case status {
    api_game.Scheduled -> Scheduled
    api_game.Live(period) -> Live(period)
    api_game.Final -> Final
  }
}

@target(javascript)
fn message_effect(msg: Message) -> Effect(Message) {
  case msg {
    AdjustAway(id, home_score, away_score, delta) ->
      api_client.send_save(
        module: "admin/games",
        message: to_server.UpdateScore(
          game_id: id,
          home_score: home_score,
          away_score: clamp_score(away_score + delta),
          period: "Live",
        ),
        on_result: fn(result) { SaveFinished(id, map_save_result(result)) },
      )
    AdjustHome(id, home_score, away_score, delta) ->
      api_client.send_save(
        module: "admin/games",
        message: to_server.UpdateScore(
          game_id: id,
          home_score: clamp_score(home_score + delta),
          away_score: away_score,
          period: "Live",
        ),
        on_result: fn(result) { SaveFinished(id, map_save_result(result)) },
      )
    MarkFinal(id) ->
      api_client.send_save(
        module: "admin/games",
        message: to_server.MarkFinal(id),
        on_result: fn(result) { SaveFinished(id, map_save_result(result)) },
      )
    Loaded(_) | Saved(_) | SaveFinished(..) -> effect.none()
  }
}

@target(erlang)
fn message_effect(_msg: Message) -> Effect(Message) {
  effect.none()
}

// nolint: prefer_guard_clause -- the case reads as a simple clamp.
@target(javascript)
fn clamp_score(score: Int) -> Int {
  case score < 0 {
    True -> 0
    False -> score
  }
}

@target(javascript)
fn map_save_result(
  result: Result(Nil, List(wire_result.ApiSaveError)),
) -> Result(Nil, SaveError) {
  case result {
    Ok(Nil) -> Ok(Nil)
    Error([wire_result.ApiSaveError(message: message, ..), ..]) ->
      Error(SaveError(message: message))
    Error([]) -> Error(SaveError(message: "Could not save game."))
  }
}

// SERVER

@target(erlang)
pub fn load(
  db: sqlight.Connection,
) -> Result(List(AdminGameSummary), LoadError) {
  case games_sql.list_admin_games(db: db) {
    Ok(rows) -> Ok(list.map(rows, admin_game_summary_from_row))
    Error(sqlight.SqlightError(..)) ->
      Error(LoadError(message: "Could not load games."))
  }
}

@target(erlang)
pub fn handle(
  db: sqlight.Connection,
  msg: ServerMsg,
) -> Result(GameUpdate, SaveError) {
  case msg {
    ServerUpdateScore(game_id, home_score, away_score, period) ->
      case
        games_sql.update_game_score(
          db: db,
          home_score: home_score,
          away_score: away_score,
          period: period,
          game_id: game_id,
        )
      {
        Ok([row, ..]) -> Ok(game_update_from_score_row(row))
        Ok([]) -> Error(SaveError(message: "Game not found."))
        Error(sqlight.SqlightError(..)) ->
          Error(SaveError(message: "Could not save game."))
      }

    ServerMarkFinal(game_id) ->
      case games_sql.update_game_final(db: db, game_id: game_id) {
        Ok([row, ..]) -> Ok(game_update_from_final_row(row))
        Ok([]) -> Error(SaveError(message: "Game not found."))
        Error(sqlight.SqlightError(..)) ->
          Error(SaveError(message: "Could not save game."))
      }
  }
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
    needs_attention: False,
  )
}

@target(erlang)
fn game_update_from_score_row(row: games_sql.UpdateGameScoreRow) -> GameUpdate {
  GameUpdate(
    id: row.id,
    home_code: row.home_code,
    away_code: row.away_code,
    home_score: row.home_score,
    away_score: row.away_score,
    status: game_status(row.period, row.final),
  )
}

@target(erlang)
fn game_update_from_final_row(row: games_sql.UpdateGameFinalRow) -> GameUpdate {
  GameUpdate(
    id: row.id,
    home_code: row.home_code,
    away_code: row.away_code,
    home_score: row.home_score,
    away_score: row.away_score,
    status: game_status(row.period, row.final),
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
