import generated/proute/public/page_input
import gleam/option.{type Option, None}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page_context.{type PageContext}
import shared/api/domain/game.{type GameDetail}
import shared/public/pages/games/id_ as shared_game_detail_page

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
  #(initial_model(page_context, route_params, query_params), effect.none())
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

pub fn view(model model: Model) -> Element(Message) {
  shared_game_detail_page.view(model.game, fn(slug) { NavigateTeam(slug:) })
}
