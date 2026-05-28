//// Per-Mount client context for the public Mount.
////
//// Shell-level state that public pages can read without keeping it as local
//// page state. The server SSR handler encodes this into the boot payload;
//// the client setup bridge decodes it and passes it into the Lustre app init.
////
//// Public receives an optional authentication_context so the nav can show
//// Sign In / Sign Out and conditionally show the Admin link.

import gleam/option.{type Option}
import shared/authentication_context.{type AuthenticationContext}

pub type PublicClientContext {
  PublicClientContext(
    league_name: String,
    active_section: String,
    authentication_context: Option(AuthenticationContext),
    can_access_admin: Bool,
  )
}
