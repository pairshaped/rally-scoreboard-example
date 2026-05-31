//// Birdie snapshots for server-rendered page HTML.

import birdie
import generated/admin/ssr_handler as admin_ssr_handler
import generated/public/ssr_handler as public_ssr_handler
import generated/routes/admin as admin_route
import generated/routes/public as public_route
import generated/runtime/db
import gleam/bit_array
import gleam/bytes_tree
import gleam/dict
import gleam/http/response.{type Response}
import gleam/option.{None}
import gleam/string
import mist.{type ResponseData, Bytes}
import server/server_context.{type ServerContext, ServerContext}
import simplifile
import sqlight

pub fn public_games_ssr_html_matches_snapshot_test() {
  public_html(public_route.Games)
  |> birdie.snap("ssr_public_games_html")
}

pub fn public_game_detail_ssr_html_matches_snapshot_test() {
  public_html(public_route.GamesId("1"))
  |> birdie.snap("ssr_public_game_detail_html")
}

pub fn public_standings_ssr_html_matches_snapshot_test() {
  public_html(public_route.Standings)
  |> birdie.snap("ssr_public_standings_html")
}

pub fn public_team_ssr_html_matches_snapshot_test() {
  public_html(public_route.Team("toronto-towers"))
  |> birdie.snap("ssr_public_team_html")
}

pub fn admin_games_ssr_html_matches_snapshot_test() {
  admin_html(admin_route.AdminGames)
  |> birdie.snap("ssr_admin_games_html")
}

fn public_html(route: public_route.Route) -> String {
  let context = server_context()
  public_ssr_handler.handle_request(
    route:,
    server_context: context,
    session_id: "snapshot-session",
    hostname: "scoreboard.test",
    query: dict.new(),
    authentication_context: None,
  )
  |> response_app_html
}

fn admin_html(route: admin_route.Route) -> String {
  let context = server_context()
  admin_ssr_handler.handle_request(
    route:,
    server_context: context,
    session_id: "snapshot-session",
    hostname: "scoreboard.test",
    query: dict.new(),
    authentication_context: None,
  )
  |> response_app_html
}

fn response_app_html(response: Response(ResponseData)) -> String {
  let assert Bytes(tree) = response.body
  let bits = bytes_tree.to_bit_array(tree)
  let assert Ok(html) = bit_array.to_string(bits)
  app_html(html)
}

fn app_html(html: String) -> String {
  let assert Ok(#(_, after_app_open)) =
    string.split_once(html, on: "<div id=\"app\">")
  let assert Ok(#(app_content, _)) =
    string.split_once(
      after_app_open,
      on: "\n  <script type=\"module\" data-runtime-client>",
    )
  "<div id=\"app\">" <> app_content
}

fn server_context() -> ServerContext {
  let assert Ok(conn) = db.open(":memory:")
  run_sql_file(conn, "db/migrations/002_teams.sql")
  run_sql_file(conn, "db/migrations/003_games.sql")
  run_sql_file(conn, "db/seeds/002_teams.sql")
  run_sql_file(conn, "db/seeds/003_games.sql")
  ServerContext(db: conn, system_db: conn)
}

fn run_sql_file(conn: sqlight.Connection, path: String) -> Nil {
  let assert Ok(sql) = simplifile.read(path)
  let assert Ok(Nil) = sqlight.exec(sql, on: conn)
  Nil
}
