//// Per-Mount ClientSharedState for the admin Mount.
////
//// Shell-level state that admin pages can read without keeping it as local
//// page state. The server SSR handler encodes this into the boot payload;
//// the client setup bridge decodes it and passes it into the Lustre app init.
////
//// Admin consumes authentication_context from the shared identity layer.
//// It does not own authentication.

import authentication_context.{type AuthenticationContext}
import gleam/option.{type Option}

/// Admin shell state shared between SSR and browser hydration.
/// app_ssr builds this for the initial document, and admin_app owns updates to
/// the hydrated client copy.
pub type AdminClientSharedState {
  AdminClientSharedState(
    authentication_context: Option(AuthenticationContext),
    league_name: String,
    dark_mode: Bool,
    active_section: String,
    toast: Option(String),
  )
}
