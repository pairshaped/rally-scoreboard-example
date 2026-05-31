import generated/proute/public/page_input
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page_context.{type PageContext}
import page_stub

pub type Model =
  page_stub.Model

pub type Message =
  page_stub.Message

pub fn init(
  _page_context: PageContext,
  _query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  page_stub.init(title: "Not found")
}

pub fn initial_model(
  _page_context: PageContext,
  _query_params: page_input.QueryParams,
) -> Model {
  page_stub.initial_model(title: "Not found")
}

pub fn update(
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  page_stub.update(model:, msg:)
}

pub fn view(model model: Model) -> Element(Message) {
  page_stub.view(model:)
}
