@target(erlang)
import app_ssr
@target(erlang)
import authentication_context
@target(erlang)
import generated/proute/admin/page_input as admin_page_input
@target(erlang)
import generated/proute/public/page_input as public_page_input
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{None, Some}
@target(erlang)
import gleam/string
@target(erlang)
import gleeunit/should
@target(erlang)
import sqlight
@target(erlang)
import support/test_db

@target(erlang)
pub fn public_games_ssr_loads_data_and_hydration_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "contract-public-games")
  let app =
    app_ssr.public_render(
      path: "/games",
      db:,
      query_params: public_page_input.empty_query_params(),
      dark_mode: False,
      authentication_context: None,
      can_access_admin: False,
    )

  list.length(app.hydration)
  |> should.equal(1)
  string.contains(app.html, "Toronto Towers")
  |> should.equal(True)
  string.contains(app.html, "Montreal Meteors")
  |> should.equal(True)
  string.contains(app.html, "Waiting for scores")
  |> should.equal(False)

  close(db)
}

@target(erlang)
pub fn public_team_ssr_loads_recent_games_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "contract-public-team")
  let app =
    app_ssr.public_render(
      path: "/teams/toronto-towers",
      db:,
      query_params: public_page_input.empty_query_params(),
      dark_mode: False,
      authentication_context: None,
      can_access_admin: False,
    )

  list.length(app.hydration)
  |> should.equal(1)
  string.contains(app.html, "Toronto Towers")
  |> should.equal(True)
  string.contains(app.html, "Recent games")
  |> should.equal(True)
  string.contains(app.html, "Loading team")
  |> should.equal(False)

  close(db)
}

@target(erlang)
pub fn public_sign_in_ssr_does_not_emit_hydration_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "contract-public-sign-in")
  let app =
    app_ssr.public_render(
      path: "/sign_in",
      db:,
      query_params: public_page_input.QueryParams([#("error", "invalid")]),
      dark_mode: False,
      authentication_context: None,
      can_access_admin: False,
    )

  list.length(app.hydration)
  |> should.equal(0)
  string.contains(app.html, "Invalid sign-in code.")
  |> should.equal(True)

  close(db)
}

@target(erlang)
pub fn admin_games_ssr_loads_score_desk_and_hydration_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "contract-admin-games")
  let app =
    app_ssr.admin_render(
      path: "/admin/games",
      db:,
      query_params: admin_page_input.empty_query_params(),
      dark_mode: False,
      authentication_context: Some(authentication_context.AuthenticationContext(
        user_id: 1,
        email: "admin@example.com",
        display_name: None,
      )),
    )

  list.length(app.hydration)
  |> should.equal(1)
  string.contains(app.html, "Admin score desk")
  |> should.equal(True)
  string.contains(app.html, "Finalize")
  |> should.equal(True)
  string.contains(app.html, "No games yet")
  |> should.equal(False)

  close(db)
}

@target(erlang)
fn close(db: sqlight.Connection) -> Nil {
  let assert Ok(_) = sqlight.close(db)
  Nil
}
