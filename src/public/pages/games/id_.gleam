import broadcasts
import generated/proute/public/page_input
import gleam/int
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import public/page_shared_state.{type PublicPageSharedState}

@target(erlang)
import generated/sql/public/pages/games/id__sql as games_sql
@target(erlang)
import sqlight

// TYPES

/// Libero wire payload nested in LoadResult.
/// Generated codecs include this because PublicGameDetailLoaded carries game
/// status values across the browser/server boundary.
pub type GameStatus {
  Scheduled
  Live(period: String)
  Final
}

/// Libero wire payload nested in GameDetail.
/// Generated codecs include this because PublicGameDetailLoaded carries teams
/// across the browser/server boundary.
pub type Team {
  Team(code: String, name: String, slug: String)
}

/// Libero wire payload nested in LoadResult.
/// Rally load responses send this through generated client/server protocol code.
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

/// Page-local load error carried by Message.Loaded.
/// Browser and SSR load adapters translate Rally/Libero load failures into this
/// type before calling update.
pub type LoadError {
  LoadError(message: String)
}

/// Rally load request message.
/// generated/rally browser and server protocol code encodes this for detail page
/// load requests, and load_route builds it from Proute route params.
pub type ServerMsg {
  PublicGameDetailLoad(game_id: Int)
}

/// Rally load response payload.
/// generated/rally and Libero code encode/decode this across SSR and websocket
/// load paths before boot code maps it into Message.
pub type LoadResult {
  PublicGameDetailLoaded(game: GameDetail)
}

/// Proute page model.
/// generated/proute/public/pages stores this inside GamesIdPage.
pub type Model {
  Model(game: Option(GameDetail))
}

/// Proute page message.
/// generated/proute/public/pages wraps this as GamesIdMsg and routes it back
/// into this module's update function.
pub type Message {
  Loaded(Result(GameDetail, LoadError))
  NavigateTeam(slug: String)
}

// INIT

/// Optional Proute page init hook.
/// Most Rally pages omit this and let generated browser/SSR glue layer loaded
/// data onto `initial_model`. Keep `init` only for page-specific client startup
/// work, such as browser APIs, local storage, focus, measurement, or one-off DOM
/// effects. This example shows a browser alert and deliberately does not start a
/// data load; generated Rally load glue owns that.
pub fn init(
  page_shared_state page_shared_state: PublicPageSharedState,
  route_params route_params: page_input.GamesIdRouteParams,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  #(
    initial_model(page_shared_state, route_params, query_params),
    alert_effect(route_params.id),
  )
}

/// Pure starting state for the game detail page.
/// Generated browser and SSR glue call this to construct an empty page before
/// Rally applies hydrated or freshly loaded data.
pub fn initial_model(
  _page_shared_state: PublicPageSharedState,
  _route_params: page_input.GamesIdRouteParams,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(game: None)
}

@target(javascript)
fn alert_effect(id: String) -> Effect(Message) {
  effect.from(fn(_dispatch) { show_game_detail_alert(id) })
}

@target(erlang)
fn alert_effect(_id: String) -> Effect(Message) {
  effect.none()
}

@target(javascript)
@external(javascript, "./id__ffi.mjs", "show_game_detail_alert")
fn show_game_detail_alert(id: String) -> Nil

// UPDATE

/// Proute page update function.
/// generated/proute/public/pages calls this when a GamesIdMsg is active on the
/// current page.
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

/// Page-owned broadcast hook.
/// Generated Rally browser push dispatch calls this after a game update frame
/// is decoded for this page's route game topic.
pub fn apply_push(
  model model: Model,
  message message: broadcasts.Event,
) -> #(Model, Effect(Message)) {
  case message {
    broadcasts.BroadcastGameUpdated(game) -> game_updated(model, game)
  }
}

pub fn topics(
  route_params: page_input.GamesIdRouteParams,
  _model: Model,
) -> List(broadcasts.Topic) {
  case int.parse(route_params.id) {
    Ok(game_id) -> [broadcasts.game_topic(game_id)]
    Error(Nil) -> []
  }
}

pub fn game_updated(
  model model: Model,
  game game: broadcasts.GameSnapshot,
) -> #(Model, Effect(Message)) {
  let broadcasts.BroadcastGameSnapshot(id:, ..) = game
  case model.game {
    Some(detail) if detail.id == id -> #(
      Model(game: Some(update_detail(detail, game))),
      effect.none(),
    )
    _ -> #(model, effect.none())
  }
}

// VIEW

/// Proute page view function.
/// generated/proute/public/pages calls this and wraps emitted messages back into
/// the generated pages.Message union.
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

fn update_detail(
  detail: GameDetail,
  game: broadcasts.GameSnapshot,
) -> GameDetail {
  let broadcasts.BroadcastGameSnapshot(home_score:, away_score:, status:, ..) =
    game
  GameDetail(
    ..detail,
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

fn status_badge(status: GameStatus) -> Element(msg) {
  case status {
    Scheduled -> html.span([attribute.class("badge")], [html.text("Scheduled")])
    Live(period) ->
      html.span([attribute.class("badge live")], [html.text(period)])
    Final -> html.span([attribute.class("badge final")], [html.text("Final")])
  }
}

// SERVER

@target(erlang)
/// Server data loader behind the generated Rally SSR and WS load adapters.
/// Rally calls this, then wraps page data in the Rally/Libero load result shape.
pub fn load(
  db: sqlight.Connection,
  game_id: Int,
) -> Result(GameDetail, LoadError) {
  case games_sql.get_game(db:, game_id:) {
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
