@target(javascript)
import app_shell
@target(javascript)
import browser_mount
@target(javascript)
import generated/proute/public/pages
@target(javascript)
import generated/rally/browser
@target(javascript)
import generated/rally/browser_app
@target(javascript)
import lustre/element.{type Element}
@target(javascript)
import page_context.{PageContext}
@target(javascript)
import public/client_shared_state.{
  type PublicClientSharedState, PublicClientSharedState,
}

@target(javascript)
/// Browser entrypoint for the public mount.
/// The app configures shared state and shell rendering; Rally owns lifecycle.
pub fn main() -> Nil {
  browser_app.start_public_mount(browser_app.PublicMountConfig(
    page_context: fn(_shared_state) { PageContext },
    shared_state: fn(current_path, dark_mode) {
      PublicClientSharedState(
        league_name: "Scoreboard",
        active_section: current_path,
        dark_mode:,
        authentication_context: browser_mount.boot_authentication_context(),
        can_access_admin: browser.boot_bool("canAccessAdmin"),
      )
    },
    set_active_path: fn(shared_state, path) {
      PublicClientSharedState(..shared_state, active_section: path)
    },
    set_dark_mode: fn(shared_state, dark_mode) {
      PublicClientSharedState(..shared_state, dark_mode:)
    },
    update_page: fn(_page_context, page, message) {
      pages.update(page, message)
    },
    view:,
  ))
}

@target(erlang)
/// Erlang-side compile anchor for the public browser module.
/// Server builds can import this module without pulling in JavaScript-only code.
pub fn ensure() -> Nil {
  Nil
}

@target(javascript)
fn view(
  model: browser_app.PublicMountModel(PublicClientSharedState),
  on_page: fn(pages.Message) -> browser_app.PublicMountMsg,
  on_dark_mode_change: fn(Bool) -> browser_app.PublicMountMsg,
  _on_navigate: fn(String) -> browser_app.PublicMountMsg,
) -> Element(browser_app.PublicMountMsg) {
  app_shell.public(
    current_path: model.shared_state.active_section,
    dark_mode: model.shared_state.dark_mode,
    authentication_context: model.shared_state.authentication_context,
    can_access_admin: model.shared_state.can_access_admin,
    on_dark_mode_change:,
    content: pages.view(model.page) |> element.map(on_page),
  )
}
