//// Generated. Do not edit.
////
//// Routes ToClient messages into the admin receiver hub.
//// Derived from shared/api/to_client.gleam and client/admin/receivers.gleam.

import client/admin/receivers
import shared/api/to_client.{type ToClient}

pub fn to_client(msg: ToClient) -> List(receivers.Msg) {
  receivers.receive_active(msg)
}
