@target(erlang)
import app_auth
@target(erlang)
import app_auth_http
@target(erlang)
import app_shell
@target(erlang)
import authentication_context.{type AuthenticationContext}
@target(erlang)
import generated/proute/admin/page_input as admin_page_input
@target(erlang)
import generated/proute/public/page_input as public_page_input
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
import page_context.{PageContext}
@target(erlang)
import rally/runtime/auth_http
@target(erlang)
import rally/runtime/session
@target(erlang)
import sqlight

@target(javascript)
/// JavaScript-side compile anchor for the SSR module.
/// Browser builds can import this module without pulling in Erlang-only code.
pub fn ensure() -> Nil {
  Nil
}

// TYPES

@target(erlang)
/// SSR render result passed to app_document.
/// app_document sends html as the response body and embeds hydration into the
/// browser boot payload.
pub type SsrApp {
  SsrApp(
    html: String,
    hydration: List(String),
    authentication_context: Option(AuthenticationContext),
    can_access_admin: Bool,
  )
}

// PUBLIC

@target(erlang)
/// Public SSR entrypoint used by app_document.
/// It resolves request identity before delegating to public_render.
pub fn public(
  req req: Request(Connection),
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: public_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  session session: session.AuthSession,
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
/// Public SSR renderer for an already-resolved shell identity.
/// app_document reaches this through public, and tests can call it without
/// needing to build an HTTP request identity.
pub fn public_render(
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: public_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
  can_access_admin can_access_admin: Bool,
) -> SsrApp {
  let page =
    server_ssr.public_render_path(
      page_context: PageContext,
      query_params:,
      path:,
      load_context: db,
    )

  SsrApp(
    html: app_shell.public(
      current_path: page.current_path,
      dark_mode: dark_mode,
      authentication_context: authentication_context,
      can_access_admin: can_access_admin,
      on_dark_mode_change: fn(_) { Nil },
      content: page.content,
    )
      |> element.to_string,
    hydration: page.hydration,
    authentication_context: authentication_context,
    can_access_admin: can_access_admin,
  )
}

// ADMIN

@target(erlang)
/// Admin SSR entrypoint used by app_document.
/// It resolves request identity before delegating to admin_render.
pub fn admin(
  req req: Request(Connection),
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: admin_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  session session: session.AuthSession,
) -> SsrApp {
  let #(authentication_context, can_access_admin) =
    boot_identity(req: req, db: db, session: session)

  admin_render(
    path:,
    db:,
    query_params:,
    dark_mode:,
    authentication_context:,
    can_access_admin:,
  )
}

@target(erlang)
/// Admin SSR renderer for an already-resolved shell identity.
/// app_document reaches this through admin, and tests can call it without
/// needing to build an HTTP request identity.
pub fn admin_render(
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: admin_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
  can_access_admin can_access_admin: Bool,
) -> SsrApp {
  let page =
    server_ssr.admin_render_path(
      page_context: PageContext,
      query_params:,
      path:,
      load_context: db,
    )

  SsrApp(
    html: app_shell.admin(
      current_path: page.current_path,
      dark_mode: dark_mode,
      authentication_context: authentication_context,
      on_dark_mode_change: fn(_) { Nil },
      content: page.content,
    )
      |> element.to_string,
    hydration: page.hydration,
    authentication_context: authentication_context,
    can_access_admin: can_access_admin,
  )
}

// HELPERS

@target(erlang)
fn boot_identity(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: session.AuthSession,
) -> #(Option(AuthenticationContext), Bool) {
  case
    auth_http.authenticated_user(
      req: req,
      auth: app_auth_http.request_auth(db: db, session: session),
    )
  {
    Ok(user) -> #(Some(user.context), app_auth.can_access_admin(user))
    Error(Nil) -> #(None, False)
  }
}
