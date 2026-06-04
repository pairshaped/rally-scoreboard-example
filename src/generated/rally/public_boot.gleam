import api/domain/game as api_game
import api/domain/team as api_team
import api/to_client.{type ToClient}
import api/to_server.{type ToServer}
@target(javascript)
import generated/libero/result as wire_result
@target(javascript)
import generated/proute/public/page_input
import generated/proute/public/pages
import generated/proute/public/routes
@target(javascript)
import generated/rally/client_transport
import gleam/int
import gleam/list
import lustre/effect.{type Effect}
@target(javascript)
import page_context.{type PageContext}
import public/pages/games as games_page
import public/pages/games/id_ as games_id_page
@target(javascript)
import public/pages/games/wire as public_games_wire
import public/pages/standings as standings_page
import public/pages/teams/slug_ as teams_slug_page

pub fn requests(route: routes.Route) -> List(ToServer) {
  case route {
    routes.Home | routes.Games -> []
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
  case route {
    routes.Home | routes.Games ->
      client_transport.send_public_games_load(on_result: fn(result) {
        public_games_load_result_message(route, result)
      })
    _ ->
      route
      |> requests
      |> list.map(fn(request) {
        client_transport.send_load(
          module: request_module(route),
          message: request,
          on_result: fn(result) { load_result_message(route, result) },
        )
      })
      |> effect.batch
  }
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

@target(javascript)
pub fn public_games_load_result_message(
  route: routes.Route,
  result: Result(public_games_wire.LoadResult, List(wire_result.ApiLoadError)),
) -> pages.Message {
  case route, result {
    routes.Home, Ok(public_games_wire.PublicGamesLoaded(games)) ->
      pages.HomeMsg(
        games_page.Loaded(Ok(list.map(games, games_page.from_wire_summary))),
      )
    routes.Games, Ok(public_games_wire.PublicGamesLoaded(games)) ->
      pages.GamesMsg(
        games_page.Loaded(Ok(list.map(games, games_page.from_wire_summary))),
      )
    _, Error(errors) -> load_error_message(route, api_load_error(errors))
    _, Ok(_) -> load_error_message(route, "Unexpected public games response.")
  }
}

@target(javascript)
fn load_result_message(
  route: routes.Route,
  result: Result(ToClient, List(wire_result.ApiLoadError)),
) -> pages.Message {
  case route, result {
    routes.GamesId(_), Ok(to_client.GameLoaded(game)) ->
      pages.GamesIdMsg(games_id_page.Loaded(Ok(detail_game(game))))
    routes.Standings, Ok(to_client.GamesLoaded(games)) ->
      pages.StandingsMsg(
        standings_page.Loaded(Ok(list.map(games, standings_game_summary))),
      )
    routes.TeamsSlug(_), Ok(to_client.TeamLoaded(team)) ->
      pages.TeamsSlugMsg(teams_slug_page.Loaded(Ok(team_detail(team))))
    _, Error(errors) -> load_error_message(route, api_load_error(errors))
    _, Ok(_) -> load_error_message(route, "Unexpected load response.")
  }
}

@target(javascript)
fn load_error_message(route: routes.Route, message: String) -> pages.Message {
  case route {
    routes.Home ->
      pages.HomeMsg(games_page.Loaded(Error(games_page.LoadError(message:))))
    routes.Games ->
      pages.GamesMsg(games_page.Loaded(Error(games_page.LoadError(message:))))
    routes.GamesId(_) ->
      pages.GamesIdMsg(
        games_id_page.Loaded(Error(games_id_page.LoadError(message:))),
      )
    routes.Standings ->
      pages.StandingsMsg(
        standings_page.Loaded(Error(standings_page.LoadError(message:))),
      )
    routes.TeamsSlug(_) ->
      pages.TeamsSlugMsg(
        teams_slug_page.Loaded(Error(teams_slug_page.LoadError(message:))),
      )
    routes.SignIn | routes.NotFound ->
      pages.GamesMsg(games_page.Loaded(Error(games_page.LoadError(message:))))
  }
}

@target(javascript)
fn api_load_error(errors: List(wire_result.ApiLoadError)) -> String {
  case errors {
    [wire_result.ApiLoadError(message: message), ..] -> message
    [] -> "Could not load page."
  }
}

pub fn apply_message(
  page page: pages.Page,
  message message: ToClient,
) -> #(pages.Page, Effect(pages.Message)) {
  case page, message {
    pages.HomePage(model), to_client.GamesLoaded(games) -> {
      let #(model, page_effect) =
        games_page.games_loaded(model, list.map(games, public_game_summary))
      #(pages.HomePage(model), effect.map(page_effect, pages.HomeMsg))
    }
    pages.HomePage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) =
        games_page.game_updated(model, public_game_update(game))
      #(pages.HomePage(model), effect.map(page_effect, pages.HomeMsg))
    }
    pages.GamesPage(model), to_client.GamesLoaded(games) -> {
      let #(model, page_effect) =
        games_page.games_loaded(model, list.map(games, public_game_summary))
      #(pages.GamesPage(model), effect.map(page_effect, pages.GamesMsg))
    }
    pages.GamesPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) =
        games_page.game_updated(model, public_game_update(game))
      #(pages.GamesPage(model), effect.map(page_effect, pages.GamesMsg))
    }
    pages.GamesIdPage(model), to_client.GameLoaded(game) -> {
      let #(model, page_effect) =
        games_id_page.game_loaded(model, detail_game(game))
      #(pages.GamesIdPage(model), effect.map(page_effect, pages.GamesIdMsg))
    }
    pages.GamesIdPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) =
        games_id_page.game_updated(model, detail_game_update(game))
      #(pages.GamesIdPage(model), effect.map(page_effect, pages.GamesIdMsg))
    }
    pages.StandingsPage(model), to_client.GamesLoaded(games) -> {
      let #(model, page_effect) =
        standings_page.games_loaded(
          model,
          list.map(games, standings_game_summary),
        )
      #(pages.StandingsPage(model), effect.map(page_effect, pages.StandingsMsg))
    }
    pages.StandingsPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) =
        standings_page.game_updated(model, standings_game_update(game))
      #(pages.StandingsPage(model), effect.map(page_effect, pages.StandingsMsg))
    }
    pages.TeamsSlugPage(model), to_client.TeamLoaded(team) -> {
      let #(model, page_effect) =
        teams_slug_page.team_loaded(model, team_detail(team))
      #(pages.TeamsSlugPage(model), effect.map(page_effect, pages.TeamsSlugMsg))
    }
    pages.TeamsSlugPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) =
        teams_slug_page.game_updated(model, team_game_update(game))
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

fn public_game_summary(
  game: api_game.PublicGameSummary,
) -> games_page.GameSummary {
  games_page.GameSummary(
    id: game.id,
    home: public_team(game.home),
    away: public_team(game.away),
    home_score: game.home_score,
    away_score: game.away_score,
    status: public_game_status(game.status),
  )
}

fn public_game_update(game: api_game.GameSnapshot) -> games_page.GameUpdate {
  games_page.GameUpdate(
    id: game.id,
    home_score: game.home_score,
    away_score: game.away_score,
    status: public_game_status(game.status),
  )
}

fn public_team(team: api_game.Team) -> games_page.Team {
  games_page.Team(code: team.code, name: team.name, slug: team.slug)
}

fn public_game_status(status: api_game.GameStatus) -> games_page.GameStatus {
  case status {
    api_game.Scheduled -> games_page.Scheduled
    api_game.Live(period) -> games_page.Live(period)
    api_game.Final -> games_page.Final
  }
}

fn detail_game(game: api_game.GameDetail) -> games_id_page.GameDetail {
  games_id_page.GameDetail(
    id: game.id,
    home: detail_team(game.home),
    away: detail_team(game.away),
    home_score: game.home_score,
    away_score: game.away_score,
    status: detail_game_status(game.status),
  )
}

fn detail_game_update(game: api_game.GameSnapshot) -> games_id_page.GameUpdate {
  games_id_page.GameUpdate(
    id: game.id,
    home_score: game.home_score,
    away_score: game.away_score,
    status: detail_game_status(game.status),
  )
}

fn detail_team(team: api_game.Team) -> games_id_page.Team {
  games_id_page.Team(code: team.code, name: team.name, slug: team.slug)
}

fn detail_game_status(status: api_game.GameStatus) -> games_id_page.GameStatus {
  case status {
    api_game.Scheduled -> games_id_page.Scheduled
    api_game.Live(period) -> games_id_page.Live(period)
    api_game.Final -> games_id_page.Final
  }
}

fn standings_game_summary(
  game: api_game.PublicGameSummary,
) -> standings_page.GameSummary {
  standings_page.GameSummary(
    id: game.id,
    home: standings_team(game.home),
    away: standings_team(game.away),
    home_score: game.home_score,
    away_score: game.away_score,
    status: standings_game_status(game.status),
  )
}

fn standings_game_update(
  game: api_game.GameSnapshot,
) -> standings_page.GameUpdate {
  standings_page.GameUpdate(
    id: game.id,
    home_score: game.home_score,
    away_score: game.away_score,
    status: standings_game_status(game.status),
  )
}

fn standings_team(team: api_game.Team) -> standings_page.Team {
  standings_page.Team(code: team.code, name: team.name, slug: team.slug)
}

fn standings_game_status(
  status: api_game.GameStatus,
) -> standings_page.GameStatus {
  case status {
    api_game.Scheduled -> standings_page.Scheduled
    api_game.Live(period) -> standings_page.Live(period)
    api_game.Final -> standings_page.Final
  }
}

fn team_detail(team: api_team.TeamDetail) -> teams_slug_page.TeamDetail {
  teams_slug_page.TeamDetail(
    code: team.code,
    name: team.name,
    slug: team.slug,
    wins: team.wins,
    losses: team.losses,
    points_for: team.points_for,
    points_against: team.points_against,
    recent_games: list.map(team.recent_games, team_game_summary),
  )
}

fn team_game_summary(
  game: api_game.PublicGameSummary,
) -> teams_slug_page.GameSummary {
  teams_slug_page.GameSummary(
    id: game.id,
    home: team_page_team(game.home),
    away: team_page_team(game.away),
    home_score: game.home_score,
    away_score: game.away_score,
    status: team_game_status(game.status),
  )
}

fn team_game_update(game: api_game.GameSnapshot) -> teams_slug_page.GameUpdate {
  teams_slug_page.GameUpdate(
    id: game.id,
    home_code: game.home.code,
    away_code: game.away.code,
    home_score: game.home_score,
    away_score: game.away_score,
    status: team_game_status(game.status),
  )
}

fn team_page_team(team: api_game.Team) -> teams_slug_page.Team {
  teams_slug_page.Team(code: team.code, name: team.name, slug: team.slug)
}

fn team_game_status(status: api_game.GameStatus) -> teams_slug_page.GameStatus {
  case status {
    api_game.Scheduled -> teams_slug_page.Scheduled
    api_game.Live(period) -> teams_slug_page.Live(period)
    api_game.Final -> teams_slug_page.Final
  }
}
