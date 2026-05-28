//// Builds the public Mount client context from server state.
////
//// The SSR handler calls this before rendering the shell so the boot payload
//// includes typed shell-level state for the public client.
////
//// Public receives an optional authentication_context so the nav can show
//// Sign In / Sign Out and conditionally show the Admin link.

import generated/public/route.{type Route}
import gleam/option.{type Option}
import shared/authentication_context.{type AuthenticationContext}
import shared/public/client_context.{
  type PublicClientContext, PublicClientContext,
}

pub fn load(
  route route: Route,
  authentication_context authentication_context: Option(AuthenticationContext),
) -> PublicClientContext {
  PublicClientContext(
    league_name: "Rally Rec League",
    active_section: active_section(route),
    authentication_context:,
  )
}

fn active_section(route: Route) -> String {
  case route {
    route.Games | route.GamesId(_) -> "games"
    route.Standings -> "standings"
    route.Team(_) -> "teams"
    route.SignIn | route.SignInPassword | route.SignInCode -> "sign_in"
    route.NotFound -> ""
  }
}
