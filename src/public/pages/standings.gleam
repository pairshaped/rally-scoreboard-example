import api/domain/standing.{type StandingRow}
@target(javascript)
import api/to_server
@target(javascript)
import client/api as api_client
import generated/proute/public/page_input
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page_context.{type PageContext}
import public/views/standings as shared_standings_page

pub type Model {
  Model(rows: List(StandingRow))
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
  Model(rows: [])
}

pub fn update(
  model model: Model,
  msg _msg: Message,
) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

pub fn standings_loaded(
  model _model: Model,
  rows rows: List(StandingRow),
) -> #(Model, Effect(Message)) {
  #(Model(rows: rows), effect.none())
}

pub fn view(model model: Model) -> Element(Message) {
  shared_standings_page.view(model.rows, fn(slug) { NavigateTeam(slug:) })
}

@target(javascript)
fn init_effect() -> Effect(Message) {
  api_client.send(module: "public/standings", message: to_server.LoadStandings)
}

@target(erlang)
fn init_effect() -> Effect(Message) {
  effect.none()
}
