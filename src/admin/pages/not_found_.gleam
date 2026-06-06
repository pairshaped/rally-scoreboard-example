import admin/page_shared_state.{type AdminPageSharedState}
import generated/proute/admin/page_input
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

pub type Model {
  Model(title: String)
}

pub type Message {
  NoOp
}

/// Pure starting state for the admin not-found page.
pub fn initial_model(
  _page_shared_state: AdminPageSharedState,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(title: "Not found")
}

/// Proute page update function for unmatched admin routes.
/// generated/proute/admin/pages calls this when NotFoundMsg is active.
pub fn update(
  model model: Model,
  msg _msg: Message,
) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

pub fn view(model model: Model) -> Element(Message) {
  html.main([], [
    html.section([attribute.class("panel")], [
      html.h1([], [html.text(model.title)]),
      html.p([attribute.class("muted")], [
        html.text("Unified source projection placeholder."),
      ]),
    ]),
  ])
}
