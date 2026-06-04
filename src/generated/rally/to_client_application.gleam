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
  case frame {
    client_protocol.Push(message: message, ..) ->
      public_boot.apply_broadcast(page: page, message:)
  }
}

@target(javascript)
fn apply_admin_frame(
  page page: admin_pages.Page,
  frame frame: client_protocol.ServerFrame,
) -> #(admin_pages.Page, effect.Effect(admin_pages.Message)) {
  case frame {
    client_protocol.Push(message: message, ..) ->
      admin_boot.apply_broadcast(page: page, message:)
  }
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
