import generated/proute/public/page_input
@target(javascript)
import generated/rally/server
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

import page_context.{type PageContext}
import public/pages/games/id_/wire

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
      server.load_public_game_detail(game_id:, on_result: fn(result) {
        Loaded(map_load_result(result))
      })
    Error(Nil) -> effect.none()
  }
}

@target(erlang)
fn init_effect(_id: String) -> Effect(Message) {
  effect.none()
}

@target(javascript)
fn map_load_result(
  result: Result(wire.LoadResult, List(server.LoadError)),
) -> Result(GameDetail, LoadError) {
  case result {
    Ok(wire.PublicGameDetailLoaded(game)) -> Ok(from_wire_detail(game))
    Error([server.LoadError(message: message), ..]) ->
      Error(LoadError(message: message))
    Error([]) -> Error(LoadError(message: "Could not load game."))
  }
}

@target(erlang)
pub fn load_wire(
  db: sqlight.Connection,
  game_id: Int,
) -> Result(wire.LoadResult, List(String)) {
  case load(db, game_id) {
    Ok(game) -> Ok(wire.PublicGameDetailLoaded(to_wire_detail(game)))
    Error(LoadError(message: message)) -> Error([message])
  }
}

@target(erlang)
pub fn loaded_from_wire(
  result: Result(wire.LoadResult, List(String)),
) -> Message {
  case result {
    Ok(wire.PublicGameDetailLoaded(game)) -> Loaded(Ok(from_wire_detail(game)))
    Error([message, ..]) -> Loaded(Error(LoadError(message: message)))
    Error([]) -> Loaded(Error(LoadError(message: "Could not load game.")))
  }
}

pub fn to_wire_detail(game: GameDetail) -> wire.GameDetail {
  wire.PublicGameDetailGameDetail(
    id: game.id,
    home: to_wire_team(game.home),
    away: to_wire_team(game.away),
    home_score: game.home_score,
    away_score: game.away_score,
    status: to_wire_status(game.status),
  )
}

pub fn from_wire_detail(game: wire.GameDetail) -> GameDetail {
  let wire.PublicGameDetailGameDetail(
    id:,
    home:,
    away:,
    home_score:,
    away_score:,
    status:,
  ) = game

  GameDetail(
    id:,
    home: from_wire_team(home),
    away: from_wire_team(away),
    home_score:,
    away_score:,
    status: from_wire_status(status),
  )
}

fn to_wire_team(team: Team) -> wire.Team {
  wire.PublicGameDetailTeam(code: team.code, name: team.name, slug: team.slug)
}

fn from_wire_team(team: wire.Team) -> Team {
  let wire.PublicGameDetailTeam(code:, name:, slug:) = team
  Team(code:, name:, slug:)
}

fn to_wire_status(status: GameStatus) -> wire.GameStatus {
  case status {
    Scheduled -> wire.PublicGameDetailScheduled
    Live(period) -> wire.PublicGameDetailLive(period)
    Final -> wire.PublicGameDetailFinal
  }
}

fn from_wire_status(status: wire.GameStatus) -> GameStatus {
  case status {
    wire.PublicGameDetailScheduled -> Scheduled
    wire.PublicGameDetailLive(period) -> Live(period)
    wire.PublicGameDetailFinal -> Final
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
