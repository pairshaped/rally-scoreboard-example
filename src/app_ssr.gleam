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
import generated/rally/server_ssr

@target(erlang)
import gleam/http/request.{type Request}
@target(erlang)
import gleam/option.{type Option, None, Some}

@target(erlang)
import lustre/element
@target(erlang)
import mist.{type Connection}
@target(erlang)
import sqlight

@target(erlang)
import admin/pages/games as admin_games_page
@target(erlang)
import admin_boot
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
import page_context.{PageContext}
@target(erlang)
import public_boot

@target(javascript)
pub fn ensure() -> Nil {
  Nil
}

// TYPES

@target(erlang)
pub type SsrApp {
  SsrApp(html: String, hydration: List(String))
}

// PUBLIC

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
  let #(page, hydration) = public_boot_page(db, query_params, route)

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
    hydration: hydration,
  )
}

// ADMIN

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
  let #(page, hydration) = admin_boot_page(db, query_params, route)

  SsrApp(
    html: app_shell.admin(
      current_path: admin_routes.route_to_path(route),
      dark_mode: dark_mode,
      authentication_context: authentication_context,
      on_dark_mode_change: fn(_) { Nil },
      content: admin_pages.view(page) |> element.map(fn(_) { Nil }),
    )
      |> element.to_string,
    hydration: hydration,
  )
}

// HELPERS

@target(erlang)
fn public_boot_page(
  db db: sqlight.Connection,
  query_params query_params: public_page_input.QueryParams,
  route route: public_routes.Route,
) -> #(public_pages.Page, List(String)) {
  server_ssr.public_boot_page(
    page_context: PageContext,
    query_params:,
    route:,
    select_load: public_boot.ssr_load_route,
    handlers: public_load_handlers(db),
    update_page: public_pages.update,
  )
}

@target(erlang)
fn admin_boot_page(
  db db: sqlight.Connection,
  query_params query_params: admin_page_input.QueryParams,
  route route: admin_routes.Route,
) -> #(admin_pages.Page, List(String)) {
  server_ssr.admin_boot_page(
    page_context: PageContext,
    query_params:,
    route:,
    select_load: admin_boot.ssr_load_route,
    handlers: admin_load_handlers(db),
    update_page: fn(page, message) {
      admin_pages.update(PageContext, page, message)
    },
  )
}

@target(erlang)
fn public_load_handlers(
  db: sqlight.Connection,
) -> server_ssr.PublicLoadHandlers {
  server_ssr.PublicLoadHandlers(load_context: fn() { db })
}

@target(erlang)
fn admin_load_handlers(db: sqlight.Connection) -> server_ssr.AdminLoadHandlers {
  server_ssr.AdminLoadHandlers(admin_games_load: fn(_route) {
    admin_games_page.load_wire(db)
  })
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
