import api/domain/game.{type GameDetail, type GameSnapshot, GameDetail}
@target(javascript)
import api/to_server
@target(javascript)
import client/api as api_client
import generated/proute/public/page_input
@target(javascript)
import gleam/int
import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page_context.{type PageContext}
import public/views/games/id_ as shared_game_detail_page

pub type Model {
  Model(game: Option(GameDetail))
}

pub type Message {
  NavigateTeam(slug: String)
}

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

pub fn update(
  model model: Model,
  msg _msg: Message,
) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

pub fn game_loaded(
  model _model: Model,
  game game: GameDetail,
) -> #(Model, Effect(Message)) {
  #(Model(game: Some(game)), effect.none())
}

pub fn game_updated(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Message)) {
  case model.game {
    Some(detail) if detail.id == game.id -> #(
      Model(game: Some(update_detail(detail, game))),
      effect.none(),
    )
    _ -> #(model, effect.none())
  }
}

pub fn view(model model: Model) -> Element(Message) {
  shared_game_detail_page.view(model.game, fn(slug) { NavigateTeam(slug:) })
}

fn update_detail(detail: GameDetail, game: GameSnapshot) -> GameDetail {
  GameDetail(
    ..detail,
    home_score: game.home_score,
    away_score: game.away_score,
    status: game.status,
  )
}

@target(javascript)
fn init_effect(id: String) -> Effect(Message) {
  case int.parse(id) {
    Ok(game_id) ->
      api_client.send(
        module: "public/games",
        message: to_server.LoadGame(game_id:),
      )
    Error(Nil) -> effect.none()
  }
}

@target(erlang)
fn init_effect(_id: String) -> Effect(Message) {
  effect.none()
}
