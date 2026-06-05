@target(javascript)
import admin/client_shared_state.{
  type AdminClientSharedState, AdminClientSharedState,
}
@target(javascript)
import admin_boot
@target(javascript)
import app_shell
@target(javascript)
import browser_mount
@target(javascript)
import generated/proute/admin/page_input
@target(javascript)
import generated/proute/admin/pages
@target(javascript)
import generated/proute/admin/routes
@target(javascript)
import generated/rally/browser
@target(javascript)
import generated/rally/browser_app
@target(javascript)
import gleam/option.{None}
@target(javascript)
import lustre/effect.{type Effect}
@target(javascript)
import lustre/element.{type Element}
@target(javascript)
import page_context.{PageContext}

// TYPES

@target(javascript)
type Model {
  Model(page: pages.Page, shared_state: AdminClientSharedState)
}

@target(javascript)
type Msg {
  PageMsg(pages.Message)
  ServerFrame(BitArray)
  DarkModeChanged(Bool)
  ShellNavigate(String)
  BrowserPathChanged(String)
}

// INIT

@target(javascript)
/// Browser entrypoint for the admin mount.
/// The admin browser bundle calls this and hands Lustre the app init, update,
/// and view functions.
pub fn main() -> Nil {
  browser_app.start(init, update, view)
}

@target(erlang)
/// Erlang-side compile anchor for the admin browser module.
/// Server builds can import this module without pulling in JavaScript-only code.
pub fn ensure() -> Nil {
  Nil
}

@target(javascript)
fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let current_path = browser.path()
  let route = routes.parse_path(current_path)
  let dark_mode = browser_mount.device_dark_mode()
  let #(page, page_effect) = initial_page(route: route)
  let shared_state =
    AdminClientSharedState(
      authentication_context: browser_mount.boot_authentication_context(),
      league_name: "Scoreboard",
      dark_mode:,
      active_section: current_path,
      toast: None,
    )

  #(
    Model(page: page, shared_state:),
    browser_app.startup_effects(
      page_effect: page_effect,
      dark_mode: dark_mode,
      on_page: PageMsg,
      on_frame: ServerFrame,
      on_shell_navigation: ShellNavigate,
      on_browser_navigation: BrowserPathChanged,
    ),
  )
}

@target(javascript)
fn initial_page(
  route route: routes.Route,
) -> #(pages.Page, Effect(pages.Message)) {
  let query_params = page_input.empty_query_params()

  browser_app.admin_initial_page(
    page_context: PageContext,
    query_params:,
    route:,
    update_page: fn(page, message) { pages.update(PageContext, page, message) },
  )
}

// UPDATE

@target(javascript)
fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    PageMsg(inner) -> {
      let #(page, page_effect) =
        browser_app.map_page_effect(
          pages.update(PageContext, model.page, inner),
          PageMsg,
        )
      #(Model(..model, page: page), page_effect)
    }
    ServerFrame(bytes) -> {
      let #(page, page_effect) =
        browser_app.server_frame_effect(
          page: model.page,
          bytes: bytes,
          apply_push: admin_boot.apply_push,
          on_page: PageMsg,
        )
      #(Model(..model, page: page), page_effect)
    }
    DarkModeChanged(dark_mode) -> {
      let shared_state =
        AdminClientSharedState(..model.shared_state, dark_mode: dark_mode)
      #(
        Model(..model, shared_state:),
        browser_mount.dark_mode_changed_effects(dark_mode),
      )
    }
    ShellNavigate(path) -> {
      let route = routes.parse_path(path)
      navigate(model: model, route: route, push_history: True)
    }
    BrowserPathChanged(path) -> {
      let route = routes.parse_path(path)
      navigate(model: model, route: route, push_history: False)
    }
  }
}

// VIEW

@target(javascript)
fn view(model: Model) -> Element(Msg) {
  app_shell.admin(
    current_path: model.shared_state.active_section,
    dark_mode: model.shared_state.dark_mode,
    authentication_context: model.shared_state.authentication_context,
    on_dark_mode_change: DarkModeChanged,
    content: pages.view(model.page) |> element.map(PageMsg),
  )
}

// HELPERS

@target(javascript)
fn navigate(
  model model: Model,
  route route: routes.Route,
  push_history push_history: Bool,
) -> #(Model, Effect(Msg)) {
  let path = routes.route_to_path(route)
  let #(page, page_effect) =
    browser_app.admin_load_client(
      page_context: PageContext,
      query_params: page_input.empty_query_params(),
      route:,
    )
  let shared_state =
    AdminClientSharedState(..model.shared_state, active_section: path)

  #(
    Model(page: page, shared_state:),
    browser_app.navigation_effects(
      path: path,
      push_history: push_history,
      page_effect: page_effect,
      on_page: PageMsg,
    ),
  )
}
