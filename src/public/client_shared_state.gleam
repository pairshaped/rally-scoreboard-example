//// Per-Mount ClientSharedState for the public Mount.
////
//// Shell-level state that public pages can read without keeping it as local
//// page state. The server SSR handler encodes this into the boot payload;
//// the client setup bridge decodes it and passes it into the Lustre app init.
////
//// Public receives an optional authentication_context so the nav can show
//// Sign In / Sign Out and conditionally show the Admin link.

import authentication_context.{type AuthenticationContext}
import gleam/option.{type Option}

/// Public shell state shared between SSR and browser hydration.
/// app_ssr builds this for the initial document, and public_app owns updates to
/// the hydrated client copy.
pub type PublicClientSharedState {
  PublicClientSharedState(
    league_name: String,
    active_section: String,
    dark_mode: Bool,
    authentication_context: Option(AuthenticationContext),
    can_access_admin: Bool,
  )
}
