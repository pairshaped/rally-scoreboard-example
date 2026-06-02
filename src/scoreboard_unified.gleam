@target(erlang)
import admin/pages/games as admin_games_page
@target(erlang)
import api/to_client
@target(erlang)
import api/to_server
@target(erlang)
import app_shell
@target(erlang)
import authentication_context.{type AuthenticationContext}
@target(erlang)
import device_preferences
@target(erlang)
import generated/api/to_client_codec
@target(erlang)
import generated/proute/admin/page_input as admin_page_input
@target(erlang)
import generated/proute/admin/pages as admin_pages
@target(erlang)
import generated/proute/admin/routes as admin_routes
@target(erlang)
import generated/proute/public/page_input as public_page_input
@target(erlang)
import generated/proute/public/pages as public_pages
@target(erlang)
import generated/proute/public/routes as public_routes
@target(erlang)
import gleam/bit_array
@target(erlang)
import gleam/bytes_tree
@target(erlang)
import gleam/crypto
@target(erlang)
import gleam/erlang/process
@target(erlang)
import gleam/http
@target(erlang)
import gleam/http/cookie
@target(erlang)
import gleam/http/request.{type Request, Request}
@target(erlang)
import gleam/http/response.{type Response}
@target(erlang)
import gleam/int
@target(erlang)
import gleam/io
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{type Option, None, Some}
@target(erlang)
import gleam/result
@target(erlang)
import gleam/string
@target(erlang)
import gleam/uri
@target(erlang)
import lustre/element
@target(erlang)
import mist.{type Connection, type ResponseData}
@target(erlang)
import page_context.{PageContext}
@target(erlang)
import public/pages/games as games_page
@target(erlang)
import public/pages/games/id_ as games_id_page
@target(erlang)
import public/pages/standings as standings_page
@target(erlang)
import public/pages/teams/slug_ as teams_slug_page
@target(erlang)
import server/api as server_api
@target(erlang)
import server/auth
@target(erlang)
import server/config
@target(erlang)
import server/session
@target(erlang)
import server/ws
@target(erlang)
import sqlight

@target(erlang)
const db_path = "db/scoreboard.db"

@target(erlang)
pub fn main() -> Nil {
  let assert Ok(db) = sqlight.open(db_path)
  let assert Ok(key) = session_key()
  let session = session.new(key)
  let port = config.http_port(default: 8080)

  let handler = fn(req: Request(Connection)) {
    let Request(path: path, method: method, ..) = req
    case method, path {
      http.Post, "/sign_in" ->
        handle_sign_in_post(req: req, db: db, session: session)
      http.Get, "/sign_out" -> handle_sign_out(req)
      http.Post, "/sign_out" -> handle_sign_out(req)
      _, "/ws" -> {
        let admin_authorized =
          check_admin_session(req: req, db: db, session: session)
          |> result.is_ok
        mist.websocket(
          req,
          ws.handler,
          fn(conn) { ws.on_init(conn, db, admin_authorized) },
          ws.on_close,
        )
      }
      _, _ ->
        case string.starts_with(path, "/_build/") {
          True -> serve_static(string.drop_start(path, 8))
          False ->
            case string.starts_with(path, "/admin") {
              True -> handle_admin_path(req: req, db: db, session: session)
              False ->
                html_response(app_html(
                  req: req,
                  path: path,
                  db: db,
                  session: session,
                ))
            }
        }
    }
  }

  io.println("Listening on http://localhost:" <> int.to_string(port))
  let assert Ok(_) =
    mist.new(handler)
    |> mist.port(port)
    |> mist.start
  process.sleep_forever()
}

@target(erlang)
fn session_key() -> Result(BitArray, config.SecretKeyError) {
  case config.secret_key() {
    Ok(key) -> Ok(key)
    Error(config.MissingSecret) -> {
      io.println_error(
        config.secret_key_error_message(config.MissingSecret)
        <> "; using an in-memory development key",
      )
      Ok(crypto.strong_random_bytes(32))
    }
    Error(error) -> {
      io.println_error(config.secret_key_error_message(error))
      Error(error)
    }
  }
}

@target(erlang)
fn serve_static(path: String) -> Response(ResponseData) {
  let content_type = case string.ends_with(path, ".mjs") {
    True -> "application/javascript; charset=utf-8"
    False ->
      case string.ends_with(path, ".css") {
        True -> "text/css; charset=utf-8"
        False -> "application/octet-stream"
      }
  }

  case mist.send_file("build/dev/javascript/" <> path, offset: 0, limit: None) {
    Ok(data) ->
      response.new(200)
      |> response.set_header("content-type", content_type)
      |> response.set_body(data)
    Error(reason) -> {
      io.println(
        "Static file not found: "
        <> path
        <> " ("
        <> string.inspect(reason)
        <> ")",
      )
      response.new(404)
      |> response.set_body(mist.Bytes(bytes_tree.from_string("Not found")))
    }
  }
}

@target(erlang)
fn html_response(body: String) -> Response(ResponseData) {
  response.new(200)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

@target(erlang)
pub type SsrApp {
  SsrApp(html: String, hydration: List(String))
}

@target(erlang)
fn app_html(
  req req: Request(Connection),
  path path: String,
  db db: sqlight.Connection,
  session session: session.Session,
) -> String {
  let entrypoint = case string.starts_with(path, "/admin") {
    True -> "admin_app.mjs"
    False -> "public_app.mjs"
  }
  let theme = resolve_theme(req)
  let ssr_app = case string.starts_with(path, "/admin") {
    True ->
      admin_ssr_app(
        req: req,
        path: path,
        db: db,
        dark_mode: theme == "dark",
        session: session,
      )
    False ->
      public_ssr_app(
        req: req,
        path: path,
        db: db,
        dark_mode: theme == "dark",
        session: session,
      )
  }
  let app_attrs =
    app_boot_attrs(req: req, db: db, session: session)
    <> hydration_attr(ssr_app.hydration)

  "<!doctype html>
<html data-theme=\"" <> theme <> "\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>Scoreboard</title>
  <link rel=\"stylesheet\" href=\"https://unpkg.com/@knadh/oat/oat.min.css\">
  <style>
" <> app_css() <> "
  </style>
</head>
<body>
  <div id=\"app\"" <> app_attrs <> ">" <> ssr_app.html <> "</div>
  <script type=\"module\">
    import { main } from '/_build/scoreboard_unified/" <> entrypoint <> "';
    main();
  </script>
</body>
</html>"
}

@target(erlang)
fn public_ssr_app(
  req req: Request(Connection),
  path path: String,
  db db: sqlight.Connection,
  dark_mode dark_mode: Bool,
  session session: session.Session,
) -> SsrApp {
  let query_params = public_query_params(req)
  let #(authentication_context, can_access_admin) =
    boot_identity(req: req, db: db, session: session)

  public_ssr_render(
    path:,
    db:,
    query_params:,
    dark_mode:,
    authentication_context:,
    can_access_admin:,
  )
}

@target(erlang)
pub fn public_ssr_render(
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: public_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
  can_access_admin can_access_admin: Bool,
) -> SsrApp {
  let route = public_routes.parse_path(path)
  let messages = public_hydration_messages(db, route)
  let page =
    public_pages.load_sync(PageContext, query_params, route)
    |> apply_public_hydration(messages)

  SsrApp(
    html: app_shell.public(
      current_path: public_routes.route_to_path(route),
      dark_mode: dark_mode,
      authentication_context: authentication_context,
      can_access_admin: can_access_admin,
      on_dark_mode_change: fn(_) { Nil },
      content: public_pages.view(page) |> element.map(fn(_) { Nil }),
    )
      |> element.to_string,
    hydration: hydration_payloads(messages),
  )
}

@target(erlang)
fn admin_ssr_app(
  req req: Request(Connection),
  path path: String,
  db db: sqlight.Connection,
  dark_mode dark_mode: Bool,
  session session: session.Session,
) -> SsrApp {
  let query_params = admin_query_params(req)
  let #(authentication_context, _) =
    boot_identity(req: req, db: db, session: session)

  admin_ssr_render(
    path:,
    db:,
    query_params:,
    dark_mode:,
    authentication_context:,
  )
}

@target(erlang)
pub fn admin_ssr_render(
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: admin_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
) -> SsrApp {
  let route = admin_routes.parse_path(path)
  let messages = admin_hydration_messages(db, route)
  let page =
    admin_pages.load_sync(PageContext, query_params, route)
    |> apply_admin_hydration(messages)

  SsrApp(
    html: app_shell.admin(
      current_path: admin_routes.route_to_path(route),
      dark_mode: dark_mode,
      authentication_context: authentication_context,
      on_dark_mode_change: fn(_) { Nil },
      content: admin_pages.view(page) |> element.map(fn(_) { Nil }),
    )
      |> element.to_string,
    hydration: hydration_payloads(messages),
  )
}

@target(erlang)
fn boot_identity(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: session.Session,
) -> #(Option(AuthenticationContext), Bool) {
  case authenticated_user(req: req, db: db, session: session) {
    Ok(user) -> #(Some(user.context), auth.can_access_admin(user))
    Error(Nil) -> #(None, False)
  }
}

@target(erlang)
fn public_query_params(
  req: Request(Connection),
) -> public_page_input.QueryParams {
  case request.get_query(req) {
    Ok(values) -> public_page_input.QueryParams(values:)
    Error(Nil) -> public_page_input.empty_query_params()
  }
}

@target(erlang)
fn admin_query_params(
  req: Request(Connection),
) -> admin_page_input.QueryParams {
  case request.get_query(req) {
    Ok(values) -> admin_page_input.QueryParams(values:)
    Error(Nil) -> admin_page_input.empty_query_params()
  }
}

@target(erlang)
fn public_hydration_messages(
  db: sqlight.Connection,
  route: public_routes.Route,
) -> List(to_client.ToClient) {
  case route {
    public_routes.Home | public_routes.Games ->
      server_api.dispatch(
        db: db,
        message: to_server.LoadGames,
        admin_authorized: False,
      )
    public_routes.GamesId(id) ->
      case int.parse(id) {
        Ok(game_id) ->
          server_api.dispatch(
            db: db,
            message: to_server.LoadGame(game_id:),
            admin_authorized: False,
          )
        Error(Nil) -> []
      }
    public_routes.Standings ->
      server_api.dispatch(
        db: db,
        message: to_server.LoadGames,
        admin_authorized: False,
      )
    public_routes.TeamsSlug(slug) ->
      server_api.dispatch(
        db: db,
        message: to_server.LoadTeam(slug:),
        admin_authorized: False,
      )
    public_routes.SignIn | public_routes.NotFound -> []
  }
}

@target(erlang)
fn admin_hydration_messages(
  db: sqlight.Connection,
  route: admin_routes.Route,
) -> List(to_client.ToClient) {
  case route {
    admin_routes.AdminHome | admin_routes.AdminGames ->
      server_api.dispatch(
        db: db,
        message: to_server.LoadAdminGames,
        admin_authorized: True,
      )
    admin_routes.NotFound -> []
  }
}

@target(erlang)
fn apply_public_hydration(
  page: public_pages.Page,
  messages: List(to_client.ToClient),
) -> public_pages.Page {
  list.fold(messages, page, fn(page, message) {
    apply_public_message(page: page, message: message)
  })
}

@target(erlang)
fn apply_admin_hydration(
  page: admin_pages.Page,
  messages: List(to_client.ToClient),
) -> admin_pages.Page {
  list.fold(messages, page, fn(page, message) {
    apply_admin_message(page: page, message: message)
  })
}

@target(erlang)
fn apply_public_message(
  page page: public_pages.Page,
  message message: to_client.ToClient,
) -> public_pages.Page {
  case page, message {
    public_pages.HomePage(model), to_client.GamesLoaded(games) -> {
      let #(model, _) = games_page.games_loaded(model, games)
      public_pages.HomePage(model)
    }
    public_pages.HomePage(model), to_client.GameUpdated(game) -> {
      let #(model, _) = games_page.game_updated(model, game)
      public_pages.HomePage(model)
    }
    public_pages.GamesPage(model), to_client.GamesLoaded(games) -> {
      let #(model, _) = games_page.games_loaded(model, games)
      public_pages.GamesPage(model)
    }
    public_pages.GamesPage(model), to_client.GameUpdated(game) -> {
      let #(model, _) = games_page.game_updated(model, game)
      public_pages.GamesPage(model)
    }
    public_pages.GamesIdPage(model), to_client.GameLoaded(game) -> {
      let #(model, _) = games_id_page.game_loaded(model, game)
      public_pages.GamesIdPage(model)
    }
    public_pages.GamesIdPage(model), to_client.GameUpdated(game) -> {
      let #(model, _) = games_id_page.game_updated(model, game)
      public_pages.GamesIdPage(model)
    }
    public_pages.StandingsPage(model), to_client.GamesLoaded(games) -> {
      let #(model, _) = standings_page.games_loaded(model, games)
      public_pages.StandingsPage(model)
    }
    public_pages.StandingsPage(model), to_client.GameUpdated(game) -> {
      let #(model, _) = standings_page.game_updated(model, game)
      public_pages.StandingsPage(model)
    }
    public_pages.TeamsSlugPage(model), to_client.TeamLoaded(team) -> {
      let #(model, _) = teams_slug_page.team_loaded(model, team)
      public_pages.TeamsSlugPage(model)
    }
    public_pages.TeamsSlugPage(model), to_client.GameUpdated(game) -> {
      let #(model, _) = teams_slug_page.game_updated(model, game)
      public_pages.TeamsSlugPage(model)
    }
    _, _ -> page
  }
}

@target(erlang)
fn apply_admin_message(
  page page: admin_pages.Page,
  message message: to_client.ToClient,
) -> admin_pages.Page {
  case page, message {
    admin_pages.AdminHomePage(model), to_client.AdminGamesLoaded(games) -> {
      let #(model, _) = admin_games_page.admin_games_loaded(model, games)
      admin_pages.AdminHomePage(model)
    }
    admin_pages.AdminHomePage(model), to_client.GameUpdated(game) -> {
      let #(model, _) = admin_games_page.game_updated(model, game)
      admin_pages.AdminHomePage(model)
    }
    admin_pages.AdminGamesPage(model), to_client.AdminGamesLoaded(games) -> {
      let #(model, _) = admin_games_page.admin_games_loaded(model, games)
      admin_pages.AdminGamesPage(model)
    }
    admin_pages.AdminGamesPage(model), to_client.GameUpdated(game) -> {
      let #(model, _) = admin_games_page.game_updated(model, game)
      admin_pages.AdminGamesPage(model)
    }
    _, _ -> page
  }
}

@target(erlang)
fn hydration_payloads(messages: List(to_client.ToClient)) -> List(String) {
  to_client_codec.ensure()
  list.map(messages, fn(message) {
    message
    |> to_client_codec.encode
    |> bit_array.base64_url_encode(False)
  })
}

@target(erlang)
fn hydration_attr(payloads: List(String)) -> String {
  case payloads {
    [] -> ""
    _ ->
      " data-hydration=\""
      <> html_attr_escape(string.join(payloads, ","))
      <> "\""
  }
}

@target(erlang)
fn resolve_theme(req: Request(Connection)) -> String {
  let cookies = request.get_cookies(req)
  case
    list.find_map(cookies, fn(cookie) {
      case cookie.0 {
        name if name == device_preferences.cookie_name -> Ok(cookie.1)
        _ -> Error(Nil)
      }
    })
  {
    Ok(value) ->
      case device_preferences.parse(value) {
        Ok(preferences) ->
          case preferences.dark_mode {
            True -> "dark"
            False -> "light"
          }
        Error(Nil) -> "light"
      }
    Error(Nil) -> "light"
  }
}

@target(erlang)
fn handle_admin_path(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: session.Session,
) -> Response(ResponseData) {
  case check_admin_session(req: req, db: db, session: session) {
    Ok(_) ->
      html_response(app_html(req: req, path: req.path, db: db, session: session))
    Error(Nil) ->
      redirect("/sign_in?return_to=" <> uri.percent_encode(req.path))
  }
}

@target(erlang)
fn handle_sign_in_post(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: session.Session,
) -> Response(ResponseData) {
  case mist.read_body(req, max_body_limit: 4096) {
    Ok(req_with_body) ->
      case bit_array.to_string(req_with_body.body) {
        Ok(body) -> process_sign_in_body(db: db, session: session, body: body)
        Error(Nil) -> redirect_to_sign_in("/admin/games")
      }
    Error(error) -> {
      io.println_error(
        "sign_in: failed to read body: " <> string.inspect(error),
      )
      redirect_to_sign_in("/admin/games")
    }
  }
}

@target(erlang)
fn process_sign_in_body(
  db db: sqlight.Connection,
  session session: session.Session,
  body body: String,
) -> Response(ResponseData) {
  case uri.parse_query(body) {
    Ok(pairs) -> verify_credentials(db: db, session: session, pairs: pairs)
    Error(Nil) -> redirect_to_sign_in("/admin/games")
  }
}

@target(erlang)
fn verify_credentials(
  db db: sqlight.Connection,
  session session: session.Session,
  pairs pairs: List(#(String, String)),
) -> Response(ResponseData) {
  let return_to =
    find_pair(pairs, "return_to")
    |> safe_admin_return_to

  case find_pair(pairs, "code") {
    Ok(code) ->
      case auth.verify_sign_in_code(db: db, code: code) {
        Ok(user_id) ->
          issue_session(
            session: session,
            return_to: return_to,
            user_id: user_id,
          )
        Error(Nil) -> redirect_to_sign_in(return_to)
      }
    Error(Nil) -> redirect_to_sign_in(return_to)
  }
}

@target(erlang)
fn issue_session(
  session session: session.Session,
  return_to return_to: String,
  user_id user_id: Int,
) -> Response(ResponseData) {
  case session.encode_user_id(user_id: user_id, session: session) {
    Ok(encoded) ->
      response.new(302)
      |> response.set_header("location", return_to)
      |> response.set_cookie(
        session.session_cookie,
        encoded,
        session_cookie_attributes(),
      )
      |> response.set_body(mist.Bytes(bytes_tree.from_string("")))
    Error(Nil) ->
      response.new(500)
      |> response.set_body(
        mist.Bytes(bytes_tree.from_string("Cannot issue session")),
      )
  }
}

@target(erlang)
fn handle_sign_out(req: Request(Connection)) -> Response(ResponseData) {
  let path = case request.get_query(req) {
    Ok(pairs) ->
      find_pair(pairs, "return_to")
      |> safe_local_path
    Error(Nil) -> "/games"
  }

  response.new(302)
  |> response.set_header("location", path)
  |> response.expire_cookie(session.session_cookie, session_cookie_attributes())
  |> response.set_body(mist.Bytes(bytes_tree.from_string("")))
}

@target(erlang)
fn redirect_to_sign_in(return_to: String) -> Response(ResponseData) {
  redirect(
    "/sign_in?return_to=" <> uri.percent_encode(return_to) <> "&error=invalid",
  )
}

@target(erlang)
fn redirect(path: String) -> Response(ResponseData) {
  response.new(302)
  |> response.set_header("location", path)
  |> response.set_body(mist.Bytes(bytes_tree.from_string("")))
}

@target(erlang)
fn session_cookie_attributes() -> cookie.Attributes {
  cookie.Attributes(
    max_age: None,
    domain: None,
    path: Some("/"),
    secure: False,
    http_only: True,
    same_site: Some(cookie.Lax),
  )
}

@target(erlang)
fn check_admin_session(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: session.Session,
) -> Result(auth.AuthenticatedUser, Nil) {
  use user <- result.try(authenticated_user(req: req, db: db, session: session))
  case auth.can_access_admin(user) {
    True -> Ok(user)
    False -> Error(Nil)
  }
}

@target(erlang)
fn authenticated_user(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: session.Session,
) -> Result(auth.AuthenticatedUser, Nil) {
  let cookies = request.get_cookies(req)
  use cookie_value <- result.try(auth.find_session(cookies))
  use user_id <- result.try(session.decode_user_id(
    encoded: cookie_value,
    session: session,
  ))
  auth.user_by_id(db: db, user_id: user_id)
}

@target(erlang)
fn app_boot_attrs(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: session.Session,
) -> String {
  case authenticated_user(req: req, db: db, session: session) {
    Ok(user) -> {
      let context = user.context
      let display_name = case context.display_name {
        Some(value) -> value
        None -> ""
      }
      " data-auth-user-id=\""
      <> int.to_string(context.user_id)
      <> "\" data-auth-email=\""
      <> html_attr_escape(context.email)
      <> "\" data-auth-display-name=\""
      <> html_attr_escape(display_name)
      <> "\" data-can-access-admin=\""
      <> bool_attr(auth.can_access_admin(user))
      <> "\""
    }
    Error(Nil) -> " data-can-access-admin=\"0\""
  }
}

// nolint: prefer_guard_clause -- this is a string conversion helper, not control flow.
@target(erlang)
fn bool_attr(value: Bool) -> String {
  case value {
    True -> "1"
    False -> "0"
  }
}

@target(erlang)
fn html_attr_escape(value: String) -> String {
  value
  |> string.replace("&", "&amp;")
  |> string.replace("\"", "&quot;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
}

@target(erlang)
fn find_pair(
  pairs: List(#(String, String)),
  name: String,
) -> Result(String, Nil) {
  list.find_map(pairs, fn(pair) {
    case pair.0 {
      key if key == name -> Ok(pair.1)
      _ -> Error(Nil)
    }
  })
}

@target(erlang)
fn safe_admin_return_to(path: Result(String, Nil)) -> String {
  case path {
    Ok("/admin") -> "/admin"
    Ok("/admin/" <> rest) -> "/admin/" <> rest
    _ -> "/admin/games"
  }
}

@target(erlang)
fn safe_local_path(path: Result(String, Nil)) -> String {
  case path {
    Ok(value) ->
      case string.starts_with(value, "/"), string.starts_with(value, "//") {
        True, False -> value
        _, _ -> "/games"
      }
    Error(Nil) -> "/games"
  }
}

@target(erlang)
fn app_css() -> String {
  "
:root {
  color-scheme: light;
  --score-ink: #132238;
  --score-muted: #5c6878;
  --score-line: #d7dde5;
  --score-panel: #ffffff;
  --score-bg: #f4f6f8;
  --score-live: #c83b2b;
  --score-win: #116d5b;
  --score-blue: #2764a6;
  --score-gold: #c2871f;
  --score-action: #132238;
  --score-action-foreground: #ffffff;
}

:root[data-theme='dark'] {
  color-scheme: dark;
  --score-ink: #e9eef6;
  --score-muted: #a7b0bf;
  --score-line: #324157;
  --score-panel: #141d2b;
  --score-bg: #0d1320;
  --score-live: #ff7a6b;
  --score-win: #5bd3b4;
  --score-blue: #6aa7ff;
  --score-gold: #f0bd56;
  --score-action: #2f6fbd;
  --score-action-foreground: #ffffff;
  --score-button-bg: #2f6fbd;
}

body {
  margin: 0;
  min-height: 100vh;
  background: var(--score-bg);
  color: var(--score-ink);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
}

.scoreboard-app {
  max-width: 1180px;
  margin: 0 auto;
  padding: 28px 20px 44px;
}

.page-explainer {
  margin: -8px 0 20px;
}

.page-explainer details {
  background: var(--score-panel);
  border: 1px solid var(--score-line);
  border-left: 4px solid var(--score-blue);
  border-radius: 8px;
}

.page-explainer summary {
  cursor: pointer;
  font-weight: 750;
  list-style: none;
  padding: 12px 14px;
}

.page-explainer summary::-webkit-details-marker {
  display: none;
}

.page-explainer summary::after {
  content: '+';
  float: right;
  color: var(--score-muted);
}

.page-explainer details[open] summary::after {
  content: '-';
}

.page-explainer ul {
  color: var(--score-muted);
  margin: 0;
  padding: 6px 14px 14px 34px;
}

.page-explainer li + li {
  margin-top: 6px;
}

.nav a.active {
  color: var(--score-ink);
  background: #e6edf5;
}

:root[data-theme='dark'] .nav a.active {
  background: #25344a;
}

.theme-switch {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--score-muted);
  padding: 7px 10px;
  border-radius: 6px;
  cursor: pointer;
}

.theme-switch input {
  margin: 0;
}

.theme-switch input[type='checkbox'][role='switch'] {
  border-radius: var(--radius-full);
  padding: 0;
}

.theme-icon {
  flex: 0 0 auto;
}

.sign-in-form {
  display: grid;
  gap: 10px;
  max-width: 320px;
}

.auth-error {
  color: var(--score-live);
  font-weight: 700;
}

.topbar, .panel, .game-card, .stat-card {
  background: var(--score-panel);
  border: 1px solid var(--score-line);
  border-radius: 8px;
}

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 16px 18px;
  margin-bottom: 20px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  font-weight: 750;
}

.brand-mark {
  width: 34px;
  height: 34px;
  border-radius: 8px;
  display: grid;
  place-items: center;
  background: var(--score-blue);
  color: white;
  font-weight: 800;
}

.nav {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.nav a {
  color: var(--score-muted);
  text-decoration: none;
  padding: 7px 10px;
  border-radius: 6px;
}

.panel {
  padding: 18px;
}

h1, h2, h3, p {
  margin-top: 0;
}

h1 {
  font-size: 28px;
  line-height: 1.15;
  margin-bottom: 4px;
}

h2 {
  font-size: 18px;
  line-height: 1.25;
  margin-bottom: 8px;
}

a {
  color: var(--score-blue);
}

.muted {
  color: var(--score-muted);
}

.section-head {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: end;
  margin-bottom: 14px;
}

.game-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 12px;
}

.game-card {
  padding: 14px;
}

.team-row, .score-line {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.score {
  font-size: 34px;
  font-weight: 800;
  line-height: 1;
}

.badge {
  display: inline-flex;
  align-items: center;
  min-height: 26px;
  padding: 2px 8px;
  border-radius: 999px;
  background: #eef2f6;
  color: var(--score-muted);
  font-size: 13px;
  font-weight: 650;
}

.badge.live {
  background: #ffe7e2;
  color: var(--score-live);
}

.badge.final {
  background: #e0f3ee;
  color: var(--score-win);
}

:root[data-theme='dark'] .badge {
  background: #243248;
}

:root[data-theme='dark'] .badge.live {
  background: #44211d;
}

:root[data-theme='dark'] .badge.final {
  background: #18362f;
}

.standings-table {
  width: 100%;
  border-collapse: collapse;
}

.standings-table th, .standings-table td {
  padding: 10px 8px;
  border-bottom: 1px solid var(--score-line);
  text-align: left;
}

.standings-table th {
  color: var(--score-muted);
  font-size: 13px;
  font-weight: 700;
}

.layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 320px;
  gap: 18px;
  align-items: start;
}

.admin-tools {
  display: grid;
  gap: 10px;
}

.toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
}

.toolbar input {
  max-width: 90px;
}

.button-row {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.admin-score-row {
  display: grid;
  grid-template-columns: minmax(7ch, 1fr) 32px 32px 4ch;
  gap: 8px;
  align-items: center;
}

.admin-score-row + .admin-score-row {
  margin-top: 8px;
}

.admin-score-row .score {
  text-align: right;
}

.admin-status-row {
  margin-top: 12px;
}

.score-control {
  min-width: 32px;
  padding-inline: 8px;
}

button, .button-link {
  border-radius: 6px;
  border: 1px solid var(--score-line);
  background: var(--score-button-bg, var(--score-ink));
  color: white;
  padding: 8px 10px;
  font-weight: 700;
  text-decoration: none;
  cursor: pointer;
}

button.secondary, .button-link.secondary {
  background: white;
  color: var(--score-ink);
}

:root[data-theme='dark'] button.secondary,
:root[data-theme='dark'] .button-link.secondary {
  background: #101827;
}

input:not([type='checkbox']):not([type='radio']):not([type='range']):not([type='file']):not([type='color']), select, textarea {
  border: 1px solid var(--score-line);
  border-radius: 6px;
  padding: 7px 9px;
}

.card, .team-record-card {
  margin: 0;
}

.team-record-title {
  margin-bottom: 14px;
  color: var(--score-muted);
}

.team-record-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
  margin: 0;
}

.team-record-grid > div {
  min-width: 0;
  padding: 10px 12px;
  border: 1px solid var(--score-line);
  border-radius: 6px;
  background: var(--score-bg);
}

.team-record-grid dt {
  color: var(--score-muted);
  font-size: 12px;
  font-weight: 700;
}

.team-record-grid dd {
  margin: 2px 0 0;
  font-size: 22px;
  font-weight: 800;
  line-height: 1.1;
}

@media (max-width: 860px) {
  .layout {
    grid-template-columns: 1fr;
  }

  .topbar {
    align-items: flex-start;
    flex-direction: column;
  }

  .team-record-grid {
    grid-template-columns: 1fr;
  }
}
"
}
