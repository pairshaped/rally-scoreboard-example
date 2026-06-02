@target(erlang)
import api/to_client
@target(erlang)
import api/to_server.{type ToServer}
@target(erlang)
import app_api
@target(erlang)
import app_auth
@target(erlang)
import app_auth_http
@target(erlang)
import app_session
@target(erlang)
import app_shell
@target(erlang)
import authentication_context.{type AuthenticationContext}
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
import generated_soon/admin_boot
@target(erlang)
import generated_soon/public_boot
@target(erlang)
import gleam/bit_array
@target(erlang)
import gleam/http/request.{type Request}
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{type Option, None, Some}
@target(erlang)
import lustre/element
@target(erlang)
import mist.{type Connection}
@target(erlang)
import page_context.{PageContext}
@target(erlang)
import sqlight

@target(erlang)
pub type SsrApp {
  SsrApp(html: String, hydration: List(String))
}

@target(erlang)
pub fn public(
  req req: Request(Connection),
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: public_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  session session: app_session.Session,
) -> SsrApp {
  let #(authentication_context, can_access_admin) =
    boot_identity(req: req, db: db, session: session)

  public_render(
    path:,
    db:,
    query_params:,
    dark_mode:,
    authentication_context:,
    can_access_admin:,
  )
}

@target(erlang)
pub fn public_render(
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: public_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
  can_access_admin can_access_admin: Bool,
) -> SsrApp {
  let route = public_routes.parse_path(path)
  let messages = public_boot_messages(db, route)
  let page =
    public_pages.load_sync(PageContext, query_params, route)
    |> public_boot.apply_messages(messages)

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
pub fn admin(
  req req: Request(Connection),
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: admin_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  session session: app_session.Session,
) -> SsrApp {
  let #(authentication_context, _) =
    boot_identity(req: req, db: db, session: session)

  admin_render(path:, db:, query_params:, dark_mode:, authentication_context:)
}

@target(erlang)
pub fn admin_render(
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: admin_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
) -> SsrApp {
  let route = admin_routes.parse_path(path)
  let messages = admin_boot_messages(db, route)
  let page =
    admin_pages.load_sync(PageContext, query_params, route)
    |> admin_boot.apply_messages(messages)

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
  session session: app_session.Session,
) -> #(Option(AuthenticationContext), Bool) {
  case app_auth_http.authenticated_user(req: req, db: db, session: session) {
    Ok(user) -> #(Some(user.context), app_auth.can_access_admin(user))
    Error(Nil) -> #(None, False)
  }
}

@target(erlang)
fn public_boot_messages(
  db: sqlight.Connection,
  route: public_routes.Route,
) -> List(to_client.ToClient) {
  dispatch_requests(
    db: db,
    requests: public_boot.requests(route),
    admin_authorized: False,
  )
}

@target(erlang)
fn admin_boot_messages(
  db: sqlight.Connection,
  route: admin_routes.Route,
) -> List(to_client.ToClient) {
  dispatch_requests(
    db: db,
    requests: admin_boot.requests(route),
    admin_authorized: True,
  )
}

@target(erlang)
fn dispatch_requests(
  db db: sqlight.Connection,
  requests requests: List(ToServer),
  admin_authorized admin_authorized: Bool,
) -> List(to_client.ToClient) {
  list.fold(requests, [], fn(messages, request) {
    list.append(
      messages,
      app_api.dispatch(
        db: db,
        message: request,
        admin_authorized: admin_authorized,
      ),
    )
  })
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
