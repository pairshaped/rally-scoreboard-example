//// Browser shell state for the public mount.
////
//// This belongs to the mount and app shell, not to page models. Rally updates
//// active route and dark mode through generated browser lifecycle glue.

/// Public browser chrome state.
pub type PublicClientShellState {
  PublicClientShellState(
    league_name: String,
    active_section: String,
    dark_mode: Bool,
  )
}
