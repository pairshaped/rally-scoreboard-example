@target(javascript)
import admin/client_shared_state.{
  type AdminClientSharedState, AdminClientSharedState,
}
@target(javascript)
import app_shell
@target(javascript)
import generated/proute/admin/page_input
@target(javascript)
import generated/proute/admin/pages
@target(javascript)
import generated/proute/admin/routes
@target(javascript)
import generated/rally/admin_boot
@target(javascript)
import generated/rally/browser
@target(javascript)
import generated/rally/browser_mount
@target(javascript)
import generated/rally/hydration
@target(javascript)
import generated/rally/to_client_application
@target(javascript)
import gleam/list
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
  ShellNavigate(String)
  BrowserPathChanged(String)
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
    effect.batch([
      effect.map(page_effect, PageMsg),
      browser_mount.startup_effects(
        dark_mode: dark_mode,
        on_frame: ServerFrame,
        on_shell_navigation: ShellNavigate,
        on_browser_navigation: BrowserPathChanged,
      ),
    ]),
  )
}

@target(javascript)
fn initial_page(
  route route: routes.Route,
) -> #(pages.Page, Effect(pages.Message)) {
  let query_params = page_input.empty_query_params()

  case hydration.messages() {
    Ok(messages) -> {
      let page =
        list.fold(
          messages,
          pages.load_sync(PageContext, query_params, route),
          fn(page, message) {
            let #(page, _) =
              to_client_application.apply_admin(page: page, message: message)
            page
          },
        )
      #(page, effect.none())
    }
    Error(Nil) -> admin_boot.load_client(PageContext, query_params, route)
  }
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
        to_client_application.decode_and_apply_admin(
          page: model.page,
          bytes: bytes,
        )
      #(Model(..model, page: page), effect.map(page_effect, PageMsg))
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

@target(javascript)
fn navigate(
  model model: Model,
  route route: routes.Route,
  push_history push_history: Bool,
) -> #(Model, Effect(Msg)) {
  let path = routes.route_to_path(route)
  let #(page, page_effect) =
    admin_boot.load_client(PageContext, page_input.empty_query_params(), route)
  let shared_state =
    AdminClientSharedState(..model.shared_state, active_section: path)
  let history_effect = case push_history {
    True -> browser_mount.push_path(path)
    False -> effect.none()
  }

  #(
    Model(page: page, shared_state:),
    effect.batch([history_effect, effect.map(page_effect, PageMsg)]),
  )
}
