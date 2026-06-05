import broadcasts
import generated/proute/public/page_input
import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import page_context.{type PageContext}

@target(erlang)
import generated/sql/public/pages/games_sql
@target(erlang)
import generated/sql/public/pages/teams/slug__sql as teams_sql
@target(erlang)
import sqlight

@target(javascript)
import generated/rally/server

// TYPES

/// Libero wire payload nested in LoadResult.
/// Generated codecs include this because PublicTeamDetailLoaded carries game
/// status values across the browser/server boundary.
pub type GameStatus {
  Scheduled
  Live(period: String)
  Final
}

/// Libero wire payload nested in TeamDetail and GameSummary.
/// Generated codecs include this because PublicTeamDetailLoaded carries team
/// values across the browser/server boundary.
pub type Team {
  Team(code: String, name: String, slug: String)
}

/// Libero wire payload nested in TeamDetail.
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

/// Libero wire payload nested in LoadResult.
/// Rally load responses send this through generated client/server protocol code.
pub type TeamDetail {
  TeamDetail(
    code: String,
    name: String,
    slug: String,
    wins: Int,
    losses: Int,
    points_for: Int,
    points_against: Int,
    recent_games: List(GameSummary),
  )
}

/// Page-local load error carried by Message.Loaded.
/// Browser and SSR load adapters translate Rally/Libero load failures into this
/// type before calling update.
pub type LoadError {
  LoadError(message: String)
}

/// Rally load request message.
/// generated/rally browser and server protocol code encodes this for team detail
/// load requests, and load_route builds it from Proute route params.
pub type ServerMsg {
  PublicTeamDetailLoad(slug: String)
}

/// Rally load response payload.
/// generated/rally and Libero code encode/decode this across SSR and websocket
/// load paths before boot code maps it into Message.
pub type LoadResult {
  PublicTeamDetailLoaded(team: TeamDetail)
}

/// Proute page model.
/// generated/proute/public/pages stores this inside TeamsSlugPage.
pub type Model {
  Model(team: Option(TeamDetail))
}

/// Proute page message.
/// generated/proute/public/pages wraps this as TeamsSlugMsg and routes it back
/// into this module's update function.
pub type Message {
  Loaded(Result(TeamDetail, LoadError))
  NavigateTeam(slug: String)
  NavigateGame(id: Int)
}

// INIT

/// Proute page init function.
/// generated/proute/public/pages calls this when it constructs the team detail
/// page, then maps the returned page effect into pages.Message.
pub fn init(
  page_context page_context: PageContext,
  route_params route_params: page_input.TeamsSlugRouteParams,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  #(
    initial_model(page_context, route_params, query_params),
    init_effect(route_params.slug),
  )
}

/// Pure starting state for the team detail page.
/// init adds the route-specific load effect on top; generated page and SSR glue
/// can call this when they need the empty page model without starting a load.
pub fn initial_model(
  _page_context: PageContext,
  _route_params: page_input.TeamsSlugRouteParams,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(team: None)
}

// LOAD LIFECYCLE

/// Page-owned load hook for Rally/Proute route glue.
/// Generated dispatch can call this after PublicTeamDetailLoaded arrives,
/// keeping the state transition here instead of in app-level boot code.
pub fn team_loaded(
  model _model: Model,
  team team: TeamDetail,
) -> #(Model, Effect(Message)) {
  apply_loaded(team)
}

@target(javascript)
fn init_effect(slug: String) -> Effect(Message) {
  server.load_public_team_detail(
    message: PublicTeamDetailLoad(slug:),
    on_result: fn(result) { Loaded(map_load_result(result)) },
  )
}

@target(erlang)
fn init_effect(_slug: String) -> Effect(Message) {
  effect.none()
}

@target(javascript)
fn map_load_result(
  result: Result(LoadResult, List(server.LoadError)),
) -> Result(TeamDetail, LoadError) {
  case result {
    Ok(PublicTeamDetailLoaded(team)) -> Ok(team)
    Error([server.LoadError(message: message), ..]) ->
      Error(LoadError(message: message))
    Error([]) -> Error(LoadError(message: "Could not load team."))
  }
}

@target(erlang)
/// SSR load adapter.
/// public_boot.ssr_load_route calls this after generated Rally SSR load code
/// runs the page load adapter, turning wire errors/results back into this page's
/// Message type.
pub fn loaded_from_wire(result: Result(LoadResult, List(String))) -> Message {
  case result {
    Ok(PublicTeamDetailLoaded(team)) -> Loaded(Ok(team))
    Error([message, ..]) -> Loaded(Error(LoadError(message: message)))
    Error([]) -> Loaded(Error(LoadError(message: "Could not load team.")))
  }
}

fn apply_loaded(team: TeamDetail) -> #(Model, Effect(Message)) {
  #(Model(team: Some(team)), effect.none())
}

// UPDATE

/// Proute page update function.
/// generated/proute/public/pages calls this when a TeamsSlugMsg is active on the
/// current page.
pub fn update(
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  case msg {
    Loaded(Ok(team)) -> apply_loaded(team)
    Loaded(Error(_)) -> #(model, effect.none())
    NavigateTeam(_) | NavigateGame(_) -> #(model, effect.none())
  }
}

/// Page-owned broadcast hook.
/// public_boot.apply_broadcast calls this after a BroadcastGameUpdated push frame
/// is decoded, then wraps the returned effect back into pages.Message.
pub fn game_updated(
  model model: Model,
  game game: broadcasts.GameSnapshot,
) -> #(Model, Effect(Message)) {
  case model.team {
    Some(team) -> #(
      Model(team: Some(apply_game_updated(team, game))),
      effect.none(),
    )
    None -> #(model, effect.none())
  }
}

// VIEW

/// Proute page view function.
/// generated/proute/public/pages calls this and wraps emitted messages back into
/// the generated pages.Message union.
pub fn view(model model: Model) -> Element(Message) {
  html.main([], [
    view_team_detail(model.team, fn(slug) { NavigateTeam(slug:) }, fn(id) {
      NavigateGame(id:)
    }),
  ])
}

// HELPERS

fn apply_game_updated(
  team: TeamDetail,
  snapshot: broadcasts.GameSnapshot,
) -> TeamDetail {
  use <- bool.guard(!game_belongs_to_team(team.code, snapshot), team)
  apply_team_game_update(team, snapshot)
}

fn game_belongs_to_team(
  team_code: String,
  snapshot: broadcasts.GameSnapshot,
) -> Bool {
  let broadcasts.BroadcastGameSnapshot(
    home: broadcasts.BroadcastTeam(code: home_code, ..),
    away: broadcasts.BroadcastTeam(code: away_code, ..),
    ..,
  ) = snapshot

  home_code == team_code || away_code == team_code
}

fn apply_team_game_update(
  team: TeamDetail,
  snapshot: broadcasts.GameSnapshot,
) -> TeamDetail {
  let broadcasts.BroadcastGameSnapshot(id:, ..) = snapshot
  case list.find(team.recent_games, fn(game) { game.id == id }) {
    Error(Nil) -> team
    Ok(existing) -> {
      let updated_games =
        list.map(team.recent_games, fn(game) {
          case game.id == id {
            True -> update_game_summary(game, snapshot)
            False -> game
          }
        })
      let #(old_wins, old_losses, old_for, old_against) =
        record_contribution(team.code, existing)
      let #(new_wins, new_losses, new_for, new_against) =
        record_contribution(team.code, update_game_summary(existing, snapshot))

      TeamDetail(
        ..team,
        wins: team.wins - old_wins + new_wins,
        losses: team.losses - old_losses + new_losses,
        points_for: team.points_for - old_for + new_for,
        points_against: team.points_against - old_against + new_against,
        recent_games: updated_games,
      )
    }
  }
}

fn update_game_summary(
  game: GameSummary,
  snapshot: broadcasts.GameSnapshot,
) -> GameSummary {
  let broadcasts.BroadcastGameSnapshot(home_score:, away_score:, status:, ..) =
    snapshot
  GameSummary(
    ..game,
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

fn record_contribution(
  team_code: String,
  game: GameSummary,
) -> #(Int, Int, Int, Int) {
  case game.status {
    Final ->
      case game.home.code == team_code, game.away.code == team_code {
        True, _ -> #(
          bool_to_int(game.home_score > game.away_score),
          bool_to_int(game.home_score < game.away_score),
          game.home_score,
          game.away_score,
        )
        _, True -> #(
          bool_to_int(game.away_score > game.home_score),
          bool_to_int(game.away_score < game.home_score),
          game.away_score,
          game.home_score,
        )
        _, _ -> #(0, 0, 0, 0)
      }
    _ -> #(0, 0, 0, 0)
  }
}

// nolint: prefer_guard_clause -- the case expression is clearer for a bool-to-int conversion than a guard with negation.
fn bool_to_int(value: Bool) -> Int {
  case value {
    True -> 1
    False -> 0
  }
}

fn view_team_detail(
  team: Option(TeamDetail),
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg) {
  case team {
    None -> html.p([attribute.class("muted")], [html.text("Loading team...")])
    Some(detail) -> {
      let TeamDetail(
        code:,
        name:,
        slug: _,
        wins:,
        losses:,
        points_for:,
        points_against:,
        recent_games:,
      ) = detail
      html.div([], [
        html.section([attribute.class("panel")], [
          section_head(name),
          html.article([attribute.class("card team-record-card")], [
            html.header([attribute.class("team-record-title")], [
              html.strong([], [html.text(code)]),
              html.text(" · " <> name),
            ]),
            html.dl([attribute.class("team-record-grid")], [
              stat_item(
                "W-L",
                int.to_string(wins) <> "-" <> int.to_string(losses),
              ),
              stat_item("PF", int.to_string(points_for)),
              stat_item("PA", int.to_string(points_against)),
            ]),
          ]),
        ]),
        html.section([attribute.class("panel")], [
          section_head("Recent games"),
          case recent_games {
            [] ->
              html.p([attribute.class("muted")], [html.text("No games yet.")])
            _ ->
              html.div(
                [attribute.class("game-grid")],
                list.map(recent_games, fn(game) {
                  view_game_card(game, on_navigate_team, on_navigate_game)
                }),
              )
          },
        ]),
      ])
    }
  }
}

fn stat_item(label: String, value: String) -> Element(msg) {
  html.div([], [
    html.dt([], [html.text(label)]),
    html.dd([], [html.text(value)]),
  ])
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
  slug: String,
) -> Result(TeamDetail, LoadError) {
  case teams_sql.get_team_by_slug(db: db, slug: slug) {
    Ok([row, ..]) -> load_team_games(db, row)
    Ok([]) -> Error(LoadError(message: "Team not found."))
    Error(sqlight.SqlightError(..)) ->
      Error(LoadError(message: "Could not load team."))
  }
}

@target(erlang)
fn load_team_games(
  db: sqlight.Connection,
  row: teams_sql.GetTeamBySlugRow,
) -> Result(TeamDetail, LoadError) {
  let team_code = optional_string(row.code)

  case games_sql.list_public_games(db: db, team_filter: team_code) {
    Ok(games) ->
      Ok(TeamDetail(
        code: team_code,
        name: row.name,
        slug: row.slug,
        wins: row.wins,
        losses: row.losses,
        points_for: row.points_for,
        points_against: row.points_against,
        recent_games: list.map(games, game_summary_from_row),
      ))
    Error(sqlight.SqlightError(..)) ->
      Error(LoadError(message: "Could not load team games."))
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

@target(erlang)
fn optional_string(value: Option(String)) -> String {
  case value {
    Some(value) -> value
    None -> ""
  }
}
