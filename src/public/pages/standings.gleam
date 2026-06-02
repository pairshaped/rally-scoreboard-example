import api/domain/game.{
  type GameSnapshot, type PublicGameSummary, PublicGameSummary,
}
@target(javascript)
import api/to_server
@target(javascript)
import client/api as api_client
import generated/proute/public/page_input
import gleam/list
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page_context.{type PageContext}
import public/views/standings as shared_standings_page

pub type Model {
  Model(games: List(PublicGameSummary))
}

pub type Message {
  NavigateTeam(slug: String)
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
  model model: Model,
  msg _msg: Message,
) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

pub fn games_loaded(
  model _model: Model,
  games games: List(PublicGameSummary),
) -> #(Model, Effect(Message)) {
  #(Model(games: games), effect.none())
}

pub fn game_updated(
  model model: Model,
  game game: GameSnapshot,
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

pub fn view(model model: Model) -> Element(Message) {
  shared_standings_page.view(
    shared_standings_page.from_games(model.games),
    fn(slug) { NavigateTeam(slug:) },
  )
}

fn update_summary(
  summary: PublicGameSummary,
  game: GameSnapshot,
) -> PublicGameSummary {
  PublicGameSummary(
    ..summary,
    home_score: game.home_score,
    away_score: game.away_score,
    status: game.status,
  )
}

@target(javascript)
fn init_effect() -> Effect(Message) {
  api_client.send(module: "public/standings", message: to_server.LoadGames)
}

@target(erlang)
fn init_effect() -> Effect(Message) {
  effect.none()
}
