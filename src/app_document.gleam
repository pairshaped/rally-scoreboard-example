@target(erlang)
import app_auth
@target(erlang)
import app_auth_http
@target(erlang)
import app_session
@target(erlang)
import app_ssr
@target(erlang)
import generated/proute/admin/page_input as admin_page_input
@target(erlang)
import generated/proute/public/page_input as public_page_input
@target(erlang)
import generated/rally/theme
@target(erlang)
import gleam/bytes_tree
@target(erlang)
import gleam/http/request.{type Request}
@target(erlang)
import gleam/http/response.{type Response}
@target(erlang)
import gleam/int
@target(erlang)
import gleam/option.{None, Some}
@target(erlang)
import gleam/string
@target(erlang)
import mist.{type Connection, type ResponseData}
@target(erlang)
import sqlight

@target(javascript)
/// JavaScript-side compile anchor for the document module.
/// Browser builds can import this module without pulling in Erlang-only code.
pub fn ensure() -> Nil {
  Nil
}

@target(erlang)
/// HTTP document response for public and admin app routes.
/// scoreboard_unified calls this after routing/auth, and this module chooses the
/// matching SSR mount and browser entrypoint.
pub fn response(
  req req: Request(Connection),
  path path: String,
  db db: sqlight.Connection,
  session session: app_session.Session,
) -> Response(ResponseData) {
  html(req: req, path: path, db: db, session: session)
  |> html_response
}

@target(erlang)
fn html_response(body: String) -> Response(ResponseData) {
  response.new(200)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

@target(erlang)
fn html(
  req req: Request(Connection),
  path path: String,
  db db: sqlight.Connection,
  session session: app_session.Session,
) -> String {
  let entrypoint = case string.starts_with(path, "/admin") {
    True -> "admin_app.mjs"
    False -> "public_app.mjs"
  }
  let dark_mode = theme.request_dark_mode(req)
  let ssr_app = case string.starts_with(path, "/admin") {
    True ->
      app_ssr.admin(
        req: req,
        path: path,
        db: db,
        query_params: admin_query_params(req),
        dark_mode: dark_mode,
        session: session,
      )
    False ->
      app_ssr.public(
        req: req,
        path: path,
        db: db,
        query_params: public_query_params(req),
        dark_mode: dark_mode,
        session: session,
      )
  }
  let app_attrs =
    app_boot_attrs(req: req, db: db, session: session)
    <> hydration_attr(ssr_app.hydration)

  "<!doctype html>
<html " <> theme.document_attribute(req) <> ">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>Scoreboard</title>
  <link rel=\"stylesheet\" href=\"https://unpkg.com/@knadh/oat/oat.min.css\">
  <link rel=\"stylesheet\" href=\"/assets/app.css\">
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
fn app_boot_attrs(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: app_session.Session,
) -> String {
  case app_auth_http.authenticated_user(req: req, db: db, session: session) {
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
      <> bool_attr(app_auth.can_access_admin(user))
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
