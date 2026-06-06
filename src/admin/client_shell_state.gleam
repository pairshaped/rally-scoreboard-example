//// Browser shell state for the admin mount.
////
//// This belongs to the mount and app shell, not to page models. Rally updates
//// active route and dark mode through generated browser lifecycle glue.

import gleam/option.{type Option}

/// Admin browser chrome state.
pub type AdminClientShellState {
  AdminClientShellState(
    league_name: String,
    active_section: String,
    dark_mode: Bool,
    toast: Option(String),
  )
}
