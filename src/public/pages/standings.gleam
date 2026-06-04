@target(javascript)
import generated/libero/result as wire_result
import generated/proute/public/page_input
@target(javascript)
import generated/rally/client_transport as api_client
@target(erlang)
import generated/sql/public/pages/games_sql

import gleam/int
import gleam/list
import gleam/order
import gleam/string

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

pub type GameSummary {
  GameSummary(
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

pub type StandingRow {
  StandingRow(
    team_code: String,
    team_name: String,
    slug: String,
    wins: Int,
    losses: Int,
    points_for: Int,
    points_against: Int,
  )
}

pub type LoadError {
  LoadError(message: String)
}

pub type Model {
  Model(games: List(GameSummary))
}

pub type Message {
  Loaded(Result(List(GameSummary), LoadError))
  NavigateTeam(slug: String)
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
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  case msg {
    Loaded(Ok(games)) -> #(Model(games: games), effect.none())
    Loaded(Error(_)) -> #(model, effect.none())
    NavigateTeam(_) -> #(model, effect.none())
  }
}

pub fn games_loaded(
  model _model: Model,
  games games: List(GameSummary),
) -> #(Model, Effect(Message)) {
  update(model: Model(games: []), msg: Loaded(Ok(games)))
}

pub fn game_updated(
  model model: Model,
  game game: GameUpdate,
) -> #(Model, Effect(Message)) {
  let games =
    list.map(model.games, fn(summary) {
      case summary.id == game.id {
        True -> update_summary(summary, game)
        False -> summary
      }
    })

  #(Model(games: games), effect.none())
}

// VIEW

pub fn view(model model: Model) -> Element(Message) {
  html.main([], [
    html.section([attribute.class("panel")], [
      section_head("League table"),
      view_standings(from_games(model.games), fn(slug) { NavigateTeam(slug:) }),
    ]),
  ])
}

// HELPERS

fn from_games(games: List(GameSummary)) -> List(StandingRow) {
  games
  |> list.fold([], add_game)
  |> list.sort(by: compare_rows)
}

fn view_standings(
  rows: List(StandingRow),
  on_navigate_team: fn(String) -> msg,
) -> Element(msg) {
  case rows {
    [] ->
      html.p([attribute.class("muted")], [html.text("Waiting for standings...")])
    _ ->
      html.table([attribute.class("standings-table")], [
        html.thead([], [
          html.tr([], [
            html.th([], [html.text("Team")]),
            html.th([], [html.text("W")]),
            html.th([], [html.text("L")]),
            html.th([], [html.text("PF")]),
            html.th([], [html.text("PA")]),
          ]),
        ]),
        html.tbody(
          [],
          list.map(rows, fn(row) { view_standing_row(row, on_navigate_team) }),
        ),
      ])
  }
}

fn add_game(rows: List(StandingRow), game: GameSummary) -> List(StandingRow) {
  let #(home_wins, home_losses, home_for, home_against) =
    home_contribution(game)
  let #(away_wins, away_losses, away_for, away_against) =
    away_contribution(game)

  rows
  |> upsert_row(
    team: game.home,
    wins: home_wins,
    losses: home_losses,
    points_for: home_for,
    points_against: home_against,
  )
  |> upsert_row(
    team: game.away,
    wins: away_wins,
    losses: away_losses,
    points_for: away_for,
    points_against: away_against,
  )
}

// nolint: label_possible -- this fold helper is called through a pipe; labelling the accumulator makes the call harder to read.
fn upsert_row(
  current_rows: List(StandingRow),
  team team: Team,
  wins wins: Int,
  losses losses: Int,
  points_for points_for: Int,
  points_against points_against: Int,
) -> List(StandingRow) {
  case list.find(current_rows, fn(row) { row.team_code == team.code }) {
    Ok(_) ->
      list.map(current_rows, fn(row) {
        case row.team_code == team.code {
          True ->
            StandingRow(
              ..row,
              wins: row.wins + wins,
              losses: row.losses + losses,
              points_for: row.points_for + points_for,
              points_against: row.points_against + points_against,
            )
          False -> row
        }
      })
    Error(Nil) ->
      list.append(current_rows, [
        StandingRow(
          team_code: team.code,
          team_name: team.name,
          slug: team.slug,
          wins: wins,
          losses: losses,
          points_for: points_for,
          points_against: points_against,
        ),
      ])
  }
}

fn home_contribution(game: GameSummary) -> #(Int, Int, Int, Int) {
  case game.status {
    Final -> #(
      bool_to_int(game.home_score > game.away_score),
      bool_to_int(game.home_score < game.away_score),
      game.home_score,
      game.away_score,
    )
    _ -> #(0, 0, 0, 0)
  }
}

fn away_contribution(game: GameSummary) -> #(Int, Int, Int, Int) {
  case game.status {
    Final -> #(
      bool_to_int(game.away_score > game.home_score),
      bool_to_int(game.away_score < game.home_score),
      game.away_score,
      game.home_score,
    )
    _ -> #(0, 0, 0, 0)
  }
}

fn compare_rows(a: StandingRow, b: StandingRow) -> order.Order {
  case int.compare(b.wins, a.wins) {
    order.Eq ->
      case int.compare(b.points_for, a.points_for) {
        order.Eq -> string.compare(a.team_code, b.team_code)
        points_order -> points_order
      }
    wins_order -> wins_order
  }
}

// nolint: prefer_guard_clause -- the case expression is clearer for a bool-to-int conversion than a guard with negation.
fn bool_to_int(value: Bool) -> Int {
  case value {
    True -> 1
    False -> 0
  }
}

fn view_standing_row(
  row: StandingRow,
  on_navigate_team: fn(String) -> msg,
) -> Element(msg) {
  html.tr([], [
    html.td([], [
      html.a(
        [
          attribute.href("/teams/" <> row.slug),
          event.on_click(on_navigate_team(row.slug))
            |> event.prevent_default,
        ],
        [
          html.strong([], [html.text(row.team_code)]),
          html.text(" " <> row.team_name),
        ],
      ),
    ]),
    html.td([], [html.text(int.to_string(row.wins))]),
    html.td([], [html.text(int.to_string(row.losses))]),
    html.td([], [html.text(int.to_string(row.points_for))]),
    html.td([], [html.text(int.to_string(row.points_against))]),
  ])
}

fn update_summary(summary: GameSummary, game: GameUpdate) -> GameSummary {
  GameSummary(
    ..summary,
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

// EFFECTS

@target(javascript)
fn init_effect() -> Effect(Message) {
  api_client.send_load(
    module: "public/standings",
    message: to_server.LoadGames,
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
) -> Result(List(GameSummary), LoadError) {
  case result {
    Ok(to_client.GamesLoaded(games)) -> Ok(list.map(games, wire_game_summary))
    Ok(_) -> Error(LoadError(message: "Unexpected standings response."))
    Error([wire_result.ApiLoadError(message: message), ..]) ->
      Error(LoadError(message: message))
    Error([]) -> Error(LoadError(message: "Could not load standings."))
  }
}

@target(javascript)
fn wire_game_summary(game: api_game.PublicGameSummary) -> GameSummary {
  GameSummary(
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
pub fn load(db: sqlight.Connection) -> Result(List(GameSummary), LoadError) {
  case games_sql.list_public_games(db: db, team_filter: "") {
    Ok(rows) -> Ok(list.map(rows, game_summary_from_row))
    Error(sqlight.SqlightError(..)) ->
      Error(LoadError(message: "Could not load standings."))
  }
}

@target(erlang)
fn game_summary_from_row(row: games_sql.ListPublicGamesRow) -> GameSummary {
  GameSummary(
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
