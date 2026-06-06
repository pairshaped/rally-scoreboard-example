@target(javascript)
import admin/client_page_shared_state.{
  type AdminClientPageSharedState, AdminClientPageSharedState,
}
@target(javascript)
import admin/client_shell_state.{
  type AdminClientShellState, AdminClientShellState,
}
@target(javascript)
import app_shell
@target(javascript)
import browser_mount
@target(javascript)
import generated/proute/admin/pages
@target(javascript)
import generated/rally/browser_app
@target(javascript)
import gleam/option.{None}
@target(javascript)
import lustre/element.{type Element}
@target(javascript)
import page_context.{PageContext}

@target(javascript)
/// Browser entrypoint for the admin mount.
/// The app configures shared state and shell rendering; Rally owns lifecycle.
pub fn main() -> Nil {
  browser_app.start_admin_mount(browser_app.AdminMountConfig(
    page_context: fn(_page_shared_state) { PageContext },
    page_shared_state: fn() {
      AdminClientPageSharedState(
        authentication_context: browser_mount.boot_authentication_context(),
      )
    },
    shell_state: fn(current_path, dark_mode) {
      AdminClientShellState(
        league_name: "Scoreboard",
        active_section: current_path,
        dark_mode:,
        toast: None,
      )
    },
    set_active_path: fn(shell_state, path) {
      AdminClientShellState(..shell_state, active_section: path)
    },
    set_dark_mode: fn(shell_state, dark_mode) {
      AdminClientShellState(..shell_state, dark_mode:)
    },
    update_page: fn(page_context, page, message) {
      pages.update(page_context, page, message)
    },
    view:,
  ))
}

@target(erlang)
/// Erlang-side compile anchor for the admin browser module.
/// Server builds can import this module without pulling in JavaScript-only code.
pub fn ensure() -> Nil {
  Nil
}

@target(javascript)
fn view(
  model: browser_app.AdminMountModel(
    AdminClientShellState,
    AdminClientPageSharedState,
  ),
  on_page: fn(pages.Message) -> browser_app.AdminMountMsg,
  on_dark_mode_change: fn(Bool) -> browser_app.AdminMountMsg,
  _on_navigate: fn(String) -> browser_app.AdminMountMsg,
) -> Element(browser_app.AdminMountMsg) {
  app_shell.admin(
    current_path: model.shell_state.active_section,
    dark_mode: model.shell_state.dark_mode,
    authentication_context: model.page_shared_state.authentication_context,
    on_dark_mode_change:,
    content: pages.view(model.page) |> element.map(on_page),
  )
}
