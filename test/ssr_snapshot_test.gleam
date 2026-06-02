@target(erlang)
import authentication_context.{type AuthenticationContext, AuthenticationContext}
@target(erlang)
import birdie
@target(erlang)
import generated/proute/admin/page_input as admin_page_input
@target(erlang)
import generated/proute/public/page_input as public_page_input
@target(erlang)
import gleam/int
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{None, Some}
@target(erlang)
import gleam/string
@target(erlang)
import scoreboard_unified.{type SsrApp}
@target(erlang)
import sqlight
@target(erlang)
import support/test_db

@target(erlang)
pub fn ssr_public_home_snapshot_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "ssr-public-home")

  scoreboard_unified.public_ssr_render(
    path: "/",
    db:,
    query_params: public_page_input.empty_query_params(),
    dark_mode: False,
    authentication_context: None,
    can_access_admin: False,
  )
  |> to_snapshot
  |> birdie.snap(title: "ssr public home")

  close(db)
}

@target(erlang)
pub fn ssr_public_games_snapshot_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "ssr-public-games")

  scoreboard_unified.public_ssr_render(
    path: "/games",
    db:,
    query_params: public_page_input.empty_query_params(),
    dark_mode: False,
    authentication_context: None,
    can_access_admin: False,
  )
  |> to_snapshot
  |> birdie.snap(title: "ssr public games")

  close(db)
}

@target(erlang)
pub fn ssr_public_game_detail_snapshot_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "ssr-public-game-detail")

  scoreboard_unified.public_ssr_render(
    path: "/games/1",
    db:,
    query_params: public_page_input.empty_query_params(),
    dark_mode: False,
    authentication_context: None,
    can_access_admin: False,
  )
  |> to_snapshot
  |> birdie.snap(title: "ssr public game detail")

  close(db)
}

@target(erlang)
pub fn ssr_public_standings_snapshot_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "ssr-public-standings")

  scoreboard_unified.public_ssr_render(
    path: "/standings",
    db:,
    query_params: public_page_input.empty_query_params(),
    dark_mode: False,
    authentication_context: None,
    can_access_admin: False,
  )
  |> to_snapshot
  |> birdie.snap(title: "ssr public standings")

  close(db)
}

@target(erlang)
pub fn ssr_public_team_snapshot_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "ssr-public-team")

  scoreboard_unified.public_ssr_render(
    path: "/teams/toronto-towers",
    db:,
    query_params: public_page_input.empty_query_params(),
    dark_mode: False,
    authentication_context: None,
    can_access_admin: False,
  )
  |> to_snapshot
  |> birdie.snap(title: "ssr public team")

  close(db)
}

@target(erlang)
pub fn ssr_public_sign_in_snapshot_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "ssr-public-sign-in")

  scoreboard_unified.public_ssr_render(
    path: "/sign_in",
    db:,
    query_params: public_page_input.QueryParams([
      #("return_to", "/admin/games"),
      #("error", "invalid"),
    ]),
    dark_mode: False,
    authentication_context: None,
    can_access_admin: False,
  )
  |> to_snapshot
  |> birdie.snap(title: "ssr public sign in")

  close(db)
}

@target(erlang)
pub fn ssr_public_not_found_snapshot_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "ssr-public-not-found")

  scoreboard_unified.public_ssr_render(
    path: "/missing",
    db:,
    query_params: public_page_input.empty_query_params(),
    dark_mode: False,
    authentication_context: None,
    can_access_admin: False,
  )
  |> to_snapshot
  |> birdie.snap(title: "ssr public not found")

  close(db)
}

@target(erlang)
pub fn ssr_admin_home_snapshot_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "ssr-admin-home")

  scoreboard_unified.admin_ssr_render(
    path: "/admin",
    db:,
    query_params: admin_page_input.empty_query_params(),
    dark_mode: False,
    authentication_context: Some(admin_context()),
  )
  |> to_snapshot
  |> birdie.snap(title: "ssr admin home")

  close(db)
}

@target(erlang)
pub fn ssr_admin_games_snapshot_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "ssr-admin-games")

  scoreboard_unified.admin_ssr_render(
    path: "/admin/games",
    db:,
    query_params: admin_page_input.empty_query_params(),
    dark_mode: False,
    authentication_context: Some(admin_context()),
  )
  |> to_snapshot
  |> birdie.snap(title: "ssr admin games")

  close(db)
}

@target(erlang)
pub fn ssr_admin_not_found_snapshot_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "ssr-admin-not-found")

  scoreboard_unified.admin_ssr_render(
    path: "/admin/missing",
    db:,
    query_params: admin_page_input.empty_query_params(),
    dark_mode: False,
    authentication_context: Some(admin_context()),
  )
  |> to_snapshot
  |> birdie.snap(title: "ssr admin not found")

  close(db)
}

@target(erlang)
fn to_snapshot(app: SsrApp) -> String {
  let formatted_html =
    app.html
    |> string.replace(each: "><", with: ">\n<")

  "hydration_count: "
  <> int.to_string(list.length(app.hydration))
  <> "\n\n"
  <> formatted_html
}

@target(erlang)
fn admin_context() -> AuthenticationContext {
  AuthenticationContext(
    user_id: 1,
    email: "admin@example.com",
    display_name: None,
  )
}

@target(erlang)
fn close(db: sqlight.Connection) -> Nil {
  let assert Ok(_) = sqlight.close(db)
  Nil
}
