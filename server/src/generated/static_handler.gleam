//// Generated. Do not edit.
////
//// Static asset handler for client build output. The SSR shell imports
//// `/_build/client/generated/app.mjs` from the browser; this module maps that prefix
//// onto the local gleam build directory so the SPA actually loads.
//// Derived from the runtime client build output path, generated/runtime/static.gleam,
//// and the configured static URL prefix.

import generated/runtime/static
import gleam/bytes_tree
import gleam/http/response.{type Response}
import gleam/option.{type Option, None, Some}
import mist.{type ResponseData}
import simplifile

const url_prefix = "/_build/"

const filesystem_root = "../client/build/dev/javascript"

/// Returns `Some(response)` when the request is a static asset under
/// `url_prefix`; `None` otherwise, so callers fall through to normal
/// routing. Path-traversal attempts (`..`, `.`, or empty segments)
/// short-circuit to 403 Forbidden. Missing files are 404 Not Found.
pub fn try_serve(request_path: String) -> Option(Response(ResponseData)) {
  case static.strip_prefix(request_path:, url_prefix:) {
    None -> None
    Some(relative) ->
      case static.has_traversal(relative) {
        True -> Some(forbidden())
        False -> Some(serve_file(relative))
      }
  }
}

fn serve_file(relative: String) -> Response(ResponseData) {
  let file_path = static.resolve_path(filesystem_root:, relative_path: relative)
  case simplifile.is_file(file_path) {
    Ok(True) ->
      case simplifile.read_bits(file_path) {
        Ok(bits) ->
          response.new(200)
          |> response.set_header("content-type", static.content_type(relative))
          |> response.set_body(mist.Bytes(bytes_tree.from_bit_array(bits)))
        Error(reason) -> file_read_failed(reason)
      }
    _ -> not_found()
  }
}

fn not_found() -> Response(ResponseData) {
  response.new(404)
  |> response.set_body(mist.Bytes(bytes_tree.from_string("Not found")))
}

fn file_read_failed(_reason: a) -> Response(ResponseData) {
  not_found()
}

fn forbidden() -> Response(ResponseData) {
  response.new(403)
  |> response.set_body(mist.Bytes(bytes_tree.from_string("Forbidden")))
}
