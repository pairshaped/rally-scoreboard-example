import api/domain/game.{type GameSnapshot}
import api/domain/team.{type TeamDetail}
@target(javascript)
import api/to_server
@target(javascript)
import client/api as api_client
import generated/proute/public/page_input
import gleam/option.{type Option, None, Some}
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
  #(
    initial_model(page_context, route_params, query_params),
    init_effect(route_params.slug),
  )
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

pub fn team_loaded(
  model _model: Model,
  team team: TeamDetail,
) -> #(Model, Effect(Message)) {
  #(Model(team: Some(shared_team_page.Model(team: team))), effect.none())
}

pub fn game_updated(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Message)) {
  case model.team {
    Some(team) -> #(
      Model(team: Some(shared_team_page.apply_game_updated(team, game))),
      effect.none(),
    )
    None -> #(model, effect.none())
  }
}

pub fn view(model model: Model) -> Element(Message) {
  shared_team_page.view(model.team, fn(slug) { NavigateTeam(slug:) }, fn(id) {
    NavigateGame(id:)
  })
}

@target(javascript)
fn init_effect(slug: String) -> Effect(Message) {
  api_client.send(module: "public/teams", message: to_server.LoadTeam(slug:))
}

@target(erlang)
fn init_effect(_slug: String) -> Effect(Message) {
  effect.none()
}
