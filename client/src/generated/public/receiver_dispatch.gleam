//// Generated. Do not edit.
////
//// Routes ToClient messages into the public receiver hub.
//// Derived from shared/api/to_client.gleam and client/public/receivers.gleam.

import client/public/receivers
import shared/api/to_client.{type ToClient}

pub fn to_client(msg: ToClient) -> List(receivers.Msg) {
  receivers.receive_active(msg)
}
