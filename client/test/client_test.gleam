//// Client-side contract tests for the Scoreboard example.
////
//// These tests keep the hand-written receiver hub and generated receiver
//// dispatch aligned while Generator Framework generation is being rebuilt toward this app.

import client/public/receivers
import generated/codec
import generated/public/receiver_dispatch
import generated/setup
import gleam/option
import gleam/string
import gleeunit
import gleeunit/should
import libero/wire as libero_wire
import shared/admin/client_context as admin_client_context
import shared/api/domain/game
import shared/api/to_client
import shared/authentication_context
import shared/public/client_context as public_client_context
import shared/public/pages/game_detail as game_detail_page
import shared/public/pages/games as games_page
import shared/public/pages/team as team_page

pub fn main() {
  gleeunit.main()
}

pub fn public_to_client_receiver_dispatch_fans_out_to_all_interested_pages_test() {
  let update =
    game.GameScoreUpdate(
      game_id: 2,
      home_score: 101,
      away_score: 99,
      period: "Q4",
      status: game.Live("Q4"),
    )

  let messages =
    receiver_dispatch.to_client(to_client.GameScoreUpdated(update:))

  messages
  |> should.equal([
    receivers.GamesPage(games_page.UpdatedScore(update)),
    receivers.GameDetailPage(game_detail_page.UpdatedScore(update)),
    receivers.TeamPage(team_page.UpdatedScore(update)),
  ])
}

pub fn admin_client_context_is_importable_test() {
  let auth_ctx =
    authentication_context.AuthenticationContext(
      user_id: 1,
      email: "admin@example.com",
      display_name: option.None,
    )
  let ctx =
    admin_client_context.AdminClientContext(
      authentication_context: option.Some(auth_ctx),
      league_name: "Rally Rec League",
      dark_mode: False,
      active_section: "games",
      toast: option.None,
    )
  case ctx.authentication_context {
    option.Some(ac) -> ac.email |> should.equal("admin@example.com")
    option.None -> should.be_true(False)
  }
}

pub fn public_client_context_is_importable_test() {
  let ctx =
    public_client_context.PublicClientContext(
      league_name: "Rally Rec League",
      active_section: "games",
      authentication_context: option.None,
      can_access_admin: False,
    )
  ctx.league_name |> should.equal("Rally Rec League")
  ctx.active_section |> should.equal("games")
  ctx.can_access_admin |> should.be_false
}

@external(javascript, "./client_context_smoke_ffi.mjs", "setWindowContext")
fn set_window_context(base64: String) -> Nil

@external(javascript, "./client_context_smoke_ffi.mjs", "clearWindowContext")
fn clear_window_context() -> Nil

pub fn client_setup_decodes_admin_context_from_window_variable_test() {
  let assert True = codec.ensure_decoders()

  let auth_ctx =
    authentication_context.AuthenticationContext(
      user_id: 7,
      email: "admin@example.com",
      display_name: option.None,
    )
  let context =
    admin_client_context.AdminClientContext(
      authentication_context: option.Some(auth_ctx),
      league_name: "Rally Rec League",
      dark_mode: False,
      active_section: "games",
      toast: option.None,
    )

  let base64 = libero_wire.encode_flags(context)
  case string.length(base64) > 0 {
    True -> Nil
    False -> should.be_true(False)
  }

  set_window_context(base64)

  let result = case setup.read_client_context() {
    option.Some(value) -> {
      let decoded: admin_client_context.AdminClientContext =
        libero_wire.coerce(value)
      Ok(decoded)
    }
    option.None -> Error(Nil)
  }

  clear_window_context()

  case result {
    Ok(decoded) -> {
      decoded.league_name |> should.equal("Rally Rec League")
      decoded.dark_mode |> should.equal(False)
      decoded.active_section |> should.equal("games")
      case decoded.authentication_context {
        option.Some(ac) -> {
          ac.user_id |> should.equal(7)
          ac.email |> should.equal("admin@example.com")
        }
        option.None -> should.be_true(False)
      }
    }
    Error(_) -> should.be_true(False)
  }
}
