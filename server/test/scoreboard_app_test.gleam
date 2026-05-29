//// Structural tests for the Scoreboard golden-path app.
////
//// These tests assert the desired root API shape directly against the example
//// files, independent of Generator Framework generator internals.

import generated/admin/request_context.{RequestContext}
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
import gleam/dict
import gleam/dynamic/decode
import gleam/list
import gleam/option
import gleam/string
import gleeunit/should
import libero/error.{type DecodeError}
import libero/wire as libero_wire
import mist
import server/admin/authentication
import server/admin/client_shared_state_loader as admin_client_shared_state_loader
import server/admin/model.{Model}
import server/admin/pages/games as admin_games_handler
import server/authentication_context_loader
import server/helpers/domain
import server/public/client_shared_state_loader as public_client_shared_state_loader
import server/server_context.{ServerContext}
import shared/admin/client_shared_state.{
  type AdminClientSharedState, AdminClientSharedState,
}
import shared/api/domain/game
import shared/api/to_client
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
  |> contains("server_context.new(db: app_db, system_db: system_conn)")
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
  let demo_sign_in_code_hash =
    authentication_runtime.hash_sign_in_code(
      scope: "admin@example.com",
      code: "A1Z9Q",
      secret_key: "scoreboard-demo-secret",
    )
  let assert Ok(sign_in_code_hash) =
    authentication_runtime.try_hash_sign_in_code(
      scope: "Dana@example.com",
      code: "A1Z9Q",
      secret_key: "test-secret",
    )

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

  entry |> contains("\"/sign_in\"") |> should.be_true
  entry |> contains("\"/sign_in/password\"") |> should.be_false
  entry |> contains("\"/sign_in/code\"") |> should.be_false
  entry |> contains("\"/admin/ws\"") |> should.be_true
  entry |> contains("admin_authenticated(req)") |> should.be_true
  entry
  |> contains("authentication.verify_password(")
  |> should.be_false
  entry
  |> contains("authentication.verify_sign_in_code(")
  |> should.be_true
  entry
  |> contains("authentication.issue_cookie(")
  |> should.be_true
  entry
  |> contains("session_id:,")
  |> should.be_true
  entry
  |> contains("set_cookie_header(authentication.clear_cookie())")
  |> should.be_true
  entry |> contains("sign_in_html") |> should.be_false
  entry |> contains("response.prepend_header(") |> should.be_true
  entry |> contains("is_safe_return_to") |> should.be_true
  entry
  |> contains("uri.percent_encode(target)")
  |> should.be_true

  admin_authentication
  |> contains("authentication_runtime.verify(")
  |> should.be_false
  admin_authentication
  |> contains("authentication_runtime.verify_sign_in_code(")
  |> should.be_true
}

pub fn fan_user_cannot_admin_test() {
  let conn = test_users_db()
  authentication_context_loader.can_access_admin(db: conn, user_id: 1)
  |> should.be_true
  authentication_context_loader.can_access_admin(db: conn, user_id: 2)
  |> should.be_false
  authentication_context_loader.can_access_admin(db: conn, user_id: 99)
  |> should.be_false
}

pub fn entry_passes_db_to_verify_sign_in_code_test() {
  let entry = read("src/generated/entry.gleam")

  entry |> contains("db: server_context.db") |> should.be_true
  entry |> contains("authentication.verify_sign_in_code(") |> should.be_true
  entry |> contains("password:") |> should.be_false
}

pub fn fan_signed_cookie_produces_non_admin_user_id_test() {
  let session_id = "test-session-fan"
  let cookie = authentication.issue_cookie(session_id:, user_id: 2)
  let assert authentication_runtime.SetCookie(name:, value:, max_age: _) =
    cookie

  let cookie_header = name <> "=" <> value
  authentication.authenticated_user_id(
    cookie_header: Ok(cookie_header),
    session_id:,
  )
  |> should.equal(option.Some(2))

  let conn = test_users_db()
  authentication_context_loader.can_access_admin(db: conn, user_id: 2)
  |> should.be_false
}

pub fn admin_user_cookie_passes_admin_gate_test() {
  let session_id = "test-session-admin"
  let cookie = authentication.issue_cookie(session_id:, user_id: 1)
  let assert authentication_runtime.SetCookie(name:, value:, max_age: _) =
    cookie

  let cookie_header = name <> "=" <> value
  authentication.authenticated_user_id(
    cookie_header: Ok(cookie_header),
    session_id:,
  )
  |> should.equal(option.Some(1))

  let conn = test_users_db()
  authentication_context_loader.can_access_admin(db: conn, user_id: 1)
  |> should.be_true
}

pub fn entry_returns_forbidden_when_user_can_access_admin_is_false_test() {
  let entry = read("src/generated/entry.gleam")

  // The admin mount handler calls user_can_access_admin, and on False returns 403
  entry |> contains("user_can_access_admin(req,") |> should.be_true
  entry |> contains("False -> forbidden()") |> should.be_true
}

pub fn public_sign_in_pages_are_client_routes_test() {
  let client = read("../client/src/scoreboard_public_client.gleam")
  let route = read("../shared/src/generated/public/route.gleam")
  let router = read("../client/src/generated/public/router.gleam")

  route |> contains("SignIn") |> should.be_true
  route |> contains("SignInPassword") |> should.be_false
  route |> contains("SignInCode") |> should.be_false
  router |> contains("[\"sign_in\"]") |> should.be_true
  router
  |> contains("[\"sign_in\", \"password\"]")
  |> should.be_false
  router |> contains("[\"sign_in\", \"code\"]") |> should.be_false
  client
  |> contains("public_route.SignInPassword")
  |> should.be_false
  client |> contains("public_route.SignInCode") |> should.be_false
  client |> contains("password") |> should.be_false
  client |> contains("Demo sign-in code: A1Z9Q") |> should.be_true
  client
  |> contains("attribute.value(\"admin@example.com\")")
  |> should.be_true
  client |> contains("attribute.value(\"A1Z9Q\")") |> should.be_true
  client
  |> contains("attribute.action(\"/sign_in\")")
  |> should.be_true
}

pub fn update_game_final_sql_only_updates_final_state_test() {
  let sql = read("src/server/sql/games/update_game_final.sql")

  sql |> contains("period = 'Final'") |> should.be_true
  sql |> contains("final = 1") |> should.be_true
  // Score columns should not appear in the SET clause
  sql |> contains("home_score =") |> should.be_false
  sql |> contains("away_score =") |> should.be_false
  // RETURNING may read scores back, that's fine
}

pub fn generated_files_stay_under_top_level_generated_dirs_test() {
  file_exists("src/generated/sql/server/games_sql.gleam") |> should.be_true
  file_exists("src/generated/sql/server/standings_sql.gleam") |> should.be_true
  file_exists("src/generated/sql/server/teams_sql.gleam") |> should.be_true
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
  |> contains("public_to_client_dispatch.apply_to_client(model.pages, event)")
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
  |> contains("admin_to_client_dispatch.apply_to_client(model.pages, event)")
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
  let admin_games_client = read("../client/src/client/admin/pages/games.gleam")

  // Admin client calls init_requests() instead of hardcoding ToServer commands.
  admin_client
  |> contains("admin_games_page.init_requests()")
  |> should.be_true
  admin_games_client
  |> contains("games: upsert_game(games: model.games, detail: game)")
  |> should.be_true
}

pub fn admin_final_games_do_not_show_final_action_test() {
  let admin_client = read("../client/src/scoreboard_admin_client.gleam")
  let admin_games_client = read("../client/src/client/admin/pages/games.gleam")
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
  |> contains("admin_games_client.MarkFinal(game_id)")
  |> should.be_true
  admin_games_client
  |> contains("MarkFinal(game_id)")
  |> should.be_true
}

pub fn admin_score_controls_live_next_to_team_names_test() {
  let admin_client = read("../client/src/scoreboard_admin_client.gleam")
  let admin_games_client = read("../client/src/client/admin/pages/games.gleam")
  let admin_games_page = read("../shared/src/shared/admin/pages/games.gleam")
  let admin_shell = read("src/server/admin/shell.html")

  admin_games_page
  |> contains("attribute.class(\"admin-score-row\")")
  |> should.be_true
  admin_client
  |> contains("admin_games_client.AdjustAway(")
  |> should.be_true
  admin_client
  |> contains("admin_games_client.AdjustHome(")
  |> should.be_true
  admin_games_client
  |> contains("AdjustAway(game_id, home_score, away_score, delta)")
  |> should.be_true
  admin_games_client
  |> contains("AdjustHome(game_id, home_score, away_score, delta)")
  |> should.be_true
  admin_games_client
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

pub fn game_status_returns_final_when_final_is_1_test() {
  // Regression: final=0 with period "Final" returns Live("Final"), not Final.
  // correct_result must use the final_admin_result row (final=1), not the
  // update_admin_score row (final=0).
  case domain.game_status(1, "Final") {
    game.Final -> Nil
    _ -> should.be_true(False)
  }
}

pub fn game_status_returns_live_when_final_is_0_test() {
  case domain.game_status(0, "Final") {
    game.Live("Final") -> Nil
    _ -> should.be_true(False)
  }
}

pub fn correct_result_returns_final_status_test() {
  let conn = test_db_with_game()
  let context = ServerContext(db: conn, system_db: conn)
  let request_context =
    RequestContext(
      route: admin_route.NotFound,
      query: dict.new(),
      session_id: "test",
      user_id: option.Some(1),
      hostname: "localhost",
    )

  let #(_, effect) =
    admin_games_handler.correct_result(
      game_id: 1,
      home_score: 5,
      away_score: 3,
      request_context:,
      server_context: context,
      backend_model: Model,
    )

  effect_runner.run_to_client_effect(effect, fn(msg) {
    case msg {
      to_client.ResultSaved(game:) -> {
        case game.status {
          game.Final -> Nil
          _ -> should.be_true(False)
        }
      }
      _ -> Nil
    }
  })
}

fn test_db_with_game() -> sqlight.Connection {
  let assert Ok(conn) = db.open(":memory:")
  let assert Ok(Nil) =
    sqlight.exec(
      "CREATE TABLE teams (code TEXT PRIMARY KEY, name TEXT NOT NULL, slug TEXT NOT NULL)",
      on: conn,
    )
  let assert Ok(Nil) =
    sqlight.exec(
      "CREATE TABLE games (id INTEGER PRIMARY KEY, home_code TEXT NOT NULL REFERENCES teams(code), away_code TEXT NOT NULL REFERENCES teams(code), home_score INTEGER NOT NULL DEFAULT 0, away_score INTEGER NOT NULL DEFAULT 0, period TEXT NOT NULL DEFAULT 'Scheduled', final INTEGER NOT NULL DEFAULT 0, CHECK (home_code <> away_code), CHECK (final IN (0, 1)))",
      on: conn,
    )
  let assert Ok(Nil) =
    sqlight.exec(
      "INSERT INTO teams (code, name, slug) VALUES ('TOR', 'Toronto', 'toronto'), ('NYC', 'New York', 'new-york')",
      on: conn,
    )
  let assert Ok(Nil) =
    sqlight.exec(
      "INSERT INTO games (id, home_code, away_code, home_score, away_score, period, final) VALUES (1, 'TOR', 'NYC', 2, 1, '3rd', 0)",
      on: conn,
    )
  conn
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
  public_ws |> contains("decode_ws_rpc_envelope") |> should.be_false
  admin_ws |> contains("decode_ws_rpc_envelope") |> should.be_false
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
  |> contains("label: \"Admin\"")
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
  |> contains("attribute.href(\"/sign_out\")")
  |> should.be_true
}

pub fn public_routes_have_matching_page_handlers_test() {
  read("src/server/public/pages/games.gleam")
  read("src/server/public/pages/games/id_.gleam")
  read("src/server/public/pages/standings.gleam")

  let dispatch = read("src/generated/public/dispatch.gleam")
  dispatch
  |> contains("server_public_pages_games.load_games(")
  |> should.be_true
  dispatch
  |> contains("server_public_pages_games_id_.load_game(")
  |> should.be_true
  dispatch
  |> contains("server_public_pages_standings.load_standings(")
  |> should.be_true
  dispatch
  |> contains("server_public_pages_teams_slug_.load_team(")
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

pub fn admin_ssr_handler_loads_and_encodes_client_shared_state_test() {
  let admin_ssr = read("src/generated/admin/ssr_handler.gleam")
  let admin_loader = read("src/server/admin/client_shared_state_loader.gleam")

  admin_ssr
  |> contains("import server/admin/client_shared_state_loader")
  |> should.be_true
  admin_ssr |> contains("client_shared_state_loader.load(") |> should.be_true
  admin_ssr
  |> contains("libero_wire.encode_flags(context)")
  |> should.be_true
  admin_ssr |> contains("client_shared_state_base64:") |> should.be_true
  admin_loader |> contains("authentication_context") |> should.be_true
  admin_loader
  |> contains("league_name: \"Rally Rec League\"")
  |> should.be_true
}

pub fn public_ssr_handler_loads_and_encodes_client_shared_state_test() {
  let public_ssr = read("src/generated/public/ssr_handler.gleam")
  let public_loader = read("src/server/public/client_shared_state_loader.gleam")

  public_ssr
  |> contains("import server/public/client_shared_state_loader")
  |> should.be_true
  public_ssr |> contains("client_shared_state_loader.load(") |> should.be_true
  public_ssr
  |> contains("libero_wire.encode_flags(context)")
  |> should.be_true
  public_ssr |> contains("client_shared_state_base64:") |> should.be_true
  public_loader
  |> contains("league_name: \"Rally Rec League\"")
  |> should.be_true
}

pub fn ssr_runtime_injects_client_shared_state_into_shell_test() {
  let runtime = read("src/generated/runtime/ssr.gleam")

  // ClientSharedState uses its own window variable.
  runtime
  |> contains("window.__RUNTIME_CLIENT_SHARED_STATE__")
  |> should.be_true
  runtime |> contains("client_shared_state_base64") |> should.be_true
  // ToClient page data uses a separate window variable so both payloads
  // can coexist without collision.
  runtime |> contains("window.__RUNTIME_SSR_TO_CLIENT__") |> should.be_true
  runtime |> contains("shared_state_base64") |> should.be_true
}

pub fn admin_and_public_client_shared_states_are_different_types_test() {
  let admin_ctx = read("../shared/src/shared/admin/client_shared_state.gleam")
  let public_ctx = read("../shared/src/shared/public/client_shared_state.gleam")

  admin_ctx |> contains("AuthenticationContext") |> should.be_true
  admin_ctx |> contains("dark_mode: Bool") |> should.be_true
  admin_ctx |> contains("toast: Option(String)") |> should.be_true

  public_ctx |> contains("AuthenticationContext") |> should.be_true
  public_ctx |> contains("dark_mode: Bool") |> should.be_false
  public_ctx |> contains("toast: Option(String)") |> should.be_false
}

pub fn ssr_shell_embeds_context_base64_in_response_body_test() {
  let resp =
    ssr.render_shell_response(
      shell_path: "src/server/admin/shell.html",
      page_html: "<p>test</p>",
      shared_state_base64: "",
      client_shared_state_base64: "dGVzdC1jb250ZXh0",
      fallback_shell: "<html><head></head><body><div id=\"app\"></div></body></html>",
    )
  case resp.body {
    mist.Bytes(tree) -> {
      let bits = bytes_tree.to_bit_array(tree)
      let assert Ok(html) = bit_array.to_string(bits)
      html
      |> contains("window.__RUNTIME_CLIENT_SHARED_STATE__='dGVzdC1jb250ZXh0'")
      |> should.be_true
    }
    _ -> should.be_true(False)
  }
}

pub fn ssr_shell_embeds_both_payloads_without_collision_test() {
  let resp =
    ssr.render_shell_response(
      shell_path: "src/server/admin/shell.html",
      page_html: "<p>test</p>",
      shared_state_base64: "dG9fY2xpZW50X3BhZ2VfZGF0YQ==",
      client_shared_state_base64: "Y2xpZW50X3NoYXJlZF9zdGF0ZQ==",
      fallback_shell: "<html><head></head><body><div id=\"app\"></div></body></html>",
    )
  case resp.body {
    mist.Bytes(tree) -> {
      let bits = bytes_tree.to_bit_array(tree)
      let assert Ok(html) = bit_array.to_string(bits)
      // Both payloads appear in distinct window variables.
      html
      |> contains(
        "window.__RUNTIME_SSR_TO_CLIENT__='dG9fY2xpZW50X3BhZ2VfZGF0YQ=='",
      )
      |> should.be_true
      html
      |> contains(
        "window.__RUNTIME_CLIENT_SHARED_STATE__='Y2xpZW50X3NoYXJlZF9zdGF0ZQ=='",
      )
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
    AdminClientSharedState(
      authentication_context: option.Some(auth_ctx),
      league_name: "Rally Rec League",
      dark_mode: False,
      active_section: "games",
      toast: option.None,
    )

  let encoded = libero_wire.encode_flags(context)
  let result: Result(AdminClientSharedState, DecodeError) =
    libero_wire.decode_flags_typed(encoded, "admin_client_shared_state")
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

pub fn client_setup_exposes_read_client_shared_state_test() {
  let setup_gleam = read("../client/src/generated/setup.gleam")
  let setup_js = read("../client/src/generated/setup_ffi.mjs")

  // ClientSharedState reader.
  setup_gleam |> contains("read_client_shared_state") |> should.be_true
  setup_js |> contains("readClientSharedState") |> should.be_true
  setup_js |> contains("__RUNTIME_CLIENT_SHARED_STATE__") |> should.be_true
  // ToClient page-data reader uses a separate window variable.
  setup_gleam |> contains("read_ssr_to_client") |> should.be_true
  setup_js |> contains("readSsrToClient") |> should.be_true
  setup_js |> contains("__RUNTIME_SSR_TO_CLIENT__") |> should.be_true
  setup_js |> contains("ssrWindow") |> should.be_true
}

pub fn client_shared_state_constructors_are_registered_for_etf_test() {
  let codec = read("../client/src/generated/codec_ffi.mjs")
  let atoms = read("src/generated/server_generated_protocol_atoms_ffi.erl")

  codec |> contains("authentication_context") |> should.be_true
  codec |> contains("admin_client_shared_state") |> should.be_true
  codec |> contains("public_client_shared_state") |> should.be_true
  codec
  |> contains("authenticationContext.AuthenticationContext, 3")
  |> should.be_true
  codec
  |> contains("adminClientSharedState.AdminClientSharedState, 5")
  |> should.be_true
  codec
  |> contains("publicClientSharedState.PublicClientSharedState, 4")
  |> should.be_true
  atoms |> contains("<<\"authentication_context\">>") |> should.be_true
  atoms |> contains("<<\"admin_client_shared_state\">>") |> should.be_true
  atoms |> contains("<<\"public_client_shared_state\">>") |> should.be_true
}

pub fn admin_client_stores_and_renders_context_test() {
  let admin_client = read("../client/src/scoreboard_admin_client.gleam")

  admin_client
  |> contains(
    "import shared/admin/client_shared_state.{type AdminClientSharedState}",
  )
  |> should.be_true
  admin_client
  |> contains("context: Option(AdminClientSharedState)")
  |> should.be_true
  admin_client |> contains("setup.read_client_shared_state()") |> should.be_true
  admin_client
  |> contains("authentication_context.display_label(ac)")
  |> should.be_true
  admin_client |> contains("ctx.league_name <> \" admin\"") |> should.be_true
}

pub fn public_client_stores_context_test() {
  let public_client = read("../client/src/scoreboard_public_client.gleam")

  public_client
  |> contains(
    "import shared/public/client_shared_state.{type PublicClientSharedState}",
  )
  |> should.be_true
  public_client
  |> contains("context: Option(PublicClientSharedState)")
  |> should.be_true
  public_client
  |> contains("setup.read_client_shared_state()")
  |> should.be_true
  public_client |> contains("ctx.league_name") |> should.be_true
}

pub fn entry_passes_authentication_context_to_admin_ssr_test() {
  let entry = read("src/generated/entry.gleam")
  let admin_ssr = read("src/generated/admin/ssr_handler.gleam")

  entry
  |> contains("import server/authentication_context_loader")
  |> should.be_true
  entry
  |> contains("authentication_context_loader.from_user_id(")
  |> should.be_true
  entry
  |> contains("db: server_context.db")
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
  let conn = test_users_db()
  let admin = authentication_context_loader.from_user_id(db: conn, user_id: 1)
  case admin {
    option.Some(ctx) -> {
      ctx.user_id |> should.equal(1)
      ctx.email |> should.equal("admin@example.com")
      ctx.display_name |> should.equal(option.None)
    }
    option.None -> should.be_true(False)
  }

  let fan = authentication_context_loader.from_user_id(db: conn, user_id: 2)
  case fan {
    option.Some(ctx) -> {
      ctx.user_id |> should.equal(2)
      ctx.email |> should.equal("fan@example.com")
      ctx.display_name |> should.equal(option.Some("Fan"))
    }
    option.None -> should.be_true(False)
  }

  authentication_context_loader.from_user_id(db: conn, user_id: 99)
  |> should.equal(option.None)
}

pub fn can_access_admin_returns_true_for_admin_user_test() {
  let conn = test_users_db()
  authentication_context_loader.can_access_admin(db: conn, user_id: 1)
  |> should.be_true
}

pub fn can_access_admin_returns_false_for_non_admin_users_test() {
  let conn = test_users_db()
  authentication_context_loader.can_access_admin(db: conn, user_id: 2)
  |> should.be_false
  authentication_context_loader.can_access_admin(db: conn, user_id: 99)
  |> should.be_false
}

pub fn public_context_loader_sets_can_access_admin_when_user_is_admin_test() {
  let conn = test_users_db()
  let auth_ctx =
    authentication_context.AuthenticationContext(
      user_id: 1,
      email: "admin@example.com",
      display_name: option.None,
    )
  let ctx =
    public_client_shared_state_loader.load(
      db: conn,
      route: public_route.Games,
      authentication_context: option.Some(auth_ctx),
    )
  ctx.can_access_admin |> should.be_true
}

pub fn public_context_loader_sets_can_access_admin_false_for_non_admin_test() {
  let conn = test_users_db()
  let auth_ctx =
    authentication_context.AuthenticationContext(
      user_id: 2,
      email: "fan@example.com",
      display_name: option.Some("Fan"),
    )
  let ctx =
    public_client_shared_state_loader.load(
      db: conn,
      route: public_route.Games,
      authentication_context: option.Some(auth_ctx),
    )
  ctx.can_access_admin |> should.be_false
}

pub fn entry_gates_admin_routes_on_can_access_admin_test() {
  let entry = read("src/generated/entry.gleam")

  entry |> contains("user_can_access_admin") |> should.be_true
  entry |> contains("can_access_admin(") |> should.be_true
  entry |> contains("forbidden()") |> should.be_true
}

pub fn public_client_nav_shows_admin_only_when_can_access_admin_test() {
  let public_client = read("../client/src/scoreboard_public_client.gleam")

  public_client |> contains("can_access_admin") |> should.be_true
  public_client
  |> contains("ctx.can_access_admin")
  |> should.be_true
}

pub fn admin_authenticated_and_user_can_access_admin_are_separate_checks_test() {
  let entry = read("src/generated/entry.gleam")

  entry |> contains("admin_authenticated") |> should.be_true
  entry |> contains("user_can_access_admin") |> should.be_true
  // user_can_access_admin is called after admin_authenticated passes
  entry
  |> contains("True ->")
  |> should.be_true
}

pub fn admin_context_loader_passes_authentication_context_through_test() {
  let auth_ctx =
    authentication_context.AuthenticationContext(
      user_id: 1,
      email: "admin@example.com",
      display_name: option.None,
    )

  let ctx =
    admin_client_shared_state_loader.load(
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

pub fn admin_context_loader_preserves_authentication_context_test() {
  let auth_ctx =
    authentication_context.AuthenticationContext(
      user_id: 1,
      email: "admin@example.com",
      display_name: option.None,
    )
  let ctx =
    admin_client_shared_state_loader.load(
      route: admin_route.AdminGames,
      authentication_context: option.Some(auth_ctx),
      dark_mode: False,
    )
  case ctx.authentication_context {
    option.Some(ac) -> ac.email |> should.equal("admin@example.com")
    option.None -> should.be_true(False)
  }
  ctx.active_section |> should.equal("games")
}

pub fn public_context_loader_returns_expected_shape_test() {
  let conn = test_users_db()
  let ctx =
    public_client_shared_state_loader.load(
      db: conn,
      route: public_route.Games,
      authentication_context: option.None,
    )
  ctx.league_name |> should.equal("Rally Rec League")
  ctx.active_section |> should.equal("games")

  let standings_ctx =
    public_client_shared_state_loader.load(
      db: conn,
      route: public_route.Standings,
      authentication_context: option.None,
    )
  standings_ctx.active_section |> should.equal("standings")
}

fn test_users_db() -> sqlight.Connection {
  let assert Ok(conn) = db.open(":memory:")
  let assert Ok(Nil) =
    sqlight.exec(
      "CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        display_name TEXT,
        sign_in_code_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'fan' CHECK (role IN ('admin', 'fan')),
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )",
      on: conn,
    )
  let assert Ok(Nil) =
    sqlight.exec(
      "INSERT OR IGNORE INTO users (email, display_name, sign_in_code_hash, role) VALUES "
        <> "('admin@example.com', NULL, '$runtime-sign-in-code-hmac-sha256$v=1$FY-UwgWkAUbUUAjKZIrySIhmkDwEniQHxhEw7QwbcGU', 'admin'),"
        <> "('fan@example.com', 'Fan', '$runtime-sign-in-code-hmac-sha256$v=1$26QkhMJZyJsBDiH3ae0NfkdhN2ynV41mmuBmMphzqB8', 'fan')",
      on: conn,
    )
  conn
}

// ---------------------------------------------------------------------------
// ToClient mini-update convention enforcement
// ---------------------------------------------------------------------------

pub fn generated_to_client_dispatch_owns_models_bundle_test() {
  let public_tc = read("../client/src/generated/public/to_client.gleam")
  let admin_tc = read("../client/src/generated/admin/to_client.gleam")

  // Generated dispatch owns a page-model bundle.
  public_tc |> contains("pub type Models {") |> should.be_true
  admin_tc |> contains("pub type Models {") |> should.be_true

  // Generated dispatch initializes the bundle from page init functions.
  public_tc |> contains("pub fn init() -> Models {") |> should.be_true
  admin_tc |> contains("pub fn init() -> Models {") |> should.be_true

  // Generated dispatch applies ToClient directly to page models.
  public_tc |> contains("pub fn apply_to_client(") |> should.be_true
  admin_tc |> contains("pub fn apply_to_client(") |> should.be_true

  // Generated dispatch has a browser-event update path.
  public_tc |> contains("pub fn update_page(") |> should.be_true
  admin_tc |> contains("pub fn update_page(") |> should.be_true
}

pub fn generated_to_client_dispatch_does_not_return_list_msg_test() {
  let public_tc = read("../client/src/generated/public/to_client.gleam")
  let admin_tc = read("../client/src/generated/admin/to_client.gleam")

  // Server-emitted ToClient values are applied directly; dispatch does not
  // return List(Msg) for server events.
  public_tc
  |> contains("to_client(msg: ToClient) -> List(Msg)")
  |> should.be_false
  admin_tc
  |> contains("to_client(msg: ToClient) -> List(Msg)")
  |> should.be_false
}

pub fn generated_to_client_module_comments_describe_mini_update_convention_test() {
  let public_tc = read("../client/src/generated/public/to_client.gleam")
  let admin_tc = read("../client/src/generated/admin/to_client.gleam")

  // Comments document the mini-update convention.
  public_tc
  |> contains("ToClient is the server-event vocabulary")
  |> should.be_true
  public_tc
  |> contains("Server events are applied as page")
  |> should.be_true
  admin_tc
  |> contains("ToClient is the server-event vocabulary")
  |> should.be_true

  // Comments document the local Msg boundary.
  public_tc
  |> contains("Local page Msg is for browser-originated events only")
  |> should.be_true
  admin_tc
  |> contains("Local page Msg is for browser-originated events only")
  |> should.be_true

  // Comments document that generated dispatch owns plumbing and effect batching.
  public_tc
  |> contains("owns page-model bundle plumbing and effect batching")
  |> should.be_true
  admin_tc
  |> contains("owns page-model bundle plumbing and effect batching")
  |> should.be_true
}

pub fn client_toclient_handlers_return_model_effect_test() {
  let pages = [
    "../client/src/client/public/pages/games.gleam",
    "../client/src/client/public/pages/games/id_.gleam",
    "../client/src/client/public/pages/standings.gleam",
    "../client/src/client/public/pages/teams/slug_.gleam",
    "../client/src/client/admin/pages/games.gleam",
  ]

  list.each(pages, fn(path) {
    let page = read(path)

    // Each page has at least one mini-update handler that receives the
    // page model as the first argument.
    page
    |> contains("model model: Model,")
    |> should.be_true

    // Mini-update handlers return #(Model, Effect(Msg)).
    page
    |> contains("#(Model(")
    |> should.be_true
  })
}

pub fn public_page_msg_does_not_mirror_toclient_constructors_test() {
  let games = read("../client/src/client/public/pages/games.gleam")
  let game_detail = read("../client/src/client/public/pages/games/id_.gleam")
  let standings = read("../client/src/client/public/pages/standings.gleam")
  let team = read("../client/src/client/public/pages/teams/slug_.gleam")

  // Public page Msg types must not contain protocol-shaped constructors
  // that only mirror ToClient values.
  games |> contains("LoadedGames") |> should.be_false
  games |> contains("UpdatedScore") |> should.be_false
  games |> contains("LoadFailed") |> should.be_false
  game_detail |> contains("LoadedGame") |> should.be_false
  game_detail |> contains("UpdatedScore") |> should.be_false
  game_detail |> contains("LoadFailed") |> should.be_false
  standings |> contains("LoadedStandings") |> should.be_false
  standings |> contains("LoadedPowerRankings") |> should.be_false
  team |> contains("LoadedTeam") |> should.be_false
  team |> contains("UpdatedScore") |> should.be_false
  team |> contains("LoadFailed") |> should.be_false
}

pub fn admin_page_msg_keeps_browser_events_removes_protocol_constructors_test() {
  let admin = read("../client/src/client/admin/pages/games.gleam")

  // Admin page Msg keeps real browser-originated events.
  admin |> contains("CreateGame") |> should.be_true
  admin |> contains("UpdateHomeCode") |> should.be_true
  admin |> contains("UpdateAwayCode") |> should.be_true
  admin |> contains("AdjustHome") |> should.be_true
  admin |> contains("AdjustAway") |> should.be_true
  admin |> contains("MarkFinal") |> should.be_true

  // Admin page Msg does not contain protocol-shaped constructors that
  // only mirror ToClient values.
  admin |> contains("LoadedGames") |> should.be_false
  admin |> contains("CreatedGame") |> should.be_false
  admin |> contains("SavedGame") |> should.be_false
  admin |> contains("ScoreUpdated") |> should.be_false
  admin |> contains("Failed") |> should.be_false
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

pub fn public_to_client_dispatch_uses_snake_case_handler_names_test() {
  let dispatch = read("../client/src/generated/public/to_client.gleam")

  dispatch |> contains("games.games_loaded(") |> should.be_true
  dispatch |> contains("games.game_created(") |> should.be_true
  dispatch |> contains("games.game_updated(") |> should.be_true
  dispatch |> contains("games.games_load_failed(") |> should.be_true
  dispatch |> contains("team.team_loaded(") |> should.be_true
  dispatch |> contains("standings.standings_loaded(") |> should.be_true
  dispatch |> contains("standings.power_rankings_loaded(") |> should.be_true
  dispatch |> contains("game_detail.game_loaded(") |> should.be_true
  dispatch |> contains("game_detail.game_updated(") |> should.be_true
  dispatch |> contains("game_detail.games_load_failed(") |> should.be_true
}

pub fn admin_to_client_dispatch_uses_snake_case_handler_names_test() {
  let dispatch = read("../client/src/generated/admin/to_client.gleam")

  dispatch |> contains("games.admin_games_loaded(") |> should.be_true
  dispatch |> contains("games.game_created(") |> should.be_true
  dispatch |> contains("games.game_updated(") |> should.be_true
  dispatch |> contains("games.score_update_saved(") |> should.be_true
  dispatch |> contains("games.result_saved(") |> should.be_true
  dispatch |> contains("games.admin_error(") |> should.be_true
}

pub fn public_server_dispatch_uses_handler_conventions_test() {
  let dispatch = read("src/generated/public/dispatch.gleam")

  // Each ToServer constructor maps to an explicit snake_case handler.
  dispatch
  |> contains("server_public_pages_games.load_games(")
  |> should.be_true
  dispatch
  |> contains("server_public_pages_games_id_.load_game(")
  |> should.be_true
  dispatch
  |> contains("server_public_pages_standings.load_standings(")
  |> should.be_true
  dispatch
  |> contains("server_public_pages_teams_slug_.load_team(")
  |> should.be_true

  // Other-Mount constructors are rejected, not silently ignored.
  dispatch |> contains("reject.reject_invalid_command(") |> should.be_true
}

pub fn admin_server_dispatch_uses_handler_conventions_test() {
  let dispatch = read("src/generated/admin/dispatch.gleam")

  // Each ToServer constructor maps to an explicit snake_case handler.
  dispatch
  |> contains("server_admin_pages_games.load_admin_games(")
  |> should.be_true

  // Command constructors call snake_case handlers with labeled args.
  dispatch
  |> contains("server_admin_pages_games.create_game(")
  |> should.be_true
  dispatch
  |> contains("server_admin_pages_games.update_score(")
  |> should.be_true
  dispatch |> contains("server_admin_pages_games.mark_final(") |> should.be_true
  dispatch
  |> contains("server_admin_pages_games.correct_result(")
  |> should.be_true

  // Other-Mount constructors are rejected, not silently ignored.
  dispatch |> contains("reject.reject_invalid_command(") |> should.be_true
}

pub fn to_client_dispatch_explicitly_handles_each_constructor_test() {
  let dispatch = read("../client/src/generated/public/to_client.gleam")

  // Verify each handled constructor has an explicit case branch,
  // not relying on the catch-all for constructors that have handlers.
  dispatch |> contains("to_client.GamesLoaded(") |> should.be_true
  dispatch |> contains("to_client.GameCreated(") |> should.be_true
  dispatch |> contains("to_client.GameUpdated(") |> should.be_true
  dispatch |> contains("to_client.GamesLoadFailed(") |> should.be_true
  dispatch |> contains("to_client.GameLoaded(") |> should.be_true
  dispatch |> contains("to_client.StandingsLoaded(") |> should.be_true
  dispatch |> contains("to_client.PowerRankingsLoaded(") |> should.be_true
  dispatch |> contains("to_client.TeamLoaded(") |> should.be_true
}

pub fn to_client_handlers_receive_labeled_args_not_whole_message_test() {
  // Handlers must use labeled args (label var: Type), not positional (var: Type).
  // Covers every client page module that owns ToClient handlers.

  let games = read("../client/src/client/public/pages/games.gleam")
  games |> contains("games games: List") |> should.be_true
  games |> contains("game game: GameSnapshot") |> should.be_true
  games |> contains("reason reason: String") |> should.be_true

  let game_detail = read("../client/src/client/public/pages/games/id_.gleam")
  game_detail |> contains("game game: GameDetail") |> should.be_true
  game_detail |> contains("game game: GameSnapshot") |> should.be_true
  game_detail |> contains("reason reason: String") |> should.be_true

  let standings = read("../client/src/client/public/pages/standings.gleam")
  standings |> contains("rows rows: List(StandingRow)") |> should.be_true
  standings
  |> contains("rows rows: List(PowerRankingRow)")
  |> should.be_true
  standings |> contains("game game: GameSnapshot") |> should.be_false

  let team = read("../client/src/client/public/pages/teams/slug_.gleam")
  team |> contains("team team: TeamDetail") |> should.be_true
  team |> contains("game game: GameSnapshot") |> should.be_true
  team |> contains("reason reason: String") |> should.be_true

  let admin_games = read("../client/src/client/admin/pages/games.gleam")
  admin_games |> contains("games games: List") |> should.be_true
  admin_games |> contains("game game: GameSnapshot") |> should.be_true
  admin_games |> contains("game game: AdminGameDetail") |> should.be_true
  admin_games |> contains("reason reason: String") |> should.be_true
}

pub fn standings_refresh_is_gated_by_active_public_route_test() {
  let public_tc = read("../client/src/generated/public/to_client.gleam")
  let standings = read("../client/src/client/public/pages/standings.gleam")
  let public_client = read("../client/src/scoreboard_public_client.gleam")

  public_tc |> contains("standings.game_updated(") |> should.be_false
  standings
  |> contains("send_to_server(to_server.LoadStandings)")
  |> should.be_false
  public_client
  |> contains("public_to_client.GameUpdated(_), public_route.Standings")
  |> should.be_true
  public_client |> contains("initial_load(route)") |> should.be_true
}

pub fn client_pages_own_tea_model_and_update_test() {
  let page_paths = [
    "../client/src/client/public/pages/games.gleam",
    "../client/src/client/public/pages/games/id_.gleam",
    "../client/src/client/public/pages/standings.gleam",
    "../client/src/client/public/pages/teams/slug_.gleam",
    "../client/src/client/admin/pages/games.gleam",
  ]

  list.each(page_paths, fn(path) {
    let page = read(path)
    page |> contains("pub type Model") |> should.be_true
    page |> contains("pub type Msg") |> should.be_true
    page |> contains("pub fn init() -> Model") |> should.be_true
    page
    |> contains("pub fn update(model: Model, msg: Msg)")
    |> should.be_true
  })
}

pub fn generated_update_page_delegates_to_page_update_test() {
  let public_tc = read("../client/src/generated/public/to_client.gleam")
  let admin_tc = read("../client/src/generated/admin/to_client.gleam")

  // Public update_page delegates each page message to the page's update.
  public_tc
  |> contains("games.update(models.games_page, page_msg)")
  |> should.be_true
  public_tc
  |> contains("game_detail.update(models.game_detail_page, page_msg)")
  |> should.be_true
  public_tc
  |> contains("standings.update(models.standings_page, page_msg)")
  |> should.be_true
  public_tc
  |> contains("team.update(models.team_page, page_msg)")
  |> should.be_true

  // Admin update_page delegates to the page's update.
  admin_tc
  |> contains("games.update(models.games_page, page_msg)")
  |> should.be_true
}

pub fn mount_clients_delegate_page_messages_through_update_page_test() {
  let public_client = read("../client/src/scoreboard_public_client.gleam")
  let admin_client = read("../client/src/scoreboard_admin_client.gleam")

  public_client
  |> contains("public_to_client_dispatch.update_page(model.pages, msg)")
  |> should.be_true

  admin_client
  |> contains("admin_to_client_dispatch.update_page(model.pages, msg)")
  |> should.be_true
}

pub fn shared_pages_expose_init_requests_with_function_comment_test() {
  let games = read("../shared/src/shared/public/pages/games.gleam")
  let game_detail = read("../shared/src/shared/public/pages/games/id_.gleam")
  let standings = read("../shared/src/shared/public/pages/standings.gleam")
  let team = read("../shared/src/shared/public/pages/teams/slug_.gleam")
  let admin_games = read("../shared/src/shared/admin/pages/games.gleam")

  // Each shared page exposes init_requests().
  games |> contains("pub fn init_requests()") |> should.be_true
  game_detail |> contains("pub fn init_requests(") |> should.be_true
  standings |> contains("pub fn init_requests()") |> should.be_true
  team |> contains("pub fn init_requests(") |> should.be_true
  admin_games |> contains("pub fn init_requests()") |> should.be_true

  // Each declared init_requests has the function-level comment
  // documenting that generated SSR and client init consume it.
  games |> contains("Generated SSR executes") |> should.be_true
  games |> contains("Generated client init sends") |> should.be_true
  game_detail |> contains("Generated SSR executes") |> should.be_true
  standings |> contains("Generated SSR executes") |> should.be_true
  team |> contains("Generated SSR executes") |> should.be_true
  admin_games |> contains("Generated SSR executes") |> should.be_true
}

pub fn ssr_handler_documents_init_requests_consumption_test() {
  let ssr = read("src/generated/public/ssr_handler.gleam")

  // SSR handler documents the init_requests convention.
  ssr |> contains("init_requests()") |> should.be_true
  ssr |> contains("generated client init sends") |> should.be_true
}

pub fn dispatch_documents_init_requests_convention_test() {
  let public_dispatch = read("src/generated/public/dispatch.gleam")
  let admin_dispatch = read("src/generated/admin/dispatch.gleam")

  public_dispatch
  |> contains("init_requests() declares which constructors")
  |> should.be_true
  admin_dispatch
  |> contains("init_requests() declares which constructors")
  |> should.be_true
}

pub fn dispatch_maps_every_load_constructor_to_explicit_handler_test() {
  let public_dispatch = read("src/generated/public/dispatch.gleam")
  let admin_dispatch = read("src/generated/admin/dispatch.gleam")

  // Every Load* ToServer constructor has an explicit snake_case handler.
  public_dispatch |> contains("load_games(") |> should.be_true
  public_dispatch |> contains("load_game(") |> should.be_true
  public_dispatch |> contains("load_standings(") |> should.be_true
  public_dispatch |> contains("load_team(") |> should.be_true
  admin_dispatch |> contains("load_admin_games(") |> should.be_true

  // No remaining generic load() calls in dispatch.
  public_dispatch
  |> contains("server_public_pages_games.load(")
  |> should.be_false
  admin_dispatch
  |> contains("server_admin_pages_games.load(")
  |> should.be_false
}

pub fn ssr_handler_calls_explicit_handler_names_not_generic_load_test() {
  let ssr = read("src/generated/public/ssr_handler.gleam")

  ssr |> contains("load_games(") |> should.be_true
  ssr |> contains("load_game(") |> should.be_true
  ssr |> contains("load_standings(") |> should.be_true
  ssr |> contains("load_team(") |> should.be_true
}

fn authentication_policy_name(
  policy: authentication_runtime.AuthenticationPolicy,
) -> String {
  case policy {
    authentication_runtime.Required -> "required"
    authentication_runtime.Optional -> "optional"
  }
}
