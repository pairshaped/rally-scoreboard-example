//// Builds the admin Mount client context from server state.
////
//// The SSR handler calls this before rendering the shell so the boot payload
//// includes typed shell-level state for the admin client.
////
//// Admin consumes authentication_context from the shared identity layer.
//// It does not own authentication.

import generated/admin/route.{type Route}
import gleam/option.{type Option, None}
import shared/admin/client_context.{type AdminClientContext, AdminClientContext}
import shared/authentication_context.{type AuthenticationContext}

pub fn load(
  route route: Route,
  authentication_context authentication_context: Option(AuthenticationContext),
  dark_mode dark_mode: Bool,
) -> AdminClientContext {
  AdminClientContext(
    authentication_context:,
    league_name: "Rally Rec League",
    dark_mode:,
    active_section: active_section(route),
    toast: None,
  )
}

fn active_section(route: Route) -> String {
  case route {
    route.AdminGames -> "games"
    route.NotFound -> ""
  }
}
