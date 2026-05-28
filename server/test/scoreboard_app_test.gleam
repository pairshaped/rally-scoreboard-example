//// Structural tests for the Scoreboard golden-path app.
////
//// These tests assert the desired root API shape directly against the example
//// files, independent of Generator Framework generator internals.

import generated/admin/route as admin_route
import generated/public/route as public_route
import generated/runtime/authentication as authentication_runtime
import generated/runtime/db
import generated/runtime/effect as server_effect
import generated/runtime/effect_runner
import generated/runtime/effect_state
import generated/runtime/jobs
import generated/runtime/ssr
import generated/runtime/system
import generated/runtime/system_db
import generated/runtime/trace
import gleam/bit_array
import gleam/bytes_tree
import gleam/dynamic/decode
import gleam/list
import gleam/option
import gleam/string
import gleeunit/should
import libero/error.{type DecodeError}
import libero/wire as libero_wire
import mist
import server/admin/authentication
import server/admin/client_context_loader as admin_client_context_loader
import server/authentication_context_loader
import server/public/client_context_loader as public_client_context_loader
import shared/admin/client_context.{type AdminClientContext, AdminClientContext}
import shared/authentication_context
import simplifile
import sqlight

pub fn server_entry_uses_generated_http_entry_test() {
  let source = read("src/scoreboard_server.gleam")

  source |> contains("mist.start") |> should.be_true
  source
  |> contains("entry.handle_request(req: req, server_context:)")
  |> should.be_true
  source |> contains("process.sleep_forever()") |> should.be_true
}

pub fn shell_uses_mount_client_and_oat_test() {
  let public_shell = read("src/server/public/shell.html")
  let admin_shell = read("src/server/admin/shell.html")

  public_shell |> contains("@knadh/oat/oat.min.css") |> should.be_true
  public_shell |> contains("data-runtime-client") |> should.be_true
  public_shell
  |> contains(
    "import { main } from \"/_build/client/scoreboard_public_client.mjs\"",
  )
  |> should.be_true
  public_shell
  |> contains("/_build/client/generated/app.mjs")
  |> should.be_false

  admin_shell |> contains("@knadh/oat/oat.min.css") |> should.be_true
  admin_shell |> contains(":root[data-theme=\"dark\"]") |> should.be_true
  admin_shell |> contains("scoreboard_dark_mode") |> should.be_true
  admin_shell |> contains("<body data-theme=\"dark\">") |> should.be_false
  admin_shell |> contains("data-runtime-client") |> should.be_true
  admin_shell
  |> contains(
    "import { main } from \"/_build/client/scoreboard_admin_client.mjs\"",
  )
  |> should.be_true
  admin_shell |> contains("/_build/client/generated/app.mjs") |> should.be_false
  public_shell |> contains(":root[data-theme=\"dark\"]") |> should.be_true
  public_shell |> contains("scoreboard_dark_mode") |> should.be_true
  public_shell |> contains("<body data-theme=\"dark\">") |> should.be_false
  public_shell |> contains("body[data-theme=\"dark\"]") |> should.be_false
}

pub fn generated_ssr_uses_mount_client_once_test() {
  let public_ssr = read("src/generated/public/ssr_handler.gleam")
  let admin_ssr = read("src/generated/admin/ssr_handler.gleam")

  public_ssr |> contains("scoreboard_public_client.mjs") |> should.be_true
  public_ssr |> contains("scoreboard_admin_client.mjs") |> should.be_false
  admin_ssr |> contains("scoreboard_admin_client.mjs") |> should.be_true
  admin_ssr |> contains("scoreboard_public_client.mjs") |> should.be_false
  public_ssr |> contains("const shell_path") |> should.be_true
  admin_ssr |> contains("const shell_path") |> should.be_true

  let ssr_runtime = read("src/generated/runtime/ssr.gleam")
  ssr_runtime |> contains("simplifile.read") |> should.be_true
}

pub fn static_handler_serves_the_whole_client_build_test() {
  let static_handler = read("src/generated/static_handler.gleam")

  static_handler
  |> contains("const url_prefix = \"/_build/\"")
  |> should.be_true
  static_handler
  |> contains("const filesystem_root = \"../client/build/dev/javascript\"")
  |> should.be_true
  file_exists("src/generated/admin/static_handler.gleam")
  |> should.be_false
  file_exists("src/generated/public/static_handler.gleam")
  |> should.be_false
}

pub fn public_root_route_renders_games_test() {
  let client_router = read("../client/src/generated/public/router.gleam")
  let server_router = read("src/generated/public/router.gleam")
  let setup = read("../client/src/generated/setup_ffi.mjs")

  client_router
  |> contains("[] -> route.Games")
  |> should.be_true
  server_router
  |> contains("[] -> route.Games")
  |> should.be_true
  setup
  |> contains("module: \"Games\", params: null")
  |> should.be_true
}

pub fn entry_uses_package_static_handler_for_all_mounts_test() {
  let entry = read("src/generated/entry.gleam")

  entry
  |> contains("import generated/static_handler")
  |> should.be_true
  entry
  |> contains("generated/admin/static_handler")
  |> should.be_false
  entry
  |> contains("generated/public/static_handler")
  |> should.be_false
  entry
  |> contains("static_handler.try_serve(path)")
  |> should.be_true
}

pub fn generated_client_setup_selects_mount_ws_and_page_init_test() {
  let setup = read("../client/src/generated/setup_ffi.mjs")

  setup |> contains("currentWsUrl()") |> should.be_true
  setup |> contains("return \"/admin/ws\"") |> should.be_true
  setup |> contains("return \"/ws\"") |> should.be_true
  setup |> contains("return null") |> should.be_true
  setup |> contains("transport.registerOnConnect") |> should.be_true
  setup
  |> contains("if (wsUrl && page) transport.send_page_init")
  |> should.be_true
  setup
  |> contains("if (wsUrl) transport.ensureSocket(wsUrl)")
  |> should.be_true
  setup |> contains("routePageInit()") |> should.be_true
  setup
  |> contains("if (wsUrl) transport.send(wsUrl, \"to_server\", msg)")
  |> should.be_true
  setup
  |> contains(
    "sendToServer: (msg) => transport.send(\"/ws\", \"to_server\", msg)",
  )
  |> should.be_false
}

pub fn generated_source_is_checked_into_the_example_test() {
  read("../client/src/generated/setup_ffi.mjs")
  read("../client/src/generated/public/router.gleam")
  read("../client/src/generated/admin/router.gleam")
  read("src/generated/entry.gleam")
  read("src/generated/ws_runtime.gleam")
  read("src/generated/public/ws_handler.gleam")
  read("src/generated/admin/ws_handler.gleam")
  read("../shared/src/generated/public/route.gleam")
  read("../shared/src/generated/admin/route.gleam")
  read("src/generated/protocol_wire.gleam")
  read("src/generated/server_generated_protocol_wire_ffi.erl")
}

pub fn rally_config_opts_mounts_into_local_logging_test() {
  let config = read("../rally.toml")

  config |> contains("namespace = \"public\"") |> should.be_true
  config |> contains("namespace = \"admin\"") |> should.be_true
  config |> contains("user_logging = true") |> should.be_true
  config |> contains("issue_logging = true") |> should.be_true
}

pub fn system_db_uses_user_and_issue_logs_test() {
  let source = read("src/generated/runtime/system_db.gleam")

  source |> contains("CREATE TABLE IF NOT EXISTS user_logs") |> should.be_true
  source |> contains("CREATE TABLE IF NOT EXISTS issue_logs") |> should.be_true
  source |> contains("CREATE TABLE IF NOT EXISTS messages") |> should.be_false
  source |> contains("user_email TEXT NOT NULL") |> should.be_true
  source |> contains("user_email TEXT") |> should.be_true
  source |> contains("route TEXT") |> should.be_true
  source |> contains("page TEXT") |> should.be_false
  source |> contains("created_at INTEGER NOT NULL") |> should.be_true
  source |> contains("timestamp INTEGER NOT NULL") |> should.be_false
  source |> contains("message_type TEXT NOT NULL") |> should.be_true
  source |> contains("action TEXT") |> should.be_false
  source |> contains("elapsed_ms") |> should.be_false
  source |> contains("INSERT INTO user_logs") |> should.be_true
  source |> contains("INSERT INTO issue_logs") |> should.be_true
  source |> contains("INSERT INTO messages") |> should.be_false
}

pub fn db_query_timing_logs_are_dev_only_test() {
  let source = read("src/generated/runtime/db.gleam")

  source |> contains("import generated/runtime/env") |> should.be_true
  source
  |> contains("use <- bool.guard(when: !env.is_dev(), return: Nil)")
  |> should.be_true
  source |> contains("add_db_timing") |> should.be_false
  source |> contains("get_db_timing") |> should.be_false
  source |> contains("init_db_timing") |> should.be_false
  file_exists("src/generated/runtime/server_generated_runtime_db_ffi.erl")
  |> should.be_false
}

pub fn system_db_connection_is_passed_explicitly_test() {
  let server = read("src/scoreboard_server.gleam")
  let context = read("src/server/server_context.gleam")
  let system = read("src/generated/runtime/system.gleam")
  let system_db = read("src/generated/runtime/system_db.gleam")

  server
  |> contains("server_context.new(db:, system_db: system_conn)")
  |> should.be_true
  context
  |> contains(
    "ServerContext(db: sqlight.Connection, system_db: sqlight.Connection)",
  )
  |> should.be_true
  system |> contains("db db: sqlight.Connection") |> should.be_true
  system |> contains("system_db.get_conn") |> should.be_false
  system_db |> contains("store_conn") |> should.be_false
  system_db |> contains("get_conn") |> should.be_false
  file_exists(
    "src/generated/runtime/server_generated_runtime_system_db_ffi.erl",
  )
  |> should.be_false
}

pub fn generated_sign_in_codes_use_uppercase_alphanumeric_text_test() {
  let source = read("src/generated/runtime/authentication.gleam")
  let secret_key = "test-secret"
  let code = authentication_runtime.generate_sign_in_code()
  let stored =
    authentication_runtime.hash_sign_in_code(
      scope: "Dana@example.com",
      code: " A1z9q ",
      secret_key:,
    )

  source
  |> contains(
    "const sign_in_code_alphabet = \"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ\"",
  )
  |> should.be_true
  source
  |> contains("let rejection_threshold = 256 / alphabet_size * alphabet_size")
  |> should.be_true
  source |> contains("|> string.uppercase") |> should.be_true
  code |> string.length |> should.equal(5)
  code
  |> string.to_graphemes
  |> list.all(fn(char) {
    string.contains("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", char)
  })
  |> should.be_true
  authentication_runtime.verify_sign_in_code(
    stored:,
    scope: " dana@EXAMPLE.com ",
    code: "a1Z9Q",
    secret_key:,
  )
  |> should.be_true
}

pub fn generated_authentication_helpers_are_exercised_test() {
  let password_hash = authentication_runtime.hash(secret: "scoreboard-secret")
  let demo_password_hash = authentication.password_hash()
  let demo_sign_in_code_hash = authentication.sign_in_code_hash()
  let assert Ok(try_password_hash) =
    authentication_runtime.try_hash(secret: "scoreboard-secret")
  let assert Ok(sign_in_code_hash) =
    authentication_runtime.try_hash_sign_in_code(
      scope: "Dana@example.com",
      code: "A1Z9Q",
      secret_key: "test-secret",
    )

  authentication_runtime.verify(
    stored: password_hash,
    secret: "scoreboard-secret",
  )
  |> should.be_true
  authentication_runtime.verify(
    stored: demo_password_hash,
    secret: authentication.password(),
  )
  |> should.be_true
  authentication_runtime.verify(
    stored: try_password_hash,
    secret: "scoreboard-secret",
  )
  |> should.be_true
  authentication_runtime.verify_sign_in_code(
    stored: sign_in_code_hash,
    scope: "dana@example.com",
    code: "a1z9q",
    secret_key: "test-secret",
  )
  |> should.be_true
  authentication.email() |> should.equal("admin@example.com")
  authentication.sign_in_code() |> string.length |> should.equal(5)
  authentication_runtime.verify_sign_in_code(
    stored: demo_sign_in_code_hash,
    scope: authentication.email(),
    code: authentication.sign_in_code(),
    secret_key: "scoreboard-demo-secret",
  )
  |> should.be_true

  authentication_policy_name(authentication_runtime.Required)
  |> should.equal("required")
  authentication_policy_name(authentication_runtime.Optional)
  |> should.equal("optional")

  let page_result: authentication_runtime.LoadResult(String) =
    authentication_runtime.Page(data: "ready", cookies: [
      authentication_runtime.SetCookie(name: "sid", value: "123", max_age: 60),
    ])
  let redirect_result: authentication_runtime.LoadResult(String) =
    authentication_runtime.Redirect(url: "/sign_in", cookies: [
      authentication_runtime.ClearCookie(name: "sid"),
    ])

  load_result_label(page_result) |> should.equal("page:ready")
  load_result_label(redirect_result) |> should.equal("redirect:/sign_in")
}

pub fn admin_mount_routes_through_authentication_test() {
  let entry = read("src/generated/entry.gleam")
  let admin_authentication = read("src/server/admin/authentication.gleam")

  entry |> contains("\"/admin/sign_in/password\"") |> should.be_true
  entry |> contains("\"/admin/sign_in/code\"") |> should.be_true
  entry |> contains("\"/admin/ws\"") |> should.be_true
  entry |> contains("admin_authenticated(req)") |> should.be_true
  entry
  |> contains("authentication.verify_password(email:, password:)")
  |> should.be_true
  entry
  |> contains("authentication.verify_sign_in_code(email:, code:)")
  |> should.be_true
  entry
  |> contains("set_cookie_header(authentication.issue_cookie(session_id:))")
  |> should.be_true
  entry
  |> contains("set_cookie_header(authentication.clear_cookie())")
  |> should.be_true
  entry |> contains("sign_in_html") |> should.be_false
  entry |> contains("response.prepend_header(") |> should.be_true

  admin_authentication
  |> contains("authentication_runtime.hash(")
  |> should.be_true
  admin_authentication
  |> contains("authentication_runtime.verify(")
  |> should.be_true
  admin_authentication
  |> contains("authentication_runtime.hash_sign_in_code(")
  |> should.be_true
  admin_authentication
  |> contains("authentication_runtime.verify_sign_in_code(")
  |> should.be_true
}

pub fn admin_sign_in_pages_are_client_routes_test() {
  let client = read("../client/src/scoreboard_admin_client.gleam")
  let route = read("../shared/src/generated/admin/route.gleam")
  let router = read("../client/src/generated/admin/router.gleam")
  let authentication_effect =
    read("../client/src/generated/runtime/authentication.gleam")
  let client_effect_ffi =
    read("../client/src/generated/runtime/client_effect_ffi.mjs")

  route |> contains("AdminSignInPassword") |> should.be_true
  route |> contains("AdminSignInCode") |> should.be_true
  router
  |> contains("[\"admin\", \"sign_in\", \"password\"]")
  |> should.be_true
  router
  |> contains("[\"admin\", \"sign_in\", \"code\"]")
  |> should.be_true
  client
  |> contains("admin_route.AdminSignInPassword")
  |> should.be_true
  client |> contains("admin_route.AdminSignInCode") |> should.be_true
  client
  |> contains("Demo account: admin@example.com / admin")
  |> should.be_true
  client |> contains("Demo sign-in code: A1Z9Q") |> should.be_true
  client
  |> contains("attribute.value(\"admin@example.com\")")
  |> should.be_true
  client |> contains("attribute.value(\"A1Z9Q\")") |> should.be_true
  client
  |> contains("attribute.action(\"/admin/sign_in\")")
  |> should.be_true
  client
  |> contains("|> event.prevent_default")
  |> should.be_true
  client
  |> contains("authentication.sign_out(path: \"/admin/sign_out\")")
  |> should.be_true
  client |> contains("event.on_click(SignOut)") |> should.be_true
  client
  |> contains("authentication_link(route: route, signed_in: signed_in)")
  |> should.be_true
  client
  |> contains("admin_link(route: route, signed_in: signed_in)")
  |> should.be_true
  client
  |> contains("ui.nav_link_external(path: \"/admin/games\", label: \"Admin\"")
  |> should.be_true
  client |> contains("True -> sign_out_link()") |> should.be_true
  client |> contains("False -> sign_in_link(route)") |> should.be_true
  authentication_effect
  |> contains("pub fn sign_out(path path: String)")
  |> should.be_true
  authentication_effect |> contains("@external(javascript") |> should.be_true
  client_effect_ffi
  |> contains("export function signOut(path)")
  |> should.be_true
  client_effect_ffi
  |> contains("globalThis.location.assign(path)")
  |> should.be_true
}

pub fn generated_files_stay_under_top_level_generated_dirs_test() {
  file_exists("src/generated/sql/server/games_sql.gleam") |> should.be_true
  file_exists("src/generated/sql/games_sql.gleam") |> should.be_false
  file_exists("src/server/generated/sql/server/games_sql.gleam")
  |> should.be_false
  file_exists("../client/src/client/public/generated/router.gleam")
  |> should.be_false
  file_exists("../client/src/client/admin/generated/router.gleam")
  |> should.be_false
  file_exists("../shared/src/generated/public/runtime/data.gleam")
  |> should.be_false
  file_exists("../shared/src/generated/admin/runtime/data.gleam")
  |> should.be_false
  file_exists("src/generated/public/page_dispatch.gleam") |> should.be_false
  file_exists("src/generated/admin/page_dispatch.gleam") |> should.be_false
  file_exists("src/generated/public/rpc_dispatch.gleam") |> should.be_false
  file_exists("src/generated/admin/rpc_dispatch.gleam") |> should.be_false
  file_exists("src/generated/runtime/dispatch.gleam") |> should.be_false
  file_exists("src/generated/public/receiver_dispatch.gleam")
  |> should.be_false
  file_exists("src/generated/admin/receiver_dispatch.gleam")
  |> should.be_false
}

pub fn generated_ws_handlers_delegate_to_package_runtime_test() {
  let runtime = read("src/generated/ws_runtime.gleam")
  let public_handler = read("src/generated/public/ws_handler.gleam")
  let admin_handler = read("src/generated/admin/ws_handler.gleam")

  runtime |> contains("pub fn on_init(") |> should.be_true
  runtime |> contains("pub fn handler(") |> should.be_true
  runtime |> contains("server/admin") |> should.be_false
  runtime |> contains("server/public") |> should.be_false
  runtime |> contains("generated/admin") |> should.be_false
  runtime |> contains("generated/public") |> should.be_false

  admin_handler |> contains("import generated/ws_runtime") |> should.be_true
  admin_handler |> contains("import server/admin/backend") |> should.be_true
  admin_handler |> contains("import generated/admin/route") |> should.be_true
  admin_handler
  |> contains("import generated/admin/request_context")
  |> should.be_true
  admin_handler
  |> contains("import generated/runtime/live_updates")
  |> should.be_true
  admin_handler |> contains("live_updates.join()") |> should.be_true
  admin_handler |> contains("ws_runtime.handler(") |> should.be_true

  public_handler |> contains("import generated/ws_runtime") |> should.be_true
  public_handler |> contains("import server/public/backend") |> should.be_true
  public_handler |> contains("import generated/public/route") |> should.be_true
  public_handler
  |> contains("import generated/public/request_context")
  |> should.be_true
  public_handler |> contains("ws_runtime.handler(") |> should.be_true
}

pub fn mount_clients_use_generated_routers_and_effects_test() {
  let public_client = read("../client/src/scoreboard_public_client.gleam")
  let admin_client = read("../client/src/scoreboard_admin_client.gleam")
  let client_ui = read("../shared/src/shared/components/ui.gleam")
  let client_effect = read("../client/src/generated/runtime/effect.gleam")
  let client_effect_ffi =
    read("../client/src/generated/runtime/client_effect_ffi.mjs")

  public_client |> contains("import modem") |> should.be_true
  public_client |> contains("modem.initial_uri()") |> should.be_true
  public_client
  |> contains("|> result.map(public_router.parse_uri)")
  |> should.be_true
  public_client
  |> contains("modem.Options(")
  |> should.be_true
  public_client
  |> contains("handle_internal_links: False")
  |> should.be_true
  public_client |> contains("UrlChanged(Uri)") |> should.be_true
  public_client
  |> contains("transport.register_push_handler(\"to_client\"")
  |> should.be_true
  public_client
  |> contains("public_receiver_dispatch.to_client(event)")
  |> should.be_true
  public_client
  |> contains("public_effect.send_page_init_and_command(")
  |> should.be_true
  public_client |> contains("public_effect.read_dark_mode()") |> should.be_true
  public_client
  |> contains("public_effect.set_dark_mode(enabled)")
  |> should.be_true
  public_client
  |> contains("ui.theme_switch(dark_mode, SetDarkMode)")
  |> should.be_true
  client_ui |> contains("event.on_check(on_change)") |> should.be_true
  client_ui |> contains("attribute.role(\"switch\")") |> should.be_true
  client_ui |> contains("sun_icon()") |> should.be_true
  client_ui |> contains("moon_icon()") |> should.be_true
  client_effect |> contains("pub fn set_dark_mode") |> should.be_true
  client_effect |> contains("pub fn read_dark_mode") |> should.be_true
  client_effect_ffi |> contains("export function setDarkMode") |> should.be_true
  client_effect_ffi
  |> contains("document.documentElement.dataset.theme")
  |> should.be_true

  admin_client |> contains("import modem") |> should.be_true
  admin_client |> contains("modem.initial_uri()") |> should.be_true
  admin_client
  |> contains("|> result.map(admin_router.parse_uri)")
  |> should.be_true
  admin_client
  |> contains("modem.Options(")
  |> should.be_true
  admin_client
  |> contains("handle_internal_links: False")
  |> should.be_true
  admin_client |> contains("UrlChanged(Uri)") |> should.be_true
  admin_client
  |> contains("transport.register_push_handler(\"to_client\"")
  |> should.be_true
  admin_client
  |> contains("admin_receiver_dispatch.to_client(event)")
  |> should.be_true
  admin_client
  |> contains("admin_effect.send_page_init_and_command(")
  |> should.be_true
  admin_client |> contains("admin_effect.read_dark_mode()") |> should.be_true
  admin_client
  |> contains("admin_effect.set_dark_mode(enabled)")
  |> should.be_true
  admin_client
  |> contains("ui.theme_switch(dark_mode, SetDarkMode)")
  |> should.be_true
}

pub fn mount_clients_do_not_import_the_opposite_api_test() {
  let public_client = read("../client/src/scoreboard_public_client.gleam")
  let admin_client = read("../client/src/scoreboard_admin_client.gleam")
  let global_codec = read("../client/src/generated/codec_ffi.mjs")

  public_client |> contains("shared/api/admin") |> should.be_false
  public_client |> contains("client/admin") |> should.be_false
  admin_client |> contains("shared/api/public") |> should.be_false
  admin_client |> contains("client/public") |> should.be_false

  global_codec |> contains("shared/api/public") |> should.be_false
  global_codec |> contains("shared/api/admin") |> should.be_false
}

pub fn generated_browser_imports_stay_inside_static_build_prefix_test() {
  let codec_ffi = read("../client/src/generated/codec_ffi.mjs")

  codec_ffi |> contains("from \"../../libero/") |> should.be_true
  codec_ffi
  |> contains("from \"../../scoreboard_shared/")
  |> should.be_true
  codec_ffi |> contains("from \"../../../libero/") |> should.be_false
  codec_ffi
  |> contains("from \"../../../scoreboard_shared/")
  |> should.be_false
}

pub fn admin_save_updates_do_not_refetch_the_games_list_test() {
  let admin_client = read("../client/src/scoreboard_admin_client.gleam")

  count(admin_client, "admin_to_server.LoadAdminGames") |> should.equal(1)
  admin_client
  |> contains("games: upsert_game(games: model.games, detail: game)")
  |> should.be_true
}

pub fn admin_final_games_do_not_show_final_action_test() {
  let admin_client = read("../client/src/scoreboard_admin_client.gleam")
  let admin_games_page = read("../shared/src/shared/admin/pages/games.gleam")

  admin_games_page
  |> contains("fn final_action")
  |> should.be_true
  admin_games_page
  |> contains("Final -> html.span([], [])")
  |> should.be_true
  admin_games_page
  |> contains("[html.text(\"Finalize\")]")
  |> should.be_true
  admin_client
  |> contains("MarkFinal(game_id)")
  |> should.be_true
}

pub fn admin_score_controls_live_next_to_team_names_test() {
  let admin_client = read("../client/src/scoreboard_admin_client.gleam")
  let admin_games_page = read("../shared/src/shared/admin/pages/games.gleam")
  let admin_shell = read("src/server/admin/shell.html")

  admin_games_page
  |> contains("attribute.class(\"admin-score-row\")")
  |> should.be_true
  admin_client
  |> contains("AdjustAway(game_id, home_score, away_score, delta)")
  |> should.be_true
  admin_client
  |> contains("AdjustHome(game_id, home_score, away_score, delta)")
  |> should.be_true
  admin_client
  |> contains("clamp_score(home_score + delta)")
  |> should.be_true
  admin_shell
  |> contains("grid-template-columns: minmax(7ch, 1fr) 32px 32px 4ch;")
  |> should.be_true
  admin_shell
  |> contains(".admin-score-row .score")
  |> should.be_true
  admin_shell
  |> contains(".admin-status-row")
  |> should.be_true
}

pub fn to_server_frames_are_fire_and_forget_test() {
  let runtime = read("src/generated/ws_runtime.gleam")
  let public_handler = read("src/generated/public/ws_handler.gleam")
  let admin_handler = read("src/generated/admin/ws_handler.gleam")
  let setup = read("../client/src/generated/setup_ffi.mjs")
  let transport = read("../client/src/generated/transport_ffi.mjs")

  runtime
  |> contains("Ok(#(\"to_server\", _request_id, _value))")
  |> should.be_true
  runtime
  |> contains("to_server_ack")
  |> should.be_false

  admin_handler
  |> contains("Ok(#(\"to_server\", _request_id, _value))")
  |> should.be_false
  public_handler
  |> contains("Ok(#(\"to_server\", _request_id, _value))")
  |> should.be_false
  admin_handler
  |> contains("to_server_ack")
  |> should.be_false
  public_handler
  |> contains("to_server_ack")
  |> should.be_false

  setup
  |> contains("if (wsUrl) transport.send(wsUrl, \"to_server\", msg)")
  |> should.be_true
  transport
  |> contains("const expectsResponse = typeof callback === \"function\"")
  |> should.be_false
  transport
  |> contains("responseCallbacks")
  |> should.be_false
  transport
  |> contains("rpcErrorHandler")
  |> should.be_false
  transport
  |> contains("RPC #")
  |> should.be_false
  transport
  |> contains("logFrame(\"->\", `command #${requestId}`")
  |> should.be_true
}

pub fn generated_runtime_has_no_legacy_rpc_or_generic_push_api_test() {
  let server_effect = read("src/generated/runtime/effect.gleam")
  let protocol_wire = read("src/generated/protocol_wire.gleam")
  let runtime = read("src/generated/ws_runtime.gleam")
  let public_ws = read("src/generated/public/ws_handler.gleam")
  let admin_ws = read("src/generated/admin/ws_handler.gleam")

  server_effect |> contains("pub fn rpc") |> should.be_false
  protocol_wire |> contains("pub fn encode_push") |> should.be_false
  protocol_wire |> contains("RpcEnvelope") |> should.be_false
  protocol_wire |> contains("RpcResult") |> should.be_false
  protocol_wire |> contains("decode_rpc_envelope") |> should.be_false
  protocol_wire |> contains("decode_ws_rpc_envelope") |> should.be_false
  protocol_wire |> contains("send_rpc_result") |> should.be_false
  protocol_wire |> contains("rpc_result_body") |> should.be_false
  protocol_wire |> contains("rpc_content_type") |> should.be_false
  protocol_wire |> contains("malformed_rpc_result") |> should.be_false
  runtime |> contains("decode_ws_rpc_envelope") |> should.be_false
  runtime |> contains("page_dispatch") |> should.be_false
  public_ws |> contains("decode_ws_rpc_envelope") |> should.be_false
  admin_ws |> contains("decode_ws_rpc_envelope") |> should.be_false
  public_ws |> contains("page_dispatch") |> should.be_false
  admin_ws |> contains("page_dispatch") |> should.be_false
}

pub fn client_same_mount_links_use_spa_navigation_test() {
  let public_client = read("../client/src/scoreboard_public_client.gleam")
  let admin_client = read("../client/src/scoreboard_admin_client.gleam")

  public_client
  |> contains("Navigate(public_route.Route)")
  |> should.be_true
  public_client
  |> contains("modem.push(public_router.route_to_path(route:), None, None)")
  |> should.be_true
  public_client
  |> contains("let route = public_router.parse_uri(uri)")
  |> should.be_true
  { count(public_client, "|> event.prevent_default") >= 1 }
  |> should.be_true
  public_client
  |> contains("ui.nav_link_external(path: \"/admin/games\", label: \"Admin\"")
  |> should.be_true

  admin_client
  |> contains("Navigate(admin_route.Route)")
  |> should.be_true
  admin_client
  |> contains("modem.push(admin_router.route_to_path(route:), None, None)")
  |> should.be_true
  admin_client
  |> contains("let route = admin_router.parse_uri(uri)")
  |> should.be_true
  { count(admin_client, "|> event.prevent_default") >= 1 }
  |> should.be_true
  admin_client
  |> contains("ui.nav_link_external(path: \"/games\", label: \"Games\"")
  |> should.be_true
  admin_client
  |> contains("path: \"/standings\"")
  |> should.be_true
  admin_client
  |> contains("authentication.sign_out(path: \"/admin/sign_out\")")
  |> should.be_true
}

pub fn public_routes_have_matching_page_handlers_test() {
  read("src/server/public/pages/games.gleam")
  read("src/server/public/pages/games/id_.gleam")
  read("src/server/public/pages/standings.gleam")

  let dispatch = read("src/generated/public/dispatch.gleam")
  dispatch
  |> contains("server_public_pages_games.load_games")
  |> should.be_true
  dispatch
  |> contains("server_public_pages_games_id_.load_game")
  |> should.be_true
  dispatch
  |> contains("server_public_pages_standings.load_standings")
  |> should.be_true
}

pub fn generated_db_helpers_are_exercised_test() {
  let assert Ok(conn) = db.open(":memory:")
  let assert Ok(Nil) =
    sqlight.exec("CREATE TABLE checks (active INTEGER, note TEXT);", on: conn)
  let assert Ok(Nil) =
    db.transaction(conn, fn() {
      sqlight.exec(
        "INSERT INTO checks (active, note) VALUES (1, 'ready');",
        on: conn,
      )
    })

  let assert Ok(rows) =
    db.query(
      sql: "SELECT active, note FROM checks WHERE active = ?1 AND note = ?2",
      on: conn,
      with: [db.bool_to_int(True), db.nullable_text(option.Some("ready"))],
      expecting: {
        use active <- decode.field(0, decode.int)
        use note <- decode.field(1, decode.string)
        decode.success(#(active, note))
      },
    )

  db.one(rows) |> should.equal(option.Some(#(1, "ready")))
}

pub fn generated_system_logs_and_jobs_are_exercised_test() {
  let assert Ok(conn) = system_db.open(":memory:")

  system_db.log_user(
    db: conn,
    user_id: 7,
    user_email: "admin@example.com",
    session_id: "session-1",
    mount: "admin",
    route: Ok("/admin/games"),
    message_type: "UpdateScore",
  )
  system_db.log_issue(
    db: conn,
    session_id: Ok("session-1"),
    user_id: Ok(7),
    user_email: Ok("admin@example.com"),
    mount: "admin",
    route: Ok("/admin/games"),
    kind: "handler_error",
    message: "could not save score",
    message_type: Ok("UpdateScore"),
    trace: Ok("trace-1"),
    context: Error(Nil),
  )
  system.enqueue_now(db: conn, name: "refresh", payload: <<"{}":utf8>>)
  system.enqueue_in(
    db: conn,
    name: "refresh-later",
    payload: <<"{}":utf8>>,
    delay_seconds: 60,
  )
  system.enqueue(
    db: conn,
    name: "refresh-at",
    payload: <<"{}":utf8>>,
    run_at: 0,
  )
  jobs.enqueue(db: conn, name: "job-direct", payload: <<"{}":utf8>>, run_at: 0)
  let _run_once = jobs.run_once
  let _run_once_at = jobs.run_once_at
  let queued_job =
    jobs.Job(id: 1, name: "demo", payload: <<"{}":utf8>>, attempts: 0)
  let jobs.Job(name: job_name, ..) = queued_job
  job_name |> should.equal("demo")
  let _supervised =
    system.supervised_job_runner(path: ":memory:", handler: fn(_name, _payload) {
      Ok(Nil)
    })
  let _start_job_runner = system.start_job_runner

  system_db.user_log_count(conn) |> should.equal(1)
  system_db.issue_log_count(conn) |> should.equal(1)
}

pub fn generated_runtime_helpers_are_exercised_test() {
  let Nil = effect_state.put_ws_state("conn", "server-context", "Games")
  effect_state.get_ws_page() |> should.equal("Games")
  effect_state.get_ws_conn() |> should.equal(Ok("conn"))
  effect_state.get_stored_server_context() |> should.equal(Ok("server-context"))

  let Nil = effect_state.put_ws_session("session-1")
  let Nil = effect_state.put_ws_hostname("localhost")
  let Nil = effect_state.put_ws_request_context("request-context")
  let Nil = effect_state.put_ws_identity("admin@example.com")
  let Nil = effect_state.put_ws_authentication_timestamp(123)
  let Nil = effect_state.put_ws_server_shared_state("shared")
  let Nil = effect_state.put_backend_model("model")
  effect_state.get_ws_session() |> should.equal("session-1")
  effect_state.get_ws_hostname() |> should.equal("localhost")
  effect_state.get_ws_request_context() |> should.equal(Ok("request-context"))
  effect_state.get_ws_identity() |> should.equal(Ok("admin@example.com"))
  effect_state.get_ws_authentication_timestamp() |> should.equal(123)
  effect_state.get_ws_server_shared_state() |> should.equal(Ok("shared"))
  effect_state.get_backend_model() |> should.equal(Ok("model"))

  let Nil = effect_state.clear_ws_authentication_state()
  effect_state.get_ws_identity() |> should.equal(Error(Nil))
  effect_state.get_ws_authentication_timestamp() |> should.equal(0)

  let Nil = effect_state.push_outgoing_frame(<<"one":utf8>>)
  let Nil = effect_state.push_outgoing_frame(<<"two":utf8>>)
  effect_state.drain_outgoing_frames()
  |> should.equal([<<"one":utf8>>, <<"two":utf8>>])

  let _run_to_client_effect = effect_runner.run_to_client_effect
  let _none = server_effect.none
  let _batch = server_effect.batch
  let _send_to_server = server_effect.send_to_server
  let _navigate = server_effect.navigate
  let _set_dark_mode = server_effect.set_dark_mode
  let _set_lang = server_effect.set_lang
  let _read_dark_mode = server_effect.read_dark_mode
  let _read_lang = server_effect.read_lang
}

pub fn generated_trace_helpers_are_exercised_test() {
  trace.try_call(fn() { "ok" }) |> should.equal(Ok("ok"))
  { trace.new_trace_id() |> string.length > 0 } |> should.be_true
}

pub fn admin_ssr_handler_loads_and_encodes_client_context_test() {
  let admin_ssr = read("src/generated/admin/ssr_handler.gleam")
  let admin_loader = read("src/server/admin/client_context_loader.gleam")

  admin_ssr
  |> contains("import server/admin/client_context_loader")
  |> should.be_true
  admin_ssr |> contains("client_context_loader.load(") |> should.be_true
  admin_ssr
  |> contains("libero_wire.encode_flags(context)")
  |> should.be_true
  admin_ssr |> contains("client_context_base64:") |> should.be_true
  admin_loader |> contains("authentication_context") |> should.be_true
  admin_loader
  |> contains("league_name: \"Rally Rec League\"")
  |> should.be_true
}

pub fn public_ssr_handler_loads_and_encodes_client_context_test() {
  let public_ssr = read("src/generated/public/ssr_handler.gleam")
  let public_loader = read("src/server/public/client_context_loader.gleam")

  public_ssr
  |> contains("import server/public/client_context_loader")
  |> should.be_true
  public_ssr |> contains("client_context_loader.load(") |> should.be_true
  public_ssr
  |> contains("libero_wire.encode_flags(context)")
  |> should.be_true
  public_ssr |> contains("client_context_base64:") |> should.be_true
  public_loader
  |> contains("league_name: \"Rally Rec League\"")
  |> should.be_true
}

pub fn ssr_runtime_injects_client_context_into_shell_test() {
  let runtime = read("src/generated/runtime/ssr.gleam")

  runtime |> contains("window.__RUNTIME_CLIENT_CONTEXT__") |> should.be_true
  runtime |> contains("client_context_base64") |> should.be_true
}

pub fn admin_and_public_client_contexts_are_different_types_test() {
  let admin_ctx = read("../shared/src/shared/admin/client_context.gleam")
  let public_ctx = read("../shared/src/shared/public/client_context.gleam")

  admin_ctx |> contains("AuthenticationContext") |> should.be_true
  admin_ctx |> contains("dark_mode: Bool") |> should.be_true
  admin_ctx |> contains("toast: Option(String)") |> should.be_true

  public_ctx |> contains("AuthenticationContext") |> should.be_false
  public_ctx |> contains("dark_mode: Bool") |> should.be_false
  public_ctx |> contains("toast: Option(String)") |> should.be_false
}

pub fn ssr_shell_embeds_context_base64_in_response_body_test() {
  let resp =
    ssr.render_shell_response(
      shell_path: "src/server/admin/shell.html",
      page_html: "<p>test</p>",
      shared_state_base64: "",
      client_context_base64: "dGVzdC1jb250ZXh0",
      fallback_shell: "<html><head></head><body><div id=\"app\"></div></body></html>",
    )
  case resp.body {
    mist.Bytes(tree) -> {
      let bits = bytes_tree.to_bit_array(tree)
      let assert Ok(html) = bit_array.to_string(bits)
      html
      |> contains("window.__RUNTIME_CLIENT_CONTEXT__='dGVzdC1jb250ZXh0'")
      |> should.be_true
    }
    _ -> should.be_true(False)
  }
}

pub fn ssr_context_roundtrips_through_encode_embed_decode_test() {
  let auth_ctx =
    authentication_context.AuthenticationContext(
      user_id: 1,
      email: "admin@example.com",
      display_name: option.None,
    )
  let context =
    AdminClientContext(
      authentication_context: option.Some(auth_ctx),
      league_name: "Rally Rec League",
      dark_mode: False,
      active_section: "games",
      toast: option.None,
    )

  let encoded = libero_wire.encode_flags(context)
  let result: Result(AdminClientContext, DecodeError) =
    libero_wire.decode_flags_typed(encoded, "admin_client_context")
  let assert Ok(decoded) = result

  case decoded.authentication_context {
    option.Some(ac) -> {
      ac.user_id |> should.equal(1)
      ac.email |> should.equal("admin@example.com")
    }
    option.None -> should.be_true(False)
  }
  decoded.league_name |> should.equal("Rally Rec League")
  decoded.dark_mode |> should.equal(False)
  decoded.active_section |> should.equal("games")
}

pub fn client_setup_exposes_read_client_context_test() {
  let setup_gleam = read("../client/src/generated/setup.gleam")
  let setup_js = read("../client/src/generated/setup_ffi.mjs")

  setup_gleam |> contains("read_client_context") |> should.be_true
  setup_js |> contains("readClientContext") |> should.be_true
  setup_js |> contains("__RUNTIME_CLIENT_CONTEXT__") |> should.be_true
  setup_js |> contains("ssrWindow") |> should.be_true
}

pub fn client_context_constructors_are_registered_for_etf_test() {
  let codec = read("../client/src/generated/codec_ffi.mjs")
  let atoms = read("src/generated/server_generated_protocol_atoms_ffi.erl")

  codec |> contains("authentication_context") |> should.be_true
  codec |> contains("admin_client_context") |> should.be_true
  codec |> contains("public_client_context") |> should.be_true
  codec
  |> contains("authenticationContext.AuthenticationContext, 3")
  |> should.be_true
  codec
  |> contains("adminClientContext.AdminClientContext, 5")
  |> should.be_true
  codec
  |> contains("publicClientContext.PublicClientContext, 2")
  |> should.be_true
  atoms |> contains("<<\"authentication_context\">>") |> should.be_true
  atoms |> contains("<<\"admin_client_context\">>") |> should.be_true
  atoms |> contains("<<\"public_client_context\">>") |> should.be_true
}

pub fn admin_client_stores_and_renders_context_test() {
  let admin_client = read("../client/src/scoreboard_admin_client.gleam")

  admin_client
  |> contains("import shared/admin/client_context.{type AdminClientContext}")
  |> should.be_true
  admin_client
  |> contains("context: Option(AdminClientContext)")
  |> should.be_true
  admin_client |> contains("setup.read_client_context()") |> should.be_true
  admin_client
  |> contains("authentication_context.display_label(ac)")
  |> should.be_true
  admin_client |> contains("ctx.league_name <> \" admin\"") |> should.be_true
}

pub fn public_client_stores_context_test() {
  let public_client = read("../client/src/scoreboard_public_client.gleam")

  public_client
  |> contains("import shared/public/client_context.{type PublicClientContext}")
  |> should.be_true
  public_client
  |> contains("context: Option(PublicClientContext)")
  |> should.be_true
  public_client |> contains("setup.read_client_context()") |> should.be_true
  public_client |> contains("ctx.league_name") |> should.be_true
}

pub fn entry_passes_authentication_context_to_admin_ssr_test() {
  let entry = read("src/generated/entry.gleam")
  let admin_ssr = read("src/generated/admin/ssr_handler.gleam")

  entry
  |> contains("import server/authentication_context_loader")
  |> should.be_true
  entry
  |> contains("authentication_context_loader.from_user_id(user_id)")
  |> should.be_true
  entry
  |> contains("authentication_context: authentication_context")
  |> should.be_true
  admin_ssr
  |> contains("authentication_context: Option(AuthenticationContext)")
  |> should.be_true
  admin_ssr
  |> contains("authentication_context:,")
  |> should.be_true
}

pub fn authentication_context_type_has_expected_shape_and_helper_test() {
  let source = read("../shared/src/shared/authentication_context.gleam")

  source |> contains("user_id: Int") |> should.be_true
  source |> contains("email: String") |> should.be_true
  source |> contains("display_name: Option(String)") |> should.be_true
  source |> contains("pub fn display_label(") |> should.be_true

  let ctx =
    authentication_context.AuthenticationContext(
      user_id: 1,
      email: "admin@example.com",
      display_name: option.None,
    )
  authentication_context.display_label(ctx)
  |> should.equal("admin@example.com")

  let named_ctx =
    authentication_context.AuthenticationContext(
      user_id: 2,
      email: "fan@example.com",
      display_name: option.Some("Fan"),
    )
  authentication_context.display_label(named_ctx)
  |> should.equal("Fan")
}

pub fn normalize_email_trims_whitespace_and_lowercases_test() {
  authentication_context.normalize_email(" Admin@Example.com ")
  |> should.equal("admin@example.com")
  authentication_context.normalize_email("admin@example.com")
  |> should.equal("admin@example.com")
  authentication_context.normalize_email("  ADMIN@EXAMPLE.COM  ")
  |> should.equal("admin@example.com")
}

pub fn normalize_display_name_trims_and_rejects_blank_test() {
  authentication_context.normalize_display_name("Dana")
  |> should.equal(option.Some("Dana"))
  authentication_context.normalize_display_name("  Dana  ")
  |> should.equal(option.Some("Dana"))
  authentication_context.normalize_display_name("")
  |> should.equal(option.None)
  authentication_context.normalize_display_name("   ")
  |> should.equal(option.None)
}

pub fn authentication_context_loader_returns_demo_users_test() {
  let admin = authentication_context_loader.from_user_id(1)
  case admin {
    option.Some(ctx) -> {
      ctx.user_id |> should.equal(1)
      ctx.email |> should.equal("admin@example.com")
      ctx.display_name |> should.equal(option.None)
    }
    option.None -> should.be_true(False)
  }

  let fan = authentication_context_loader.from_user_id(2)
  case fan {
    option.Some(ctx) -> {
      ctx.user_id |> should.equal(2)
      ctx.email |> should.equal("fan@example.com")
      ctx.display_name |> should.equal(option.Some("Fan"))
    }
    option.None -> should.be_true(False)
  }

  authentication_context_loader.from_user_id(99)
  |> should.equal(option.None)
}

pub fn admin_context_loader_passes_authentication_context_through_test() {
  let auth_ctx =
    authentication_context.AuthenticationContext(
      user_id: 1,
      email: "admin@example.com",
      display_name: option.None,
    )

  let ctx =
    admin_client_context_loader.load(
      route: admin_route.AdminGames,
      authentication_context: option.Some(auth_ctx),
      dark_mode: False,
    )
  case ctx.authentication_context {
    option.Some(ac) -> {
      ac.user_id |> should.equal(1)
      ac.email |> should.equal("admin@example.com")
    }
    option.None -> should.be_true(False)
  }
  ctx.league_name |> should.equal("Rally Rec League")
  should.equal(ctx.dark_mode, False)
  ctx.active_section |> should.equal("games")
}

pub fn admin_context_loader_returns_none_authentication_for_sign_in_routes_test() {
  let ctx =
    admin_client_context_loader.load(
      route: admin_route.AdminSignInPassword,
      authentication_context: option.None,
      dark_mode: False,
    )
  case ctx.authentication_context {
    option.Some(_) -> should.be_true(False)
    option.None -> Nil
  }
  ctx.active_section |> should.equal("sign_in")
}

pub fn public_context_loader_returns_expected_shape_test() {
  let ctx = public_client_context_loader.load(route: public_route.Games)
  ctx.league_name |> should.equal("Rally Rec League")
  ctx.active_section |> should.equal("games")

  let standings_ctx =
    public_client_context_loader.load(route: public_route.Standings)
  standings_ctx.active_section |> should.equal("standings")
}

fn read(path: String) -> String {
  let assert Ok(source) = simplifile.read(path)
  source
}

fn file_exists(path: String) -> Bool {
  case simplifile.is_file(path) {
    Ok(True) -> True
    _ -> False
  }
}

fn contains(source: String, needle: String) -> Bool {
  string.contains(source, needle)
}

fn count(source: String, needle: String) -> Int {
  count_from(source, needle, 0)
}

fn count_from(source: String, needle: String, total: Int) -> Int {
  case string.split_once(source, needle) {
    Ok(#(_before, after)) -> count_from(after, needle, total + 1)
    Error(Nil) -> total
  }
}

fn load_result_label(
  result: authentication_runtime.LoadResult(String),
) -> String {
  case result {
    authentication_runtime.Page(data:, cookies:) -> {
      let _cookies = cookies
      "page:" <> data
    }
    authentication_runtime.Redirect(url:, cookies:) -> {
      let _cookies = cookies
      "redirect:" <> url
    }
  }
}

fn authentication_policy_name(
  policy: authentication_runtime.AuthenticationPolicy,
) -> String {
  case policy {
    authentication_runtime.Required -> "required"
    authentication_runtime.Optional -> "optional"
  }
}
