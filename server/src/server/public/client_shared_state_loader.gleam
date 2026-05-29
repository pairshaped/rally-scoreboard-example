//// Builds the public Mount ClientSharedState from server state.
////
//// The SSR handler calls this before rendering the shell so the boot payload
//// includes typed shell-level state for the public client.
////
//// Public receives an optional authentication_context so the nav can show
//// Sign In / Sign Out and conditionally show the Admin link.

import generated/public/route.{type Route}
import gleam/option.{type Option, None, Some}
import server/authentication_context_loader
import shared/authentication_context.{
  type AuthenticationContext, AuthenticationContext,
}
import shared/public/client_shared_state.{
  type PublicClientSharedState, PublicClientSharedState,
}
import sqlight

pub fn load(
  db db: sqlight.Connection,
  route route: Route,
  authentication_context authentication_context: Option(AuthenticationContext),
) -> PublicClientSharedState {
  let can_access_admin = case authentication_context {
    Some(AuthenticationContext(user_id:, ..)) ->
      authentication_context_loader.can_access_admin(db:, user_id:)
    None -> False
  }
  PublicClientSharedState(
    league_name: "Rally Rec League",
    active_section: active_section(route),
    authentication_context:,
    can_access_admin:,
  )
}

fn active_section(route: Route) -> String {
  case route {
    route.Games | route.GamesId(_) -> "games"
    route.Standings -> "standings"
    route.Team(_) -> "teams"
    route.SignIn -> "sign_in"
    route.NotFound -> ""
  }
}
