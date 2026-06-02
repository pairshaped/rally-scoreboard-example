import admin/views/games as shared_admin_games_page
import api/domain/game.{
  type AdminGameSummary, type GameSnapshot, AdminGameSummary,
}
@target(javascript)
import api/to_server
@target(javascript)
import client/api as api_client
import generated/proute/admin/page_input
import gleam/list
import lustre/effect.{type Effect}
import lustre/element.{type Element}
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
  shared_admin_games_page.view(
    model.games,
    fn(id, home_score, away_score, delta) {
      AdjustAway(id:, home_score:, away_score:, delta:)
    },
    fn(id, home_score, away_score, delta) {
      AdjustHome(id:, home_score:, away_score:, delta:)
    },
    fn(id) { MarkFinal(id:) },
  )
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
