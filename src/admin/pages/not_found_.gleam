import generated/proute/admin/page_input
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page_context.{type PageContext}
import page_stub

/// Proute page model for unmatched admin routes.
/// generated/proute/admin/pages stores this inside NotFoundPage, while the page
/// delegates its concrete model shape to page_stub.
pub type Model =
  page_stub.Model

/// Proute page message for unmatched admin routes.
/// generated/proute/admin/pages wraps this as NotFoundMsg, while the page
/// delegates concrete messages to page_stub.
pub type Message =
  page_stub.Message

/// Proute page init function for unmatched admin routes.
/// generated/proute/admin/pages calls this when it constructs NotFoundPage.
pub fn init(
  _page_context: PageContext,
  _query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  page_stub.init(title: "Not found")
}

/// Pure starting state for the admin not-found page.
/// This delegates to page_stub so generated page glue can create the page model
/// without also running init effects.
pub fn initial_model(
  _page_context: PageContext,
  _query_params: page_input.QueryParams,
) -> Model {
  page_stub.initial_model(title: "Not found")
}

/// Proute page update function for unmatched admin routes.
/// generated/proute/admin/pages calls this when NotFoundMsg is active.
pub fn update(
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  page_stub.update(model:, msg:)
}

/// Proute page view function for unmatched admin routes.
/// generated/proute/admin/pages calls this when rendering NotFoundPage.
pub fn view(model model: Model) -> Element(Message) {
  page_stub.view(model:)
}
