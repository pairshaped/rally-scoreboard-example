@target(javascript)
import admin/client_shared_state.{
  type AdminClientSharedState, AdminClientSharedState,
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
    page_context: PageContext,
    shared_state: fn(current_path, dark_mode) {
      AdminClientSharedState(
        authentication_context: browser_mount.boot_authentication_context(),
        league_name: "Scoreboard",
        dark_mode:,
        active_section: current_path,
        toast: None,
      )
    },
    set_active_path: fn(shared_state, path) {
      AdminClientSharedState(..shared_state, active_section: path)
    },
    set_dark_mode: fn(shared_state, dark_mode) {
      AdminClientSharedState(..shared_state, dark_mode:)
    },
    update_page: fn(page, message) { pages.update(PageContext, page, message) },
    view: view,
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
  model: browser_app.AdminMountModel(AdminClientSharedState),
  on_page: fn(pages.Message) -> browser_app.AdminMountMsg,
  on_dark_mode_change: fn(Bool) -> browser_app.AdminMountMsg,
  _on_navigate: fn(String) -> browser_app.AdminMountMsg,
) -> Element(browser_app.AdminMountMsg) {
  app_shell.admin(
    current_path: model.shared_state.active_section,
    dark_mode: model.shared_state.dark_mode,
    authentication_context: model.shared_state.authentication_context,
    on_dark_mode_change: on_dark_mode_change,
    content: pages.view(model.page) |> element.map(on_page),
  )
}
