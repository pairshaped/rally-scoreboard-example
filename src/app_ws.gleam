@target(erlang)
import generated/rally/server_ws

@target(erlang)
import gleam/dynamic/decode
@target(erlang)
import gleam/erlang/atom
@target(erlang)
import gleam/erlang/process.{type Selector}
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{type Option, None, Some}
@target(erlang)
import gleam/result

@target(erlang)
import mist.{type Next, type WebsocketConnection, type WebsocketMessage}
@target(erlang)
import sqlight

@target(erlang)
import admin/pages/games as admin_games_page
@target(erlang)
import app_api
@target(erlang)
import app_topics
@target(erlang)
import public/pages/games as public_games_page
@target(erlang)
import public/pages/games/id_ as public_game_detail_page
@target(erlang)
import public/pages/games/id_/wire as public_game_detail_wire
@target(erlang)
import public/pages/games/wire as public_games_wire
@target(erlang)
import public/pages/standings as public_standings_page
@target(erlang)
import public/pages/standings/wire as public_standings_wire
@target(erlang)
import public/pages/teams/slug_ as public_team_detail_page
@target(erlang)
import public/pages/teams/slug_/wire as public_team_detail_wire

// TYPES

@target(erlang)
pub type State {
  State(db: sqlight.Connection, admin_authorized: Bool)
}

// INIT

@target(erlang)
pub fn on_init(
  _conn: WebsocketConnection,
  db: sqlight.Connection,
  admin_authorized: Bool,
) -> #(State, Option(Selector(BitArray))) {
  app_topics.start()
  app_topics.join("app")
  let selector =
    process.new_selector()
    |> process.select_record(
      tag: atom.create("scoreboard_frame"),
      fields: 1,
      mapping: fn(msg) {
        msg
        |> decode.run(decode.at([1], decode.bit_array))
        |> result.unwrap(<<>>)
      },
    )
  #(State(db: db, admin_authorized:), Some(selector))
}

@target(erlang)
pub fn on_close(_state: State) -> Nil {
  Nil
}

// HANDLER

@target(erlang)
pub fn handler(
  state state: State,
  msg msg: WebsocketMessage(BitArray),
  conn conn: WebsocketConnection,
) -> Next(State, BitArray) {
  case msg {
    mist.Binary(data) -> {
      server_ws.handle_client_frame(
        state: state,
        conn: conn,
        data: data,
        handlers: handlers(),
      )
      mist.continue(state)
    }
    mist.Custom(frame) -> {
      let _sent = mist.send_binary_frame(conn, frame)
      mist.continue(state)
    }
    mist.Text(_) -> mist.continue(state)
    mist.Closed -> mist.stop()
    mist.Shutdown -> mist.stop()
  }
}

// HELPERS

@target(erlang)
fn handlers() -> server_ws.Handlers(State) {
  server_ws.Handlers(
    admin_games_load: load_admin_games,
    public_game_detail_load: load_public_game_detail,
    public_games_load: load_public_games,
    public_standings_load: load_public_standings,
    public_team_detail_load: load_public_team_detail,
    admin_games_save: save_admin_games,
    after_admin_games_save: after_admin_games_save,
  )
}

@target(erlang)
fn load_admin_games(
  state: State,
) -> Result(admin_games_page.LoadResult, List(server_ws.LoadError)) {
  case state.admin_authorized {
    False -> Error([server_ws.LoadError(message: "Unauthorized.")])
    True -> admin_games_page.load_wire(state.db) |> map_load_wire_result
  }
}

@target(erlang)
fn save_admin_games(
  state: State,
  message: admin_games_page.ServerMsg,
) -> Result(admin_games_page.GameUpdate, List(server_ws.SaveError)) {
  case state.admin_authorized {
    False -> Error([server_ws.SaveError(field: None, message: "Unauthorized.")])
    True ->
      case admin_games_page.handle(state.db, message) {
        Ok(game) -> Ok(game)
        Error(admin_games_page.SaveError(message: message)) ->
          Error([server_ws.SaveError(field: None, message:)])
      }
  }
}

@target(erlang)
fn after_admin_games_save(
  state: State,
  message: admin_games_page.ServerMsg,
  _game: admin_games_page.GameUpdate,
) -> Nil {
  broadcast_admin_game_update(state: state, message: message)
}

@target(erlang)
fn broadcast_admin_game_update(
  state state: State,
  message message: admin_games_page.ServerMsg,
) -> Nil {
  case admin_games_request_game_id(message) {
    Ok(game_id) ->
      case app_api.game_updated_broadcast(state.db, game_id) {
        Ok(event) ->
          app_topics.broadcast_except_self(
            "app",
            app_api.push(module: "app", message: event),
          )
        Error(Nil) -> Nil
      }
    Error(Nil) -> Nil
  }
}

@target(erlang)
fn admin_games_request_game_id(
  message: admin_games_page.ServerMsg,
) -> Result(Int, Nil) {
  case message {
    admin_games_page.AdminGamesUpdateScore(game_id, ..) -> Ok(game_id)
    admin_games_page.AdminGamesMarkFinal(game_id) -> Ok(game_id)
    admin_games_page.AdminGamesLoad -> Error(Nil)
  }
}

@target(erlang)
fn load_public_games(
  state: State,
) -> Result(public_games_wire.LoadResult, List(server_ws.LoadError)) {
  public_games_page.load_wire(state.db) |> map_load_wire_result
}

@target(erlang)
fn load_public_game_detail(
  state: State,
  game_id: Int,
) -> Result(public_game_detail_wire.LoadResult, List(server_ws.LoadError)) {
  public_game_detail_page.load_wire(state.db, game_id)
  |> map_load_wire_result
}

@target(erlang)
fn load_public_standings(
  state: State,
) -> Result(public_standings_wire.LoadResult, List(server_ws.LoadError)) {
  public_standings_page.load_wire(state.db) |> map_load_wire_result
}

@target(erlang)
fn load_public_team_detail(
  state: State,
  slug: String,
) -> Result(public_team_detail_wire.LoadResult, List(server_ws.LoadError)) {
  public_team_detail_page.load_wire(state.db, slug) |> map_load_wire_result
}

@target(erlang)
fn map_load_wire_result(
  result: Result(a, List(String)),
) -> Result(a, List(server_ws.LoadError)) {
  case result {
    Ok(value) -> Ok(value)
    Error(errors) ->
      Error(list.map(errors, fn(message) { server_ws.LoadError(message:) }))
  }
}
