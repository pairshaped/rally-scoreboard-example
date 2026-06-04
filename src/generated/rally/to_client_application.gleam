@target(javascript)
import api/to_client.{type ToClient}
@target(javascript)
import generated/proute/admin/pages as admin_pages
@target(javascript)
import generated/proute/public/pages as public_pages
@target(javascript)
import generated/rally/admin_boot
@target(javascript)
import generated/rally/client_protocol
@target(javascript)
import generated/rally/public_boot
@target(javascript)
import lustre/effect

@target(javascript)
fn apply_public_frame(
  page page: public_pages.Page,
  frame frame: client_protocol.ServerFrame,
) -> #(public_pages.Page, effect.Effect(public_pages.Message)) {
  apply_public(page: page, message: server_frame_message(frame))
}

@target(javascript)
fn apply_admin_frame(
  page page: admin_pages.Page,
  frame frame: client_protocol.ServerFrame,
) -> #(admin_pages.Page, effect.Effect(admin_pages.Message)) {
  apply_admin(page: page, message: server_frame_message(frame))
}

@target(javascript)
pub fn decode_and_apply_public(
  page page: public_pages.Page,
  bytes bytes: BitArray,
) -> #(public_pages.Page, effect.Effect(public_pages.Message)) {
  case client_protocol.decode_server_frame(bytes) {
    Ok(frame) -> apply_public_frame(page: page, frame: frame)
    Error(Nil) -> #(page, effect.none())
  }
}

@target(javascript)
pub fn decode_and_apply_admin(
  page page: admin_pages.Page,
  bytes bytes: BitArray,
) -> #(admin_pages.Page, effect.Effect(admin_pages.Message)) {
  case client_protocol.decode_server_frame(bytes) {
    Ok(frame) -> apply_admin_frame(page: page, frame: frame)
    Error(Nil) -> #(page, effect.none())
  }
}

@target(javascript)
pub fn apply_public(
  page page: public_pages.Page,
  message message: ToClient,
) -> #(public_pages.Page, effect.Effect(public_pages.Message)) {
  public_boot.apply_message(page: page, message: message)
}

@target(javascript)
pub fn apply_admin(
  page page: admin_pages.Page,
  message message: ToClient,
) -> #(admin_pages.Page, effect.Effect(admin_pages.Message)) {
  admin_boot.apply_message(page: page, message: message)
}

@target(javascript)
fn server_frame_message(frame: client_protocol.ServerFrame) -> ToClient {
  case frame {
    client_protocol.Response(message: message) -> message
    client_protocol.Push(message: message, ..) -> message
  }
}
