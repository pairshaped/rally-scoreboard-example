@target(javascript)
import admin/pages/games as admin_games_page
@target(javascript)
import api/to_client.{type ToClient}
@target(javascript)
import generated/api/client as generated_client
@target(javascript)
import generated/proute/admin/pages as admin_pages
@target(javascript)
import generated/proute/public/pages as public_pages
@target(javascript)
import lustre/effect.{type Effect}
@target(javascript)
import public/pages/games as games_page
@target(javascript)
import public/pages/games/id_ as games_id_page
@target(javascript)
import public/pages/standings as standings_page
@target(javascript)
import public/pages/teams/slug_ as teams_slug_page

// nolint: unused_exports -- called by the client shell once websocket frames are connected.
@target(javascript)
pub fn apply_public_frame(
  page page: public_pages.Page,
  frame frame: generated_client.ServerFrame,
) -> #(public_pages.Page, Effect(public_pages.Message)) {
  let message = server_frame_message(frame)
  apply_public(page: page, message: message)
}

// nolint: unused_exports -- called by the admin client shell once websocket frames are connected.
@target(javascript)
pub fn apply_admin_frame(
  page page: admin_pages.Page,
  frame frame: generated_client.ServerFrame,
) -> #(admin_pages.Page, Effect(admin_pages.Message)) {
  let message = server_frame_message(frame)
  apply_admin(page: page, message: message)
}

@target(javascript)
pub fn decode_and_apply_public(
  page page: public_pages.Page,
  bytes bytes: BitArray,
) -> #(public_pages.Page, Effect(public_pages.Message)) {
  case generated_client.decode_server_frame(bytes) {
    Ok(frame) -> apply_public_frame(page: page, frame: frame)
    Error(Nil) -> #(page, effect.none())
  }
}

@target(javascript)
pub fn decode_and_apply_admin(
  page page: admin_pages.Page,
  bytes bytes: BitArray,
) -> #(admin_pages.Page, Effect(admin_pages.Message)) {
  case generated_client.decode_server_frame(bytes) {
    Ok(frame) -> apply_admin_frame(page: page, frame: frame)
    Error(Nil) -> #(page, effect.none())
  }
}

// nolint: unused_exports -- this is the app-owned reducer generated glue will call.
@target(javascript)
pub fn apply_public(
  page page: public_pages.Page,
  message message: ToClient,
) -> #(public_pages.Page, Effect(public_pages.Message)) {
  case page, message {
    public_pages.HomePage(model), to_client.GamesLoaded(games) -> {
      let #(model, page_effect) = games_page.games_loaded(model, games)
      #(
        public_pages.HomePage(model),
        effect.map(page_effect, public_pages.HomeMsg),
      )
    }
    public_pages.HomePage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) = games_page.game_updated(model, game)
      #(
        public_pages.HomePage(model),
        effect.map(page_effect, public_pages.HomeMsg),
      )
    }
    public_pages.GamesPage(model), to_client.GamesLoaded(games) -> {
      let #(model, page_effect) = games_page.games_loaded(model, games)
      #(
        public_pages.GamesPage(model),
        effect.map(page_effect, public_pages.GamesMsg),
      )
    }
    public_pages.GamesPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) = games_page.game_updated(model, game)
      #(
        public_pages.GamesPage(model),
        effect.map(page_effect, public_pages.GamesMsg),
      )
    }
    public_pages.GamesIdPage(model), to_client.GameLoaded(game) -> {
      let #(model, page_effect) = games_id_page.game_loaded(model, game)
      #(
        public_pages.GamesIdPage(model),
        effect.map(page_effect, public_pages.GamesIdMsg),
      )
    }
    public_pages.GamesIdPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) = games_id_page.game_updated(model, game)
      #(
        public_pages.GamesIdPage(model),
        effect.map(page_effect, public_pages.GamesIdMsg),
      )
    }
    public_pages.StandingsPage(model), to_client.GamesLoaded(games) -> {
      let #(model, page_effect) = standings_page.games_loaded(model, games)
      #(
        public_pages.StandingsPage(model),
        effect.map(page_effect, public_pages.StandingsMsg),
      )
    }
    public_pages.StandingsPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) = standings_page.game_updated(model, game)
      #(
        public_pages.StandingsPage(model),
        effect.map(page_effect, public_pages.StandingsMsg),
      )
    }
    public_pages.TeamsSlugPage(model), to_client.TeamLoaded(team) -> {
      let #(model, page_effect) = teams_slug_page.team_loaded(model, team)
      #(
        public_pages.TeamsSlugPage(model),
        effect.map(page_effect, public_pages.TeamsSlugMsg),
      )
    }
    public_pages.TeamsSlugPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) = teams_slug_page.game_updated(model, game)
      #(
        public_pages.TeamsSlugPage(model),
        effect.map(page_effect, public_pages.TeamsSlugMsg),
      )
    }
    _, _ -> #(page, effect.none())
  }
}

// nolint: unused_exports -- this is the app-owned reducer generated glue will call.
@target(javascript)
pub fn apply_admin(
  page page: admin_pages.Page,
  message message: ToClient,
) -> #(admin_pages.Page, Effect(admin_pages.Message)) {
  case page, message {
    admin_pages.AdminHomePage(model), to_client.AdminGamesLoaded(games) -> {
      let #(model, page_effect) =
        admin_games_page.admin_games_loaded(model, games)
      #(
        admin_pages.AdminHomePage(model),
        effect.map(page_effect, admin_pages.AdminHomeMsg),
      )
    }
    admin_pages.AdminHomePage(model), to_client.ScoreUpdateSaved(game) -> {
      let #(model, page_effect) =
        admin_games_page.score_update_saved(model, game)
      #(
        admin_pages.AdminHomePage(model),
        effect.map(page_effect, admin_pages.AdminHomeMsg),
      )
    }
    admin_pages.AdminHomePage(model), to_client.ResultSaved(game) -> {
      let #(model, page_effect) = admin_games_page.result_saved(model, game)
      #(
        admin_pages.AdminHomePage(model),
        effect.map(page_effect, admin_pages.AdminHomeMsg),
      )
    }
    admin_pages.AdminGamesPage(model), to_client.AdminGamesLoaded(games) -> {
      let #(model, page_effect) =
        admin_games_page.admin_games_loaded(model, games)
      #(
        admin_pages.AdminGamesPage(model),
        effect.map(page_effect, admin_pages.AdminGamesMsg),
      )
    }
    admin_pages.AdminGamesPage(model), to_client.ScoreUpdateSaved(game) -> {
      let #(model, page_effect) =
        admin_games_page.score_update_saved(model, game)
      #(
        admin_pages.AdminGamesPage(model),
        effect.map(page_effect, admin_pages.AdminGamesMsg),
      )
    }
    admin_pages.AdminGamesPage(model), to_client.ResultSaved(game) -> {
      let #(model, page_effect) = admin_games_page.result_saved(model, game)
      #(
        admin_pages.AdminGamesPage(model),
        effect.map(page_effect, admin_pages.AdminGamesMsg),
      )
    }
    _, _ -> #(page, effect.none())
  }
}

@target(javascript)
fn server_frame_message(frame: generated_client.ServerFrame) -> ToClient {
  case frame {
    generated_client.Response(message: message, ..) -> message
    generated_client.Push(message: message, ..) -> message
  }
}
