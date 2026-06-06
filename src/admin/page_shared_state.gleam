//// Page-visible shared state for the admin browser mount.
////
//// This is the client-side app state pages may intentionally depend on. It is
//// separate from shell state so browser chrome details do not leak into page
//// construction.

import authentication_context.{type AuthenticationContext}
import gleam/option.{type Option}

/// Admin app facts shared with page construction on the browser.
pub type AdminPageSharedState {
  AdminPageSharedState(authentication_context: Option(AuthenticationContext))
}
