import generated/proute/public/page_input
import gleam/option.{type Option, None}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page_context.{type PageContext}
import public/views/teams/slug_ as shared_team_page

pub type Model {
  Model(team: Option(shared_team_page.Model))
}

pub type Message {
  NavigateTeam(slug: String)
  NavigateGame(id: Int)
}

pub fn init(
  page_context page_context: PageContext,
  route_params route_params: page_input.TeamsSlugRouteParams,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  #(initial_model(page_context, route_params, query_params), effect.none())
}

pub fn initial_model(
  _page_context: PageContext,
  _route_params: page_input.TeamsSlugRouteParams,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(team: None)
}

pub fn update(
  model model: Model,
  msg _msg: Message,
) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

pub fn view(model model: Model) -> Element(Message) {
  shared_team_page.view(model.team, fn(slug) { NavigateTeam(slug:) }, fn(id) {
    NavigateGame(id:)
  })
}
