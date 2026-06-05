@target(erlang)
import app_auth
@target(erlang)
import app_session
@target(erlang)
import gleam/bit_array
@target(erlang)
import gleam/bytes_tree
@target(erlang)
import gleam/http/cookie
@target(erlang)
import gleam/http/request.{type Request}
@target(erlang)
import gleam/http/response
@target(erlang)
import gleam/io
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{None, Some}
@target(erlang)
import gleam/result
@target(erlang)
import gleam/string
@target(erlang)
import gleam/uri
@target(erlang)
import mist.{type Connection, type ResponseData}
@target(erlang)
import sqlight

@target(erlang)
/// HTTP handler for POST /sign_in.
/// scoreboard_unified routes auth requests here before normal document routing.
pub fn handle_sign_in_post(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: app_session.Session,
) -> response.Response(ResponseData) {
  case mist.read_body(req, max_body_limit: 4096) {
    Ok(req_with_body) ->
      case bit_array.to_string(req_with_body.body) {
        Ok(body) -> process_sign_in_body(db: db, session: session, body: body)
        Error(Nil) -> redirect_to_invalid_sign_in("/admin/games")
      }
    Error(error) -> {
      io.println_error(
        "sign_in: failed to read body: " <> string.inspect(error),
      )
      redirect_to_invalid_sign_in("/admin/games")
    }
  }
}

@target(erlang)
/// HTTP handler for sign-out routes.
/// scoreboard_unified routes GET/POST /sign_out here so the session cookie can
/// be expired before redirecting.
pub fn handle_sign_out(
  req: Request(Connection),
) -> response.Response(ResponseData) {
  let path = case request.get_query(req) {
    Ok(pairs) ->
      find_pair(pairs, "return_to")
      |> safe_local_path
    Error(Nil) -> "/games"
  }

  response.new(302)
  |> response.set_header("location", path)
  |> response.expire_cookie(
    app_session.session_cookie,
    session_cookie_attributes(),
  )
  |> response.set_body(mist.Bytes(bytes_tree.from_string("")))
}

@target(erlang)
/// Redirect helper used by admin route protection.
/// scoreboard_unified calls this when an unauthenticated request targets /admin.
pub fn sign_in_redirect(return_to: String) -> response.Response(ResponseData) {
  redirect("/sign_in?return_to=" <> uri.percent_encode(return_to))
}

@target(erlang)
/// Admin session guard.
/// scoreboard_unified uses this for admin HTTP and websocket entrypoints, and
/// app_ssr uses it when deciding shell identity.
pub fn check_admin_session(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: app_session.Session,
) -> Result(app_auth.AuthenticatedUser, Nil) {
  use user <- result.try(authenticated_user(req: req, db: db, session: session))
  case app_auth.can_access_admin(user) {
    True -> Ok(user)
    False -> Error(Nil)
  }
}

@target(erlang)
/// Request identity loader.
/// app_ssr and check_admin_session use this to turn cookies into an
/// AuthenticatedUser.
pub fn authenticated_user(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: app_session.Session,
) -> Result(app_auth.AuthenticatedUser, Nil) {
  let cookies = request.get_cookies(req)
  use cookie_value <- result.try(app_auth.find_session(cookies))
  use user_id <- result.try(app_session.decode_user_id(
    encoded: cookie_value,
    session: session,
  ))
  app_auth.user_by_id(db: db, user_id: user_id)
}

@target(erlang)
fn process_sign_in_body(
  db db: sqlight.Connection,
  session session: app_session.Session,
  body body: String,
) -> response.Response(ResponseData) {
  case uri.parse_query(body) {
    Ok(pairs) -> verify_credentials(db: db, session: session, pairs: pairs)
    Error(Nil) -> redirect_to_invalid_sign_in("/admin/games")
  }
}

@target(erlang)
fn verify_credentials(
  db db: sqlight.Connection,
  session session: app_session.Session,
  pairs pairs: List(#(String, String)),
) -> response.Response(ResponseData) {
  let return_to =
    find_pair(pairs, "return_to")
    |> safe_admin_return_to

  case find_pair(pairs, "code") {
    Ok(code) ->
      case app_auth.verify_sign_in_code(db: db, code: code) {
        Ok(user_id) ->
          issue_session(
            session: session,
            return_to: return_to,
            user_id: user_id,
          )
        Error(Nil) -> redirect_to_invalid_sign_in(return_to)
      }
    Error(Nil) -> redirect_to_invalid_sign_in(return_to)
  }
}

@target(erlang)
fn issue_session(
  session session: app_session.Session,
  return_to return_to: String,
  user_id user_id: Int,
) -> response.Response(ResponseData) {
  case app_session.encode_user_id(user_id: user_id, session: session) {
    Ok(encoded) ->
      response.new(302)
      |> response.set_header("location", return_to)
      |> response.set_cookie(
        app_session.session_cookie,
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
fn redirect_to_invalid_sign_in(
  return_to: String,
) -> response.Response(ResponseData) {
  redirect(
    "/sign_in?return_to=" <> uri.percent_encode(return_to) <> "&error=invalid",
  )
}

@target(erlang)
fn redirect(path: String) -> response.Response(ResponseData) {
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
