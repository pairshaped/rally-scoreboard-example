//// Encrypted/authenticated session cookie helpers.

@target(erlang)
import gleam/bit_array
@target(erlang)
import gleam/int
@target(erlang)
import gleam/list
@target(erlang)
import gleam/result
@target(erlang)
import gleam/string

@target(erlang)
pub const session_cookie = "_scoreboard_session"

@target(erlang)
const session_aad = "_scoreboard_session:v1"

@target(erlang)
const session_version = "v1"

@target(erlang)
pub type Session {
  Session(key: BitArray)
}

@target(erlang)
type Encrypted {
  Encrypted(iv: BitArray, ciphertext: BitArray, tag: BitArray)
}

@target(erlang)
pub fn new(key: BitArray) -> Session {
  Session(key:)
}

@target(erlang)
fn encode(
  payload payload: String,
  session session: Session,
) -> Result(String, Nil) {
  let plaintext = bit_array.from_string(payload)
  let aad = bit_array.from_string(session_aad)

  case encrypt(session.key, plaintext, aad) {
    Ok(encrypted) -> {
      let iv_b64 = bit_array.base64_url_encode(encrypted.iv, False)
      let cipher_b64 = bit_array.base64_url_encode(encrypted.ciphertext, False)
      let tag_b64 = bit_array.base64_url_encode(encrypted.tag, False)
      Ok(
        session_version <> "." <> iv_b64 <> "." <> cipher_b64 <> "." <> tag_b64,
      )
    }
    Error(Nil) -> Error(Nil)
  }
}

@target(erlang)
fn decode(
  encoded encoded: String,
  session session: Session,
) -> Result(String, Nil) {
  case string.split(encoded, ".") {
    [version, iv_b64, cipher_b64, tag_b64] if version == session_version -> {
      use iv <- result.try(bit_array.base64_url_decode(iv_b64))
      use ciphertext <- result.try(bit_array.base64_url_decode(cipher_b64))
      use tag <- result.try(bit_array.base64_url_decode(tag_b64))
      let aad = bit_array.from_string(session_aad)
      let data = Encrypted(iv:, ciphertext:, tag:)
      use plaintext <- result.try(decrypt(session.key, data, aad))
      bit_array.to_string(plaintext)
    }
    _ -> Error(Nil)
  }
}

@target(erlang)
pub fn decode_user_id(
  encoded encoded: String,
  session session: Session,
) -> Result(Int, Nil) {
  use payload <- result.try(decode(encoded: encoded, session: session))
  use pairs <- result.try(parse_query(payload))
  use _ <- result.try(require_version(pairs))
  use user_id_string <- result.try(list.key_find(pairs, "user_id"))
  int.parse(user_id_string)
}

@target(erlang)
pub fn encode_user_id(
  user_id user_id: Int,
  session session: Session,
) -> Result(String, Nil) {
  encode(payload: "v=1&user_id=" <> int.to_string(user_id), session: session)
}

@target(erlang)
fn parse_query(query: String) -> Result(List(#(String, String)), Nil) {
  case query {
    "" -> Ok([])
    _ ->
      query
      |> string.split("&")
      |> list.map(fn(pair) {
        case string.split(pair, "=") {
          [key, value] -> Ok(#(key, value))
          _ -> Error(Nil)
        }
      })
      |> result.all
  }
}

@target(erlang)
fn require_version(pairs: List(#(String, String))) -> Result(Nil, Nil) {
  case list.key_find(pairs, "v") {
    Ok("1") -> Ok(Nil)
    _ -> Error(Nil)
  }
}

@target(erlang)
@external(erlang, "session_crypto_ffi", "encrypt")
fn encrypt(
  key: BitArray,
  plaintext: BitArray,
  aad: BitArray,
) -> Result(Encrypted, Nil)

@target(erlang)
@external(erlang, "session_crypto_ffi", "decrypt")
fn decrypt(
  key: BitArray,
  encrypted: Encrypted,
  aad: BitArray,
) -> Result(BitArray, Nil)
