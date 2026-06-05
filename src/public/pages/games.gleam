import broadcasts
import components/ui
import generated/proute/public/page_input
import gleam/int
import gleam/list
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
/// Generated codecs include this because PublicGamesLoaded carries game status
/// values across the browser/server boundary.
pub type GameStatus {
  Scheduled
  Live(period: String)
  Final
}

/// Libero wire payload nested in GameSummary.
/// Generated codecs include this because PublicGamesLoaded carries teams across
/// the browser/server boundary.
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

/// Page-local load error carried by Message.Loaded.
/// Browser and SSR load adapters translate Rally/Libero load failures into this
/// type before calling update.
pub type LoadError {
  LoadError(message: String)
}

/// Rally load request message.
/// generated/rally browser and server protocol code encodes this for page load
/// requests, and load_route builds it for the current Proute route.
pub type ServerMsg {
  PublicGamesLoad
}

/// Rally load response payload.
/// generated/rally and Libero code encode/decode this across SSR and websocket
/// load paths before boot code maps it into Message.
pub type LoadResult {
  PublicGamesLoaded(games: List(GameSummary))
}

/// Proute page model.
/// generated/proute/public/pages stores this inside HomePage and GamesPage.
pub type Model {
  Model(games: List(GameSummary))
}

/// Proute page message.
/// generated/proute/public/pages wraps this as HomeMsg or GamesMsg and routes it
/// back into this module's update function.
pub type Message {
  NavigateTeam(slug: String)
  NavigateGame(id: Int)
  Loaded(Result(List(GameSummary), LoadError))
}

// INIT

/// Proute page init function.
/// generated/proute/public/pages calls this when it constructs the home or games
/// page, then maps the returned page effect into pages.Message.
pub fn init(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  #(initial_model(page_context, query_params), init_effect())
}

/// Pure starting state for the games list page.
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
/// Generated dispatch can call this after PublicGamesLoaded arrives, keeping
/// the state transition here instead of in app-level boot code.
pub fn games_loaded(
  model _model: Model,
  games games: List(GameSummary),
) -> #(Model, Effect(Message)) {
  apply_loaded(games)
}

@target(javascript)
fn init_effect() -> Effect(Message) {
  server.load_public_games(message: PublicGamesLoad, on_result: fn(result) {
    Loaded(map_load_result(result))
  })
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
    Ok(PublicGamesLoaded(games)) -> Ok(games)
    Error([server.LoadError(message: message), ..]) ->
      Error(LoadError(message: message))
    Error([]) -> Error(LoadError(message: "Could not load games."))
  }
}

@target(erlang)
/// SSR load adapter.
/// Generated Rally SSR load code calls this after the page load adapter runs,
/// turning wire errors/results back into this page's Message type.
pub fn loaded_from_wire(result: Result(LoadResult, List(String))) -> Message {
  case result {
    Ok(PublicGamesLoaded(games)) -> Loaded(Ok(games))
    Error([message, ..]) -> Loaded(Error(LoadError(message: message)))
    Error([]) -> Loaded(Error(LoadError(message: "Could not load games.")))
  }
}

fn apply_loaded(games: List(GameSummary)) -> #(Model, Effect(Message)) {
  #(Model(games: games), effect.none())
}

// UPDATE

/// Proute page update function.
/// generated/proute/public/pages calls this when a HomeMsg or GamesMsg is active
/// on the current page.
pub fn update(
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  case msg {
    Loaded(Ok(games)) -> apply_loaded(games)
    Loaded(Error(_)) -> #(model, effect.none())
    NavigateTeam(_) | NavigateGame(_) -> #(model, effect.none())
  }
}

/// Page-owned broadcast hook.
/// Generated Rally browser push dispatch calls this after a game update frame
/// is decoded for one of this page's topics.
pub fn apply_push(
  model model: Model,
  message message: broadcasts.Event,
) -> #(Model, Effect(Message)) {
  case message {
    broadcasts.BroadcastGameUpdated(game) -> game_updated(model, game)
  }
}

pub fn topics(_model: Model) -> List(String) {
  [broadcasts.all_games_topic()]
}

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
      ui.section_head("Today", ""),
      view_game_grid(model.games, fn(slug) { NavigateTeam(slug:) }, fn(id) {
        NavigateGame(id:)
      }),
    ]),
  ])
}

// HELPERS

fn view_game_grid(
  games: List(GameSummary),
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg) {
  case games {
    [] ->
      html.p([attribute.class("muted")], [html.text("Waiting for scores...")])
    _ ->
      html.div(
        [attribute.class("game-grid")],
        list.map(games, fn(game) {
          view_game_card(game, on_navigate_team, on_navigate_game)
        }),
      )
  }
}

fn view_game_card(
  game: GameSummary,
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg) {
  html.article([attribute.class("game-card")], [
    html.div([attribute.class("team-row")], [
      team_link(game.away, on_navigate_team),
      html.span([attribute.class("score")], [
        html.text(int.to_string(game.away_score)),
      ]),
    ]),
    html.div([attribute.class("team-row")], [
      team_link(game.home, on_navigate_team),
      html.span([attribute.class("score")], [
        html.text(int.to_string(game.home_score)),
      ]),
    ]),
    html.div([attribute.class("score-line")], [
      status_badge(game.status),
      html.a(
        [
          attribute.href("/games/" <> int.to_string(game.id)),
          event.on_click(on_navigate_game(game.id))
            |> event.prevent_default,
        ],
        [html.text("Details")],
      ),
    ]),
  ])
}

fn team_link(team: Team, on_navigate_team: fn(String) -> msg) -> Element(msg) {
  html.a(
    [
      attribute.href("/teams/" <> team.slug),
      event.on_click(on_navigate_team(team.slug))
        |> event.prevent_default,
    ],
    [html.strong([], [html.text(team.name)])],
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

// SERVER

@target(erlang)
/// Server data loader behind the generated Rally SSR and WS load adapters.
/// Rally calls this, then wraps page data in the Rally/Libero load result shape.
pub fn load(db: sqlight.Connection) -> Result(List(GameSummary), LoadError) {
  case games_sql.list_public_games(db: db, team_filter: "") {
    Ok(rows) -> Ok(list.map(rows, game_summary_from_row))
    Error(sqlight.SqlightError(..)) ->
      Error(LoadError(message: "Could not load games."))
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
