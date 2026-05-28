//// Builds the public Mount client context from server state.
////
//// The SSR handler calls this before rendering the shell so the boot payload
//// includes typed shell-level state for the public client.

import generated/public/route.{type Route}
import shared/public/client_context.{
  type PublicClientContext, PublicClientContext,
}

pub fn load(route route: Route) -> PublicClientContext {
  PublicClientContext(
    league_name: "Rally Rec League",
    active_section: active_section(route),
  )
}

fn active_section(route: Route) -> String {
  case route {
    route.Games | route.GamesId(_) -> "games"
    route.Standings -> "standings"
    route.Team(_) -> "teams"
    route.NotFound -> ""
  }
}
