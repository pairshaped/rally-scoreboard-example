@target(erlang)
import device_preferences
@target(erlang)
import gleam/bytes_tree
@target(erlang)
import gleam/erlang/process
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
import gleam/option.{None}
@target(erlang)
import gleam/string
@target(erlang)
import mist.{type Connection, type ResponseData}
@target(erlang)
import server/ws
@target(erlang)
import sqlight

@target(erlang)
const db_path = "db/scoreboard.db"

@target(erlang)
pub fn main() -> Nil {
  let assert Ok(db) = sqlight.open(db_path)
  let port = 8080

  let handler = fn(req: Request(Connection)) {
    let Request(path: path, ..) = req
    case path {
      "/ws" ->
        mist.websocket(
          req,
          ws.handler,
          fn(conn) { ws.on_init(conn, db) },
          ws.on_close,
        )
      _ ->
        case string.starts_with(path, "/_build/") {
          True -> serve_static(string.drop_start(path, 8))
          False -> html_response(app_html(req, path))
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
fn app_html(req: Request(Connection), path: String) -> String {
  let entrypoint = case string.starts_with(path, "/admin") {
    True -> "admin_app.mjs"
    False -> "public_app.mjs"
  }
  let theme = resolve_theme(req)

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
  <div id=\"app\"></div>
  <script type=\"module\">
    import { main } from '/_build/scoreboard_unified/" <> entrypoint <> "';
    main();
  </script>
</body>
</html>"
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
