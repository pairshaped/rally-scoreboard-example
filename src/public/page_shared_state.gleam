//// Page-visible shared state for the public browser mount.
////
//// This is the client-side app state pages may intentionally depend on. It is
//// separate from shell state so browser chrome details do not leak into page
//// construction.

import authentication_context.{type AuthenticationContext}
import gleam/option.{type Option}

/// Public app facts shared with page construction on the browser.
pub type PublicPageSharedState {
  PublicPageSharedState(
    authentication_context: Option(AuthenticationContext),
    can_access_admin: Bool,
  )
}
