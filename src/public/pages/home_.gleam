//// Public default route.
////
//// This page exists so `/` is a real Proute page while delegating the actual
//// model, update, subscriptions, and view to the public games page.

import broadcasts
import generated/proute/public/page_input
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import public/page_shared_state.{type PublicPageSharedState}
import public/pages/games as games_page

pub type Model =
  games_page.Model

pub type Message =
  games_page.Message

pub fn initial_model(
  page_shared_state page_shared_state: PublicPageSharedState,
  query_params query_params: page_input.QueryParams,
) -> Model {
  games_page.initial_model(page_shared_state, query_params)
}

pub fn update(
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  games_page.update(model:, msg:)
}

// BROADCAST

/// Required because generated/rally/browser_app module calls this to sync active broadcast topics.
pub fn broadcast_subscriptions(model: Model) -> List(broadcasts.Topic) {
  games_page.broadcast_subscriptions(model)
}

pub fn apply_broadcast(
  model model: Model,
  message message: broadcasts.Event,
) -> #(Model, Effect(Message)) {
  games_page.apply_broadcast(model:, message:)
}

pub fn view(model model: Model) -> Element(Message) {
  games_page.view(model:)
}
