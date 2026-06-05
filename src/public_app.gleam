@target(javascript)
import app_shell
@target(javascript)
import browser_mount
@target(javascript)
import generated/proute/public/page_input
@target(javascript)
import generated/proute/public/pages
@target(javascript)
import generated/rally/browser
@target(javascript)
import generated/rally/browser_app
@target(javascript)
import gleam/option.{None, Some}
@target(javascript)
import lustre/effect.{type Effect}
@target(javascript)
import lustre/element.{type Element}
@target(javascript)
import page_context.{PageContext}
@target(javascript)
import public/client_shared_state.{
  type PublicClientSharedState, PublicClientSharedState,
}
@target(javascript)
import public_boot

// TYPES

@target(javascript)
type Model {
  Model(page: pages.Page, shared_state: PublicClientSharedState)
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
/// Browser entrypoint for the public mount.
/// The public browser bundle calls this and hands Lustre the app init, update,
/// and view functions.
pub fn main() -> Nil {
  browser_app.start(init, update, view)
}

@target(erlang)
/// Erlang-side compile anchor for the public browser module.
/// Server builds can import this module without pulling in JavaScript-only code.
pub fn ensure() -> Nil {
  Nil
}

@target(javascript)
fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let current_path = browser.path()
  let query_params = query_params_from_browser()
  let dark_mode = browser_mount.device_dark_mode()
  let #(page, page_effect) =
    browser_app.public_initial_page_from_path(
      page_context: PageContext,
      query_params:,
      path: current_path,
      update_page: pages.update,
    )
  let shared_state =
    PublicClientSharedState(
      league_name: "Scoreboard",
      active_section: current_path,
      dark_mode:,
      authentication_context: browser_mount.boot_authentication_context(),
      can_access_admin: browser.boot_bool("canAccessAdmin"),
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

// UPDATE

@target(javascript)
fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    PageMsg(inner) -> {
      case browser_app.public_message_path(inner) {
        Some(path) -> navigate(model: model, path: path, push_history: True)
        None -> {
          let #(page, page_effect) =
            browser_app.map_page_effect(
              pages.update(model.page, inner),
              PageMsg,
            )
          #(Model(..model, page: page), page_effect)
        }
      }
    }
    ServerFrame(bytes) -> {
      let #(page, page_effect) =
        browser_app.server_frame_effect(
          page: model.page,
          bytes: bytes,
          apply_push: public_boot.apply_push,
          on_page: PageMsg,
        )
      #(Model(..model, page: page), page_effect)
    }
    DarkModeChanged(dark_mode) -> {
      let shared_state =
        PublicClientSharedState(..model.shared_state, dark_mode: dark_mode)
      #(
        Model(..model, shared_state:),
        browser_mount.dark_mode_changed_effects(dark_mode),
      )
    }
    ShellNavigate(path) -> {
      navigate(model: model, path: path, push_history: True)
    }
    BrowserPathChanged(path) -> {
      navigate(model: model, path: path, push_history: False)
    }
  }
}

// VIEW

@target(javascript)
fn view(model: Model) -> Element(Msg) {
  app_shell.public(
    current_path: model.shared_state.active_section,
    dark_mode: model.shared_state.dark_mode,
    authentication_context: model.shared_state.authentication_context,
    can_access_admin: model.shared_state.can_access_admin,
    on_dark_mode_change: DarkModeChanged,
    content: pages.view(model.page) |> element.map(PageMsg),
  )
}

// HELPERS

@target(javascript)
fn navigate(
  model model: Model,
  path path: String,
  push_history push_history: Bool,
) -> #(Model, Effect(Msg)) {
  let #(canonical_path, page, page_effect) =
    browser_app.public_load_path(
      page_context: PageContext,
      query_params: page_input.empty_query_params(),
      path:,
    )
  let shared_state =
    PublicClientSharedState(
      ..model.shared_state,
      active_section: canonical_path,
    )

  #(
    Model(page: page, shared_state:),
    browser_app.navigation_effects(
      path: canonical_path,
      push_history: push_history,
      page_effect: page_effect,
      on_page: PageMsg,
    ),
  )
}

@target(javascript)
fn query_params_from_browser() -> page_input.QueryParams {
  page_input.QueryParams(values: browser_mount.query_pairs())
}
