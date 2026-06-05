import broadcasts
import generated/proute/public/page_input
import gleam/int
import gleam/list
import gleam/order
import gleam/string
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import page_context.{type PageContext}

@target(erlang)
import generated/sql/public/pages/games_sql
@target(erlang)
import sqlight

@target(javascript)
import generated/rally/server

// TYPES

/// Libero wire payload nested in LoadResult.
/// Generated codecs include this because PublicStandingsLoaded carries game
/// status values across the browser/server boundary.
pub type GameStatus {
  Scheduled
  Live(period: String)
  Final
}

/// Libero wire payload nested in GameSummary.
/// Generated codecs include this because PublicStandingsLoaded carries teams
/// across the browser/server boundary.
pub type Team {
  Team(code: String, name: String, slug: String)
}

/// Libero wire payload nested in LoadResult.
/// Rally load responses send this through generated client/server protocol code.
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

/// Derived view model for standings rows.
/// view builds these from the loaded GameSummary values so the standings table
/// does not need to store a second copy in Model.
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

/// Page-local load error carried by Message.Loaded.
/// Browser and SSR load adapters translate Rally/Libero load failures into this
/// type before calling update.
pub type LoadError {
  LoadError(message: String)
}

/// Rally load request message.
/// generated/rally browser and server protocol code encodes this for standings
/// load requests, and load_route builds it for the Proute route.
pub type ServerMsg {
  PublicStandingsLoad
}

/// Rally load response payload.
/// generated/rally and Libero code encode/decode this across SSR and websocket
/// load paths before boot code maps it into Message.
pub type LoadResult {
  PublicStandingsLoaded(games: List(GameSummary))
}

/// Proute page model.
/// generated/proute/public/pages stores this inside StandingsPage.
pub type Model {
  Model(games: List(GameSummary))
}

/// Proute page message.
/// generated/proute/public/pages wraps this as StandingsMsg and routes it back
/// into this module's update function.
pub type Message {
  Loaded(Result(List(GameSummary), LoadError))
  NavigateTeam(slug: String)
}

// INIT

/// Proute page init function.
/// generated/proute/public/pages calls this when it constructs the standings
/// page, then maps the returned page effect into pages.Message.
pub fn init(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  #(initial_model(page_context, query_params), init_effect())
}

/// Pure starting state for the standings page.
/// init adds the load effect on top; generated page and SSR glue can call this
/// when they need the empty page model without starting a load.
pub fn initial_model(
  _page_context: PageContext,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(games: [])
}

// LOAD LIFECYCLE

/// Page-owned load hook for Rally/Proute route glue.
/// Generated dispatch can call this after PublicStandingsLoaded arrives,
/// keeping the state transition here instead of in app-level boot code.
pub fn games_loaded(
  model _model: Model,
  games games: List(GameSummary),
) -> #(Model, Effect(Message)) {
  apply_loaded(games)
}

@target(javascript)
fn init_effect() -> Effect(Message) {
  server.load_public_standings(
    message: PublicStandingsLoad,
    on_result: fn(result) { Loaded(map_load_result(result)) },
  )
}

@target(erlang)
fn init_effect() -> Effect(Message) {
  effect.none()
}

@target(javascript)
fn map_load_result(
  result: Result(LoadResult, List(server.LoadError)),
) -> Result(List(GameSummary), LoadError) {
  case result {
    Ok(PublicStandingsLoaded(games)) -> Ok(games)
    Error([server.LoadError(message: message), ..]) ->
      Error(LoadError(message: message))
    Error([]) -> Error(LoadError(message: "Could not load standings."))
  }
}

@target(erlang)
/// SSR load adapter.
/// public_boot.ssr_load_route calls this after generated Rally SSR load code
/// runs the page load adapter, turning wire errors/results back into this page's
/// Message type.
pub fn loaded_from_wire(result: Result(LoadResult, List(String))) -> Message {
  case result {
    Ok(PublicStandingsLoaded(games)) -> Loaded(Ok(games))
    Error([message, ..]) -> Loaded(Error(LoadError(message: message)))
    Error([]) -> Loaded(Error(LoadError(message: "Could not load standings.")))
  }
}

fn apply_loaded(games: List(GameSummary)) -> #(Model, Effect(Message)) {
  #(Model(games: games), effect.none())
}

// UPDATE

/// Proute page update function.
/// generated/proute/public/pages calls this when a StandingsMsg is active on the
/// current page.
pub fn update(
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  case msg {
    Loaded(Ok(games)) -> apply_loaded(games)
    Loaded(Error(_)) -> #(model, effect.none())
    NavigateTeam(_) -> #(model, effect.none())
  }
}

/// Page-owned broadcast hook.
/// public_boot.apply_broadcast calls this after a BroadcastGameUpdated push frame
/// is decoded, then wraps the returned effect back into pages.Message.
pub fn game_updated(
  model model: Model,
  game game: broadcasts.GameSnapshot,
) -> #(Model, Effect(Message)) {
  let broadcasts.BroadcastGameSnapshot(id:, ..) = game
  let games =
    list.map(model.games, fn(summary) {
      case summary.id == id {
        True -> update_summary(summary, game)
        False -> summary
      }
    })

  #(Model(games: games), effect.none())
}

// VIEW

/// Proute page view function.
/// generated/proute/public/pages calls this and wraps emitted messages back into
/// the generated pages.Message union.
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

fn update_summary(
  summary: GameSummary,
  game: broadcasts.GameSnapshot,
) -> GameSummary {
  let broadcasts.BroadcastGameSnapshot(home_score:, away_score:, status:, ..) =
    game
  GameSummary(
    ..summary,
    home_score:,
    away_score:,
    status: broadcast_game_status(status),
  )
}

fn broadcast_game_status(status: broadcasts.GameStatus) -> GameStatus {
  case status {
    broadcasts.BroadcastScheduled -> Scheduled
    broadcasts.BroadcastLive(period) -> Live(period)
    broadcasts.BroadcastFinal -> Final
  }
}

fn section_head(title: String) -> Element(msg) {
  html.div([attribute.class("section-head")], [
    html.div([], [html.h1([], [html.text(title)]), html.span([], [])]),
  ])
}

// SERVER

@target(erlang)
/// Server data loader behind the generated Rally SSR and WS load adapters.
/// Rally calls this, then wraps page data in the Rally/Libero load result shape;
/// focused tests also call it directly.
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
