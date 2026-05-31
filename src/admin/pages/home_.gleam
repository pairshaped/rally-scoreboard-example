import admin/pages/games as games_page
import generated/proute/admin/page_input
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page_context.{type PageContext}

pub type Model =
  games_page.Model

pub type Message =
  games_page.Message

pub fn init(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  games_page.init(page_context, query_params)
}

pub fn initial_model(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
) -> Model {
  games_page.initial_model(page_context, query_params)
}

pub fn update(
  page_context page_context: PageContext,
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  games_page.update(page_context, model, msg)
}

pub fn view(model model: Model) -> Element(Message) {
  games_page.view(model:)
}
