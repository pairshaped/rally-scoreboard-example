@target(javascript)
import generated/libero/result as wire_result
import generated/proute/public/page_input
@target(javascript)
import generated/rally/client_transport as api_client
@target(erlang)
import generated/sql/public/pages/games/id__sql as games_sql

import gleam/int
import gleam/option.{type Option, None, Some}

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

pub type Team {
  Team(code: String, name: String, slug: String)
}

pub type GameDetail {
  GameDetail(
    id: Int,
    home: Team,
    away: Team,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
  )
}

pub type GameUpdate {
  GameUpdate(id: Int, home_score: Int, away_score: Int, status: GameStatus)
}

pub type LoadError {
  LoadError(message: String)
}

pub type Model {
  Model(game: Option(GameDetail))
}

pub type Message {
  Loaded(Result(GameDetail, LoadError))
  NavigateTeam(slug: String)
}

// INIT

pub fn init(
  page_context page_context: PageContext,
  route_params route_params: page_input.GamesIdRouteParams,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  #(
    initial_model(page_context, route_params, query_params),
    init_effect(route_params.id),
  )
}

pub fn initial_model(
  _page_context: PageContext,
  _route_params: page_input.GamesIdRouteParams,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(game: None)
}

// UPDATE

pub fn update(
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  case msg {
    Loaded(Ok(game)) -> #(Model(game: Some(game)), effect.none())
    Loaded(Error(_)) -> #(model, effect.none())
    NavigateTeam(_) -> #(model, effect.none())
  }
}

pub fn game_loaded(
  model _model: Model,
  game game: GameDetail,
) -> #(Model, Effect(Message)) {
  update(model: Model(game: None), msg: Loaded(Ok(game)))
}

pub fn game_updated(
  model model: Model,
  game game: GameUpdate,
) -> #(Model, Effect(Message)) {
  case model.game {
    Some(detail) if detail.id == game.id -> #(
      Model(game: Some(update_detail(detail, game))),
      effect.none(),
    )
    _ -> #(model, effect.none())
  }
}

// VIEW

pub fn view(model model: Model) -> Element(Message) {
  html.main([], [
    html.section([attribute.class("panel")], [
      section_head("Game detail"),
      view_game_detail(model.game, fn(slug) { NavigateTeam(slug:) }),
    ]),
  ])
}

// HELPERS

fn view_game_detail(
  game: Option(GameDetail),
  on_navigate_team: fn(String) -> msg,
) -> Element(msg) {
  case game {
    None -> html.p([attribute.class("muted")], [html.text("Loading game...")])
    Some(game) ->
      html.div([], [
        html.div([attribute.class("game-card")], [
          html.div([attribute.class("team-row")], [
            html.a(
              [
                attribute.href("/teams/" <> game.away.slug),
                event.on_click(on_navigate_team(game.away.slug))
                  |> event.prevent_default,
              ],
              [html.strong([], [html.text(game.away.name)])],
            ),
            html.span([attribute.class("score")], [
              html.text(int.to_string(game.away_score)),
            ]),
          ]),
          html.div([attribute.class("team-row")], [
            html.a(
              [
                attribute.href("/teams/" <> game.home.slug),
                event.on_click(on_navigate_team(game.home.slug))
                  |> event.prevent_default,
              ],
              [html.strong([], [html.text(game.home.name)])],
            ),
            html.span([attribute.class("score")], [
              html.text(int.to_string(game.home_score)),
            ]),
          ]),
          status_badge(game.status),
        ]),
      ])
  }
}

fn update_detail(detail: GameDetail, game: GameUpdate) -> GameDetail {
  GameDetail(
    ..detail,
    home_score: game.home_score,
    away_score: game.away_score,
    status: game.status,
  )
}

fn section_head(title: String) -> Element(msg) {
  html.div([attribute.class("section-head")], [
    html.div([], [html.h1([], [html.text(title)]), html.span([], [])]),
  ])
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
fn init_effect(id: String) -> Effect(Message) {
  case int.parse(id) {
    Ok(game_id) ->
      api_client.send_load(
        module: "public/games",
        message: to_server.LoadGame(game_id:),
        on_result: fn(result) { Loaded(map_load_result(result)) },
      )
    Error(Nil) -> effect.none()
  }
}

@target(erlang)
fn init_effect(_id: String) -> Effect(Message) {
  effect.none()
}

@target(javascript)
fn map_load_result(
  result: Result(to_client.ToClient, List(wire_result.ApiLoadError)),
) -> Result(GameDetail, LoadError) {
  case result {
    Ok(to_client.GameLoaded(game)) -> Ok(wire_game_detail(game))
    Ok(_) -> Error(LoadError(message: "Unexpected game response."))
    Error([wire_result.ApiLoadError(message: message), ..]) ->
      Error(LoadError(message: message))
    Error([]) -> Error(LoadError(message: "Could not load game."))
  }
}

@target(javascript)
fn wire_game_detail(game: api_game.GameDetail) -> GameDetail {
  GameDetail(
    id: game.id,
    home: wire_team(game.home),
    away: wire_team(game.away),
    home_score: game.home_score,
    away_score: game.away_score,
    status: wire_game_status(game.status),
  )
}

@target(javascript)
fn wire_team(team: api_game.Team) -> Team {
  Team(code: team.code, name: team.name, slug: team.slug)
}

@target(javascript)
fn wire_game_status(status: api_game.GameStatus) -> GameStatus {
  case status {
    api_game.Scheduled -> Scheduled
    api_game.Live(period) -> Live(period)
    api_game.Final -> Final
  }
}

// SERVER

@target(erlang)
pub fn load(
  db: sqlight.Connection,
  game_id: Int,
) -> Result(GameDetail, LoadError) {
  case games_sql.get_game(db: db, game_id: game_id) {
    Ok([row, ..]) -> Ok(game_detail_from_row(row))
    Ok([]) -> Error(LoadError(message: "Game not found."))
    Error(sqlight.SqlightError(..)) ->
      Error(LoadError(message: "Could not load game."))
  }
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
