import api/to_client.{type ToClient}
import api/to_server.{type ToServer}
@target(javascript)
import generated/proute/public/page_input
import generated/proute/public/pages
import generated/proute/public/routes
@target(javascript)
import generated_soon/client_transport
import gleam/int
import gleam/list
import lustre/effect.{type Effect}
@target(javascript)
import page_context.{type PageContext}
import public/pages/games as games_page
import public/pages/games/id_ as games_id_page
import public/pages/standings as standings_page
import public/pages/teams/slug_ as teams_slug_page

pub fn requests(route: routes.Route) -> List(ToServer) {
  case route {
    routes.Home | routes.Games -> [to_server.LoadGames]
    routes.GamesId(id) ->
      case int.parse(id) {
        Ok(game_id) -> [to_server.LoadGame(game_id:)]
        Error(Nil) -> []
      }
    routes.Standings -> [to_server.LoadGames]
    routes.TeamsSlug(slug) -> [to_server.LoadTeam(slug:)]
    routes.SignIn | routes.NotFound -> []
  }
}

@target(javascript)
pub fn load_client(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
  route route: routes.Route,
) -> #(pages.Page, Effect(pages.Message)) {
  #(pages.load_sync(page_context, query_params, route), request_effect(route))
}

@target(javascript)
fn request_effect(route: routes.Route) -> Effect(pages.Message) {
  route
  |> requests
  |> list.map(fn(request) {
    client_transport.send(module: request_module(route), message: request)
  })
  |> effect.batch
}

@target(javascript)
fn request_module(route: routes.Route) -> String {
  case route {
    routes.Home | routes.Games | routes.GamesId(_) -> "public/games"
    routes.Standings -> "public/standings"
    routes.TeamsSlug(_) -> "public/teams"
    routes.SignIn | routes.NotFound -> ""
  }
}

pub fn apply_message(
  page page: pages.Page,
  message message: ToClient,
) -> #(pages.Page, Effect(pages.Message)) {
  case page, message {
    pages.HomePage(model), to_client.GamesLoaded(games) -> {
      let #(model, page_effect) = games_page.games_loaded(model, games)
      #(pages.HomePage(model), effect.map(page_effect, pages.HomeMsg))
    }
    pages.HomePage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) = games_page.game_updated(model, game)
      #(pages.HomePage(model), effect.map(page_effect, pages.HomeMsg))
    }
    pages.GamesPage(model), to_client.GamesLoaded(games) -> {
      let #(model, page_effect) = games_page.games_loaded(model, games)
      #(pages.GamesPage(model), effect.map(page_effect, pages.GamesMsg))
    }
    pages.GamesPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) = games_page.game_updated(model, game)
      #(pages.GamesPage(model), effect.map(page_effect, pages.GamesMsg))
    }
    pages.GamesIdPage(model), to_client.GameLoaded(game) -> {
      let #(model, page_effect) = games_id_page.game_loaded(model, game)
      #(pages.GamesIdPage(model), effect.map(page_effect, pages.GamesIdMsg))
    }
    pages.GamesIdPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) = games_id_page.game_updated(model, game)
      #(pages.GamesIdPage(model), effect.map(page_effect, pages.GamesIdMsg))
    }
    pages.StandingsPage(model), to_client.GamesLoaded(games) -> {
      let #(model, page_effect) = standings_page.games_loaded(model, games)
      #(pages.StandingsPage(model), effect.map(page_effect, pages.StandingsMsg))
    }
    pages.StandingsPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) = standings_page.game_updated(model, game)
      #(pages.StandingsPage(model), effect.map(page_effect, pages.StandingsMsg))
    }
    pages.TeamsSlugPage(model), to_client.TeamLoaded(team) -> {
      let #(model, page_effect) = teams_slug_page.team_loaded(model, team)
      #(pages.TeamsSlugPage(model), effect.map(page_effect, pages.TeamsSlugMsg))
    }
    pages.TeamsSlugPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) = teams_slug_page.game_updated(model, game)
      #(pages.TeamsSlugPage(model), effect.map(page_effect, pages.TeamsSlugMsg))
    }
    _, _ -> #(page, effect.none())
  }
}

pub fn apply_messages(
  page page: pages.Page,
  messages messages: List(ToClient),
) -> pages.Page {
  list.fold(messages, page, fn(page, message) {
    let #(page, _) = apply_message(page: page, message: message)
    page
  })
}
