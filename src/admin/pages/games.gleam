import api/domain/game.{
  type AdminGameSummary, type GameSnapshot, AdminGameSummary, Final,
}
@target(javascript)
import api/to_server
@target(javascript)
import client/api as api_client
import components/ui
import generated/proute/admin/page_input
import gleam/int
import gleam/list
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import page_context.{type PageContext}

pub type Model {
  Model(games: List(AdminGameSummary))
}

pub type Message {
  AdjustAway(id: Int, home_score: Int, away_score: Int, delta: Int)
  AdjustHome(id: Int, home_score: Int, away_score: Int, delta: Int)
  MarkFinal(id: Int)
}

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

pub fn update(
  _page_context: PageContext,
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  #(model, message_effect(msg))
}

pub fn admin_games_loaded(
  model _model: Model,
  games games: List(AdminGameSummary),
) -> #(Model, Effect(Message)) {
  #(Model(games: games), effect.none())
}

pub fn game_updated(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Message)) {
  #(upsert_game(model, snapshot_summary(game)), effect.none())
}

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
      ui.status_badge(game.status),
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

fn snapshot_summary(game: GameSnapshot) -> AdminGameSummary {
  AdminGameSummary(
    id: game.id,
    home_code: game.home.code,
    away_code: game.away.code,
    home_score: game.home_score,
    away_score: game.away_score,
    status: game.status,
    needs_attention: False,
  )
}

@target(javascript)
fn init_effect() -> Effect(Message) {
  api_client.send(module: "admin/games", message: to_server.LoadAdminGames)
}

@target(erlang)
fn init_effect() -> Effect(Message) {
  effect.none()
}

@target(javascript)
fn message_effect(msg: Message) -> Effect(Message) {
  case msg {
    AdjustAway(id, home_score, away_score, delta) ->
      api_client.send(
        module: "admin/games",
        message: to_server.UpdateScore(
          game_id: id,
          home_score: home_score,
          away_score: clamp_score(away_score + delta),
          period: "Live",
        ),
      )
    AdjustHome(id, home_score, away_score, delta) ->
      api_client.send(
        module: "admin/games",
        message: to_server.UpdateScore(
          game_id: id,
          home_score: clamp_score(home_score + delta),
          away_score: away_score,
          period: "Live",
        ),
      )
    MarkFinal(id) ->
      api_client.send(module: "admin/games", message: to_server.MarkFinal(id))
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
