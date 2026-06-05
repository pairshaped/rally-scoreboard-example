@target(erlang)
import generated/proute/admin/page_input as admin_page_input
@target(erlang)
import generated/proute/public/page_input as public_page_input
@target(erlang)
import generated/rally/server_ssr
@target(erlang)
import gleam/list
@target(erlang)
import gleam/string
@target(erlang)
import gleeunit/should
@target(erlang)
import lustre/element
@target(erlang)
import page_context.{PageContext}
@target(erlang)
import sqlight
@target(erlang)
import support/test_db

@target(javascript)
pub fn ensure() -> Nil {
  Nil
}

@target(erlang)
pub fn generated_public_render_path_returns_shell_inputs_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "generated-public-render-path")
  let output =
    server_ssr.public_render_path(
      page_context: PageContext,
      query_params: public_page_input.empty_query_params(),
      path: "/games/",
      handlers: server_ssr.PublicLoadHandlers(load_context: fn() { db }),
    )

  output.current_path
  |> should.equal("/games")
  output.hydration
  |> list.length
  |> should.equal(1)
  output.content
  |> element.to_string
  |> string.contains("Toronto Towers")
  |> should.equal(True)

  close(db)
}

@target(erlang)
pub fn generated_admin_render_path_returns_shell_inputs_test() -> Nil {
  let assert Ok(db) = test_db.setup(name: "generated-admin-render-path")
  let output =
    server_ssr.admin_render_path(
      page_context: PageContext,
      query_params: admin_page_input.empty_query_params(),
      path: "/admin/games/",
      handlers: server_ssr.AdminLoadHandlers(load_context: fn() { db }),
    )

  output.current_path
  |> should.equal("/admin/games")
  output.hydration
  |> list.length
  |> should.equal(1)
  output.content
  |> element.to_string
  |> string.contains("TOR")
  |> should.equal(True)

  close(db)
}

@target(erlang)
fn close(db: sqlight.Connection) -> Nil {
  let assert Ok(_) = sqlight.close(db)
  Nil
}
