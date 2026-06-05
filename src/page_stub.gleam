//// Temporary page implementation for the unified source projection spike.
////
//// Proute needs real page modules today. The Rust projector will later replace
//// these placeholders with the authored page logic that projects into client
//// and server targets.

import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

/// Placeholder Proute page model.
/// Real adapter pages alias this so generated/proute pages can still store a
/// concrete Model while this spike keeps placeholder views.
pub type Model {
  Model(title: String)
}

/// Placeholder Proute page message.
/// Real adapter pages alias this so generated/proute pages can still wrap page
/// messages into their generated Message union.
pub type Message {
  NoOp
}

/// Placeholder Proute page init function.
/// Adapter pages call this from their generated page init convention while the
/// unified source projection work is still in flight.
pub fn init(title title: String) -> #(Model, Effect(Message)) {
  #(initial_model(title:), effect.none())
}

/// Pure starting state for placeholder pages.
/// Keeping it separate from init lets adapter pages and generated page glue build
/// the same model without also creating effects.
pub fn initial_model(title title: String) -> Model {
  Model(title:)
}

/// Placeholder Proute page update function.
/// Adapter pages call this from their generated page update convention.
pub fn update(
  model model: Model,
  msg _msg: Message,
) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

/// Placeholder Proute page view function.
/// Adapter pages call this from their generated page view convention.
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
