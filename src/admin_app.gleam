@target(javascript)
import admin/client_shared_state.{
  type AdminClientSharedState, AdminClientSharedState,
}
@target(javascript)
import app_shell
@target(javascript)
import browser
@target(javascript)
import client/api as api_client
@target(javascript)
import client/to_client
@target(javascript)
import generated/proute/admin/page_input
@target(javascript)
import generated/proute/admin/pages
@target(javascript)
import generated/proute/admin/routes
@target(javascript)
import gleam/option.{None}
@target(javascript)
import lustre
@target(javascript)
import lustre/effect.{type Effect}
@target(javascript)
import lustre/element.{type Element}
@target(javascript)
import page_context.{PageContext}

@target(javascript)
type Model {
  Model(page: pages.Page, shared_state: AdminClientSharedState)
}

@target(javascript)
type Msg {
  PageMsg(pages.Message)
  ServerFrame(BitArray)
  DarkModeChanged(Bool)
}

@target(javascript)
pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let _started = lustre.start(app, "#app", Nil)
  Nil
}

@target(javascript)
fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let current_path = browser.path()
  let route = routes.parse_path(current_path)
  let dark_mode = browser.device_dark_mode()
  let #(page, page_effect) =
    pages.load(PageContext, page_input.empty_query_params(), route)
  let shared_state =
    AdminClientSharedState(
      authentication_context: None,
      league_name: "Scoreboard",
      dark_mode:,
      active_section: current_path,
      toast: None,
    )

  #(
    Model(page: page, shared_state:),
    effect.batch([
      effect.map(page_effect, PageMsg),
      apply_dark_mode(dark_mode),
      api_client.connect(url: browser.websocket_url(), on_frame: ServerFrame),
    ]),
  )
}

@target(javascript)
fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    PageMsg(inner) -> {
      let #(page, page_effect) = pages.update(PageContext, model.page, inner)
      #(Model(..model, page: page), effect.map(page_effect, PageMsg))
    }
    ServerFrame(bytes) -> {
      let #(page, page_effect) =
        to_client.decode_and_apply_admin(page: model.page, bytes: bytes)
      #(Model(..model, page: page), effect.map(page_effect, PageMsg))
    }
    DarkModeChanged(dark_mode) -> {
      let shared_state =
        AdminClientSharedState(..model.shared_state, dark_mode: dark_mode)
      #(
        Model(..model, shared_state:),
        effect.batch([persist_dark_mode(dark_mode), apply_dark_mode(dark_mode)]),
      )
    }
  }
}

@target(javascript)
fn view(model: Model) -> Element(Msg) {
  app_shell.admin(
    current_path: model.shared_state.active_section,
    dark_mode: model.shared_state.dark_mode,
    on_dark_mode_change: DarkModeChanged,
    content: pages.view(model.page) |> element.map(PageMsg),
  )
}

@target(javascript)
fn apply_dark_mode(dark_mode: Bool) -> Effect(Msg) {
  effect.from(fn(_dispatch) { browser.apply_dark_mode(dark_mode) })
}

@target(javascript)
fn persist_dark_mode(dark_mode: Bool) -> Effect(Msg) {
  effect.from(fn(_dispatch) { browser.persist_dark_mode(dark_mode) })
}
