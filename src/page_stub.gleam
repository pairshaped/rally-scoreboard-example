//// Temporary page implementation for the unified source projection spike.
////
//// Proute needs real page modules today. The Rust projector will later replace
//// these placeholders with the authored page logic that projects into client
//// and server targets.

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

pub fn init(title title: String) -> #(Model, Effect(Message)) {
  #(initial_model(title:), effect.none())
}

pub fn initial_model(title title: String) -> Model {
  Model(title:)
}

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
