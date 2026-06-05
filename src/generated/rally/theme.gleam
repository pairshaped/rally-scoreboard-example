@target(erlang)
import gleam/http/request.{type Request}
@target(erlang)
import gleam/list
@target(erlang)
import gleam/result

pub const dark_mode_cookie = "__rally_dark_mode"

@target(javascript)
pub fn ensure() -> Nil {
  Nil
}

@target(erlang)
pub fn document_attribute(req: Request(body)) -> String {
  "data-theme=\"" <> document_theme(req) <> "\""
}

@target(erlang)
pub fn document_theme(req: Request(body)) -> String {
  case request_dark_mode(req) {
    True -> "dark"
    False -> "light"
  }
}

@target(erlang)
pub fn request_dark_mode(req: Request(body)) -> Bool {
  request.get_cookies(req)
  |> list.find_map(fn(cookie) {
    case cookie.0, cookie.1 {
      name, "1" if name == dark_mode_cookie -> Ok(True)
      name, "0" if name == dark_mode_cookie -> Ok(False)
      _, _ -> Error(Nil)
    }
  })
  |> result.unwrap(False)
}
